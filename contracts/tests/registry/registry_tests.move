#[test_only]
module suins::registry_tests {

    use sui::test_scenario::{Self, Scenario};
    use sui::dynamic_field;
    use suins::registry::{Self, AdminCap};
    use suins::registrar;
    use std::string::utf8;
    use suins::entity::SuiNS;
    use suins::entity;

    friend suins::resolver_tests;

    const SUINS_ADDRESS: address = @0xA001;
    const FIRST_USER_ADDRESS: address = @0xB001;
    const SECOND_USER_ADDRESS: address = @0xB002;
    const FIRST_RESOLVER_ADDRESS: address = @0xC001;
    const SECOND_RESOLVER_ADDRESS: address = @0xC002;
    const FIRST_SUB_NODE: vector<u8> = b"eastagile.sui";
    const SECOND_SUB_NODE: vector<u8> = b"secondsuitest.sui";
    const THIRD_SUB_NODE: vector<u8> = b"ea.eastagile.sui";

    fun test_init(): Scenario {
        let scenario = test_scenario::begin(SUINS_ADDRESS);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            registry::test_init(ctx);
            entity::test_init(ctx);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            registrar::new_tld(&admin_cap, &mut suins, b"sui", test_scenario::ctx(&mut scenario));
            registrar::new_tld(&admin_cap, &mut suins, b"addr.reverse", test_scenario::ctx(&mut scenario));
            registrar::new_tld(&admin_cap, &mut suins, b"move", test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(suins);
            test_scenario::return_to_sender(&mut scenario, admin_cap);
        };
        scenario
    }

    public(friend) fun mint_record(scenario: &mut Scenario) {
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            registry::set_record_internal(
                &mut suins,
                utf8(FIRST_SUB_NODE),
                FIRST_USER_ADDRESS,
                FIRST_RESOLVER_ADDRESS,
                10,
            );
            test_scenario::return_shared(suins);
        };
    }

    // TODO: test for emitted events
    #[test]
    fun test_set_record_internal() {
        let scenario = test_init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            assert!(registry::owner(&suins, FIRST_SUB_NODE) == FIRST_USER_ADDRESS, 0);
            assert!(registry::resolver(&suins, FIRST_SUB_NODE) == FIRST_RESOLVER_ADDRESS, 0);
            assert!(registry::ttl(&suins, FIRST_SUB_NODE) == 10, 0);

            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::set_record_internal(
                &mut suins,
                utf8(FIRST_SUB_NODE),
                SECOND_USER_ADDRESS,
                SECOND_RESOLVER_ADDRESS,
                20,
            );
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let (owner, resolver, ttl) = registry::get_record_by_key(&suins, utf8(FIRST_SUB_NODE));

            assert!(owner == SECOND_USER_ADDRESS, 0);
            assert!(resolver == SECOND_RESOLVER_ADDRESS, 0);
            assert!(ttl == 20, 0);

            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_set_owner() {
        let scenario = test_init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::set_owner(
                &mut suins,
                FIRST_SUB_NODE,
                SECOND_USER_ADDRESS,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, SECOND_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            assert!(registry::owner(&suins, FIRST_SUB_NODE) == SECOND_USER_ADDRESS, 0);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = dynamic_field::EFieldDoesNotExist)]
    fun test_set_owner_abort_if_node_not_exists() {
        let scenario = test_init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            registry::set_owner(
                &mut suins,
                SECOND_SUB_NODE,
                SECOND_USER_ADDRESS,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registry::EUnauthorized)]
    fun test_set_owner_abort_if_unauthorised() {
        let scenario = test_init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, SECOND_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::set_owner(
                &mut suins,
                FIRST_SUB_NODE,
                SECOND_USER_ADDRESS,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_set_subnode_owner() {
        let scenario = test_init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::set_record_internal(
                &mut suins,
                utf8(THIRD_SUB_NODE),
                FIRST_USER_ADDRESS,
                FIRST_RESOLVER_ADDRESS,
                10,
            );
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::set_subnode_owner(
                &mut suins,
                FIRST_SUB_NODE,
                b"ea",
                SECOND_USER_ADDRESS,
                test_scenario::ctx(&mut scenario),
            );

            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, SECOND_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            assert!(registry::owner(&suins, THIRD_SUB_NODE) == SECOND_USER_ADDRESS, 0);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = dynamic_field::EFieldDoesNotExist)]
    fun test_set_subnode_owner_abort_if_node_not_exists() {
        let scenario = test_init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::set_subnode_owner(
                &mut suins,
                SECOND_SUB_NODE,
                b"ea",
                SECOND_USER_ADDRESS,
                test_scenario::ctx(&mut scenario)
            );
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = dynamic_field::EFieldDoesNotExist)]
    fun test_set_subnode_owner_abort_if_subnode_not_exists() {
        let scenario = test_init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::set_subnode_owner(
                &mut suins,
                FIRST_SUB_NODE,
                b"ea",
                SECOND_USER_ADDRESS,
                test_scenario::ctx(&mut scenario)
            );
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registry::EUnauthorized)]
    fun test_set_subnode_owner_abort_if_unauthorised() {
        let scenario = test_init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, SECOND_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            registry::set_subnode_owner(
                &mut suins,
                FIRST_SUB_NODE,
                b"ea",
                SECOND_USER_ADDRESS,
                test_scenario::ctx(&mut scenario)
            );

            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_set_subnode_owner_overwrite_value_if_node_exists() {
        let scenario = test_init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            registry::set_record_internal(
                &mut suins,
                utf8(THIRD_SUB_NODE),
                FIRST_USER_ADDRESS,
                FIRST_RESOLVER_ADDRESS,
                10,
            );
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            registry::set_subnode_owner(
                &mut suins,
                FIRST_SUB_NODE,
                b"ea",
                SECOND_USER_ADDRESS,
                test_scenario::ctx(&mut scenario)
            );

            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let (owner, _, _) = registry::get_record_by_key(&suins, utf8(THIRD_SUB_NODE));
            assert!(owner == SECOND_USER_ADDRESS, 0);

            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_set_resolver() {
        let scenario = test_init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::set_resolver(
                &mut suins,
                FIRST_SUB_NODE,
                SECOND_RESOLVER_ADDRESS,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            assert!(registry::resolver(&suins, FIRST_SUB_NODE) == SECOND_RESOLVER_ADDRESS, 0);
            test_scenario::return_shared(suins);
        };

        // new resolver == current resolver
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            registry::set_resolver(
                &mut suins,
                FIRST_SUB_NODE,
                SECOND_RESOLVER_ADDRESS,
                test_scenario::ctx(&mut scenario),
            );

            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            assert!(registry::resolver(&suins, FIRST_SUB_NODE) == SECOND_RESOLVER_ADDRESS, 0);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registry::EUnauthorized)]
    fun test_set_resolver_abort_if_unauthorised() {
        let scenario = test_init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, SECOND_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::set_resolver(
                &mut suins,
                FIRST_SUB_NODE,
                SECOND_RESOLVER_ADDRESS,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = dynamic_field::EFieldDoesNotExist)]
    fun test_set_resolver_abort_if_node_not_exists() {
        let scenario = test_init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::set_resolver(
                &mut suins,
                SECOND_SUB_NODE,
                SECOND_RESOLVER_ADDRESS,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_set_ttl() {
        let scenario = test_init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::set_TTL(&mut suins, FIRST_SUB_NODE, 20, test_scenario::ctx(&mut scenario));
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            assert!(registry::ttl(&suins, FIRST_SUB_NODE) == 20, 0);
            test_scenario::return_shared(suins);
        };

        // new ttl == current ttl
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::set_TTL(&mut suins, FIRST_SUB_NODE, 20, test_scenario::ctx(&mut scenario));
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            assert!(registry::ttl(&suins, FIRST_SUB_NODE) == 20, 0);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registry::EUnauthorized)]
    fun test_set_ttl_abort_if_unauthorised() {
        let scenario = test_init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, SECOND_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            registry::set_TTL(&mut suins, FIRST_SUB_NODE, 20, test_scenario::ctx(&mut scenario));
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = dynamic_field::EFieldDoesNotExist)]
    fun test_set_ttl_abort_if_node_not_exists() {
        let scenario = test_init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::set_TTL(&mut suins, SECOND_SUB_NODE, 20, test_scenario::ctx(&mut scenario));
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_get_resolver() {
        let scenario = test_init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let resolver = registry::resolver(&suins, FIRST_SUB_NODE);
            assert!(resolver == FIRST_RESOLVER_ADDRESS, 0);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = dynamic_field::EFieldDoesNotExist)]
    fun test_get_resolver_if_node_not_exists() {
        let scenario = test_init();
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::resolver(&suins, FIRST_SUB_NODE);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_get_ttl() {
        let scenario = test_init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let ttl = registry::ttl(&suins, FIRST_SUB_NODE);
            assert!(ttl == 10, 0);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = dynamic_field::EFieldDoesNotExist)]
    fun test_get_ttl_if_node_not_exists() {
        let scenario = test_init();
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::ttl(&suins, FIRST_SUB_NODE);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }
}
