#[test_only]
///
module suins::suins_tests {
    use sui::coin;
    use sui::balance;
    use sui::sui::SUI;
    use sui::tx_context;
    use sui::test_utils::assert_eq;
    use suins::suins::{Self, AdminCap, SuiNS};

    // === Config management ===

    struct TestConfig has store, drop { a: u8 }

    #[test]
    /// Add a configuration; get it back; remove it.
    fun config_management() {
        let ctx = tx_context::dummy();
        let (suins, cap) = suins::new_for_testing(&mut ctx);

        suins::add_config(&cap, &mut suins, TestConfig { a: 1 });
        let _cfg = suins::get_config<TestConfig>(&suins);
        let cfg = suins::remove_config<TestConfig>(&cap, &mut suins);
        assert_eq(cfg.a, 1);

        wrapup(suins, cap);
    }

    // === Registry ===

    struct TestRegistry has store { counter: u8 }

    #[test]
    /// Add a registry; read it.
    fun registry_management() {
        let ctx = tx_context::dummy();
        let (suins, cap) = suins::new_for_testing(&mut ctx);

        suins::add_registry(&cap, &mut suins, TestRegistry { counter: 1 });
        let reg = suins::registry<TestRegistry>(&suins);
        assert_eq(reg.counter, 1);

        wrapup(suins, cap);
    }

    // === Application Auth ===

    struct TestApp has drop {}

    #[test, expected_failure(abort_code = suins::suins::EAppNotAuthorized)]
    /// Only authorized applications can add balance to SuiNS.
    fun app_add_to_balance_fail() {
        let ctx = tx_context::dummy();
        let (suins, _cap) = suins::new_for_testing(&mut ctx);
        suins::app_add_balance(TestApp {}, &mut suins, balance::zero());
        abort 1337
    }

    #[test, expected_failure(abort_code = suins::suins::EAppNotAuthorized)]
    /// Only authorized applications can access the registry mut.
    fun app_registry_mut_fail() {
        let ctx = tx_context::dummy();
        let (suins, _cap) = suins::new_for_testing(&mut ctx);
        suins::app_registry_mut<TestApp, TestRegistry>(TestApp {}, &mut suins);
        abort 1337
    }

    #[test]
    /// 1. Authorize TestApp;
    /// 2. Adds balance to SuiNS, access registry mut.
    fun authorize_and_access() {
        let ctx = tx_context::dummy();
        let (suins, cap) = suins::new_for_testing(&mut ctx);
        suins::add_registry(&cap, &mut suins, TestRegistry { counter: 1 });

        // authorize and check right away
        suins::authorize_app<TestApp>(&cap, &mut suins);
        assert!(suins::is_app_authorized<TestApp>(&suins), 0);
        suins::assert_app_is_authorized<TestApp>(&suins);

        // add balance and read registry
        suins::app_add_balance(TestApp {}, &mut suins, balance::zero());
        let registry = suins::app_registry_mut<TestApp, TestRegistry>(TestApp {}, &mut suins);
        registry.counter = 2;

        // now read the registry again
        assert_eq(suins::registry<TestRegistry>(&suins).counter, 2);

        // deauthorize application
        suins::deauthorize_app<TestApp>(&cap, &mut suins);
        assert!(!suins::is_app_authorized<TestApp>(&suins), 0);

        wrapup(suins, cap);
    }

    #[test]
    /// 1. Authorize TestApp and add to balance;
    /// 2. Admin withdraws the balance.
    fun balance_and_withdraw() {
        let ctx = tx_context::dummy();
        let (suins, cap) = suins::new_for_testing(&mut ctx);
        suins::authorize_app<TestApp>(&cap, &mut suins);

        let paid = balance::create_for_testing<SUI>(1000);
        suins::app_add_balance(TestApp {}, &mut suins, paid);

        let withdrawn = suins::withdraw(&cap, &mut suins, &mut ctx);
        assert_eq(coin::burn_for_testing(withdrawn), 1000);

        wrapup(suins, cap);
    }

    #[test, expected_failure(abort_code = suins::suins::ENoProfits)]
    /// 1. Authorize TestApp and add to balance;
    /// 2. Admin tries to withdraw an empty balance.
    fun balance_and_withdraw_fail_no_profits() {
        let ctx = tx_context::dummy();
        let (suins, cap) = suins::new_for_testing(&mut ctx);
        let _withdrawn = suins::withdraw(&cap, &mut suins, &mut ctx);

        abort 1337
    }

    // === Helpers ===

    // for a softer and simpler wrapup we can just share the object
    fun wrapup(suins: SuiNS, cap: AdminCap) {
        suins::share_for_testing(suins);
        suins::burn_admin_cap_for_testing(cap);
    }
}
