#[test_only]
module suins_bbb::bbb_burn_tests;

use std::{
    type_name::{Self, TypeName},
};
use sui::{
    balance::{Balance},
    coin::{Self, Coin},
    test_utils::{assert_eq, destroy},
    test_scenario::{Self, Scenario},
};
use suins_bbb::{
    bbb_admin::{Self, BBBAdminCap},
    bbb_burn::{Self, burn_address},
    bbb_burn_registry::{Self, BurnRegistry},
    bbb_vault::{Self, BBBVault},
    fakecoin::{FAKECOIN},
};

#[test]
fun end_to_end() {
    let (mut scen, cap, registry, mut vault) = setup();

    let coin = coin::mint_for_testing<FAKECOIN>(1000, scen.ctx());
    vault.deposit(coin);

    let coin_type = type_name::get<FAKECOIN>();
    assert_eq(vault.balances().length(), 1);
    assert_eq(
        vault.balances()
            .borrow<TypeName, Balance<FAKECOIN>>(coin_type)
            .value(),
        1000,
    );

    let burn = registry.get<FAKECOIN>();
    burn.burn<FAKECOIN>(&mut vault, scen.ctx());

    assert_eq(vault.balances().length(), 1);
    assert_eq(
        vault.balances()
            .borrow<TypeName, Balance<FAKECOIN>>(coin_type)
            .value(),
        0,
    );

    scen.next_tx(burn_address!());
    let coin = scen.take_from_sender<Coin<FAKECOIN>>();
    assert_eq(coin.value(), 1000);
    scen.return_to_sender(coin);

    destroy(cap);
    destroy(registry);
    destroy(vault);
    destroy(scen);
}

// === helpers ===

fun setup(): (Scenario, BBBAdminCap, BurnRegistry, BBBVault) {
    let mut scen = test_scenario::begin(@0x123);
    let cap = bbb_admin::new_for_testing(scen.ctx());
    let mut registry = bbb_burn_registry::new_for_testing(scen.ctx());
    registry.add(&cap, bbb_burn::new<FAKECOIN>(&cap));
    let vault = bbb_vault::new_for_testing(scen.ctx());
    (scen, cap, registry, vault)
}
