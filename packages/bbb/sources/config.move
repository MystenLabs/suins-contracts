module suins_bbb::bbb_config;

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
use pyth::{
    price_feed::{PriceFeed},
};
use suins_bbb::{
    bbb_admin::{BBBAdminCap},
};

// === errors ===

const EInvalidBurnBps: u64 = 100;
const EInvalidSlippage: u64 = 101;
const EBurnActionAlreadyExists: u64 = 102;
const EAftermathSwapAlreadyExists: u64 = 103;
const EBurnActionNotFound: u64 = 104;
const EAftermathSwapNotFound: u64 = 105;

// === constants ===

macro fun init_burn_bps(): u64 { 80_00 } // 80%
macro fun init_slippage(): u64 { 980_000_000_000_000_000 } // 2%

macro fun max_burn_bps(): u64 { 100_00 } // 100%
macro fun max_slippage(): u64 { 1_000_000_000_000_000_000 } // 100%

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

/// Aftermath swap configuration.
public struct AftermathSwapConfig has copy, drop, store {
    /// Type of coin to be swapped into `coin_out_type`
    coin_in_type: TypeName,
    /// Type of coin to be received from the swap
    coin_out_type: TypeName,
    /// Pyth `PriceFeed` identifier for `coin_in_type` without the `0x` prefix
    coin_in_feed_id: vector<u8>,
    /// Pyth `PriceFeed` identifier for `coin_out_type` without the `0x` prefix
    coin_out_feed_id: vector<u8>,
    /// Aftermath `Pool` object `ID`
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

public fun is_burnable<C>(
    config: &BBBConfig,
): bool {
    let coin_type = type_name::get<C>();
    config.burn_types.any!(|burn_type| {
        burn_type == coin_type
    })
}

public fun get_aftermath_swap_config<CoinIn>(
    config: &BBBConfig,
): Option<AftermathSwapConfig> {
    let coin_in_type = type_name::get<CoinIn>();
    let idx = config.af_swaps.find_index!(|swap| {
        swap.coin_in_type == coin_in_type
    });
    assert!(idx.is_some(), EAftermathSwapNotFound);

    option::some(config.af_swaps[idx.destroy_some()])
}

// === public admin functions ===

public fun add_burn_action<C>(
    config: &mut BBBConfig,
    _cap: &BBBAdminCap,
) {
    let coin_type = type_name::get<C>();
    let idx = config.burn_types.find_index!(|burn_type| {
        burn_type == coin_type
    });
    assert!(idx.is_none(), EBurnActionAlreadyExists);

    config.burn_types.push_back(coin_type);
}

public fun add_aftermath_swap<CoinIn, CoinOut, L>(
    config: &mut BBBConfig,
    _cap: &BBBAdminCap,
    coin_in_feed: &PriceFeed,
    coin_out_feed: &PriceFeed,
    af_pool: &Pool<L>,
) {
    let coin_in_type = type_name::get<CoinIn>();
    let idx = config.af_swaps.find_index!(|swap_config| {
        swap_config.coin_in_type == coin_in_type
    });
    assert!(idx.is_none(), EAftermathSwapAlreadyExists);

    config.af_swaps.push_back(AftermathSwapConfig {
        coin_in_type,
        coin_out_type: type_name::get<CoinOut>(),
        coin_in_feed_id: coin_in_feed.get_price_identifier().get_bytes(),
        coin_out_feed_id: coin_out_feed.get_price_identifier().get_bytes(),
        pool_id: object::id(af_pool),
    });
}

public fun remove_burn_action<C>(
    config: &mut BBBConfig,
    _: &BBBAdminCap,
) {
    let coin_type = type_name::get<C>();
    let idx = config.burn_types.find_index!(|burn_type| {
        burn_type == coin_type
    });
    assert!(idx.is_some(), EBurnActionNotFound);

    config.burn_types.swap_remove(idx.destroy_some());
}

public fun remove_aftermath_swap<CoinIn>(
    config: &mut BBBConfig,
    _: &BBBAdminCap,
) {
    let coin_in_type = type_name::get<CoinIn>();
    let idx = config.af_swaps.find_index!(|swap_config| {
        swap_config.coin_in_type == coin_in_type
    });
    assert!(idx.is_some(), EAftermathSwapNotFound);

    config.af_swaps.swap_remove(idx.destroy_some());
}

public fun set_burn_bps(config: &mut BBBConfig, _: &BBBAdminCap, burn_bps: u64) {
    assert!(burn_bps <= max_burn_bps!(), EInvalidBurnBps);
    emit_event(b"burn_bps", config.burn_bps, burn_bps);
    config.burn_bps = burn_bps;
}

public fun set_slippage(config: &mut BBBConfig, _: &BBBAdminCap, slippage: u64) {
    assert!(slippage <= max_slippage!(), EInvalidSlippage);
    emit_event(b"slippage", config.slippage, slippage);
    config.slippage = slippage;
}

// === getters: BBBConfig ===

public fun id(config: &BBBConfig): ID { config.id.to_inner() }
public fun burn_bps(config: &BBBConfig): u64 { config.burn_bps }
public fun slippage(config: &BBBConfig): u64 { config.slippage }
public fun burn_types(config: &BBBConfig): &vector<TypeName> { &config.burn_types }
public fun af_swaps(config: &BBBConfig): &vector<AftermathSwapConfig> { &config.af_swaps }

// === getters: AftermathSwapConfig ===

public fun coin_in_type(swap: &AftermathSwapConfig): &TypeName { &swap.coin_in_type }
public fun coin_out_type(swap: &AftermathSwapConfig): &TypeName { &swap.coin_out_type }
public fun coin_in_feed_id(swap: &AftermathSwapConfig): &vector<u8> { &swap.coin_in_feed_id }
public fun coin_out_feed_id(swap: &AftermathSwapConfig): &vector<u8> { &swap.coin_out_feed_id }
public fun pool_id(swap: &AftermathSwapConfig): &ID { &swap.pool_id }

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
