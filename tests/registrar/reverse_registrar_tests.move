#[test_only]
module suins::reverse_registrar_tests {

    use sui::test_scenario::{Self, Scenario};
    use suins::base_registry::{Self, Registry, AdminCap};
    use suins::reverse_registrar::{Self, ReverseRegistrar};

    const SUINS_ADDRESS: address = @0xA001;
    const FIRST_USER_ADDRESS: address = @0xB001;
    const SECOND_USER_ADDRESS: address = @0xB002;
    const FIRST_RESOLVER_ADDRESS: address = @0xC001;
    const SECOND_RESOLVER_ADDRESS: address = @0xC002;

    fun init(): Scenario {
        let scenario = test_scenario::begin(&SUINS_ADDRESS);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            base_registry::test_init(ctx);
            reverse_registrar::test_init(ctx);
        };
        scenario
    }

    #[test]
    fun test_claim_for_addr() {
        let scenario = init();

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let registrar_wrapper = test_scenario::take_shared<ReverseRegistrar>(&mut scenario);
            let registrar = test_scenario::borrow_mut(&mut registrar_wrapper);

            assert!(reverse_registrar::get_records_len(registrar) == 0, 0);

            test_scenario::return_shared(&mut scenario, registrar_wrapper);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);
            let registrar_wrapper = test_scenario::take_shared<ReverseRegistrar>(&mut scenario);
            let registrar = test_scenario::borrow_mut(&mut registrar_wrapper);

            reverse_registrar::claim_for_addr(
                registrar,
                registry,
                FIRST_USER_ADDRESS,
                FIRST_RESOLVER_ADDRESS,
                test_scenario::ctx(&mut scenario),
            );

            test_scenario::return_shared(&mut scenario, registry_wrapper);
            test_scenario::return_shared(&mut scenario, registrar_wrapper);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let registrar_wrapper = test_scenario::take_shared<ReverseRegistrar>(&mut scenario);
            let registrar = test_scenario::borrow_mut(&mut registrar_wrapper);

            assert!(reverse_registrar::get_records_len(registrar) == 1, 0);
            let (addr, resolver) = reverse_registrar::get_record_at_index(registrar, 0);
            assert!(*addr == FIRST_USER_ADDRESS, 0);
            assert!(*resolver == FIRST_RESOLVER_ADDRESS, 0);

            test_scenario::return_shared(&mut scenario, registrar_wrapper);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);
            let registrar_wrapper = test_scenario::take_shared<ReverseRegistrar>(&mut scenario);
            let registrar = test_scenario::borrow_mut(&mut registrar_wrapper);

            reverse_registrar::claim_for_addr(
                registrar,
                registry,
                FIRST_USER_ADDRESS,
                SECOND_RESOLVER_ADDRESS,
                test_scenario::ctx(&mut scenario),
            );

            test_scenario::return_shared(&mut scenario, registry_wrapper);
            test_scenario::return_shared(&mut scenario, registrar_wrapper);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let registrar_wrapper = test_scenario::take_shared<ReverseRegistrar>(&mut scenario);
            let registrar = test_scenario::borrow_mut(&mut registrar_wrapper);

            assert!(reverse_registrar::get_records_len(registrar) == 1, 0);
            let (addr, resolver) = reverse_registrar::get_record_at_index(registrar, 0);
            assert!(*addr == FIRST_USER_ADDRESS, 0);
            assert!(*resolver == SECOND_RESOLVER_ADDRESS, 0);

            test_scenario::return_shared(&mut scenario, registrar_wrapper);
        };
    }

    #[test]
    #[expected_failure(abort_code = 101)]
    fun test_claim_for_addr_abort_if_unauthorized() {
        let scenario = init();

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);
            let registrar_wrapper = test_scenario::take_shared<ReverseRegistrar>(&mut scenario);
            let registrar = test_scenario::borrow_mut(&mut registrar_wrapper);

            reverse_registrar::claim_for_addr(
                registrar,
                registry,
                SECOND_USER_ADDRESS,
                FIRST_RESOLVER_ADDRESS,
                test_scenario::ctx(&mut scenario),
            );

            test_scenario::return_shared(&mut scenario, registry_wrapper);
            test_scenario::return_shared(&mut scenario, registrar_wrapper);
        };
    }

    #[test]
    #[expected_failure(abort_code = 501)]
    fun test_claim_for_addr_abort_with_invalid_resolver() {
        let scenario = init();

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);
            let registrar_wrapper = test_scenario::take_shared<ReverseRegistrar>(&mut scenario);
            let registrar = test_scenario::borrow_mut(&mut registrar_wrapper);

            reverse_registrar::claim_for_addr(
                registrar,
                registry,
                SECOND_USER_ADDRESS,
                @0x0,
                test_scenario::ctx(&mut scenario),
            );

            test_scenario::return_shared(&mut scenario, registry_wrapper);
            test_scenario::return_shared(&mut scenario, registrar_wrapper);
        };
    }

    #[test]
    fun test_claim_for_addr_by_operator() {
        let scenario = init();

        test_scenario::next_tx(&mut scenario, &SECOND_USER_ADDRESS);
        {
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            base_registry::set_approval_for_all(
                registry,
                FIRST_USER_ADDRESS,
                true,
                test_scenario::ctx(&mut scenario),
            );

            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);
            let registrar_wrapper = test_scenario::take_shared<ReverseRegistrar>(&mut scenario);
            let registrar = test_scenario::borrow_mut(&mut registrar_wrapper);

            reverse_registrar::claim_for_addr(
                registrar,
                registry,
                SECOND_USER_ADDRESS,
                FIRST_RESOLVER_ADDRESS,
                test_scenario::ctx(&mut scenario),
            );

            test_scenario::return_shared(&mut scenario, registry_wrapper);
            test_scenario::return_shared(&mut scenario, registrar_wrapper);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let registrar_wrapper = test_scenario::take_shared<ReverseRegistrar>(&mut scenario);
            let registrar = test_scenario::borrow_mut(&mut registrar_wrapper);

            assert!(reverse_registrar::get_records_len(registrar) == 1, 0);
            let (addr, resolver) = reverse_registrar::get_record_at_index(registrar, 0);
            assert!(*addr == SECOND_USER_ADDRESS, 0);
            assert!(*resolver == FIRST_RESOLVER_ADDRESS, 0);

            test_scenario::return_shared(&mut scenario, registrar_wrapper);
        };
    }

    #[test]
    fun test_claim() {
        let scenario = init();

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let registrar_wrapper = test_scenario::take_shared<ReverseRegistrar>(&mut scenario);
            let registrar = test_scenario::borrow_mut(&mut registrar_wrapper);

            assert!(reverse_registrar::get_records_len(registrar) == 0, 0);

            test_scenario::return_shared(&mut scenario, registrar_wrapper);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);
            let registrar_wrapper = test_scenario::take_shared<ReverseRegistrar>(&mut scenario);
            let registrar = test_scenario::borrow_mut(&mut registrar_wrapper);

            reverse_registrar::claim(
                registrar,
                registry,
                test_scenario::ctx(&mut scenario),
            );

            test_scenario::return_shared(&mut scenario, registry_wrapper);
            test_scenario::return_shared(&mut scenario, registrar_wrapper);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let registrar_wrapper = test_scenario::take_shared<ReverseRegistrar>(&mut scenario);
            let registrar = test_scenario::borrow_mut(&mut registrar_wrapper);

            assert!(reverse_registrar::get_records_len(registrar) == 1, 0);
            let (addr, resolver) = reverse_registrar::get_record_at_index(registrar, 0);
            assert!(*addr == FIRST_USER_ADDRESS, 0);
            assert!(*resolver == SUINS_ADDRESS, 0);

            test_scenario::return_shared(&mut scenario, registrar_wrapper);
        };
    }

    #[test]
    fun test_claim_with_resolver() {
        let scenario = init();

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let registrar_wrapper = test_scenario::take_shared<ReverseRegistrar>(&mut scenario);
            let registrar = test_scenario::borrow_mut(&mut registrar_wrapper);

            assert!(reverse_registrar::get_records_len(registrar) == 0, 0);

            test_scenario::return_shared(&mut scenario, registrar_wrapper);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);
            let registrar_wrapper = test_scenario::take_shared<ReverseRegistrar>(&mut scenario);
            let registrar = test_scenario::borrow_mut(&mut registrar_wrapper);

            reverse_registrar::claim_with_resolver(
                registrar,
                registry,
                FIRST_RESOLVER_ADDRESS,
                test_scenario::ctx(&mut scenario),
            );

            test_scenario::return_shared(&mut scenario, registry_wrapper);
            test_scenario::return_shared(&mut scenario, registrar_wrapper);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let registrar_wrapper = test_scenario::take_shared<ReverseRegistrar>(&mut scenario);
            let registrar = test_scenario::borrow_mut(&mut registrar_wrapper);

            assert!(reverse_registrar::get_records_len(registrar) == 1, 0);
            let (addr, resolver) = reverse_registrar::get_record_at_index(registrar, 0);
            assert!(*addr == FIRST_USER_ADDRESS, 0);
            assert!(*resolver == FIRST_RESOLVER_ADDRESS, 0);

            test_scenario::return_shared(&mut scenario, registrar_wrapper);
        };
    }

    #[test]
    #[expected_failure(abort_code = 501)]
    fun test_claim_with_resolver_abort_with_invalid_resolver() {
        let scenario = init();

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);
            let registrar_wrapper = test_scenario::take_shared<ReverseRegistrar>(&mut scenario);
            let registrar = test_scenario::borrow_mut(&mut registrar_wrapper);

            reverse_registrar::claim_with_resolver(
                registrar,
                registry,
                @0x0,
                test_scenario::ctx(&mut scenario),
            );

            test_scenario::return_shared(&mut scenario, registry_wrapper);
            test_scenario::return_shared(&mut scenario, registrar_wrapper);
        };
    }

    #[test]
    fun test_set_default_resolver() {
        let scenario = init();

        test_scenario::next_tx(&mut scenario, &SUINS_ADDRESS);
        {
            let registrar_wrapper = test_scenario::take_shared<ReverseRegistrar>(&mut scenario);
            let registrar = test_scenario::borrow_mut(&mut registrar_wrapper);

            let default_resolver = reverse_registrar::get_default_resolver(registrar);
            assert!(default_resolver == SUINS_ADDRESS, 0);

            test_scenario::return_shared(&mut scenario, registrar_wrapper);
        };

        test_scenario::next_tx(&mut scenario, &SUINS_ADDRESS);
        {
            let registrar_wrapper = test_scenario::take_shared<ReverseRegistrar>(&mut scenario);
            let registrar = test_scenario::borrow_mut(&mut registrar_wrapper);
            let admin_cap = test_scenario::take_owned<AdminCap>(&mut scenario);

            reverse_registrar::set_default_resolver(
                &admin_cap,
                registrar,
                FIRST_RESOLVER_ADDRESS,
            );

            test_scenario::return_shared(&mut scenario, registrar_wrapper);
            test_scenario::return_owned(&mut scenario, admin_cap);
        };

        test_scenario::next_tx(&mut scenario, &SUINS_ADDRESS);
        {
            let registrar_wrapper = test_scenario::take_shared<ReverseRegistrar>(&mut scenario);
            let registrar = test_scenario::borrow_mut(&mut registrar_wrapper);

            let default_resolver = reverse_registrar::get_default_resolver(registrar);
            assert!(default_resolver == FIRST_RESOLVER_ADDRESS, 0);

            test_scenario::return_shared(&mut scenario, registrar_wrapper);
        };
    }

    #[test]
    #[expected_failure(abort_code = 501)]
    fun test_set_default_resolver_if_new_resolver_is_invalid() {
        let scenario = init();

        test_scenario::next_tx(&mut scenario, &SUINS_ADDRESS);
        {
            let registrar_wrapper = test_scenario::take_shared<ReverseRegistrar>(&mut scenario);
            let registrar = test_scenario::borrow_mut(&mut registrar_wrapper);
            let admin_cap = test_scenario::take_owned<AdminCap>(&mut scenario);

            reverse_registrar::set_default_resolver(
                &admin_cap,
                registrar,
                @0x0,
            );

            test_scenario::return_shared(&mut scenario, registrar_wrapper);
            test_scenario::return_owned(&mut scenario, admin_cap);
        };
    }
}
