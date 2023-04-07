#[test_only]
module suins::registry_tests_2 {

    use sui::test_scenario::{Self, Scenario};
    use suins::registry;
    use suins::registry_tests;
    use suins::entity::{Self, SuiNS};
    use std::string::utf8;

    const SUINS_ADDRESS: address = @0xA001;
    const FIRST_NAME: vector<u8> = b"sui";
    const SECOND_NAME: vector<u8> = b"move";
    const FIRST_USER_ADDRESS: address = @0xB001;
    const FIRST_REVERSE_DOMAIN: vector<u8> = b"000000000000000000000000000000000000000000000000000000000000b001.addr.reverse";
    const SECOND_USER_ADDRESS: address = @0xB002;
    const ADDR_REVERSE_BASE_NODE: vector<u8> = b"addr.reverse";
    const FIRST_SUB_NODE: vector<u8> = b"eastagile.sui";
    const SECOND_SUB_NODE: vector<u8> = b"suins.sui";
    const FIRST_AVATAR: vector<u8> = b"QmfWrgbTZqwzqsvdeNc3NKacggMuTaN83sQ8V7Bs2nXKRD";
    const FIRST_CONTENTHASH: vector<u8> = b"QmfWrgbTZqwzqsvdeNc3NKacggMuTaN83sQ8V7Bs2nXKRD";
    const ADDR: vector<u8> = b"addr";
    const AVATAR: vector<u8> = b"avatar";
    const CONTENTHASH: vector<u8> = b"contenthash";
    const CUSTOM_KEY: vector<u8> = b"custom_key";
    const FIRST_CONTENT_HASH: vector<u8> = b"mtwirsqawjuoloq2gvtyug2tc3jbf5htm2zeo4rsknfiv3fdp46a";

    fun test_init(): Scenario {
        let scenario = test_scenario::begin(SUINS_ADDRESS);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            registry::test_init(ctx);
            entity::test_init(ctx);
        };
        scenario
    }

    fun set_default_name(scenario: &mut Scenario) {
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            registry::new_record_test(&mut suins, utf8(FIRST_REVERSE_DOMAIN), FIRST_USER_ADDRESS, test_scenario::ctx(scenario));
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            registry::set_default_domain_name(&mut suins, FIRST_NAME, test_scenario::ctx(scenario));
            test_scenario::return_shared(suins);
        };
    }

    #[test, expected_failure(abort_code = registry::EDomainNameNotExists)]
    fun test_get_default_name_aborts_if_reverse_domain_name_not_exists() {
        let scenario = test_init();
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::default_domain_name(&suins, FIRST_REVERSE_DOMAIN);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_set_default_name() {
        let scenario = test_init();
        set_default_name(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let name= registry::default_domain_name(&suins, FIRST_REVERSE_DOMAIN);
            assert!(name == utf8(FIRST_NAME), 0);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_get_name_returns_empty_if_already_being_unset() {
        let scenario = test_init();
        set_default_name(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::unset_default_domain_name(&mut suins, test_scenario::ctx(&mut scenario));
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let name = registry::default_domain_name(&suins, FIRST_REVERSE_DOMAIN);
            assert!(name == utf8(b""), 0);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registry::EDomainNameNotExists)]
    fun test_unset_name_abort_if_unauthorized() {
        let scenario = test_init();
        set_default_name(&mut scenario);
        test_scenario::next_tx(&mut scenario, SECOND_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::unset_default_domain_name(&mut suins, test_scenario::ctx(&mut scenario));
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_unset_name_works_if_being_called_twice() {
        let scenario = test_init();
        set_default_name(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::unset_default_domain_name(&mut suins, test_scenario::ctx(&mut scenario));
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::unset_default_domain_name(&mut suins, test_scenario::ctx(&mut scenario));
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let name = registry::default_domain_name(&suins, FIRST_REVERSE_DOMAIN);
            assert!(name == utf8(b""), 0);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registry::EDomainNameNotExists)]
    fun test_unset_name_abort_if_domain_name_not_exists() {
        let scenario = test_init();
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::unset_default_domain_name(&mut suins, test_scenario::ctx(&mut scenario));
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_set_name_override_value_if_exists() {
        let scenario = test_init();
        set_default_name(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::set_default_domain_name(
                &mut suins,
                SECOND_NAME,
                test_scenario::ctx(&mut scenario)
            );
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            let name = registry::default_domain_name(&suins, FIRST_REVERSE_DOMAIN);
            assert!(name == utf8(SECOND_NAME), 0);

            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registry::EDomainNameNotExists)]
    fun test_set_name_abort_if_record_not_exists_in_registry() {
        let scenario = test_init();
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::set_default_domain_name(&mut suins, FIRST_NAME, test_scenario::ctx(&mut scenario));
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registry::EDomainNameNotExists)]
    fun test_get_addr_returns_empty_if_node_not_exists() {
        let scenario = test_init();
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let addr = registry::linked_addr(&suins, FIRST_SUB_NODE);
            assert!(addr == @0x0, 0);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_set_addr() {
        let scenario = test_init();
        registry_tests::mint_record(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::set_linked_addr(
                &mut suins,
                FIRST_SUB_NODE,
                FIRST_USER_ADDRESS,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let addr = registry::linked_addr(&suins, FIRST_SUB_NODE);
            assert!(addr == FIRST_USER_ADDRESS, 0);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_set_addr_override_value_if_exists() {
        let scenario = test_init();
        registry_tests::mint_record(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::set_linked_addr(
                &mut suins,
                FIRST_SUB_NODE,
                FIRST_USER_ADDRESS,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::set_linked_addr(
                &mut suins,
                FIRST_SUB_NODE,
                SECOND_USER_ADDRESS,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let addr = registry::linked_addr(&suins, FIRST_SUB_NODE);
            assert!(addr == SECOND_USER_ADDRESS, 0);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registry::EUnauthorized)]
    fun test_set_address_aborts_if_unauthorized() {
        let scenario = test_init();
        registry_tests::mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::set_linked_addr(
                &mut suins,
                FIRST_SUB_NODE,
                FIRST_USER_ADDRESS,
                test_scenario::ctx(&mut scenario)
            );
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::set_linked_addr(
                &mut suins,
                FIRST_SUB_NODE,
                SECOND_USER_ADDRESS,
                test_scenario::ctx(&mut scenario)
            );
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registry::EUnauthorized)]
    fun test_set_data_abort_if_unauthorized() {
        let scenario = test_init();
        registry_tests::mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::set_data(
                &mut suins,
                FIRST_SUB_NODE,
                AVATAR,
                FIRST_AVATAR,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_set_data() {
        let scenario = test_init();
        registry_tests::mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::set_data(
                &mut suins,
                FIRST_SUB_NODE,
                AVATAR,
                FIRST_AVATAR,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let avatar = registry::get_name_record_data(&suins, FIRST_SUB_NODE, AVATAR);
            assert!(avatar == utf8(FIRST_AVATAR), 0);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registry::EKeyNotExists)]
    fun test_set_data_returns_empty_with_wrong_node() {
        let scenario = test_init();
        registry_tests::mint_record(&mut scenario);
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::set_record_internal(
                &mut suins,
                utf8(SECOND_SUB_NODE),
                FIRST_USER_ADDRESS,
                10,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::set_data(
                &mut suins,
                FIRST_SUB_NODE,
                AVATAR,
                FIRST_AVATAR,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let avatar = registry::get_name_record_data(&suins, SECOND_SUB_NODE, AVATAR);
            assert!(avatar == utf8(b""), 0);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_set_contenthash() {
        let scenario = test_init();
        registry_tests::mint_record(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::set_data(
                &mut suins,
                FIRST_SUB_NODE,
                CONTENTHASH,
                FIRST_CONTENT_HASH,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let hash = registry::get_name_record_data(&suins, FIRST_SUB_NODE, CONTENTHASH);
            assert!(hash == utf8(FIRST_CONTENT_HASH), 0);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registry::EUnauthorized)]
    fun test_set_contenthash_abort_if_unauthorized() {
        let scenario = test_init();
        registry_tests::mint_record(&mut scenario);
        test_scenario::next_tx(&mut scenario, SECOND_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::set_data(
                &mut suins,
                FIRST_SUB_NODE,
                CONTENTHASH,
                FIRST_CONTENT_HASH,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registry::EDomainNameNotExists)]
    fun test_set_contenthash_abort_if_node_not_exists() {
        let scenario = test_init();
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::set_data(
                &mut suins,
                FIRST_SUB_NODE,
                CONTENTHASH,
                FIRST_CONTENT_HASH,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registry::EDomainNameNotExists)]
    fun test_get_contenthash_aborts_if_node_not_exists() {
        let scenario = test_init();
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::get_name_record_data(&suins, FIRST_SUB_NODE, CONTENTHASH);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registry::EDomainNameNotExists)]
    fun test_get_contenthash_returns_empty_with_wrong_node() {
        let scenario = test_init();
        registry_tests::mint_record(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::set_data(
                &mut suins,
                FIRST_SUB_NODE,
                CONTENTHASH,
                FIRST_CONTENTHASH,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let content_hash = registry::get_name_record_data(&suins, SECOND_SUB_NODE, CONTENTHASH);
            assert!(content_hash == utf8(b""), 0);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registry::EDomainNameNotExists)]
    fun test_set_avatar_abort_if_node_not_exists() {
        let scenario = test_init();
        test_scenario::next_tx(&mut scenario, SECOND_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::set_data(
                &mut suins,
                FIRST_SUB_NODE,
                AVATAR,
                FIRST_AVATAR,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registry::EKeyNotExists)]
    fun test_set_then_unset_contenthash() {
        let scenario = test_init();
        registry_tests::mint_record(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::set_data(
                &mut suins,
                FIRST_SUB_NODE,
                CONTENTHASH,
                FIRST_CONTENTHASH,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::unset_data(
                &mut suins,
                FIRST_SUB_NODE,
                CONTENTHASH,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let contenthash = registry::get_name_record_data(&suins, FIRST_SUB_NODE, CONTENTHASH);
            assert!(contenthash == utf8(b""), 0);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registry::EDomainNameNotExists)]
    fun test_unset_contenthash_abort_if_node_not_exists() {
        let scenario = test_init();
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::unset_data(
                &mut suins,
                FIRST_SUB_NODE,
                CONTENTHASH,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registry::EUnauthorized)]
    fun test_unset_contenthash_abort_if_unauthorized() {
        let scenario = test_init();
        registry_tests::mint_record(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::set_data(
                &mut suins,
                FIRST_SUB_NODE,
                CONTENTHASH,
                FIRST_CONTENTHASH,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, SECOND_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::unset_data(
                &mut suins,
                FIRST_SUB_NODE,
                CONTENTHASH,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
        };

        test_scenario::end(scenario);
    }

    #[test]
    fun test_all_data() {
        let scenario = test_init();
        set_default_name(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::set_linked_addr(
                &mut suins,
                FIRST_REVERSE_DOMAIN,
                SECOND_USER_ADDRESS,
                test_scenario::ctx(&mut scenario),
            );
            registry::set_default_domain_name(
                &mut suins,
                SECOND_NAME,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let (owner, addr, ttl, name) = registry::get_name_record_all_fields(&suins, FIRST_REVERSE_DOMAIN);
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(addr == SECOND_USER_ADDRESS, 0);
            assert!(ttl == 0, 0);
            assert!(name == utf8(SECOND_NAME), 0);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registry::EDomainNameNotExists)]
    fun test_get_all_data_aborts_if_node_not_exists() {
        let scenario = test_init();
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::get_name_record_all_fields(&suins, FIRST_SUB_NODE);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_get_full_data_returns_empty_for_non_existed_field() {
        let scenario = test_init();
        registry_tests::mint_record(&mut scenario);
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let (owner, addr, ttl, name) = registry::get_name_record_all_fields(&suins, FIRST_SUB_NODE);
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(addr == @0x0, 0);
            assert!(ttl == 10, 0);
            assert!(name == utf8(b""), 0);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registry::EKeyNotExists)]
    fun test_get_contenthash_returns_empty_if_not_being_set() {
        let scenario = test_init();
        registry_tests::mint_record(&mut scenario);
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let hash = registry::get_name_record_data(&suins, FIRST_SUB_NODE, CONTENTHASH);
            assert!(hash == utf8(b""), 0);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_get_addr_returns_empty_if_not_being_set() {
        let scenario = test_init();
        registry_tests::mint_record(&mut scenario);
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let addr = registry::linked_addr(&suins, FIRST_SUB_NODE);
            assert!(addr == @0x0, 0);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }
}
