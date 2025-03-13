module suins_voting::staking_batch;

// === imports ===

use sui::{
    balance::{Balance},
    clock::{Clock},
    coin::{Coin},
    event::{emit},
    package::{Self},
};
use token::{
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
const EUnstakeAlreadyRequested: u64 = 3;
const EUnstakeNotRequested: u64 = 4;
const ECooldownNotOver: u64 = 5;
const EBatchIsVoting: u64 = 6;
const EInvalidVotingUntilMs: u64 = 7;

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

    let start_ms = clock.timestamp_ms();
    let unlock_ms = start_ms + (lock_months * month_ms!());
    let coin_value = coin.value();

    let batch = StakingBatch {
        id: object::new(ctx),
        balance: coin.into_balance(),
        start_ms,
        unlock_ms,
        cooldown_end_ms: 0,
        voting_until_ms: 0,
    };

    emit(EventNew {
        batch_id: batch.id.to_address(),
        balance: coin_value,
        lock_months,
        start_ms,
        unlock_ms,
    });

    batch
}

/// transfer the batch to the sender
public fun keep(
    batch: StakingBatch,
    ctx: &mut TxContext,
) {
    transfer::transfer(batch, ctx.sender());
}

/// Lock staked tokens, or extend an existing lock
public fun lock(
    batch: &mut StakingBatch,
    config: &StakingConfig,
    new_lock_months: u64,
) {
    let curr_lock_months = (batch.unlock_ms - batch.start_ms) / month_ms!();
    assert!(new_lock_months > curr_lock_months, EInvalidLockPeriod);
    assert!(new_lock_months <= config.max_lock_months(), EInvalidLockPeriod);

    // Lock the batch
    let new_unlock_ms = batch.start_ms + (new_lock_months * month_ms!());
    batch.unlock_ms = new_unlock_ms;

    // Reset the cooldown, if any
    batch.cooldown_end_ms = 0;

    emit(EventLock {
        batch_id: batch.id.to_address(),
        balance: batch.balance.value(),
        lock_months: new_lock_months,
        unlock_ms: new_unlock_ms,
    });
}

/// Request to unstake a batch, initiating cooldown period
public fun request_unstake(
    batch: &mut StakingBatch,
    config: &StakingConfig,
    clock: &Clock,
) {
    assert!(batch.is_unlocked(clock), EBatchLocked);
    assert!(batch.cooldown_end_ms == 0, EUnstakeAlreadyRequested);

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
    assert!(batch.is_unlocked(clock), EBatchLocked);
    assert!(batch.cooldown_end_ms > 0, EUnstakeNotRequested);
    let now = clock.timestamp_ms();
    assert!(now >= batch.cooldown_end_ms, ECooldownNotOver);
    assert!(now >= batch.voting_until_ms, EBatchIsVoting);

    let batch_address = batch.id.to_address();
    let coin_value = batch.balance.value();

    let StakingBatch { id, balance, .. } = batch;
    object::delete(id);

    emit(EventUnstake {
        batch_id: batch_address,
        balance: coin_value,
    });

    balance
}

// === admin functions ===

/// Stake NS into a new batch with arbitrary start_ms and unlock_ms
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

public fun admin_transfer(
    _: &StakingAdminCap,
    batch: StakingBatch,
    recipient: address,
) {
    transfer::transfer(batch, recipient);
}

// === package functions ===

public(package) fun set_voting_until_ms(
    batch: &mut StakingBatch,
    voting_until_ms: u64,
    clock: &Clock,
) {
    assert!(voting_until_ms >= clock.timestamp_ms(), EInvalidVotingUntilMs);
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
    let lock_ms = batch.unlock_ms - batch.start_ms;
    let lock_months = lock_ms / month_ms!();

    // Special case: locking for max months gets a higher multiplier
    if (lock_months >= config.max_lock_months()) {
        let balance = batch.balance.value() as u128;
        let max_boost = config.max_boost_bps() as u128;
        return ((balance * max_boost) / 10000) as u64
    };

    // Calculate locked + staked months
    let mut total_months = lock_months;

    // Add months from staking (if any)
    let now = clock.timestamp_ms();
    if (now > batch.unlock_ms) {
        let staking_ms = now - batch.unlock_ms;
        let staking_months = staking_ms / month_ms!();
        total_months = total_months + staking_months;
    };

    // e.g. if max_lock_months is 12, cap at 11 months (which gives 2.85x multiplier)
    let max_effective_months = config.max_lock_months() - 1;
    if (total_months > max_effective_months) {
        total_months = max_effective_months;
    };

    // Apply multiplier: 1.1^total_months
    let mut power = batch.balance.value() as u128;
    let monthly_boost = config.monthly_boost_bps() as u128;
    let mut i = 0;
    while (i < total_months) {
        power = (power * monthly_boost) / 10000;
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

public fun is_in_cooldown(
    batch: &StakingBatch,
    clock: &Clock,
): bool {
    batch.cooldown_end_ms > 0 && clock.timestamp_ms() < batch.cooldown_end_ms
}

public fun is_voting(
    batch: &StakingBatch,
    clock: &Clock,
): bool {
    batch.voting_until_ms > 0 && clock.timestamp_ms() < batch.voting_until_ms
}

// === accessors ===

public fun id(batch: &StakingBatch): ID { batch.id.to_inner() }
public fun balance(batch: &StakingBatch): &Balance<NS> { &batch.balance }
public fun start_ms(batch: &StakingBatch): u64 { batch.start_ms }
public fun unlock_ms(batch: &StakingBatch): u64 { batch.unlock_ms }
public fun cooldown_end_ms(batch: &StakingBatch): u64 { batch.cooldown_end_ms }
public fun voting_until_ms(batch: &StakingBatch): u64 { batch.voting_until_ms }

// === method aliases ===

// === events ===

public struct EventNew has copy, drop {
    batch_id: address,
    balance: u64,
    lock_months: u64,
    start_ms: u64,
    unlock_ms: u64,
}

public struct EventLock has copy, drop {
    batch_id: address,
    balance: u64,
    lock_months: u64,
    unlock_ms: u64,
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
