#[test_only]
module suins_bbb::bbb_burn_registry_tests;

use sui::{
    test_utils::{assert_eq, destroy},
};
use suins_bbb::{
    bbb_admin::{BBBAdminCap, Self},
    bbb_burn::{Self},
    bbb_burn_registry::{BurnRegistry, Self},
    fakecoin::{FAKECOIN},
};

#[test]
fun end_to_end() {
    let (_ctx, cap, mut registry) = setup();

    // add
    let burn = bbb_burn::new<FAKECOIN>(&cap);
    registry.add(&cap, burn);
    assert_eq(registry.burns().length(), 1);

    // get
    let promise = registry.get<FAKECOIN>();
    assert_eq(registry.burns().length(), 1); // burn was copied, not popped
    destroy(promise);

    // remove
    registry.remove<FAKECOIN>(&cap);
    assert_eq(registry.burns().length(), 0);

    destroy(cap);
    destroy(registry);
}

// EBurnTypeAlreadyExists
#[test, expected_failure(abort_code = bbb_burn_registry::EBurnTypeAlreadyExists)]
fun add_duplicate() {
    let (_ctx, cap, mut registry) = setup();

    let burn1 = bbb_burn::new<FAKECOIN>(&cap);
    registry.add(&cap, burn1);

    let burn2 = bbb_burn::new<FAKECOIN>(&cap);
    registry.add(&cap, burn2);

    abort 123
}

// EBurnTypeNotFound
#[test, expected_failure(abort_code = bbb_burn_registry::EBurnTypeNotFound)]
fun get_nonexistent() {
    let (_ctx, _cap, registry) = setup();

    let _promise = registry.get<FAKECOIN>();
    abort 123
}

// === helpers ===

fun setup(): (TxContext, BBBAdminCap, BurnRegistry) {
    let mut ctx = sui::tx_context::dummy();
    let cap = bbb_admin::new_for_testing(&mut ctx);
    let registry = bbb_burn_registry::new_for_testing(&mut ctx);
    (ctx, cap, registry)
}
