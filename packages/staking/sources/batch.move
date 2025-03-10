module staking::batch;

// === imports ===

use sui::{
    balance::{Balance},
    clock::{Clock},
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

// === method aliases ===

// === public functions ===

/// Stake or lock NS for a given period
public fun stake(
    balance: Balance<NS>,
    lock_months: u64,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    assert!(lock_months <= max_lock_months!(), EInvalidLockPeriod);
    let now = clock.timestamp_ms();
    let batch = Batch {
        id: object::new(ctx),
        balance,
        start_ms: now,
        unlock_ms: now + (lock_months * month_ms!()),
        cooldown_end_ms: 0,
    };
    transfer::transfer(batch, ctx.sender());
}

/// Request to withdraw a batch, initiating cooldown period
public fun request_withdraw(
    self: &mut Batch,
    clock: &Clock,
) {
    assert!(self.cooldown_end_ms == 0, EWithdrawAlreadyRequested);
    let now = clock.timestamp_ms();
    self.cooldown_end_ms = now + cooldown_period_ms!();
}

/// Withdraw tokens after cooldown period has ended
public fun withdraw(
    self: Batch,
    clock: &Clock,
): Balance<NS> {
    let now = clock.timestamp_ms();
    assert!(self.cooldown_end_ms > 0, EWithdrawNotRequested);
    assert!(now >= self.cooldown_end_ms, ECooldownNotOver);

    let Batch { id, balance, .. } = self;
    object::delete(id);
    balance
}

/// Calculate voting power for a batch based on staking duration or lock period
public fun power( // TODO cap at 1.1^11 or 3x multiplier
    batch: &Batch,
    clock: &Clock,
): u64 {
    let now = clock.timestamp_ms();
    let mut multiplier_bps: u64 = 100; // 1.0x (no increase)

    // Calculate locking multiplier
    if (batch.start_ms < batch.unlock_ms) {
        // This batch was locked at some point
        let lock_duration_ms = batch.unlock_ms - batch.start_ms;
        let months_locked = lock_duration_ms / month_ms!();

        if (months_locked == max_lock_months!()) {
            // Special case: 12-month lock gets 3.0x instead of 2.85x (0.15x bonus)
            return (batch.balance.value() * 300) / 100
        } else {
            // Apply 10% increase per month
            let mut i = 0;
            while (i < months_locked) {
                multiplier_bps = multiplier_bps * 110 / 100;
                i = i + 1;
            }
        }
    };

    // Calculate staking multiplier
    if (now >= batch.unlock_ms) {
        // For regular staking batches, start_ms == unlock_ms
        // For previously locked batches, we only count additional staking time after unlock
        let staking_duration_ms = now - batch.unlock_ms;
        let staking_months = staking_duration_ms / month_ms!();

        // Apply 10% increase per month
        let mut i = 0;
        while (i < staking_months) {
            multiplier_bps = multiplier_bps * 110 / 100;
            i = i + 1;
        }
    };

    (batch.balance.value() * multiplier_bps) / 100
}

// === admin functions ===

// === package functions ===

// === private functions ===

// === helpers ===

/// Check if a batch is currently locked
public fun is_locked(
    self: &Batch,
    clock: &Clock,
): bool {
    self.start_ms < self.unlock_ms && clock.timestamp_ms() < self.unlock_ms
}

/// Check if a batch is in cooldown period
public fun is_in_cooldown(
    self: &Batch,
    clock: &Clock,
): bool {
    self.cooldown_end_ms > 0 && clock.timestamp_ms() < self.cooldown_end_ms
}

// === accessors ===

public fun id(self: &Batch): ID { self.id.to_inner() }
public fun balance(self: &Batch): &Balance<NS> { &self.balance }
public fun start_ms(self: &Batch): u64 { self.start_ms }
public fun unlock_ms(self: &Batch): u64 { self.unlock_ms }
public fun cooldown_end_ms(self: &Batch): u64 { self.cooldown_end_ms }

// === events ===

// === test functions ===
