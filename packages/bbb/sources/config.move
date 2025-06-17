module suins_bbb::bbb_config;

use std::{
    type_name::{Self},
};
use amm::{
    pool::Pool,
};
use pyth::{
    price_feed::{PriceFeed},
};
use suins_bbb::{
    bbb_admin::{BBBAdminCap},
    bbb_aftermath_swap::{Self, AftermathSwap},
    bbb_burn::{Self, Burn},
};

// === errors ===

const EBurnTypeAlreadyExists: u64 = 100;
const EAftermathSwapAlreadyExists: u64 = 101;
const EBurnTypeNotFound: u64 = 102;
const EAftermathSwapNotFound: u64 = 103;
const EInvalidCoinInType: u64 = 104;
const EInvalidCoinOutType: u64 = 105;

// === structs ===

/// Buy Back & Burn configuration. Singleton.
public struct BBBConfig has key {
    id: UID,
    /// Aftermath swap configurations
    af_swaps: vector<AftermathSwap>,
    /// Coin types that can be burned
    burns: vector<Burn>,
}

public fun id(conf: &BBBConfig): ID { conf.id.to_inner() }
public fun af_swaps(conf: &BBBConfig): &vector<AftermathSwap> { &conf.af_swaps }
public fun burns(conf: &BBBConfig): &vector<Burn> { &conf.burns }

fun new(
    ctx: &mut TxContext,
): BBBConfig {
    BBBConfig {
        id: object::new(ctx),
        af_swaps: vector::empty(),
        burns: vector::empty(),
    }
}

// === initialization ===

public struct BBB_CONFIG has drop {}

fun init(_otw: BBB_CONFIG, ctx: &mut TxContext) {
    transfer::share_object(new(ctx));
}

// === public functions ===

public fun get_aftermath_swap<CoinIn>(
    conf: &BBBConfig,
): AftermathSwap {
    let type_in = type_name::get<CoinIn>();
    let idx = conf.af_swaps.find_index!(|swap| {
        swap.type_in() == type_in
    });
    assert!(idx.is_some(), EAftermathSwapNotFound);
    conf.af_swaps[idx.destroy_some()]
}

public fun get_burn<C>(
    conf: &BBBConfig,
): Burn {
    let coin_type = type_name::get<C>();
    let idx = conf.burns.find_index!(|burn| {
        burn.coin_type() == coin_type
    });
    assert!(idx.is_some(), EBurnTypeNotFound);
    conf.burns[idx.destroy_some()]
}

// === public admin functions ===

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

    conf.af_swaps.push_back(bbb_aftermath_swap::new(
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

public fun add_burn_type<C>(
    conf: &mut BBBConfig,
    _cap: &BBBAdminCap,
) {
    let coin_type = type_name::get<C>();
    let already_exists = conf.burns.any!(|burn| {
        burn.coin_type() == coin_type
    });
    assert!(!already_exists, EBurnTypeAlreadyExists);

    conf.burns.push_back(bbb_burn::new<C>());
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

public fun remove_burn_type<C>(
    conf: &mut BBBConfig,
    _: &BBBAdminCap,
) {
    let coin_type = type_name::get<C>();
    let idx = conf.burns.find_index!(|burn| {
        burn.coin_type() == coin_type
    });
    assert!(idx.is_some(), EBurnTypeNotFound);

    conf.burns.swap_remove(idx.destroy_some());
}

// === test functions ===

#[test_only]
public fun new_for_testing(
    ctx: &mut TxContext,
): BBBConfig {
    new(ctx)
}
