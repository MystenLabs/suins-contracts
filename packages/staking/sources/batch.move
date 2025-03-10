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
use staking::constants::{
    month_ms,
    cooldown_period_ms,
    max_lock_months,
};

// === errors ===

const EInvalidLockPeriod: u64 = 0;
const EWithdrawAlreadyRequested: u64 = 1;
const EWithdrawNotRequested: u64 = 2;
const ECooldownNotOver: u64 = 3;
const ECoinValueZero: u64 = 4;
const EAlreadyLocked: u64 = 5;

// === constants ===

// === structs ===

// Represents both staked and locked batches.
public struct Batch has key {
    id: UID,
    /// Staked/locked NS balance.
    balance: Balance<NS>,
    /// When the batch was created.
    start_ms: u64,
    /// When the batch will be unlocked.
    /// For staked batches, it's equal to `start_ms` as the batch was never locked.
    /// Locked batches become staked if `clock.timestamp_ms() >= unlock_ms`
    unlock_ms: u64,
    /// When the user can withdraw their NS from the batch. It's `0` if unlock was not requested.
    cooldown_end_ms: u64,
}

// === initialization ===

// === public functions ===

/// Stake or lock NS
public fun new(
    coin: Coin<NS>,
    lock_months: u64,
    clock: &Clock,
    ctx: &mut TxContext,
): Batch {
    assert!(lock_months <= max_lock_months!(), EInvalidLockPeriod);
    assert!(coin.value() > 0, ECoinValueZero);
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

/// Lock a staked batch
public fun lock(
    batch: &mut Batch,
    lock_months: u64,
    clock: &Clock,
) {
    assert!(batch.is_staked(clock), EAlreadyLocked); // TODO should increasing lock time be allowed?
    assert!(lock_months > 0 && lock_months <= max_lock_months!(), EInvalidLockPeriod);
    // If the batch is in cooldown, abort the withdraw request
    if (batch.is_in_cooldown(clock)) {
        batch.cooldown_end_ms = 0;
    };
    let now = clock.timestamp_ms();
    batch.unlock_ms = now + (lock_months * month_ms!());
}

/// Request to withdraw a batch, initiating cooldown period
public fun request_withdraw(
    batch: &mut Batch,
    clock: &Clock,
) {
    assert!(batch.cooldown_end_ms == 0, EWithdrawAlreadyRequested);
    let now = clock.timestamp_ms();
    batch.cooldown_end_ms = now + cooldown_period_ms!();
}

/// Withdraw balance and destroy batch after cooldown period has ended
public fun withdraw(
    batch: Batch,
    clock: &Clock,
): Balance<NS> {
    let now = clock.timestamp_ms();
    assert!(batch.cooldown_end_ms > 0, EWithdrawNotRequested);
    assert!(now >= batch.cooldown_end_ms, ECooldownNotOver);

    let Batch { id, balance, .. } = batch;
    object::delete(id);
    balance
}

/// Calculate voting power for a batch based on locking and/or staking duration
public fun power(
    batch: &Batch,
    clock: &Clock,
): u64 {
    let lock_ms = batch.unlock_ms - batch.start_ms;
    let lock_months = lock_ms / month_ms!();

    // Special case: 12-month lock gets 3.0x multiplier
    if (lock_months == max_lock_months!()) {
        return (batch.balance.value() * 300) / 100
    };

    // Locked + staked months
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
        power = power * 110 / 100; // +10% per month
        i = i + 1;
    };

    power
}

// === admin functions ===

// === package functions ===

// === private functions ===

// === view functions ===

/// Check if a batch is staked
public fun is_staked(
    batch: &Batch,
    clock: &Clock,
): bool {
    clock.timestamp_ms() >= batch.unlock_ms
}

/// Check if a batch is currently locked
public fun is_locked(
    batch: &Batch,
    clock: &Clock,
): bool {
    batch.start_ms < batch.unlock_ms && clock.timestamp_ms() < batch.unlock_ms
}

/// Check if a batch is in cooldown period
public fun is_in_cooldown(
    batch: &Batch,
    clock: &Clock,
): bool {
    batch.cooldown_end_ms > 0 && clock.timestamp_ms() < batch.cooldown_end_ms
}

// === events ===

// === accessors ===

public fun id(batch: &Batch): ID { batch.id.to_inner() }
public fun balance(batch: &Batch): &Balance<NS> { &batch.balance }
public fun start_ms(batch: &Batch): u64 { batch.start_ms }
public fun unlock_ms(batch: &Batch): u64 { batch.unlock_ms }
public fun cooldown_end_ms(batch: &Batch): u64 { batch.cooldown_end_ms }

// === method aliases ===

// === test functions ===
