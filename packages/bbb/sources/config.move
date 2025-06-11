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

// === initial config values ===

macro fun init_burn_bps(): u64 { 80_00 } // 80%
macro fun init_slippage(): u64 { 980_000_000_000_000_000 } // 2%

// === structs ===

/// Buy Back & Burn configuration. Singleton.
public struct BBBConfig has key {
    id: UID,
    /// Percentage of revenue that will be burned, in basis points
    burn_bps: u64,
    /// Slippage tolerance as (1 - slippage) in 18-decimal fixed point.
    /// E.g., 2% slippage = 980_000_000_000_000_000 (represents 0.98)
    slippage: u64,
    /// Coin types that can be burned
    burn_types: vector<TypeName>,
    /// Aftermath swap configurations
    af_swaps: vector<AftermathSwapConfig>,
}

public struct AftermathSwapConfig has copy, drop, store {
    /// The type of coin to be swapped
    coin_type: TypeName,
    /// The ID of the Aftermath `Pool` object
    pool_id: ID,
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
        slippage: init_slippage!(),
        burn_types: vector::empty(),
        af_swaps: vector::empty(),
    };
    transfer::share_object(config);
}

// === public functions ===

// === public helpers ===

public fun is_burnable<C>(
    config: &BBBConfig,
): bool {
    config.burn_types.any!(|coin_type| {
        coin_type == type_name::get<C>()
    })
}

public fun get_aftermath_swap_config<C>(
    config: &BBBConfig,
): Option<AftermathSwapConfig> {
    let coin_type = type_name::get<C>();

    let idx = config.af_swaps.find_index!(|swap| {
        swap.coin_type == coin_type
    });

    if (idx.is_none()) {
        option::none()
    } else {
        option::some(config.af_swaps[idx.destroy_some()])
    }
}

// === public admin functions ===

public fun add_burn_action<C>(
    config: &mut BBBConfig,
    _cap: &BBBAdminCap,
) {
    // TODO: check if already exists
    config.burn_types.push_back(type_name::get<C>());
}

public fun add_aftermath_swap<C, L>(
    config: &mut BBBConfig,
    _cap: &BBBAdminCap,
    pool: &Pool<L>,
) {
    // TODO: check if already exists
    config.af_swaps.push_back(AftermathSwapConfig {
        coin_type: type_name::get<C>(),
        pool_id: object::id(pool),
    });
}

// === setters (admin only) ===

public fun set_burn_bps(config: &mut BBBConfig, _: &BBBAdminCap, burn_bps: u64) {
    assert!(burn_bps <= 100_00, EInvalidBurnBps);
    emit_event(b"burn_bps", config.burn_bps, burn_bps);
    config.burn_bps = burn_bps;
}

// === getters: BBBConfig ===

public fun id(config: &BBBConfig): ID { config.id.to_inner() }
public fun burn_bps(config: &BBBConfig): u64 { config.burn_bps }
public fun slippage(config: &BBBConfig): u64 { config.slippage }

// === getters: AftermathSwapConfig ===

public fun coin_type(swap: &AftermathSwapConfig): TypeName { swap.coin_type }
public fun pool_id(swap: &AftermathSwapConfig): ID { swap.pool_id }

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
