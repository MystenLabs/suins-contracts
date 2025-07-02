module suins_bbb::bbb_cetus_config;

use std::{
    type_name::{Self},
};
use suins_bbb::{
    bbb_admin::BBBAdminCap,
    bbb_cetus_swap::CetusSwap,
};

// === errors ===

const ECetusSwapAlreadyExists: u64 = 1000;
const ECetusSwapNotFound: u64 = 101;

// === structs ===

/// Enables coin swaps via Cetus.
public struct CetusConfig has key {
    id: UID,
    swaps: vector<CetusSwap>,
}

public fun id(self: &CetusConfig): &UID { &self.id }
public fun swaps(self: &CetusConfig): &vector<CetusSwap> { &self.swaps }

// === public functions ===

public fun get<CoinIn>(
    self: &CetusConfig,
): CetusSwap {
    let type_in = type_name::get<CoinIn>();
    let idx = self.swaps.find_index!(|swap| {
        type_in == if (swap.a2b()) {
            swap.type_a()
        } else {
            swap.type_b()
        }
    });
    assert!(idx.is_some(), ECetusSwapNotFound);
    self.swaps[idx.destroy_some()]
}

// === admin functions ===

public fun new(
    _cap: &BBBAdminCap,
    ctx: &mut TxContext,
): CetusConfig {
    CetusConfig {
        id: object::new(ctx),
        swaps: vector::empty(),
    }
}

public fun add(
    self: &mut CetusConfig,
    _cap: &BBBAdminCap,
    af_swap: CetusSwap,
) {
    let new_type_in = if (af_swap.a2b()) {
        af_swap.type_a()
    } else {
        af_swap.type_b()
    };

    let already_exists = self.swaps.any!(|existing| {
        new_type_in == if (existing.a2b()) {
            existing.type_a()
        } else {
            existing.type_b()
        };
    });

    assert!(!already_exists, ECetusSwapAlreadyExists);
    self.swaps.push_back(af_swap);
}

public fun remove<CoinIn>(
    self: &mut CetusConfig,
    _cap: &BBBAdminCap,
) {
    let type_in = type_name::get<CoinIn>();
    let idx = self.swaps.find_index!(|existing| {
        type_in == if (existing.a2b()) {
            existing.type_a()
        } else {
            existing.type_b()
        }
    });
    assert!(idx.is_some(), ECetusSwapNotFound);

    self.swaps.swap_remove(idx.destroy_some());
}
