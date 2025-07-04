module suins_bbb::bbb_aftermath_config;

use std::{
    type_name::{Self},
};
use suins_bbb::{
    bbb_admin::{BBBAdminCap},
    bbb_aftermath_swap::{AftermathSwap},
};

// === errors ===

const EAftermathSwapAlreadyExists: u64 = 1000;
const EAftermathSwapNotFound: u64 = 101;

// === structs ===

/// Registry of available Aftermath swaps.
///
/// Each coin type can only appear on the input side of a swap once.
/// E.g. there can only be 1 swap that converts SUI to another coin,
/// but there can be multiple swaps that convert other coins to SUI.
public struct AftermathConfig has key {
    id: UID,
    swaps: vector<AftermathSwap>,
}

// === accessors ===

public fun id(self: &AftermathConfig): &UID { &self.id }
public fun swaps(self: &AftermathConfig): &vector<AftermathSwap> { &self.swaps }

// === constructors ===

public fun new(
    _cap: &BBBAdminCap,
    ctx: &mut TxContext,
): AftermathConfig {
    AftermathConfig {
        id: object::new(ctx),
        swaps: vector::empty(),
    }
}

// === public functions ===

/// Get the swap that takes `CoinIn` as input.
/// Errors if not found.
public fun get<CoinIn>(
    self: &AftermathConfig,
): AftermathSwap {
    let type_in = type_name::get<CoinIn>();
    let idx = self.swaps.find_index!(|swap| {
        swap.type_in() == type_in
    });
    assert!(idx.is_some(), EAftermathSwapNotFound);
    self.swaps[idx.destroy_some()]
}

// === admin functions ===

/// Add a swap to the config.
/// Errors if the swap's input coin type already exists.
public fun add(
    self: &mut AftermathConfig,
    _cap: &BBBAdminCap,
    swap: AftermathSwap,
) {
    let already_exists = self.swaps.any!(|old| {
        old.type_in() == swap.type_in()
    });
    assert!(!already_exists, EAftermathSwapAlreadyExists);

    self.swaps.push_back(swap);
}

/// Remove a swap from the config.
/// Errors if the swap's input coin type doesn't exist.
public fun remove<CoinIn>(
    self: &mut AftermathConfig,
    _cap: &BBBAdminCap,
) {
    let idx = self.swaps.find_index!(|old| {
        old.type_in() == type_name::get<CoinIn>()
    });
    assert!(idx.is_some(), EAftermathSwapNotFound);

    self.swaps.swap_remove(idx.destroy_some());
}

/// Remove all swaps from the config.
public fun remove_all(
    self: &mut AftermathConfig,
    _cap: &BBBAdminCap,
) {
    self.swaps.length().do!(|_| self.swaps.pop_back());
}

/// Delete the object.
public fun destroy(
    self: AftermathConfig,
    _cap: &BBBAdminCap,
) {
    let AftermathConfig { id, swaps: _ } = self;
    object::delete(id);
}
