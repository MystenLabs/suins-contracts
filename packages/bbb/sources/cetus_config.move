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
const ECetusSwapNotFound: u64 = 1001;

// === structs ===

/// Registry of available Cetus swaps.
/// Each coin pair (CoinIn, CoinOut) can only appear once.
public struct CetusConfig has key {
    id: UID,
    swaps: vector<CetusSwap>,
}

// === accessors ===

public fun id(self: &CetusConfig): &UID { &self.id }
public fun swaps(self: &CetusConfig): &vector<CetusSwap> { &self.swaps }

// === constructors ===

fun new(
    ctx: &mut TxContext,
): CetusConfig {
    CetusConfig {
        id: object::new(ctx),
        swaps: vector::empty(),
    }
}

// === initialization ===

public struct BBB_CETUS_CONFIG has drop {}

fun init(_otw: BBB_CETUS_CONFIG, ctx: &mut TxContext) {
    transfer::share_object(new(ctx));
}

// === public functions ===

/// Get the swap that converts `CoinIn` to `CoinOut`.
/// Errors if not found.
public fun get<CoinIn, CoinOut>(
    self: &CetusConfig,
): CetusSwap {
    let idx = self.swaps.find_index!(|swap| {
        let (type_in, type_out) = if (swap.a2b()) {
            (swap.type_a(), swap.type_b())
        } else {
            (swap.type_b(), swap.type_a())
        };
        type_name::get<CoinIn>() == type_in &&
        type_name::get<CoinOut>() == type_out
    });
    assert!(idx.is_some(), ECetusSwapNotFound);
    self.swaps[idx.destroy_some()]
}

// === admin functions ===

/// Add a swap to the config.
/// Errors if the swap's coin pair already exists.
public fun add(
    self: &mut CetusConfig,
    _cap: &BBBAdminCap,
    swap: CetusSwap,
) {
    let (new_in, new_out) = if (swap.a2b()) {
        (swap.type_a(), swap.type_b())
    } else {
        (swap.type_b(), swap.type_a())
    };
    let already_exists = self.swaps.any!(|old| {
        let (old_in, old_out) = if (old.a2b()) {
            (old.type_a(), old.type_b())
        } else {
            (old.type_b(), old.type_a())
        };
        new_in == old_in && new_out == old_out
    });
    assert!(!already_exists, ECetusSwapAlreadyExists);
    self.swaps.push_back(swap);
}

/// Remove a swap from the config.
/// Errors if the swap's coin pair doesn't exist.
public fun remove<CoinIn, CoinOut>(
    self: &mut CetusConfig,
    _cap: &BBBAdminCap,
) {
    let idx = self.swaps.find_index!(|old| {
        let (old_in, old_out) = if (old.a2b()) {
            (old.type_a(), old.type_b())
        } else {
            (old.type_b(), old.type_a())
        };
        type_name::get<CoinIn>() == old_in &&
        type_name::get<CoinOut>() == old_out
    });
    assert!(idx.is_some(), ECetusSwapNotFound);
    self.swaps.swap_remove(idx.destroy_some());
}

/// Remove all swaps from the config.
public fun remove_all(
    self: &mut CetusConfig,
    _cap: &BBBAdminCap,
) {
    self.swaps.length().do!(|_| self.swaps.pop_back());
}
