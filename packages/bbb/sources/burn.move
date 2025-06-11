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

public fun burn<C>(
    config: &BBBConfig,
    vault: &mut BBBVault,
    ctx: &mut TxContext,
) {
    assert!(config.is_burnable<C>(), ENotBurnable);

    let mut balance = vault.withdraw<C>();
    if (balance.value() == 0) {
        balance.destroy_zero();
        return
    };

    let burn_amount = balance.value() * config.burn_bps() / 100_00;
    let burn_balance = balance.split(burn_amount);
    vault.deposit<C>(balance);

    transfer::public_transfer(
        burn_balance.into_coin(ctx), burn_address!()
    )
}
