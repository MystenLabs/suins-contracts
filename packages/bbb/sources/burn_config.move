module suins_bbb::bbb_burn_config;

use std::{
    type_name::{Self},
};
use suins_bbb::{
    bbb_admin::BBBAdminCap,
    bbb_burn::Burn,
};

// === errors ===

const EBurnTypeAlreadyExists: u64 = 1000;
const EBurnTypeNotFound: u64 = 1001;

// === structs ===

/// Enables burning selected coin types.
public struct BurnConfig has key {
    id: UID,
    burns: vector<Burn>,
}
public fun burns(cnf: &BurnConfig): &vector<Burn> { &cnf.burns }

// === public functions ===

public fun get<C>(
    conf: &BurnConfig,
): Burn {
    let coin_type = type_name::get<C>();
    let idx = conf.burns.find_index!(|burn| {
        burn.coin_type() == coin_type
    });
    assert!(idx.is_some(), EBurnTypeNotFound);
    conf.burns[idx.destroy_some()]
}

// === admin functions ===

public fun new(
    _cap: &BBBAdminCap,
    ctx: &mut TxContext,
): BurnConfig {
    BurnConfig {
        id: object::new(ctx),
        burns: vector::empty(),
    }
}

public fun add(
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

public fun remove<C>(
    conf: &mut BurnConfig,
    _cap: &BBBAdminCap,
) {
    let idx = conf.burns.find_index!(|existing| {
        existing.coin_type() == type_name::get<C>()
    });
    assert!(idx.is_some(), EBurnTypeNotFound);

    conf.burns.swap_remove(idx.destroy_some());
}
