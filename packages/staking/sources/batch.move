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
    withdraw_cooldown_ms,
    max_lock_months,
    monthly_boost_pct,
    max_boost_pct,
};

// === errors ===

const EInvalidLockPeriod: u64 = 0;
const ECoinValueZero: u64 = 1;
const EAlreadyLocked: u64 = 2;
const EWithdrawCooldownNotOver: u64 = 3;
const EWithdrawAlreadyRequested: u64 = 4;
const EWithdrawNotRequested: u64 = 5;
const ECannotWithdrawLockedBatch: u64 = 6;

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
    withdraw_cooldown_end_ms: u64,
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
        withdraw_cooldown_end_ms: 0,
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
    // Lock the batch
    let now = clock.timestamp_ms();
    batch.unlock_ms = now + (lock_months * month_ms!());
    // Reset the withdraw request, if any
    batch.withdraw_cooldown_end_ms = 0;
}

/// Request to withdraw a batch, initiating cooldown period
public fun request_withdraw(
    batch: &mut Batch,
    clock: &Clock,
) {
    assert!(batch.withdraw_cooldown_end_ms == 0, EWithdrawAlreadyRequested);
    assert!(batch.is_staked(clock), ECannotWithdrawLockedBatch);
    let now = clock.timestamp_ms();
    batch.withdraw_cooldown_end_ms = now + withdraw_cooldown_ms!();
}

/// Withdraw balance and destroy batch after cooldown period has ended
public fun withdraw(
    batch: Batch,
    clock: &Clock,
): Balance<NS> {
    let now = clock.timestamp_ms();
    assert!(batch.withdraw_cooldown_end_ms > 0, EWithdrawNotRequested);
    assert!(now >= batch.withdraw_cooldown_end_ms, EWithdrawCooldownNotOver);

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
        power = power * monthly_boost_pct!() / 100;
        i = i + 1;
    };

    power
}

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
    batch.withdraw_cooldown_end_ms > 0 && clock.timestamp_ms() < batch.withdraw_cooldown_end_ms
}

// === accessors ===

public fun id(batch: &Batch): ID { batch.id.to_inner() }
public fun balance(batch: &Batch): &Balance<NS> { &batch.balance }
public fun start_ms(batch: &Batch): u64 { batch.start_ms }
public fun unlock_ms(batch: &Batch): u64 { batch.unlock_ms }
public fun withdraw_cooldown_end_ms(batch: &Batch): u64 { batch.withdraw_cooldown_end_ms }

// === method aliases ===

// === events ===

// === test functions ===
