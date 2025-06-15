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
    bbb_aftermath::{AftermathSwapConfig, new_aftermath_swap_config},
};

// === errors ===

const EInvalidBurnBps: u64 = 100;
const EBurnActionAlreadyExists: u64 = 101;
const EAftermathSwapAlreadyExists: u64 = 102;
const EBurnActionNotFound: u64 = 103;
const EAftermathSwapNotFound: u64 = 104;
const EInvalidCoinInType: u64 = 105;
const EInvalidCoinOutType: u64 = 106;

// === constants ===

macro fun init_burn_bps(): u64 { 80_00 } // 80%
macro fun max_burn_bps(): u64 { 100_00 } // 100%

// === structs & getters ===

/// Buy Back & Burn configuration. Singleton.
public struct BBBConfig has key {
    id: UID,
    /// Percentage of revenue that will be burned, in basis points
    burn_bps: u64,
    /// Coin types that can be burned
    burn_types: vector<TypeName>,
    /// Aftermath swap configurations
    af_swaps: vector<AftermathSwapConfig>,
}

// === getters ===

public fun id(conf: &BBBConfig): ID { conf.id.to_inner() }
public fun burn_bps(conf: &BBBConfig): u64 { conf.burn_bps }
public fun burn_types(conf: &BBBConfig): &vector<TypeName> { &conf.burn_types }
public fun af_swaps(conf: &BBBConfig): &vector<AftermathSwapConfig> { &conf.af_swaps }

// === initialization ===

public struct BBB_CONFIG has drop {}

fun init(
    _otw: BBB_CONFIG,
    ctx: &mut TxContext,
) {
    let conf = BBBConfig {
        id: object::new(ctx),
        burn_bps: init_burn_bps!(),
        burn_types: vector::empty(),
        af_swaps: vector::empty(),
    };
    transfer::share_object(conf);
}

// === public functions ===

public fun is_burnable<C>(
    conf: &BBBConfig,
): bool {
    let coin_type = type_name::get<C>();
    conf.burn_types.any!(|burn_type| {
        burn_type == coin_type
    })
}

public fun get_aftermath_swap_config<CoinIn>(
    conf: &BBBConfig,
): AftermathSwapConfig {
    let coin_in_type = type_name::get<CoinIn>();
    let idx = conf.af_swaps.find_index!(|swap| {
        swap.coin_in_type() == coin_in_type
    });
    assert!(idx.is_some(), EAftermathSwapNotFound);
    conf.af_swaps[idx.destroy_some()]
}

// === public admin functions ===

public fun set_burn_bps(
    conf: &mut BBBConfig,
    _: &BBBAdminCap,
    burn_bps: u64,
) {
    assert!(burn_bps <= max_burn_bps!(), EInvalidBurnBps);
    emit_event(b"burn_bps", conf.burn_bps, burn_bps);
    conf.burn_bps = burn_bps;
}

public fun add_burn_action<C>(
    conf: &mut BBBConfig,
    _cap: &BBBAdminCap,
) {
    let coin_type = type_name::get<C>();
    let idx = conf.burn_types.find_index!(|burn_type| {
        burn_type == coin_type
    });
    assert!(idx.is_none(), EBurnActionAlreadyExists);

    conf.burn_types.push_back(coin_type);
}

public fun add_aftermath_swap<CoinIn, CoinOut, L>(
    conf: &mut BBBConfig,
    _cap: &BBBAdminCap,
    coin_in_decimals: u8,
    coin_out_decimals: u8,
    coin_in_feed: &PriceFeed,
    coin_out_feed: &PriceFeed,
    af_pool: &Pool<L>,
    slippage: u64,
    max_age_secs: u64,
) {
    let coin_in_type = type_name::get<CoinIn>();
    let idx = conf.af_swaps.find_index!(|swap_config| {
        swap_config.coin_in_type() == coin_in_type
    });
    assert!(idx.is_none(), EAftermathSwapAlreadyExists);

    let coin_out_type = type_name::get<CoinOut>();
    assert!(af_pool.type_names().contains(&coin_in_type.into_string()), EInvalidCoinInType);
    assert!(af_pool.type_names().contains(&coin_out_type.into_string()), EInvalidCoinOutType);

    conf.af_swaps.push_back(new_aftermath_swap_config(
        coin_in_type,
        coin_out_type,
        coin_in_decimals,
        coin_out_decimals,
        coin_in_feed.get_price_identifier().get_bytes(),
        coin_out_feed.get_price_identifier().get_bytes(),
        object::id(af_pool),
        slippage,
        max_age_secs,
    ));
}

public fun remove_burn_action<C>(
    conf: &mut BBBConfig,
    _: &BBBAdminCap,
) {
    let coin_type = type_name::get<C>();
    let idx = conf.burn_types.find_index!(|burn_type| {
        burn_type == coin_type
    });
    assert!(idx.is_some(), EBurnActionNotFound);

    conf.burn_types.swap_remove(idx.destroy_some());
}

public fun remove_aftermath_swap<CoinIn>(
    conf: &mut BBBConfig,
    _: &BBBAdminCap,
) {
    let coin_in_type = type_name::get<CoinIn>();
    let idx = conf.af_swaps.find_index!(|swap_config| {
        swap_config.coin_in_type() == coin_in_type
    });
    assert!(idx.is_some(), EAftermathSwapNotFound);

    conf.af_swaps.swap_remove(idx.destroy_some());
}

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
