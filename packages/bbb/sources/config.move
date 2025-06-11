module suins_bbb::bbb_config;

// === imports ===

use std::{
    string::{String},
    type_name::{Self, TypeName},
};
use sui::{
    event::{emit},
};
use amm::{
    pool::Pool,
};
use suins_bbb::{
    bbb_admin::{BBBAdminCap},
};

// === errors ===

const EInvalidBurnBps: u64 = 100;

// === constants: initial values ===

macro fun init_burn_bps(): u64 { 80_00 } // 80%

// === structs ===

/// Buy Back & Burn configuration. Singleton.
public struct BBBConfig has key {
    id: UID,
    /// Percentage of revenue that will be burned, in basis points
    burn_bps: u64,
    /// Operations that can be performed on assets inside the vault
    actions: vector<BBBAction>,
}

public enum BBBAction has store {
    Burn {
        coin_type: TypeName,
    },
    Swap {
        coin_type: TypeName,
        pool_id: ID,
    }
}

/// One-Time Witness
public struct BBB_CONFIG has drop {}

// === initialization ===

fun init(
    _otw: BBB_CONFIG,
    ctx: &mut TxContext,
) {
    let config = BBBConfig {
        id: object::new(ctx),
        burn_bps: init_burn_bps!(),
        actions: vector::empty(),
    };
    transfer::share_object(config);
}

// === public functions ===

// === admin functions ===

public fun add_burn_action<C>(
    config: &mut BBBConfig,
    _cap: &BBBAdminCap,
) {
    let action = BBBAction::Burn {
        coin_type: type_name::get<C>(),
    };
    config.actions.push_back(action);
}

public fun add_swap_action<L>(
    config: &mut BBBConfig,
    _cap: &BBBAdminCap,
    pool: &Pool<L>,
) {
    let action = BBBAction::Swap {
        coin_type: type_name::get<L>(),
        pool_id: object::id(pool),
    };
    config.actions.push_back(action);
}

public fun set_burn_bps(config: &mut BBBConfig, _: &BBBAdminCap, burn_bps: u64) {
    assert!(burn_bps <= 100_00, EInvalidBurnBps);
    emit_event(b"burn_bps", config.burn_bps, burn_bps);
    config.burn_bps = burn_bps;
}

// === getters TODO ===

// === private functions ===

fun emit_event(
    property: vector<u8>,
    old_value: u64,
    new_value: u64,
) {
    emit(EventConfigChange {
        property: property.to_string(),
        old_value,
        new_value,
    });
}

// === accessors ===

public fun id(config: &BBBConfig): ID { config.id.to_inner() }
public fun burn_bps(config: &BBBConfig): u64 { config.burn_bps }

// === events ===

public struct EventConfigChange has copy, drop {
    property: String,
    old_value: u64,
    new_value: u64,
}

// === test functions ===

#[test_only]
public fun init_for_testing(
    ctx: &mut TxContext,
) {
    let otw = BBB_CONFIG {};
    init(otw, ctx);
}
