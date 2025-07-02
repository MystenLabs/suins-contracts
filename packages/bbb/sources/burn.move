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

// === errors ===

const EInvalidCoinType: u64 = 100;

// === constants ===

macro fun burn_address(): address { @0x9526d8dbc3d24a9bc43a1c87f205ebd8d534155bc9b57771e2bf3aa6e4466686 } // TODO: dev-only: change to 0x0

// === structs ===

/// Coin burn configuration.
/// Grants the right to burn `Balance<coin_type>` in the vault.
/// Only the admin can create it.
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
    burn: &Burn,
    vault: &mut BBBVault,
    ctx: &mut TxContext,
) {
    let coin_type = type_name::get<C>();
    assert!(coin_type == burn.coin_type, EInvalidCoinType);

    let balance = vault.withdraw<C>();
    if (balance.value() == 0) {
        balance.destroy_zero();
        return
    };

    emit(BurnEvent {
        coin_type: coin_type.into_string(),
        amount: balance.value(),
    });

    transfer::public_transfer(
        balance.into_coin(ctx), burn_address!()
    )
}

// === events ===

public struct BurnEvent has drop, copy {
    coin_type: String,
    amount: u64,
}
