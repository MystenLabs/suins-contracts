module suins_bbb::bbb_vault;

// === imports ===

use std::{
    type_name::{Self, TypeName},
};
use sui::{
    balance::{Balance},
    bag::{Self, Bag},
};

// === errors ===

// === constants ===

// === structs ===

/// Buy Back & Burn vault. Singleton.
public struct BBBVault has key {
    id: UID,
    balances: Bag,
}

/// One-Time Witness
public struct BBB_VAULT has drop {}

// === initialization ===

fun init(
    _otw: BBB_VAULT,
    ctx: &mut TxContext,
) {
    let vault = BBBVault {
        id: object::new(ctx),
        balances: bag::new(ctx),
    };
    transfer::share_object(vault);
}

// === package functions ===

public(package) fun add_balance<C>(
    vault: &mut BBBVault,
    balance: Balance<C>,
) {
    let balances = &mut vault.balances;
    let coin_type = type_name::get<C>();
    if (!balances.contains(coin_type)) {
        balances.add(coin_type, balance);
    } else {
        balances
            .borrow_mut<TypeName, Balance<C>>(coin_type)
            .join(balance);
    };
}

// === private functions ===

// === accessors ===

public fun id(vault: &BBBVault): ID { vault.id.to_inner() }
public fun balances(vault: &BBBVault): &Bag { &vault.balances }

// === events ===

// === test functions ===

#[test_only]
public fun init_for_testing(
    ctx: &mut TxContext,
) {
    let otw = BBB_VAULT {};
    init(otw, ctx);
}
