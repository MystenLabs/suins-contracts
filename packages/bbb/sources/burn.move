module suins_bbb::bbb_burn;

use std::{
    type_name::{Self, TypeName},
};
use suins_bbb::{
    bbb_admin::BBBAdminCap,
    bbb_vault::{BBBVault},
};

// === constants ===

macro fun burn_address(): address { @0x0 }

// === structs ===

/// Coin burn configuration.
public struct Burn has copy, drop, store {
    coin_type: TypeName,
}

public fun coin_type(burn: &Burn): &TypeName { &burn.coin_type }

public fun new<C>(_cap: &BBBAdminCap): Burn {
    Burn { coin_type: type_name::get<C>() }
}

// === public functions ===

/// Burn all `Balance<C>` in the vault by sending it to the burn address.
public fun burn<C>(
    _config: &Burn,
    vault: &mut BBBVault,
    ctx: &mut TxContext,
) {
    let balance = vault.withdraw<C>();
    if (balance.value() == 0) {
        balance.destroy_zero();
        return
    };

    transfer::public_transfer(
        balance.into_coin(ctx), burn_address!()
    )
}
