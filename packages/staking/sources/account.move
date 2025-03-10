module staking::account;

// === imports ===

use sui::{
    linked_table::{LinkedTable},
};
use staking::{
    batch::{Batch},
};

// === errors ===

// === constants ===

// === structs ===

public struct Account has key {
    id: UID,
    batches: LinkedTable<ID, Batch>,
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

public fun id(self: &Account): ID { self.id.to_inner() }
public fun batches(self: &Account): &LinkedTable<ID, Batch> { &self.batches }

// === test functions ===
