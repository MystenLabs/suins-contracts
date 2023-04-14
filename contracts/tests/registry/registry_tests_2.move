#[test_only]
module suins::registry_tests_2 {

    use sui::test_scenario::{Self, Scenario};
    use suins::registry;
    use suins::registry_tests;
    use suins::entity::{Self, SuiNS};
    use std::string::utf8;

    const SUINS_ADDRESS: address = @0xA001;
    const FIRST_USER_ADDRESS: address = @0xB001;
    const FIRST_REVERSE_DOMAIN: vector<u8> = b"000000000000000000000000000000000000000000000000000000000000b001.addr.reverse";
    const SECOND_USER_ADDRESS: address = @0xB002;
    const ADDR_REVERSE_TLD: vector<u8> = b"addr.reverse";
    const FIRST_DOMAIN_NAME: vector<u8> = b"eastagile.sui";
    const SECOND_DOMAIN_NAME: vector<u8> = b"suins.sui";
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
            registry::new_record_test(
                &mut suins,
                utf8(FIRST_REVERSE_DOMAIN),
                FIRST_USER_ADDRESS,
                test_scenario::ctx(scenario)
            );
            registry::set_default_domain_name(&mut suins, utf8(FIRST_DOMAIN_NAME), test_scenario::ctx(scenario));
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            registry::set_record_internal(
                &mut suins,
                utf8(FIRST_DOMAIN_NAME),
                FIRST_USER_ADDRESS,
                10,
                test_scenario::ctx(scenario),
            );
            registry::set_linked_addr(&mut suins, utf8(FIRST_DOMAIN_NAME), FIRST_USER_ADDRESS, test_scenario::ctx(scenario));
            test_scenario::return_shared(suins);
        };
    }

    #[test, expected_failure(abort_code = registry::EDomainNameNotExists)]
    fun test_get_default_name_aborts_if_reverse_domain_name_not_exists() {
        let scenario = test_init();
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::default_domain_name(&suins, FIRST_USER_ADDRESS);
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
            let name= registry::default_domain_name_test(&suins, FIRST_USER_ADDRESS);
            assert!(name == utf8(FIRST_DOMAIN_NAME), 0);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_set_default_domain_name_to_differnt_owned_one() {
        let scenario = test_init();
        set_default_name(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let name = registry::default_domain_name_test(&suins, FIRST_USER_ADDRESS);
            assert!(name == utf8(FIRST_DOMAIN_NAME), 0);

            let name = registry::default_domain_name(&suins, FIRST_USER_ADDRESS);
            assert!(name == utf8(FIRST_DOMAIN_NAME), 0);
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::set_default_domain_name(&mut suins, utf8(SECOND_DOMAIN_NAME), test_scenario::ctx(&mut scenario));
            registry::set_record_internal(
                &mut suins,
                utf8(SECOND_DOMAIN_NAME),
                FIRST_USER_ADDRESS,
                10,
                test_scenario::ctx(&mut scenario),
            );
            registry::set_linked_addr(&mut suins, utf8(SECOND_DOMAIN_NAME), FIRST_USER_ADDRESS, test_scenario::ctx(&mut scenario));
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let name = registry::default_domain_name_test(&suins, FIRST_USER_ADDRESS);
            assert!(name == utf8(SECOND_DOMAIN_NAME), 0);

            let name = registry::default_domain_name(&suins, FIRST_USER_ADDRESS);
            assert!(name == utf8(SECOND_DOMAIN_NAME), 0);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_get_default_domain_name_works() {
        let scenario = test_init();
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::new_record_test(
                &mut suins,
                utf8(FIRST_REVERSE_DOMAIN),
                FIRST_USER_ADDRESS,
                test_scenario::ctx(&mut scenario)
            );
            registry::set_default_domain_name(&mut suins, utf8(FIRST_DOMAIN_NAME), test_scenario::ctx(&mut scenario));
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::set_record_internal(
                &mut suins,
                utf8(FIRST_DOMAIN_NAME),
                FIRST_USER_ADDRESS,
                10,
                test_scenario::ctx(&mut scenario),
            );
            registry::set_linked_addr(&mut suins, utf8(FIRST_DOMAIN_NAME), SECOND_USER_ADDRESS, test_scenario::ctx(&mut scenario));
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let name = registry::default_domain_name_test(&suins, FIRST_USER_ADDRESS);
            assert!(name == utf8(FIRST_DOMAIN_NAME), 0);
            registry::default_domain_name(&suins, FIRST_USER_ADDRESS);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registry::EDefaultDomainNameNotMatch)]
    fun test_get_default_domain_name_aborts_if_set_to_non_owned_one() {
        let scenario = test_init();
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::new_record_test(
                &mut suins,
                utf8(FIRST_REVERSE_DOMAIN),
                FIRST_USER_ADDRESS,
                test_scenario::ctx(&mut scenario)
            );
            registry::set_default_domain_name(&mut suins, utf8(FIRST_DOMAIN_NAME), test_scenario::ctx(&mut scenario));
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::set_record_internal(
                &mut suins,
                utf8(FIRST_DOMAIN_NAME),
                SECOND_USER_ADDRESS,
                10,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::default_domain_name_test(&suins, FIRST_USER_ADDRESS);
            registry::default_domain_name(&suins, FIRST_USER_ADDRESS);
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
            let name = registry::default_domain_name_test(&suins, FIRST_USER_ADDRESS);
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
            let name = registry::default_domain_name_test(&suins, FIRST_USER_ADDRESS);
            assert!(name == utf8(b""), 0);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registry::EDomainNameNotExists)]
    fun test_get_default_name_aborts_if_unset() {
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
            registry::default_domain_name(&suins, FIRST_USER_ADDRESS);
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
                utf8(SECOND_DOMAIN_NAME),
                test_scenario::ctx(&mut scenario)
            );
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            let name = registry::default_domain_name_test(&suins, FIRST_USER_ADDRESS);
            assert!(name == utf8(SECOND_DOMAIN_NAME), 0);

            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registry::EDomainNameNotExists)]
    fun test_get_name_aborts_if_not_own_the_name() {
        let scenario = test_init();
        set_default_name(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::set_default_domain_name(
                &mut suins,
                utf8(SECOND_DOMAIN_NAME),
                test_scenario::ctx(&mut scenario)
            );
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::default_domain_name(&suins, FIRST_USER_ADDRESS);
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
            registry::set_default_domain_name(&mut suins, utf8(FIRST_DOMAIN_NAME), test_scenario::ctx(&mut scenario));
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registry::EDomainNameNotExists)]
    fun test_get_addr_returns_empty_if_domain_name_not_exists() {
        let scenario = test_init();
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let addr = registry::linked_addr(&suins, utf8(FIRST_DOMAIN_NAME));
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
                utf8(FIRST_DOMAIN_NAME),
                FIRST_USER_ADDRESS,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let addr = registry::linked_addr(&suins, utf8(FIRST_DOMAIN_NAME));
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
                utf8(FIRST_DOMAIN_NAME),
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
                utf8(FIRST_DOMAIN_NAME),
                SECOND_USER_ADDRESS,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let addr = registry::linked_addr(&suins, utf8(FIRST_DOMAIN_NAME));
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
                utf8(FIRST_DOMAIN_NAME),
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
                utf8(FIRST_DOMAIN_NAME),
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
                utf8(FIRST_DOMAIN_NAME),
                    utf8(AVATAR),
                        utf8(FIRST_AVATAR),
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
                utf8(FIRST_DOMAIN_NAME),
                    utf8(AVATAR),
                        utf8(FIRST_AVATAR),
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let avatar = registry::get_name_record_data(&suins, utf8(FIRST_DOMAIN_NAME), utf8(AVATAR));
            assert!(avatar == utf8(FIRST_AVATAR), 0);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registry::EKeyNotExists)]
    fun test_set_data_returns_empty_with_wrong_domain_name() {
        let scenario = test_init();
        registry_tests::mint_record(&mut scenario);
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::set_record_internal(
                &mut suins,
                utf8(SECOND_DOMAIN_NAME),
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
                utf8(FIRST_DOMAIN_NAME),
                    utf8(AVATAR),
                        utf8(FIRST_AVATAR),
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let avatar = registry::get_name_record_data(&suins, utf8(SECOND_DOMAIN_NAME), utf8(AVATAR));
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
                utf8(FIRST_DOMAIN_NAME),
                    utf8(CONTENTHASH),
                        utf8(FIRST_CONTENT_HASH),
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let hash = registry::get_name_record_data(&suins, utf8(FIRST_DOMAIN_NAME), utf8(CONTENTHASH));
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
                utf8(FIRST_DOMAIN_NAME),
                    utf8(CONTENTHASH),
                        utf8(FIRST_CONTENT_HASH),
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registry::EDomainNameNotExists)]
    fun test_set_contenthash_abort_if_domain_name_not_exists() {
        let scenario = test_init();
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::set_data(
                &mut suins,
                utf8(FIRST_DOMAIN_NAME),
                    utf8(CONTENTHASH),
                        utf8(FIRST_CONTENT_HASH),
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registry::EDomainNameNotExists)]
    fun test_get_contenthash_aborts_if_domain_name_not_exists() {
        let scenario = test_init();
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::get_name_record_data(&suins, utf8(FIRST_DOMAIN_NAME), utf8(CONTENTHASH));
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registry::EDomainNameNotExists)]
    fun test_get_contenthash_returns_empty_with_wrong_domain_name() {
        let scenario = test_init();
        registry_tests::mint_record(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::set_data(
                &mut suins,
                utf8(FIRST_DOMAIN_NAME),
                    utf8(CONTENTHASH),
                        utf8(FIRST_CONTENTHASH),
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let content_hash = registry::get_name_record_data(&suins, utf8(SECOND_DOMAIN_NAME), utf8(CONTENTHASH));
            assert!(content_hash == utf8(b""), 0);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registry::EDomainNameNotExists)]
    fun test_set_avatar_abort_if_domain_name_not_exists() {
        let scenario = test_init();
        test_scenario::next_tx(&mut scenario, SECOND_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::set_data(
                &mut suins,
                utf8(FIRST_DOMAIN_NAME),
                    utf8(AVATAR),
                        utf8(FIRST_AVATAR),
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
                utf8(FIRST_DOMAIN_NAME),
                    utf8(CONTENTHASH),
                        utf8(FIRST_CONTENTHASH),
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::unset_data(
                &mut suins,
                utf8(FIRST_DOMAIN_NAME),
                utf8(CONTENTHASH),
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let contenthash = registry::get_name_record_data(&suins, utf8(FIRST_DOMAIN_NAME), utf8(CONTENTHASH));
            assert!(contenthash == utf8(b""), 0);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registry::EDomainNameNotExists)]
    fun test_unset_contenthash_abort_if_domain_name_not_exists() {
        let scenario = test_init();
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::unset_data(
                &mut suins,
                utf8(FIRST_DOMAIN_NAME),
                    utf8(CONTENTHASH),
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
                utf8(FIRST_DOMAIN_NAME),
                    utf8(CONTENTHASH),
                        utf8(FIRST_CONTENTHASH),
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, SECOND_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::unset_data(
                &mut suins,
                utf8(FIRST_DOMAIN_NAME),
            utf8(CONTENTHASH),
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
                utf8(FIRST_REVERSE_DOMAIN),
                SECOND_USER_ADDRESS,
                test_scenario::ctx(&mut scenario),
            );
            registry::set_default_domain_name(
                &mut suins,
                utf8(SECOND_DOMAIN_NAME),
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let (owner, linked_addr, ttl, name) = registry::get_name_record_all_fields(&suins, utf8(FIRST_REVERSE_DOMAIN));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(linked_addr == SECOND_USER_ADDRESS, 0);
            assert!(ttl == 0, 0);
            assert!(name == utf8(SECOND_DOMAIN_NAME), 0);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registry::EDomainNameNotExists)]
    fun test_get_all_data_aborts_if_domain_name_not_exists() {
        let scenario = test_init();
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::get_name_record_all_fields(&suins, utf8(FIRST_DOMAIN_NAME));
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
            let (owner, linked_addr, ttl, name) = registry::get_name_record_all_fields(&suins, utf8(FIRST_DOMAIN_NAME));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(linked_addr == FIRST_USER_ADDRESS, 0);
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
            let hash = registry::get_name_record_data(&suins, utf8(FIRST_DOMAIN_NAME), utf8(CONTENTHASH));
            assert!(hash == utf8(b""), 0);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_linked_addr_default_to_be_the_same_as_owner() {
        let scenario = test_init();
        registry_tests::mint_record(&mut scenario);
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let addr = registry::linked_addr(&suins, utf8(FIRST_DOMAIN_NAME));
            assert!(addr == FIRST_USER_ADDRESS, 0);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }
}
