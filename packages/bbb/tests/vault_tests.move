#[test_only]
module suins_bbb::bbb_vault_tests;

use std::type_name::{Self, TypeName};
use sui::{balance::Balance, coin, test_utils::destroy};
use suins_bbb::{bbb_vault::{Self, BBBVault}, fakecoin::FAKECOIN};

// === withdraw tests ===

#[test]
/// Full withdraw drains the entire balance.
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

#[test]
/// Withdraw on a coin type not in the vault returns zero balance.
fun withdraw_nonexistent_coin() {
    let ctx = &mut tx_context::dummy();
    let mut vault = bbb_vault::new_for_testing(ctx);

    let withdrawn = vault.withdraw<FAKECOIN>();
    assert!(withdrawn.value() == 0);

    withdrawn.destroy_zero();
    destroy(vault);
}
