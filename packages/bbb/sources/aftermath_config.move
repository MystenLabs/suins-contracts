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
    swaps: vector<AftermathSwap>,
}

public fun id(self: &AftermathConfig): &UID { &self.id }
public fun swaps(self: &AftermathConfig): &vector<AftermathSwap> { &self.swaps }

// === public functions ===

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

public fun new(
    _cap: &BBBAdminCap,
    ctx: &mut TxContext,
): AftermathConfig {
    AftermathConfig {
        id: object::new(ctx),
        swaps: vector::empty(),
    }
}

public fun add(
    self: &mut AftermathConfig,
    _cap: &BBBAdminCap,
    af_swap: AftermathSwap,
) {
    let already_exists = self.swaps.any!(|existing| {
        existing.type_in() == af_swap.type_in()
    });
    assert!(!already_exists, EAftermathSwapAlreadyExists);

    self.swaps.push_back(af_swap);
}

public fun remove<CoinIn>(
    self: &mut AftermathConfig,
    _cap: &BBBAdminCap,
) {
    let idx = self.swaps.find_index!(|existing| {
        existing.type_in() == type_name::get<CoinIn>()
    });
    assert!(idx.is_some(), EAftermathSwapNotFound);

    self.swaps.swap_remove(idx.destroy_some());
}
