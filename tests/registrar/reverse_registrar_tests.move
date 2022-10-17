#[test_only]
module suins::reverse_registrar_tests {

    use sui::test_scenario::{Self, Scenario};
    use suins::base_registry::{Self, Registry, AdminCap};
    use suins::reverse_registrar::{Self, ReverseRegistrar};
    use std::string;

    const SUINS_ADDRESS: address = @0xA001;
    const FIRST_USER_ADDRESS: address = @0xB001;
    const SECOND_USER_ADDRESS: address = @0xB002;
    const FIRST_RESOLVER_ADDRESS: address = @0xC001;
    const SECOND_RESOLVER_ADDRESS: address = @0xC002;
    const FIRST_NODE: vector<u8> = b"000000000000000000000000000000000000b001.addr.reverse";
    const SECOND_NODE: vector<u8> = b"000000000000000000000000000000000000b002.addr.reverse";

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
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            assert!(base_registry::get_records_len(registry) == 2, 0);

            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            reverse_registrar::claim_for_addr(
                registry,
                FIRST_USER_ADDRESS,
                FIRST_USER_ADDRESS,
                FIRST_RESOLVER_ADDRESS,
                test_scenario::ctx(&mut scenario),
            );

            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            assert!(base_registry::get_records_len(registry) == 3, 0);
            let (node, record) = base_registry::get_record_at_index(registry, 2);
            assert!(node == &string::utf8(FIRST_NODE), 0);
            assert!(base_registry::get_record_node(record) == string::utf8(FIRST_NODE), 0);
            assert!(base_registry::get_record_ttl(record) == 0, 0);
            assert!(base_registry::get_record_resolver(record) == FIRST_RESOLVER_ADDRESS, 0);
            assert!(base_registry::get_record_owner(record) == FIRST_USER_ADDRESS, 0);

            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            reverse_registrar::claim_for_addr(
                registry,
                FIRST_USER_ADDRESS,
                SECOND_USER_ADDRESS,
                SECOND_RESOLVER_ADDRESS,
                test_scenario::ctx(&mut scenario),
            );

            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            assert!(base_registry::get_records_len(registry) == 3, 0);
            let (node, record) = base_registry::get_record_at_index(registry, 2);
            assert!(node == &string::utf8(FIRST_NODE), 0);
            assert!(base_registry::get_record_node(record) == string::utf8(FIRST_NODE), 0);
            assert!(base_registry::get_record_ttl(record) == 0, 0);
            assert!(base_registry::get_record_resolver(record) == SECOND_RESOLVER_ADDRESS, 0);
            assert!(base_registry::get_record_owner(record) == SECOND_USER_ADDRESS, 0);

            test_scenario::return_shared(&mut scenario, registry_wrapper);
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

            reverse_registrar::claim_for_addr(
                registry,
                SECOND_USER_ADDRESS,
                FIRST_USER_ADDRESS,
                FIRST_RESOLVER_ADDRESS,
                test_scenario::ctx(&mut scenario),
            );

            test_scenario::return_shared(&mut scenario, registry_wrapper);
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

            reverse_registrar::claim_for_addr(
                registry,
                FIRST_USER_ADDRESS,
                SECOND_USER_ADDRESS,
                @0x0,
                test_scenario::ctx(&mut scenario),
            );

            test_scenario::return_shared(&mut scenario, registry_wrapper);
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

            reverse_registrar::claim_for_addr(
                registry,
                SECOND_USER_ADDRESS,
                FIRST_USER_ADDRESS,
                FIRST_RESOLVER_ADDRESS,
                test_scenario::ctx(&mut scenario),
            );

            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            assert!(base_registry::get_records_len(registry) == 3, 0);
            let (node, record) = base_registry::get_record_at_index(registry, 2);
            assert!(node == &string::utf8(SECOND_NODE), 0);
            assert!(base_registry::get_record_node(record) == string::utf8(SECOND_NODE), 0);
            assert!(base_registry::get_record_ttl(record) == 0, 0);
            assert!(base_registry::get_record_resolver(record) == FIRST_RESOLVER_ADDRESS, 0);
            assert!(base_registry::get_record_owner(record) == FIRST_USER_ADDRESS, 0);

            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };
    }

    #[test]
    fun test_claim() {
        let scenario = init();

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            assert!(base_registry::get_records_len(registry) == 2, 0);

            test_scenario::return_shared(&mut scenario, registry_wrapper);
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
                FIRST_USER_ADDRESS,
                test_scenario::ctx(&mut scenario),
            );

            test_scenario::return_shared(&mut scenario, registry_wrapper);
            test_scenario::return_shared(&mut scenario, registrar_wrapper);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            assert!(base_registry::get_records_len(registry) == 3, 0);
            let (node, record) = base_registry::get_record_at_index(registry, 2);
            assert!(node == &string::utf8(FIRST_NODE), 0);
            assert!(base_registry::get_record_node(record) == string::utf8(FIRST_NODE), 0);
            assert!(base_registry::get_record_ttl(record) == 0, 0);
            assert!(base_registry::get_record_resolver(record) == SUINS_ADDRESS, 0);
            assert!(base_registry::get_record_owner(record) == FIRST_USER_ADDRESS, 0);

            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };
    }

    #[test]
    fun test_claim_with_resolver() {
        let scenario = init();

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            assert!(base_registry::get_records_len(registry) == 2, 0);

            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            reverse_registrar::claim_with_resolver(
                registry,
                FIRST_USER_ADDRESS,
                SECOND_RESOLVER_ADDRESS,
                test_scenario::ctx(&mut scenario),
            );

            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            assert!(base_registry::get_records_len(registry) == 3, 0);
            let (node, record) = base_registry::get_record_at_index(registry, 2);
            assert!(node == &string::utf8(FIRST_NODE), 0);
            assert!(base_registry::get_record_node(record) == string::utf8(FIRST_NODE), 0);
            assert!(base_registry::get_record_ttl(record) == 0, 0);
            assert!(base_registry::get_record_resolver(record) == SECOND_RESOLVER_ADDRESS, 0);
            assert!(base_registry::get_record_owner(record) == FIRST_USER_ADDRESS, 0);

            test_scenario::return_shared(&mut scenario, registry_wrapper);
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

            reverse_registrar::claim_with_resolver(
                registry,
                FIRST_USER_ADDRESS,
                @0x0,
                test_scenario::ctx(&mut scenario),
            );

            test_scenario::return_shared(&mut scenario, registry_wrapper);
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
