module suins_bbb::bbb_burn;

use std::{
    ascii::{String},
    type_name::{Self, TypeName},
};
use sui::{
    event::{emit},
};
use suins_bbb::{
    bbb_admin::BBBAdminCap,
    bbb_vault::{BBBVault},
};

// === constants ===

macro fun burn_address(): address { @0x9526d8dbc3d24a9bc43a1c87f205ebd8d534155bc9b57771e2bf3aa6e4466686 } // TODO: dev-only: change to 0x0

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

    emit(Burned {
        coin_type: type_name::get<C>().into_string(),
        amount: balance.value(),
    });

    transfer::public_transfer(
        balance.into_coin(ctx), burn_address!()
    )
}

// === events ===

public struct Burned has drop, copy {
    coin_type: String,
    amount: u64,
}
