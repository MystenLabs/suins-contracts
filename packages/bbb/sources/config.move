module suins_bbb::bbb_config;

use std::{
    type_name::{Self, TypeName},
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
const EBurnTypeAlreadyExists: u64 = 101;
const EAftermathSwapAlreadyExists: u64 = 102;
const EBurnTypeNotFound: u64 = 103;
const EAftermathSwapNotFound: u64 = 104;
const EInvalidCoinInType: u64 = 105;
const EInvalidCoinOutType: u64 = 106;

// === constants ===

macro fun init_burn_bps(): u64 { 80_00 } // 80%
macro fun max_burn_bps(): u64 { 100_00 } // 100%

// === structs ===

/// Buy Back & Burn configuration. Singleton.
public struct BBBConfig has key {
    id: UID,
    /// % of revenue that payments package sends to the vault for burning
    burn_bps: u64,
    /// Coin types that can be burned
    burn_types: vector<TypeName>,
    /// Aftermath swap configurations
    af_swaps: vector<AftermathSwapConfig>,
}

public fun id(conf: &BBBConfig): ID { conf.id.to_inner() }
public fun burn_bps(conf: &BBBConfig): u64 { conf.burn_bps }
public fun burn_types(conf: &BBBConfig): &vector<TypeName> { &conf.burn_types }
public fun af_swaps(conf: &BBBConfig): &vector<AftermathSwapConfig> { &conf.af_swaps }

fun new(
    ctx: &mut TxContext,
): BBBConfig {
    BBBConfig {
        id: object::new(ctx),
        burn_bps: init_burn_bps!(),
        burn_types: vector::empty(),
        af_swaps: vector::empty(),
    }
}

// === initialization ===

public struct BBB_CONFIG has drop {}

fun init(_otw: BBB_CONFIG, ctx: &mut TxContext) {
    transfer::share_object(new(ctx));
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
    let type_in = type_name::get<CoinIn>();
    let idx = conf.af_swaps.find_index!(|swap| {
        swap.type_in() == type_in
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
    conf.burn_bps = burn_bps;
}

public fun add_burn_type<C>(
    conf: &mut BBBConfig,
    _cap: &BBBAdminCap,
) {
    assert!(!conf.is_burnable<C>(), EBurnTypeAlreadyExists);
    conf.burn_types.push_back(type_name::get<C>());
}

public fun remove_burn_type<C>(
    conf: &mut BBBConfig,
    _: &BBBAdminCap,
) {
    let coin_type = type_name::get<C>();
    let idx = conf.burn_types.find_index!(|burn_type| {
        burn_type == coin_type
    });
    assert!(idx.is_some(), EBurnTypeNotFound);

    conf.burn_types.swap_remove(idx.destroy_some());
}

public fun add_aftermath_swap<CoinIn, CoinOut, L>(
    conf: &mut BBBConfig,
    _cap: &BBBAdminCap,
    decimals_in: u8,
    decimals_out: u8,
    feed_in: &PriceFeed,
    feed_out: &PriceFeed,
    af_pool: &Pool<L>,
    slippage: u64,
    max_age_secs: u64,
) {
    let type_in = type_name::get<CoinIn>();
    let already_exists = conf.af_swaps.any!(|swap_config| {
        swap_config.type_in() == type_in
    });
    assert!(!already_exists, EAftermathSwapAlreadyExists);

    let type_out = type_name::get<CoinOut>();
    assert!(af_pool.type_names().contains(&type_in.into_string()), EInvalidCoinInType);
    assert!(af_pool.type_names().contains(&type_out.into_string()), EInvalidCoinOutType);

    conf.af_swaps.push_back(new_aftermath_swap_config(
        type_in,
        type_out,
        decimals_in,
        decimals_out,
        feed_in.get_price_identifier().get_bytes(),
        feed_out.get_price_identifier().get_bytes(),
        object::id(af_pool),
        slippage,
        max_age_secs,
    ));
}

public fun remove_aftermath_swap<CoinIn>(
    conf: &mut BBBConfig,
    _: &BBBAdminCap,
) {
    let type_in = type_name::get<CoinIn>();
    let idx = conf.af_swaps.find_index!(|swap_config| {
        swap_config.type_in() == type_in
    });
    assert!(idx.is_some(), EAftermathSwapNotFound);

    conf.af_swaps.swap_remove(idx.destroy_some());
}

// === test functions ===

#[test_only]
public fun new_for_testing(
    ctx: &mut TxContext,
): BBBConfig {
    new(ctx)
}
