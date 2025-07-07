module suins_bbb::bbb_burn_registry;

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
public struct BurnRegistry has key {
    id: UID,
    burns: vector<Burn>,
}

// === accessors ===

public fun id(self: &BurnRegistry): &UID { &self.id }
public fun burns(self: &BurnRegistry): &vector<Burn> { &self.burns }

// === constructors ===

fun new(
    ctx: &mut TxContext,
): BurnRegistry {
    BurnRegistry {
        id: object::new(ctx),
        burns: vector::empty(),
    }
}

// === initialization ===

public struct BBB_BURN_REGISTRY has drop {}

fun init(_otw: BBB_BURN_REGISTRY, ctx: &mut TxContext) {
    transfer::share_object(new(ctx));
}

// === public functions ===

/// Get the burn for `CoinType`.
/// Errors if not found.
public fun get<CoinType>(
    self: &BurnRegistry,
): Burn {
    let coin_type = type_name::get<CoinType>();
    let idx = self.burns.find_index!(|burn| {
        burn.coin_type() == coin_type
    });
    assert!(idx.is_some(), EBurnTypeNotFound);
    self.burns[idx.destroy_some()]
}

// === admin functions ===

/// Add a burn for `CoinType`.
/// Errors if the coin type already exists.
public fun add(
    self: &mut BurnRegistry,
    _cap: &BBBAdminCap,
    burn: Burn,
) {
    let already_exists = self.burns.any!(|existing| {
        existing.coin_type() == burn.coin_type()
    });
    assert!(!already_exists, EBurnTypeAlreadyExists);

    self.burns.push_back(burn);
}

/// Remove the burn for `CoinType`.
/// Errors if the coin type does not exist.
public fun remove<CoinType>(
    self: &mut BurnRegistry,
    _cap: &BBBAdminCap,
) {
    let idx = self.burns.find_index!(|existing| {
        existing.coin_type() == type_name::get<CoinType>()
    });
    assert!(idx.is_some(), EBurnTypeNotFound);

    self.burns.swap_remove(idx.destroy_some());
}

/// Remove all burns.
public fun remove_all(
    self: &mut BurnRegistry,
    _cap: &BBBAdminCap,
) {
    self.burns.length().do!(|_| self.burns.pop_back());
}
