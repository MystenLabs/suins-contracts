#[test_only]
module suins::base_registry_tests {
    use sui::test_scenario::{Self, Scenario};
    use suins::base_registry::{Self, Registry};

    const SUINS_ADDRESS: address = @0xA001;
    const FIRST_USER_ADDRESS: address = @0xB001;
    const SECOND_USER_ADDRESS: address = @0xB002;
    const FIRST_RESOLVER_ADDRESS: address = @0xC001;
    const SECOND_RESOLVER_ADDRESS: address = @0xC002;
    const FIRST_BASE_NODE: vector<u8> = b"sui";
    const SECOND_BASE_NODE: vector<u8> = b"secondsuitest";
    const SUB_NODE: vector<u8> = b"ea.sui";

    fun init(): Scenario {
        let scenario = test_scenario::begin(SUINS_ADDRESS);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            base_registry::test_init(ctx);
        };
        scenario
    }

    fun mint_record(scenario: &mut Scenario) {
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(scenario);

            // registry has default records for `sui` and `move` TLD
            assert!(base_registry::get_records_len(&registry) == 3, 0);
            base_registry::set_record(
                &mut registry,
                FIRST_BASE_NODE,
                FIRST_USER_ADDRESS,
                FIRST_RESOLVER_ADDRESS,
                10,
                test_scenario::ctx(scenario),
            );
            // override the existing record
            assert!(base_registry::get_records_len(&registry) == 3, 0);

            test_scenario::return_shared(registry);
        };
    }

    // TODO: test for emitted events
    #[test]
    fun test_mint_new_record() {
        let scenario = init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);

            assert!(base_registry::owner(&registry, FIRST_BASE_NODE) == FIRST_USER_ADDRESS, 0);
            assert!(base_registry::resolver(&registry, FIRST_BASE_NODE) == FIRST_RESOLVER_ADDRESS, 0);
            assert!(base_registry::ttl(&registry, FIRST_BASE_NODE) == 10, 0);

            test_scenario::return_shared(registry);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);

            assert!(base_registry::get_records_len(&registry) == 3, 0);
            base_registry::set_record(
                &mut registry,
                FIRST_BASE_NODE,
                SECOND_USER_ADDRESS,
                SECOND_RESOLVER_ADDRESS,
                20,
                test_scenario::ctx(&mut scenario),
            );
            assert!(base_registry::get_records_len(&registry) == 3, 0);

            test_scenario::return_shared(registry);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let (_, record) = base_registry::get_record_at_index(&registry, 0);

            assert!(base_registry::get_record_owner(record) == SECOND_USER_ADDRESS, 0);
            assert!(base_registry::get_record_resolver(record) == SECOND_RESOLVER_ADDRESS, 0);
            assert!(base_registry::get_record_ttl(record) == 20, 0);

            test_scenario::return_shared(registry);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_set_owner() {
        let scenario = init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);

            assert!(base_registry::get_records_len(&registry) == 3, 0);
            base_registry::set_owner(
                &mut registry,
                FIRST_BASE_NODE,
                SECOND_USER_ADDRESS,
                test_scenario::ctx(&mut scenario),
            );
            assert!(base_registry::get_records_len(&registry) == 3, 0);

            test_scenario::return_shared(registry);
        };

        test_scenario::next_tx(&mut scenario, SECOND_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);

            assert!(base_registry::owner(&registry, FIRST_BASE_NODE) == SECOND_USER_ADDRESS, 0);

            test_scenario::return_shared(registry);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 102)]
    fun test_set_owner_abort_if_node_not_exists() {
        let scenario = init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);

            assert!(base_registry::get_records_len(&registry) == 3, 0);

            base_registry::set_owner(
                &mut registry,
                SECOND_BASE_NODE,
                SECOND_USER_ADDRESS,
                test_scenario::ctx(&mut scenario),
            );

            assert!(base_registry::get_records_len(&registry) == 1, 0);
            test_scenario::return_shared(registry);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 101)]
    fun test_set_owner_abort_if_unauthorised() {
        let scenario = init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, SECOND_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);

            assert!(base_registry::get_records_len(&registry) == 3, 0);

            base_registry::set_owner(
                &mut registry,
                FIRST_BASE_NODE,
                SECOND_USER_ADDRESS,
                test_scenario::ctx(&mut scenario),
            );

            assert!(base_registry::get_records_len(&registry) == 3, 0);
            test_scenario::return_shared(registry);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_set_subnode_owner() {
        let scenario = init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);

            assert!(base_registry::get_records_len(&registry) == 3, 0);
            base_registry::set_subnode_owner(
                &mut registry,
                FIRST_BASE_NODE,
                b"ea",
                SECOND_USER_ADDRESS,
                test_scenario::ctx(&mut scenario),
            );
            assert!(base_registry::get_records_len(&registry) == 4, 0);

            test_scenario::return_shared(registry);
        };

        test_scenario::next_tx(&mut scenario, SECOND_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);

            assert!(base_registry::owner(&registry, SUB_NODE) == SECOND_USER_ADDRESS, 0);

            test_scenario::return_shared(registry);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 102)]
    fun test_set_subnode_owner_abort_if_node_not_exists() {
        let scenario = init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);

            assert!(base_registry::get_records_len(&registry) == 3, 0);
            base_registry::set_subnode_owner(
                &mut registry,
                SECOND_BASE_NODE,
                b"ea",
                SECOND_USER_ADDRESS,
                test_scenario::ctx(&mut scenario)
            );
            assert!(base_registry::get_records_len(&registry) == 3, 0);

            test_scenario::return_shared(registry);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 101)]
    fun test_set_subnode_owner_abort_if_unauthorised() {
        let scenario = init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, SECOND_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);

            assert!(base_registry::get_records_len(&registry) == 3, 0);
            base_registry::set_subnode_owner(
                &mut registry,
                FIRST_BASE_NODE,
                b"ea",
                SECOND_USER_ADDRESS,
                test_scenario::ctx(&mut scenario)
            );
            assert!(base_registry::get_records_len(&registry) == 3, 0);

            test_scenario::return_shared(registry);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_set_subnode_owner_overwrite_value_if_node_exists() {
        let scenario = init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);

            assert!(base_registry::get_records_len(&registry) == 3, 0);
            base_registry::set_subnode_owner(
                &mut registry,
                FIRST_BASE_NODE,
                b"ea",
                SECOND_USER_ADDRESS,
                test_scenario::ctx(&mut scenario)
            );
            assert!(base_registry::get_records_len(&registry) == 4, 0);

            test_scenario::return_shared(registry);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);

            assert!(base_registry::get_records_len(&registry) == 4, 0);
            base_registry::set_subnode_owner(
                &mut registry,
                FIRST_BASE_NODE,
                b"ea",
                FIRST_USER_ADDRESS,
                test_scenario::ctx(&mut scenario)
            );
            assert!(base_registry::get_records_len(&registry) == 4, 0);

            test_scenario::return_shared(registry);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let (_, record) = base_registry::get_record_at_index(&registry, 3);
            assert!(base_registry::get_record_owner(record) == FIRST_USER_ADDRESS, 0);

            test_scenario::return_shared(registry);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_set_resolver() {
        let scenario = init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);

            base_registry::set_resolver(
                &mut registry,
                FIRST_BASE_NODE,
                SECOND_RESOLVER_ADDRESS,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(registry);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);

            assert!(base_registry::resolver(&registry, FIRST_BASE_NODE) == SECOND_RESOLVER_ADDRESS, 0);

            test_scenario::return_shared(registry);
        };

        // new resolver == current resolver
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);

            assert!(base_registry::get_records_len(&registry) == 3, 0);
            base_registry::set_resolver(
                &mut registry,
                FIRST_BASE_NODE,
                SECOND_RESOLVER_ADDRESS,
                test_scenario::ctx(&mut scenario),
            );
            assert!(base_registry::get_records_len(&registry) == 3, 0);

            test_scenario::return_shared(registry);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);

            assert!(base_registry::resolver(&registry, FIRST_BASE_NODE) == SECOND_RESOLVER_ADDRESS, 0);

            test_scenario::return_shared(registry);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 101)]
    fun test_set_resolver_abort_if_unauthorised() {
        let scenario = init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, SECOND_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);

            base_registry::set_resolver(
                &mut registry,
                FIRST_BASE_NODE,
                SECOND_RESOLVER_ADDRESS,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(registry);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 102)]
    fun test_set_resolver_abort_if_node_not_exists() {
        let scenario = init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);

            assert!(base_registry::get_records_len(&registry) == 3, 0);

            base_registry::set_resolver(
                &mut registry,
                SECOND_BASE_NODE,
                SECOND_RESOLVER_ADDRESS,
                test_scenario::ctx(&mut scenario),
            );

            assert!(base_registry::get_records_len(&registry) == 2, 0);
            test_scenario::return_shared(registry);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_set_ttl() {
        let scenario = init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);

            base_registry::set_TTL(&mut registry, FIRST_BASE_NODE, 20, test_scenario::ctx(&mut scenario));
            test_scenario::return_shared(registry);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);

            assert!(base_registry::ttl(&registry, FIRST_BASE_NODE) == 20, 0);

            test_scenario::return_shared(registry);
        };

        // new ttl == current ttl
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);

            assert!(base_registry::get_records_len(&registry) == 3, 0);
            base_registry::set_TTL(&mut registry, FIRST_BASE_NODE, 20, test_scenario::ctx(&mut scenario));
            assert!(base_registry::get_records_len(&registry) == 3, 0);

            test_scenario::return_shared(registry);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);

            assert!(base_registry::ttl(&registry, FIRST_BASE_NODE) == 20, 0);

            test_scenario::return_shared(registry);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 101)]
    fun test_set_ttl_abort_if_unauthorised() {
        let scenario = init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, SECOND_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);

            base_registry::set_TTL(&mut registry, FIRST_BASE_NODE, 20, test_scenario::ctx(&mut scenario));
            test_scenario::return_shared(registry);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 102)]
    fun test_set_ttl_abort_if_node_not_exists() {
        let scenario = init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);

            assert!(base_registry::get_records_len(&registry) == 3, 0);
            base_registry::set_TTL(&mut registry, SECOND_BASE_NODE, 20, test_scenario::ctx(&mut scenario));
            assert!(base_registry::get_records_len(&registry) == 2, 0);

            test_scenario::return_shared(registry);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_set_subnode_record() {
        let scenario = init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);

            assert!(base_registry::get_records_len(&registry) == 3, 0);
            base_registry::set_subnode_record(
                &mut registry,
                FIRST_BASE_NODE,
                b"ea",
                SECOND_USER_ADDRESS,
                SECOND_RESOLVER_ADDRESS,
                20,
                test_scenario::ctx(&mut scenario),
            );
            assert!(base_registry::get_records_len(&registry) == 4, 0);

            test_scenario::return_shared(registry);
        };

        test_scenario::next_tx(&mut scenario, SECOND_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);

            assert!(base_registry::owner(&registry, SUB_NODE) == SECOND_USER_ADDRESS, 0);
            assert!(base_registry::resolver(&registry, SUB_NODE) == SECOND_RESOLVER_ADDRESS, 0);
            assert!(base_registry::ttl(&registry, SUB_NODE) == 20, 0);

            test_scenario::return_shared(registry);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);

            assert!(base_registry::get_records_len(&registry) == 4, 0);
            base_registry::set_subnode_record(
                &mut registry,
                FIRST_BASE_NODE,
                b"ea",
                FIRST_USER_ADDRESS,
                FIRST_RESOLVER_ADDRESS,
                10,
                test_scenario::ctx(&mut scenario),
            );
            assert!(base_registry::get_records_len(&registry) == 4, 0);

            test_scenario::return_shared(registry);
        };

        test_scenario::next_tx(&mut scenario, SECOND_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);

            assert!(base_registry::owner(&registry, SUB_NODE) == FIRST_USER_ADDRESS, 0);
            assert!(base_registry::resolver(&registry, SUB_NODE) == FIRST_RESOLVER_ADDRESS, 0);
            assert!(base_registry::ttl(&registry, SUB_NODE) == 10, 0);

            test_scenario::return_shared(registry);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 101)]
    fun test_set_subnode_record_if_unauthorised() {
        let scenario = init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, SECOND_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);

            base_registry::set_subnode_record(
                &mut registry,
                FIRST_BASE_NODE,
                b"ea",
                SECOND_USER_ADDRESS,
                SECOND_RESOLVER_ADDRESS,
                20,
                test_scenario::ctx(&mut scenario),
            );

            test_scenario::return_shared(registry);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 102)]
    fun test_set_subnode_record_if_node_not_exists() {
        let scenario = init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);

            base_registry::set_subnode_record(
                &mut registry,
                SECOND_BASE_NODE,
                b"ea",
                SECOND_USER_ADDRESS,
                SECOND_RESOLVER_ADDRESS,
                20,
                test_scenario::ctx(&mut scenario),
            );

            test_scenario::return_shared(registry);
        };
        test_scenario::end(scenario);
    }
}
