module suins_bbb::bbb_config;

use std::{
    type_name::{Self},
};
use suins_bbb::{
    bbb_admin::BBBAdminCap,
    bbb_aftermath_swap::AftermathSwap,
    bbb_burn::Burn,
};

// === errors ===

const EBurnTypeAlreadyExists: u64 = 100;
const EAftermathSwapAlreadyExists: u64 = 101;
const EBurnTypeNotFound: u64 = 102;
const EAftermathSwapNotFound: u64 = 103;

// === structs ===

/// Enables burning selected coin types.
public struct BurnConfig has key {
    id: UID,
    burns: vector<Burn>,
}
public fun burns(cnf: &BurnConfig): &vector<Burn> { &cnf.burns }

/// Enables coin swaps via Aftermath.
public struct AftermathConfig has key {
    id: UID,
    af_swaps: vector<AftermathSwap>,
}
public fun af_swaps(cnf: &AftermathConfig): &vector<AftermathSwap> { &cnf.af_swaps }

// === public functions ===

public fun get_burn<C>(
    conf: &BurnConfig,
): Burn {
    let coin_type = type_name::get<C>();
    let idx = conf.burns.find_index!(|burn| {
        burn.coin_type() == coin_type
    });
    assert!(idx.is_some(), EBurnTypeNotFound);
    conf.burns[idx.destroy_some()]
}

public fun get_aftermath_swap<CoinIn>(
    conf: &AftermathConfig,
): AftermathSwap {
    let type_in = type_name::get<CoinIn>();
    let idx = conf.af_swaps.find_index!(|swap| {
        swap.type_in() == type_in
    });
    assert!(idx.is_some(), EAftermathSwapNotFound);
    conf.af_swaps[idx.destroy_some()]
}

// === admin functions ===

public fun new_burn_config(
    _cap: &BBBAdminCap,
    ctx: &mut TxContext,
): BurnConfig {
    BurnConfig {
        id: object::new(ctx),
        burns: vector::empty(),
    }
}

public fun new_aftermath_config(
    _cap: &BBBAdminCap,
    ctx: &mut TxContext,
): AftermathConfig {
    AftermathConfig {
        id: object::new(ctx),
        af_swaps: vector::empty(),
    }
}

public fun add_burn_type(
    conf: &mut BurnConfig,
    _cap: &BBBAdminCap,
    burn: Burn,
) {
    let already_exists = conf.burns.any!(|existing| {
        existing.coin_type() == burn.coin_type()
    });
    assert!(!already_exists, EBurnTypeAlreadyExists);

    conf.burns.push_back(burn);
}

public fun add_aftermath_swap(
    conf: &mut AftermathConfig,
    _cap: &BBBAdminCap,
    af_swap: AftermathSwap,
) {
    let already_exists = conf.af_swaps.any!(|existing| {
        existing.type_in() == af_swap.type_in()
    });
    assert!(!already_exists, EAftermathSwapAlreadyExists);

    conf.af_swaps.push_back(af_swap);
}

public fun remove_burn_type<C>(
    conf: &mut BurnConfig,
    _cap: &BBBAdminCap,
) {
    let idx = conf.burns.find_index!(|existing| {
        existing.coin_type() == type_name::get<C>()
    });
    assert!(idx.is_some(), EBurnTypeNotFound);

    conf.burns.swap_remove(idx.destroy_some());
}

public fun remove_aftermath_swap<CoinIn>(
    conf: &mut AftermathConfig,
    _cap: &BBBAdminCap,
) {
    let idx = conf.af_swaps.find_index!(|existing| {
        existing.type_in() == type_name::get<CoinIn>()
    });
    assert!(idx.is_some(), EAftermathSwapNotFound);

    conf.af_swaps.swap_remove(idx.destroy_some());
}
