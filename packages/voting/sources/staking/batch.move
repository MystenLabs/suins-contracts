// TODO: add Stats (total staked/locked)
// TODO: add events
module suins_voting::staking_batch;

// === imports ===

use sui::{
    balance::{Balance},
    clock::{Clock},
    coin::{Coin},
    event::{emit},
    package::{Self},
};
use suins_token::{
    ns::NS,
};
use suins_voting::{
    staking_admin::{StakingAdminCap},
    staking_config::{StakingConfig},
    staking_constants::{month_ms},
};

// === errors ===

const EInvalidLockPeriod: u64 = 0;
const EBalanceTooLow: u64 = 1;
const EBatchLocked: u64 = 2;
const ECooldownAlreadyRequested: u64 = 3;
const ECooldownNotRequested: u64 = 4;
const ECooldownNotOver: u64 = 5;
const EBatchIsVoting: u64 = 6;
const EVotingUntilMsInPast: u64 = 7;
const EVotingUntilMsNotExtended: u64 = 8;

// === constants ===

// === structs ===

/// A batch of staked NS
public struct StakingBatch has key {
    id: UID,
    /// Staked NS balance.
    balance: Balance<NS>,
    /// When the batch was created.
    start_ms: u64,
    /// When the batch will be unlocked. If the batch was never locked, it's equal to `start_ms`.
    unlock_ms: u64,
    /// When the user can unstake the batch. `0` if cooldown was not requested.
    cooldown_end_ms: u64,
    /// Until when the batch is being used to vote on a proposal. `0` if never voted.
    voting_until_ms: u64,
}

/// one-time witness
public struct STAKING_BATCH has drop {}

// === initialization ===

fun init(otw: STAKING_BATCH, ctx: &mut TxContext)
{
    let publisher = package::claim(otw, ctx);
    transfer::public_transfer(publisher, ctx.sender());
}

// === public functions ===

/// Stake NS into a new batch, optionally locking it for a number of months
public fun new(
    config: &StakingConfig,
    coin: Coin<NS>,
    lock_months: u64,
    clock: &Clock,
    ctx: &mut TxContext,
): StakingBatch {
    assert!(coin.value() >= config.min_balance(), EBalanceTooLow);
    assert!(lock_months <= config.max_lock_months(), EInvalidLockPeriod);

    let now = clock.timestamp_ms();
    let batch = StakingBatch {
        id: object::new(ctx),
        balance: coin.into_balance(),
        start_ms: now,
        unlock_ms: now + (lock_months * month_ms!()),
        cooldown_end_ms: 0,
        voting_until_ms: 0,
    };

    emit(EventNew {
        batch_id: batch.id.to_address(),
        balance: batch.balance.value(),
        start_ms: batch.start_ms,
        unlock_ms: batch.unlock_ms,
    });

    batch
}

/// transfer the batch to the sender
public fun keep(
    batch: StakingBatch,
    ctx: &TxContext,
) {
    transfer::transfer(batch, ctx.sender());
}

/// Lock a staked batch, or extend the lock duration of a locked batch
public fun lock(
    batch: &mut StakingBatch,
    config: &StakingConfig,
    new_lock_months: u64,
    clock: &Clock,
) {
    assert!(!batch.is_voting(clock), EBatchIsVoting);
    assert!(!batch.is_cooldown_requested(), ECooldownAlreadyRequested);
    let old_unlock_ms = batch.unlock_ms;
    let old_lock_months = (old_unlock_ms - batch.start_ms) / month_ms!();
    assert!(new_lock_months > old_lock_months, EInvalidLockPeriod);
    assert!(new_lock_months <= config.max_lock_months(), EInvalidLockPeriod);

    // Lock the batch
    let new_unlock_ms = batch.start_ms + (new_lock_months * month_ms!());
    batch.unlock_ms = new_unlock_ms;

    emit(EventLock {
        batch_id: batch.id.to_address(),
        balance: batch.balance.value(),
        start_ms: batch.start_ms,
        old_unlock_ms,
        new_unlock_ms,
    });
}

/// Request to unstake a batch, initiating cooldown period
public fun request_unstake(
    batch: &mut StakingBatch,
    config: &StakingConfig,
    clock: &Clock,
) {
    assert!(!batch.is_voting(clock), EBatchIsVoting);
    assert!(batch.is_unlocked(clock), EBatchLocked);
    assert!(!batch.is_cooldown_requested(), ECooldownAlreadyRequested);

    let now = clock.timestamp_ms();
    let cooldown_end_ms = now + config.cooldown_ms();
    batch.cooldown_end_ms = cooldown_end_ms;

    emit(EventRequestUnstake {
        batch_id: batch.id.to_address(),
        balance: batch.balance.value(),
        cooldown_end_ms,
    });
}

/// Withdraw balance and destroy batch after cooldown period has ended
public fun unstake(
    batch: StakingBatch,
    clock: &Clock,
): Balance<NS> {
    assert!(!batch.is_voting(clock), EBatchIsVoting);
    assert!(batch.is_unlocked(clock), EBatchLocked);
    assert!(batch.is_cooldown_requested(), ECooldownNotRequested);
    assert!(batch.is_cooldown_over(clock), ECooldownNotOver);

    let batch_address = batch.id.to_address();

    let StakingBatch { id, balance, .. } = batch;
    object::delete(id);

    emit(EventUnstake {
        batch_id: batch_address,
        balance: balance.value(),
    });

    balance
}

// === admin functions ===

/// Stake NS into a new batch with arbitrary parameters
public fun admin_new(
    _: &StakingAdminCap,
    coin: Coin<NS>,
    start_ms: u64,
    unlock_ms: u64,
    ctx: &mut TxContext,
): StakingBatch {
    assert!(start_ms <= unlock_ms, EInvalidLockPeriod);

    let batch = StakingBatch {
        id: object::new(ctx),
        balance: coin.into_balance(),
        start_ms,
        unlock_ms,
        cooldown_end_ms: 0,
        voting_until_ms: 0,
    };
    batch
}

/// Allows the admin to airdrop batches
public fun admin_transfer(
    _: &StakingAdminCap,
    batch: StakingBatch,
    recipient: address,
) {
    transfer::transfer(batch, recipient);
}

// === package functions ===

/// Flag a batch as being used to vote on a proposal
public(package) fun set_voting_until_ms(
    batch: &mut StakingBatch,
    voting_until_ms: u64,
    clock: &Clock,
) {
    assert!(voting_until_ms >= clock.timestamp_ms(), EVotingUntilMsInPast);
    assert!(voting_until_ms > batch.voting_until_ms, EVotingUntilMsNotExtended);

    batch.voting_until_ms = voting_until_ms;

    emit(EventSetVoting {
        batch_id: batch.id.to_address(),
        balance: batch.balance.value(),
        voting_until_ms,
    });
}

// === private functions ===

// === view functions ===

/// Calculate voting power for a batch based on locking and/or staking duration
public fun power(
    batch: &StakingBatch,
    config: &StakingConfig,
    clock: &Clock,
): u64 {
    let mut power = batch.balance.value() as u128; // base power is the NS balance
    let mut months: u64; // how many monthly boosts to apply
    let max_months = config.max_lock_months();

    if (batch.is_locked(clock)) {
        let lock_ms = batch.unlock_ms - batch.start_ms;
        months = lock_ms / month_ms!();
        // Locking for max months gets a higher multiplier
        if (months >= max_months) {
            let max_boost = config.max_boost_bps() as u128;
            return ((power * max_boost) / 100_00) as u64
        };
    } else {
        let stake_ms = clock.timestamp_ms() - batch.start_ms;
        months = stake_ms / month_ms!();
        // Staking max boost is capped at max_months - 1
        if (months >= max_months) {
            months = max_months - 1;
        };
    };

    // Apply multiplier: monthly_boost^months
    let monthly_boost = config.monthly_boost_bps() as u128;
    let mut i = 0;
    while (i < months) {
        power = (power * monthly_boost) / 100_00;
        i = i + 1;
    };

    (power as u64)
}

public fun is_locked(
    batch: &StakingBatch,
    clock: &Clock,
): bool {
    clock.timestamp_ms() < batch.unlock_ms
}

public fun is_unlocked(
    batch: &StakingBatch,
    clock: &Clock,
): bool {
    !batch.is_locked(clock)
}

public fun is_cooldown_requested(
    batch: &StakingBatch,
): bool {
    batch.cooldown_end_ms > 0
}

public fun is_cooldown_over(
    batch: &StakingBatch,
    clock: &Clock,
): bool {
    batch.is_cooldown_requested() && clock.timestamp_ms() >= batch.cooldown_end_ms
}

public fun is_voting(
    batch: &StakingBatch,
    clock: &Clock,
): bool {
    batch.voting_until_ms > 0 && clock.timestamp_ms() < batch.voting_until_ms
}

// === accessors ===

public fun id(batch: &StakingBatch): ID { batch.id.to_inner() }
public fun balance(batch: &StakingBatch): u64 { batch.balance.value() }
public fun start_ms(batch: &StakingBatch): u64 { batch.start_ms }
public fun unlock_ms(batch: &StakingBatch): u64 { batch.unlock_ms }
public fun cooldown_end_ms(batch: &StakingBatch): u64 { batch.cooldown_end_ms }
public fun voting_until_ms(batch: &StakingBatch): u64 { batch.voting_until_ms }

// === method aliases ===

// === events ===

public struct EventNew has copy, drop {
    batch_id: address,
    balance: u64,
    start_ms: u64,
    unlock_ms: u64,
}

public struct EventLock has copy, drop {
    batch_id: address,
    balance: u64,
    start_ms: u64,
    old_unlock_ms: u64,
    new_unlock_ms: u64,
}

public struct EventRequestUnstake has copy, drop {
    batch_id: address,
    balance: u64,
    cooldown_end_ms: u64,
}

public struct EventUnstake has copy, drop {
    batch_id: address,
    balance: u64,
}

public struct EventSetVoting has copy, drop {
    batch_id: address,
    balance: u64,
    voting_until_ms: u64,
}

// === test functions ===
