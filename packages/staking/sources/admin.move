module staking::admin;

// === imports ===

use sui::{
    package::{Self},
};

// === errors ===

// === constants ===

// === structs ===

public struct AdminCap has key, store {
    id: UID,
}

/// one-time witness
public struct ADMIN has drop {}

// === initialization ===

fun init(otw: ADMIN, ctx: &mut TxContext)
{
    let publisher = package::claim(otw, ctx);
    transfer::public_transfer(publisher, ctx.sender());

    let admin_cap = AdminCap { id: object::new(ctx) };
    transfer::transfer(admin_cap, ctx.sender());
}

// === public functions ===

// === admin functions ===

// === package functions ===

// === private functions ===

// === view functions ===

// === accessors ===

public fun id(cap: &AdminCap): ID { cap.id.to_inner() }

// === method aliases ===

// === events ===

// === test functions ===
