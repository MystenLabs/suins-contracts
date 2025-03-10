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
};
// === errors ===

const EInvalidLockPeriod: u64 = 0;

// === constants ===

const MAX_LOCK_MONTHS: u8 = 12;

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

public fun stake(
    balance: Balance<NS>,
    lock_months: u8,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    assert!(lock_months <= MAX_LOCK_MONTHS, EInvalidLockPeriod);
    let now = clock.timestamp_ms();
    let batch = Batch {
        id: object::new(ctx),
        balance,
        start_ms: now,
        unlock_ms: now + ((lock_months as u64) * month_ms!()),
        cooldown_end_ms: 0,
    };
    transfer::transfer(batch, ctx.sender());
}

// === view functions ===

// === admin functions ===

// === package functions ===

// === private functions ===

// === events ===

// === accessors ===

public fun id(self: &Batch): ID { self.id.to_inner() }
public fun balance(self: &Batch): &Balance<NS> { &self.balance }
public fun start_ms(self: &Batch): u64 { self.start_ms }
public fun unlock_ms(self: &Batch): u64 { self.unlock_ms }
public fun cooldown_end_ms(self: &Batch): u64 { self.cooldown_end_ms }

// === test functions ===
