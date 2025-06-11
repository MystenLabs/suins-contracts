module suins_bbb::bbb_burn;

use suins_bbb::{
    bbb_config::{BBBConfig},
    bbb_vault::{BBBVault},
};

// === constants ===

macro fun burn_address(): address { @0x0 }

// === errors ===

const ENotBurnable: u64 = 100;

// === public functions ===

/// Burn all `Balance<C>` in the vault by sending it to the burn address.
public fun burn<C>(
    config: &BBBConfig,
    vault: &mut BBBVault,
    ctx: &mut TxContext,
) {
    assert!(config.is_burnable<C>(), ENotBurnable);

    let balance = vault.withdraw<C>();
    if (balance.value() == 0) {
        balance.destroy_zero();
        return
    };

    transfer::public_transfer(
        balance.into_coin(ctx), burn_address!()
    )
}
