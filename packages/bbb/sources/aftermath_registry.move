module suins_bbb::bbb_aftermath_registry;

use std::{
    type_name::{Self},
};
use suins_bbb::{
    bbb_admin::{BBBAdminCap},
    bbb_aftermath_swap::{AftermathSwap},
};

// === errors ===

const EAftermathSwapAlreadyExists: u64 = 1000;
const EAftermathSwapNotFound: u64 = 1001;

// === structs ===

/// Registry of available Aftermath swaps.
/// Each coin pair (CoinIn, CoinOut) can only appear once.
public struct AftermathRegistry has key {
    id: UID,
    swaps: vector<AftermathSwap>,
}

// === accessors ===

public fun id(self: &AftermathRegistry): &UID { &self.id }
public fun swaps(self: &AftermathRegistry): &vector<AftermathSwap> { &self.swaps }

// === constructors ===

fun new(
    ctx: &mut TxContext,
): AftermathRegistry {
    AftermathRegistry {
        id: object::new(ctx),
        swaps: vector::empty(),
    }
}

// === initialization ===

public struct BBB_AFTERMATH_REGISTRY has drop {}

fun init(_otw: BBB_AFTERMATH_REGISTRY, ctx: &mut TxContext) {
    transfer::share_object(new(ctx));
}

// === public functions ===

/// Get the swap that converts `CoinIn` to `CoinOut`.
/// Errors if not found.
public fun get<CoinIn, CoinOut>(
    self: &AftermathRegistry,
): AftermathSwap {
    let idx = self.swaps.find_index!(|swap| {
        swap.type_in() == type_name::get<CoinIn>() &&
        swap.type_out() == type_name::get<CoinOut>()
    });
    assert!(idx.is_some(), EAftermathSwapNotFound);
    self.swaps[idx.destroy_some()]
}

// === admin functions ===

/// Add a swap to the registry.
/// Errors if the coin pair already exists in the registry.
public fun add(
    self: &mut AftermathRegistry,
    _cap: &BBBAdminCap,
    swap: AftermathSwap,
) {
    let already_exists = self.swaps.any!(|old| {
        old.type_in() == swap.type_in() &&
        old.type_out() == swap.type_out()
    });
    assert!(!already_exists, EAftermathSwapAlreadyExists);

    self.swaps.push_back(swap);
}

/// Remove a swap from the registry.
/// Errors if the coin pair doesn't exist in the registry.
public fun remove<CoinIn, CoinOut>(
    self: &mut AftermathRegistry,
    _cap: &BBBAdminCap,
) {
    let idx = self.swaps.find_index!(|swap| {
        swap.type_in() == type_name::get<CoinIn>() &&
        swap.type_out() == type_name::get<CoinOut>()
    });
    assert!(idx.is_some(), EAftermathSwapNotFound);

    self.swaps.swap_remove(idx.destroy_some());
}

/// Remove all swaps from the registry.
public fun remove_all(
    self: &mut AftermathRegistry,
    _cap: &BBBAdminCap,
) {
    self.swaps.length().do!(|_| self.swaps.pop_back());
}
