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
    operations: vector<AssetOperation>,
}

public enum AssetOperation has store {
    Burn {
        type_name: TypeName,
    },
    Swap {
        type_name: TypeName,
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
        operations: vector::empty(),
    };
    transfer::share_object(config);
}

// === admin functions ===

public fun add_burn_operation<C>(
    config: &mut BBBConfig,
    _cap: &BBBAdminCap,
) {
    let operation = AssetOperation::Burn {
        type_name: type_name::get<C>(),
    };
    config.operations.push_back(operation);
}

public fun add_swap_operation<L>(
    config: &mut BBBConfig,
    _cap: &BBBAdminCap,
    pool: &Pool<L>,
) {
    let operation = AssetOperation::Swap {
        type_name: type_name::get<L>(),
        pool_id: object::id(pool),
    };
    config.operations.push_back(operation);
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
