module suins_bbb::bbb_aftermath_config;

use std::{
    type_name::{Self},
};
use suins_bbb::{
    bbb_admin::BBBAdminCap,
    bbb_aftermath_swap::AftermathSwap,
};

// === errors ===

const EAftermathSwapAlreadyExists: u64 = 1000;
const EAftermathSwapNotFound: u64 = 101;

// === structs ===

/// Enables coin swaps via Aftermath.
public struct AftermathConfig has key {
    id: UID,
    af_swaps: vector<AftermathSwap>,
}
public fun af_swaps(cnf: &AftermathConfig): &vector<AftermathSwap> { &cnf.af_swaps }

// === public functions ===

public fun get<CoinIn>(
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

public fun new(
    _cap: &BBBAdminCap,
    ctx: &mut TxContext,
): AftermathConfig {
    AftermathConfig {
        id: object::new(ctx),
        af_swaps: vector::empty(),
    }
}

public fun add(
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

public fun remove<CoinIn>(
    conf: &mut AftermathConfig,
    _cap: &BBBAdminCap,
) {
    let idx = conf.af_swaps.find_index!(|existing| {
        existing.type_in() == type_name::get<CoinIn>()
    });
    assert!(idx.is_some(), EAftermathSwapNotFound);

    conf.af_swaps.swap_remove(idx.destroy_some());
}
