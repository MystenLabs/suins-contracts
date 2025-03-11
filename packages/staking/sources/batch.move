module staking::batch;

// === imports ===

use sui::{
    balance::{Balance},
    clock::{Clock},
    coin::{Coin},
};
use token::{
    ns::NS,
};
use staking::config::{
    cooldown_ms,
    max_boost_pct,
    max_lock_months,
    min_balance,
    month_ms,
    monthly_boost_pct,
};

// === errors ===

const EInvalidLockPeriod: u64 = 0;
const EBalanceTooLow: u64 = 1;
const EBatchLocked: u64 = 2;
const EUnstakeAlreadyRequested: u64 = 3;
const EUnstakeNotRequested: u64 = 4;
const ECooldownNotOver: u64 = 5;

// === constants ===

// === structs ===

/// A batch of staked NS
public struct Batch has key {
    id: UID,
    /// Staked NS balance.
    balance: Balance<NS>,
    /// When the batch was created.
    start_ms: u64,
    /// When the batch will be unlocked. If the batch was never locked, it's equal to `start_ms`.
    unlock_ms: u64,
    /// When the user can unstake the batch. It's `0` if cooldown was not requested.
    cooldown_end_ms: u64,
}

// === initialization ===

// === public functions ===

/// Stake NS into a new batch, optionally locking it for a number of months
public fun new(
    coin: Coin<NS>,
    lock_months: u64,
    clock: &Clock,
    ctx: &mut TxContext,
): Batch {
    assert!(coin.value() >= min_balance!(), EBalanceTooLow);
    assert!(lock_months <= max_lock_months!(), EInvalidLockPeriod);
    let now = clock.timestamp_ms();
    let batch = Batch {
        id: object::new(ctx),
        balance: coin.into_balance(),
        start_ms: now,
        unlock_ms: now + (lock_months * month_ms!()),
        cooldown_end_ms: 0,
    };
    batch
}

/// Extend the lock period of a batch
public fun lock(
    batch: &mut Batch,
    new_lock_months: u64,
) {
    let curr_lock_months = (batch.unlock_ms - batch.start_ms) / month_ms!();
    assert!(new_lock_months > curr_lock_months, EInvalidLockPeriod);
    assert!(new_lock_months <= max_lock_months!(), EInvalidLockPeriod);
    // Lock the batch
    batch.unlock_ms = batch.start_ms + (new_lock_months * month_ms!());
    // Reset the cooldown, if any
    batch.cooldown_end_ms = 0;
}

/// Request to unstake a batch, initiating cooldown period
public fun request_unstake(
    batch: &mut Batch,
    clock: &Clock,
) {
    assert!(batch.is_unlocked(clock), EBatchLocked);
    assert!(batch.cooldown_end_ms == 0, EUnstakeAlreadyRequested);
    let now = clock.timestamp_ms();
    batch.cooldown_end_ms = now + cooldown_ms!();
}

/// Withdraw balance and destroy batch after cooldown period has ended
public fun unstake(
    batch: Batch,
    clock: &Clock,
): Balance<NS> {
    let now = clock.timestamp_ms();
    assert!(batch.cooldown_end_ms > 0, EUnstakeNotRequested);
    assert!(now >= batch.cooldown_end_ms, ECooldownNotOver);

    let Batch { id, balance, .. } = batch;
    object::delete(id);
    balance
}

// === admin functions ===

// === package functions ===

// === private functions ===

// === view functions ===

/// Calculate voting power for a batch based on locking and/or staking duration
public fun power(
    batch: &Batch,
    clock: &Clock,
): u64 {
    let lock_ms = batch.unlock_ms - batch.start_ms;
    let lock_months = lock_ms / month_ms!();

    // Special case: 12-month lock gets 3.0x multiplier
    if (lock_months == max_lock_months!()) {
        return (batch.balance.value() * max_boost_pct!()) / 100
    };

    // Calculate locked + staked months
    let mut total_months = lock_months;

    // Add months from staking (if any)
    let now = clock.timestamp_ms();
    if (now > batch.unlock_ms) {
        let stake_ms = now - batch.unlock_ms;
        let stake_months = stake_ms / month_ms!();
        total_months = total_months + stake_months;
    };

    // Cap at 11 months (which gives 2.85x multiplier)
    let max_effective_months = max_lock_months!() - 1;
    if (total_months > max_effective_months) {
        total_months = max_effective_months;
    };

    // Apply multiplier: 1.1^total_months
    let mut power = batch.balance.value();
    let mut i = 0;
    while (i < total_months) {
        power = power * monthly_boost_pct!() / 100;
        i = i + 1;
    };

    power
}

/// Check if a batch is locked
public fun is_locked(
    batch: &Batch,
    clock: &Clock,
): bool {
    clock.timestamp_ms() < batch.unlock_ms
}

/// Check if a batch is unlocked
public fun is_unlocked(
    batch: &Batch,
    clock: &Clock,
): bool {
    !batch.is_locked(clock)
}

// === accessors ===

public fun id(batch: &Batch): ID { batch.id.to_inner() }
public fun balance(batch: &Batch): &Balance<NS> { &batch.balance }
public fun start_ms(batch: &Batch): u64 { batch.start_ms }
public fun unlock_ms(batch: &Batch): u64 { batch.unlock_ms }
public fun cooldown_end_ms(batch: &Batch): u64 { batch.cooldown_end_ms }

// === method aliases ===

// === events ===

// === test functions ===
