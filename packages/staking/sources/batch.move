module staking::batch;

// === imports ===

use sui::{
    balance::Balance,
};
use token::ns::NS;

// === errors ===

// === constants ===

// === structs ===

public struct Batch has key, store {
    id: UID,
    balance: Balance<NS>,
    start_ms: u64,
    unlock_ms: u64,
    cooldown_end_ms: u64,
}

// === initialization ===

// === events ===

// === method aliases ===

// === public functions ===

// === view functions ===

// === admin functions ===

// === package functions ===

// === private functions ===

// === accessors ===

public fun id(self: &Batch): ID { self.id.to_inner() }
public fun balance(self: &Batch): &Balance<NS> { &self.balance }
public fun start_ms(self: &Batch): u64 { self.start_ms }
public fun unlock_ms(self: &Batch): u64 { self.unlock_ms }
public fun cooldown_end_ms(self: &Batch): u64 { self.cooldown_end_ms }

// === test functions ===
