module suins_bbb::bbb_vault;

use std::{
    type_name::{Self, TypeName},
};
use sui::{
    balance::{Self, Balance},
    bag::{Self, Bag},
    coin::{Coin},
};

// === structs ===

/// Buy Back & Burn vault. Singleton.
/// Holds the coin balances that will be burned (or swapped & burned).
public struct BBBVault has key {
    id: UID,
    balances: Bag,
}

// === accessors ===

public fun id(vault: &BBBVault): ID { vault.id.to_inner() }
public fun balances(vault: &BBBVault): &Bag { &vault.balances }

// === constructors ===

fun new(
    ctx: &mut TxContext,
): BBBVault {
    BBBVault {
        id: object::new(ctx),
        balances: bag::new(ctx),
    }
}

// === initialization ===

public struct BBB_VAULT has drop {}

fun init(_otw: BBB_VAULT, ctx: &mut TxContext) {
    transfer::share_object(new(ctx));
}

// === public functions ===

/// Deposit a coin into the vault.
/// Anybody can deposit any coin type.
public fun deposit<C>(
    self: &mut BBBVault,
    coin: Coin<C>,
) {
    let balances = &mut self.balances;
    let coin_type = type_name::get<C>();
    if (!balances.contains(coin_type)) {
        balances.add(coin_type, coin.into_balance());
    } else {
        balances
            .borrow_mut<TypeName, Balance<C>>(coin_type)
            .join(coin.into_balance());
    };
}

// === package functions ===

/// Withdraw all `Balance<C>` from the vault.
/// Returns zero balance if the coin type is not in the vault.
public(package) fun withdraw<C>(
    self: &mut BBBVault,
): Balance<C> {
    let balances = &mut self.balances;
    let coin_type = type_name::get<C>();
    if (!balances.contains(coin_type)) {
        balance::zero()
    } else {
        balances
            .borrow_mut<TypeName, Balance<C>>(coin_type)
            .withdraw_all()
    }
}

// === test functions ===

#[test_only]
public fun new_for_testing(
    ctx: &mut TxContext,
): BBBVault {
    new(ctx)
}
