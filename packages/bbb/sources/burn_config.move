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

/// Registry of burnable coin types.
public struct BurnConfig has key {
    id: UID,
    burns: vector<Burn>,
}

// === accessors ===

public fun id(self: &BurnConfig): &UID { &self.id }
public fun burns(self: &BurnConfig): &vector<Burn> { &self.burns }

// === constructors ===

public fun new(
    _cap: &BBBAdminCap,
    ctx: &mut TxContext,
): BurnConfig {
    BurnConfig {
        id: object::new(ctx),
        burns: vector::empty(),
    }
}

// === public functions ===

public fun get<C>(
    self: &BurnConfig,
): Burn {
    let coin_type = type_name::get<C>();
    let idx = self.burns.find_index!(|burn| {
        burn.coin_type() == coin_type
    });
    assert!(idx.is_some(), EBurnTypeNotFound);
    self.burns[idx.destroy_some()]
}

// === admin functions ===

public fun add(
    self: &mut BurnConfig,
    _cap: &BBBAdminCap,
    burn: Burn,
) {
    let already_exists = self.burns.any!(|existing| {
        existing.coin_type() == burn.coin_type()
    });
    assert!(!already_exists, EBurnTypeAlreadyExists);

    self.burns.push_back(burn);
}

public fun remove<C>(
    self: &mut BurnConfig,
    _cap: &BBBAdminCap,
) {
    let idx = self.burns.find_index!(|existing| {
        existing.coin_type() == type_name::get<C>()
    });
    assert!(idx.is_some(), EBurnTypeNotFound);

    self.burns.swap_remove(idx.destroy_some());
}
