#[test_only]
module suins_bbb::bbb_vault_tests;

use std::type_name::{Self, TypeName};
use sui::{balance::Balance, coin, test_utils::destroy};
use suins_bbb::{bbb_vault::{Self, BBBVault}, fakecoin::FAKECOIN};

// A second coin type for multi-coin tests
public struct OTHERCOIN has drop {}

// === withdraw_partial tests ===

#[test]
/// withdraw_partial with max_amount less than balance returns max_amount and leaves the rest.
fun withdraw_partial_less_than_balance() {
    let ctx = &mut tx_context::dummy();
    let mut vault = bbb_vault::new_for_testing(ctx);

    vault.deposit(coin::mint_for_testing<FAKECOIN>(1000, ctx));

    let withdrawn = vault.withdraw_partial<FAKECOIN>(400);
    assert!(withdrawn.value() == 400);

    // remaining balance should be 600
    let remaining = vault
        .balances()
        .borrow<TypeName, Balance<FAKECOIN>>(type_name::get<FAKECOIN>())
        .value();
    assert!(remaining == 600);

    destroy(withdrawn);
    destroy(vault);
}

#[test]
/// withdraw_partial with max_amount equal to balance returns everything.
fun withdraw_partial_equal_to_balance() {
    let ctx = &mut tx_context::dummy();
    let mut vault = bbb_vault::new_for_testing(ctx);

    vault.deposit(coin::mint_for_testing<FAKECOIN>(500, ctx));

    let withdrawn = vault.withdraw_partial<FAKECOIN>(500);
    assert!(withdrawn.value() == 500);

    // remaining balance should be 0
    let remaining = vault
        .balances()
        .borrow<TypeName, Balance<FAKECOIN>>(type_name::get<FAKECOIN>())
        .value();
    assert!(remaining == 0);

    destroy(withdrawn);
    destroy(vault);
}

#[test]
/// withdraw_partial with max_amount greater than balance returns whatever is available.
fun withdraw_partial_more_than_balance() {
    let ctx = &mut tx_context::dummy();
    let mut vault = bbb_vault::new_for_testing(ctx);

    vault.deposit(coin::mint_for_testing<FAKECOIN>(300, ctx));

    let withdrawn = vault.withdraw_partial<FAKECOIN>(1000);
    assert!(withdrawn.value() == 300);

    // remaining balance should be 0
    let remaining = vault
        .balances()
        .borrow<TypeName, Balance<FAKECOIN>>(type_name::get<FAKECOIN>())
        .value();
    assert!(remaining == 0);

    destroy(withdrawn);
    destroy(vault);
}

#[test]
/// withdraw_partial on a coin type not in the vault returns zero balance.
fun withdraw_partial_nonexistent_coin() {
    let ctx = &mut tx_context::dummy();
    let mut vault = bbb_vault::new_for_testing(ctx);

    let withdrawn = vault.withdraw_partial<FAKECOIN>(500);
    assert!(withdrawn.value() == 0);

    withdrawn.destroy_zero();
    destroy(vault);
}

#[test]
/// withdraw_partial with max_amount of zero returns zero balance.
fun withdraw_partial_zero_amount() {
    let ctx = &mut tx_context::dummy();
    let mut vault = bbb_vault::new_for_testing(ctx);

    vault.deposit(coin::mint_for_testing<FAKECOIN>(1000, ctx));

    let withdrawn = vault.withdraw_partial<FAKECOIN>(0);
    assert!(withdrawn.value() == 0);

    // original balance untouched
    let remaining = vault
        .balances()
        .borrow<TypeName, Balance<FAKECOIN>>(type_name::get<FAKECOIN>())
        .value();
    assert!(remaining == 1000);

    withdrawn.destroy_zero();
    destroy(vault);
}

#[test]
/// Multiple sequential withdraw_partial calls drain the vault correctly.
fun withdraw_partial_sequential() {
    let ctx = &mut tx_context::dummy();
    let mut vault = bbb_vault::new_for_testing(ctx);

    vault.deposit(coin::mint_for_testing<FAKECOIN>(1000, ctx));

    let w1 = vault.withdraw_partial<FAKECOIN>(300);
    assert!(w1.value() == 300);

    let w2 = vault.withdraw_partial<FAKECOIN>(300);
    assert!(w2.value() == 300);

    let w3 = vault.withdraw_partial<FAKECOIN>(300);
    assert!(w3.value() == 300);

    // only 100 left
    let w4 = vault.withdraw_partial<FAKECOIN>(300);
    assert!(w4.value() == 100);

    // now empty
    let w5 = vault.withdraw_partial<FAKECOIN>(300);
    assert!(w5.value() == 0);

    w5.destroy_zero();
    destroy(w1);
    destroy(w2);
    destroy(w3);
    destroy(w4);
    destroy(vault);
}

#[test]
/// withdraw_partial only affects the specified coin type, not others.
fun withdraw_partial_does_not_affect_other_coins() {
    let ctx = &mut tx_context::dummy();
    let mut vault = bbb_vault::new_for_testing(ctx);

    vault.deposit(coin::mint_for_testing<FAKECOIN>(1000, ctx));
    vault.deposit(coin::mint_for_testing<OTHERCOIN>(500, ctx));

    let withdrawn = vault.withdraw_partial<FAKECOIN>(400);
    assert!(withdrawn.value() == 400);

    // FAKECOIN reduced
    let remaining_fake = vault
        .balances()
        .borrow<TypeName, Balance<FAKECOIN>>(type_name::get<FAKECOIN>())
        .value();
    assert!(remaining_fake == 600);

    // OTHERCOIN untouched
    let remaining_other = vault
        .balances()
        .borrow<TypeName, Balance<OTHERCOIN>>(type_name::get<OTHERCOIN>())
        .value();
    assert!(remaining_other == 500);

    destroy(withdrawn);
    destroy(vault);
}

#[test]
/// Full withdraw still drains the entire balance.
fun withdraw_full_drains_all() {
    let ctx = &mut tx_context::dummy();
    let mut vault = bbb_vault::new_for_testing(ctx);

    vault.deposit(coin::mint_for_testing<FAKECOIN>(1000, ctx));

    let withdrawn = vault.withdraw<FAKECOIN>();
    assert!(withdrawn.value() == 1000);

    let remaining = vault
        .balances()
        .borrow<TypeName, Balance<FAKECOIN>>(type_name::get<FAKECOIN>())
        .value();
    assert!(remaining == 0);

    destroy(withdrawn);
    destroy(vault);
}
