module suins_bbb::bbb_cetus_config;

use std::{
    type_name::{Self},
};
use suins_bbb::{
    bbb_admin::{BBBAdminCap},
    bbb_cetus_swap::{CetusSwap},
};

// === errors ===

const ECetusSwapAlreadyExists: u64 = 1000;
const ECetusSwapNotFound: u64 = 101;

// === structs ===

/// Registry of available Cetus swaps.
///
/// Each coin type can only appear on the input side of a swap once.
/// E.g. there can only be 1 swap that converts SUI to another coin,
/// but there can be multiple swaps that convert other coins to SUI.
public struct CetusConfig has key {
    id: UID,
    swaps: vector<CetusSwap>,
}

// === accessors ===

public fun id(self: &CetusConfig): &UID { &self.id }
public fun swaps(self: &CetusConfig): &vector<CetusSwap> { &self.swaps }

// === constructors ===

public fun new(
    _cap: &BBBAdminCap,
    ctx: &mut TxContext,
): CetusConfig {
    CetusConfig {
        id: object::new(ctx),
        swaps: vector::empty(),
    }
}

// === public functions ===

/// Get the swap that takes `CoinIn` as input.
/// Errors if not found.
public fun get<CoinIn>(
    self: &CetusConfig,
): CetusSwap {
    let type_in = type_name::get<CoinIn>();
    let idx = self.swaps.find_index!(|swap| {
        let swap_type_in = if (swap.a2b()) swap.type_a() else swap.type_b();
        type_in == swap_type_in
    });
    assert!(idx.is_some(), ECetusSwapNotFound);
    self.swaps[idx.destroy_some()]
}

// === admin functions ===

/// Add a swap to the config.
/// Errors if the swap's input coin type already exists.
public fun add(
    self: &mut CetusConfig,
    _cap: &BBBAdminCap,
    swap: CetusSwap,
) {
    let new_type_in = if (swap.a2b()) swap.type_a() else swap.type_b();
    let already_exists = self.swaps.any!(|old| {
        let old_type_in = if (old.a2b()) old.type_a() else old.type_b();
        new_type_in == old_type_in
    });
    assert!(!already_exists, ECetusSwapAlreadyExists);
    self.swaps.push_back(swap);
}

/// Remove a swap from the config.
/// Errors if the swap's input coin type doesn't exist.
public fun remove<CoinIn>(
    self: &mut CetusConfig,
    _cap: &BBBAdminCap,
) {
    let type_in = type_name::get<CoinIn>();
    let idx = self.swaps.find_index!(|old| {
        let old_type_in = if (old.a2b()) old.type_a() else old.type_b();
        type_in == old_type_in
    });
    assert!(idx.is_some(), ECetusSwapNotFound);
    self.swaps.swap_remove(idx.destroy_some());
}

/// Delete the object.
public fun destroy(
    self: CetusConfig,
    _cap: &BBBAdminCap,
) {
    let CetusConfig { id, swaps: _ } = self;
    object::delete(id);
}
