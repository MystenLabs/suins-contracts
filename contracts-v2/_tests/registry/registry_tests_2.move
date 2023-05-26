#[test_only]
module suins::registry_tests_2 {

    use std::string::utf8;
    use sui::test_scenario::{Self, Scenario};


    use suins::registry_tests;
    use suins::suins::{Self, SuiNS};
    use suins::name_record;

    const SUINS_ADDRESS: address = @0xA001;
    const FIRST_USER_ADDRESS: address = @0xB001;
    const SECOND_USER_ADDRESS: address = @0xB002;
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
            suins::test_setup::setup(ctx);
        };
        scenario
    }

    fun set_default_name(scenario: &mut Scenario) {
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            suins::add_record_for_testing(
                &mut suins,
                utf8(FIRST_DOMAIN_NAME),
                FIRST_USER_ADDRESS,
            );
            suins::set_target_address(&mut suins, utf8(FIRST_DOMAIN_NAME), FIRST_USER_ADDRESS, test_scenario::ctx(scenario));
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            suins::set_default_domain_name(&mut suins, utf8(FIRST_DOMAIN_NAME), test_scenario::ctx(scenario));
            test_scenario::return_shared(suins);
        };
    }

    #[test, expected_failure(abort_code = sui::dynamic_field::EFieldDoesNotExist)]
    fun test_get_default_name_aborts_if_reverse_domain_name_not_exists() {
        let scenario = test_init();
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            suins::default_domain_name(&suins, FIRST_USER_ADDRESS);
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
            let name = suins::default_domain_name(&suins, FIRST_USER_ADDRESS);
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

            let name = suins::default_domain_name(&suins, FIRST_USER_ADDRESS);
            assert!(name == utf8(FIRST_DOMAIN_NAME), 0);

            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            suins::add_record_for_testing(
                &mut suins,
                utf8(SECOND_DOMAIN_NAME),
                FIRST_USER_ADDRESS,
            );
            suins::set_target_address(&mut suins, utf8(SECOND_DOMAIN_NAME), FIRST_USER_ADDRESS, test_scenario::ctx(&mut scenario));
            suins::set_default_domain_name(&mut suins, utf8(SECOND_DOMAIN_NAME), test_scenario::ctx(&mut scenario));
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            let name = suins::default_domain_name(&suins, FIRST_USER_ADDRESS);
            assert!(name == utf8(SECOND_DOMAIN_NAME), 0);

            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_default_name_is_cleared_when_target_address_changes() {
        let scenario = test_init();
        set_default_name(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let name = suins::default_domain_name(&suins, FIRST_USER_ADDRESS);
            assert!(name == utf8(FIRST_DOMAIN_NAME), 0);
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            suins::set_target_address(&mut suins, utf8(FIRST_DOMAIN_NAME), SECOND_USER_ADDRESS, test_scenario::ctx(&mut scenario));

            let reverse_registry = suins::reverse_registry(&suins);
            assert!(!sui::table::contains(reverse_registry, FIRST_USER_ADDRESS), 0);

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
            suins::add_record_for_testing(
                &mut suins,
                utf8(FIRST_DOMAIN_NAME),
                FIRST_USER_ADDRESS,
            );
            suins::set_target_address(&mut suins, utf8(FIRST_DOMAIN_NAME), FIRST_USER_ADDRESS, test_scenario::ctx(&mut scenario));
            suins::set_default_domain_name(&mut suins, utf8(FIRST_DOMAIN_NAME), test_scenario::ctx(&mut scenario));
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let name = suins::default_domain_name(&suins, FIRST_USER_ADDRESS);
            assert!(name == utf8(FIRST_DOMAIN_NAME), 0);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = suins::suins::EDefaultDomainNameNotMatch)]
    fun test_set_default_domain_name_aborts_if_non_target_addressess_is_used() {
        let scenario = test_init();
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            suins::add_record_for_testing(
                &mut suins,
                utf8(FIRST_DOMAIN_NAME),
                FIRST_USER_ADDRESS,
            );
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, SECOND_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            suins::set_default_domain_name(&mut suins, utf8(FIRST_DOMAIN_NAME), test_scenario::ctx(&mut scenario));
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = sui::dynamic_field::EFieldDoesNotExist)]
    fun test_get_default_name_aborts_if_unset() {
        let scenario = test_init();
        set_default_name(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            suins::unset_default_domain_name(&mut suins, test_scenario::ctx(&mut scenario));
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            suins::default_domain_name(&suins, FIRST_USER_ADDRESS);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = sui::dynamic_field::EFieldDoesNotExist)]
    fun test_unset_name_abort_if_domain_name_not_exists() {
        let scenario = test_init();
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            suins::unset_default_domain_name(&mut suins, test_scenario::ctx(&mut scenario));
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = sui::dynamic_field::EFieldDoesNotExist)]
    fun test_get_name_aborts_if_not_own_the_name() {
        let scenario = test_init();
        set_default_name(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            suins::set_default_domain_name(
                &mut suins,
                utf8(SECOND_DOMAIN_NAME),
                test_scenario::ctx(&mut scenario)
            );
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            suins::default_domain_name(&suins, FIRST_USER_ADDRESS);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = sui::dynamic_field::EFieldDoesNotExist)]
    fun test_set_name_abort_if_record_not_exists_in_registry() {
        let scenario = test_init();
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            suins::set_default_domain_name(&mut suins, utf8(FIRST_DOMAIN_NAME), test_scenario::ctx(&mut scenario));
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = sui::dynamic_field::EFieldDoesNotExist)]
    fun test_get_addr_returns_empty_if_domain_name_not_exists() {
        let scenario = test_init();
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let addr = suins::target_address(&suins, utf8(FIRST_DOMAIN_NAME));
            assert!(addr == std::option::none(), 0);
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
            suins::set_target_address(
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
            let addr = suins::target_address(&suins, utf8(FIRST_DOMAIN_NAME));
            assert!(addr == std::option::some(FIRST_USER_ADDRESS), 0);
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
            suins::set_target_address(
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
            suins::set_target_address(
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
            let addr = suins::target_address(&suins, utf8(FIRST_DOMAIN_NAME));
            assert!(addr == std::option::some(SECOND_USER_ADDRESS), 0);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = suins::suins::ENotRecordOwner)]
    fun test_set_address_aborts_if_unauthorized() {
        let scenario = test_init();
        registry_tests::mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            suins::set_target_address(
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
            suins::set_target_address(
                &mut suins,
                utf8(FIRST_DOMAIN_NAME),
                SECOND_USER_ADDRESS,
                test_scenario::ctx(&mut scenario)
            );
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    // #[test, expected_failure(abort_code = suins::suins::ENotRecordOwner)]
    // fun test_set_data_abort_if_unauthorized() {
    //     let scenario = test_init();
    //     registry_tests::mint_record(&mut scenario);

    //     test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
    //     {
    //         let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
    //         registry::set_data(
    //             &mut suins,
    //             utf8(FIRST_DOMAIN_NAME),
    //                 utf8(AVATAR),
    //                     utf8(FIRST_AVATAR),
    //             test_scenario::ctx(&mut scenario),
    //         );
    //         test_scenario::return_shared(suins);
    //     };
    //     test_scenario::end(scenario);
    // }

    // #[test]
    // fun test_set_data() {
    //     let scenario = test_init();
    //     registry_tests::mint_record(&mut scenario);

    //     test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
    //     {
    //         let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
    //         registry::set_data(
    //             &mut suins,
    //             utf8(FIRST_DOMAIN_NAME),
    //                 utf8(AVATAR),
    //                     utf8(FIRST_AVATAR),
    //             test_scenario::ctx(&mut scenario),
    //         );
    //         test_scenario::return_shared(suins);
    //     };

    //     test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
    //     {
    //         let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
    //         let avatar = user_data::get(&suins, utf8(FIRST_DOMAIN_NAME), utf8(AVATAR));
    //         assert!(avatar == utf8(FIRST_AVATAR), 0);
    //         test_scenario::return_shared(suins);
    //     };
    //     test_scenario::end(scenario);
    // }

    // #[test, expected_failure(abort_code = registry::EKeyNotExists)]
    // fun test_set_data_returns_empty_with_wrong_domain_name() {
    //     let scenario = test_init();
    //     registry_tests::mint_record(&mut scenario);
    //     test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
    //     {
    //         let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
    //         suins::add_record_for_testing(
    //             &mut suins,
    //             utf8(SECOND_DOMAIN_NAME),
    //             FIRST_USER_ADDRESS,
    //         );
    //         test_scenario::return_shared(suins);
    //     };
    //     test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
    //     {
    //         let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
    //         registry::set_data(
    //             &mut suins,
    //             utf8(FIRST_DOMAIN_NAME),
    //                 utf8(AVATAR),
    //                     utf8(FIRST_AVATAR),
    //             test_scenario::ctx(&mut scenario),
    //         );
    //         test_scenario::return_shared(suins);
    //     };
    //     test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
    //     {
    //         let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
    //         let avatar = user_data::get(&suins, utf8(SECOND_DOMAIN_NAME), utf8(AVATAR));
    //         assert!(avatar == utf8(b""), 0);
    //         test_scenario::return_shared(suins);
    //     };
    //     test_scenario::end(scenario);
    // }

    // #[test]
    // fun test_set_contenthash() {
    //     let scenario = test_init();
    //     registry_tests::mint_record(&mut scenario);
    //     test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
    //     {
    //         let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
    //         registry::set_data(
    //             &mut suins,
    //             utf8(FIRST_DOMAIN_NAME),
    //                 utf8(CONTENTHASH),
    //                     utf8(FIRST_CONTENT_HASH),
    //             test_scenario::ctx(&mut scenario),
    //         );
    //         test_scenario::return_shared(suins);
    //     };

    //     test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
    //     {
    //         let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
    //         let hash = user_data::get(&suins, utf8(FIRST_DOMAIN_NAME), utf8(CONTENTHASH));
    //         assert!(hash == utf8(FIRST_CONTENT_HASH), 0);
    //         test_scenario::return_shared(suins);
    //     };
    //     test_scenario::end(scenario);
    // }

    // #[test, expected_failure(abort_code = suins::suins::ENotRecordOwner)]
    // fun test_set_contenthash_abort_if_unauthorized() {
    //     let scenario = test_init();
    //     registry_tests::mint_record(&mut scenario);
    //     test_scenario::next_tx(&mut scenario, SECOND_USER_ADDRESS);
    //     {
    //         let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
    //         registry::set_data(
    //             &mut suins,
    //             utf8(FIRST_DOMAIN_NAME),
    //                 utf8(CONTENTHASH),
    //                     utf8(FIRST_CONTENT_HASH),
    //             test_scenario::ctx(&mut scenario),
    //         );
    //         test_scenario::return_shared(suins);
    //     };
    //     test_scenario::end(scenario);
    // }

    // #[test, expected_failure(abort_code = sui::dynamic_field::EFieldDoesNotExist)]
    // fun test_set_contenthash_abort_if_domain_name_not_exists() {
    //     let scenario = test_init();
    //     test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
    //     {
    //         let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
    //         registry::set_data(
    //             &mut suins,
    //             utf8(FIRST_DOMAIN_NAME),
    //                 utf8(CONTENTHASH),
    //                     utf8(FIRST_CONTENT_HASH),
    //             test_scenario::ctx(&mut scenario),
    //         );
    //         test_scenario::return_shared(suins);
    //     };
    //     test_scenario::end(scenario);
    // }

    // #[test, expected_failure(abort_code = sui::dynamic_field::EFieldDoesNotExist)]
    // fun test_get_contenthash_aborts_if_domain_name_not_exists() {
    //     let scenario = test_init();
    //     test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
    //     {
    //         let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
    //         user_data::get(&suins, utf8(FIRST_DOMAIN_NAME), utf8(CONTENTHASH));
    //         test_scenario::return_shared(suins);
    //     };
    //     test_scenario::end(scenario);
    // }

    // #[test, expected_failure(abort_code = sui::dynamic_field::EFieldDoesNotExist)]
    // fun test_get_contenthash_returns_empty_with_wrong_domain_name() {
    //     let scenario = test_init();
    //     registry_tests::mint_record(&mut scenario);
    //     test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
    //     {
    //         let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
    //         registry::set_data(
    //             &mut suins,
    //             utf8(FIRST_DOMAIN_NAME),
    //                 utf8(CONTENTHASH),
    //                     utf8(FIRST_CONTENTHASH),
    //             test_scenario::ctx(&mut scenario),
    //         );
    //         test_scenario::return_shared(suins);
    //     };
    //     test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
    //     {
    //         let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
    //         let content_hash = user_data::get(&suins, utf8(SECOND_DOMAIN_NAME), utf8(CONTENTHASH));
    //         assert!(content_hash == utf8(b""), 0);
    //         test_scenario::return_shared(suins);
    //     };
    //     test_scenario::end(scenario);
    // }

    // #[test, expected_failure(abort_code = sui::dynamic_field::EFieldDoesNotExist)]
    // fun test_set_avatar_abort_if_domain_name_not_exists() {
    //     let scenario = test_init();
    //     test_scenario::next_tx(&mut scenario, SECOND_USER_ADDRESS);
    //     {
    //         let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
    //         registry::set_data(
    //             &mut suins,
    //             utf8(FIRST_DOMAIN_NAME),
    //                 utf8(AVATAR),
    //                     utf8(FIRST_AVATAR),
    //             test_scenario::ctx(&mut scenario),
    //         );
    //         test_scenario::return_shared(suins);
    //     };
    //     test_scenario::end(scenario);
    // }

    // #[test, expected_failure(abort_code = registry::EKeyNotExists)]
    // fun test_set_then_unset_contenthash() {
    //     let scenario = test_init();
    //     registry_tests::mint_record(&mut scenario);
    //     test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
    //     {
    //         let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
    //         registry::set_data(
    //             &mut suins,
    //             utf8(FIRST_DOMAIN_NAME),
    //                 utf8(CONTENTHASH),
    //                     utf8(FIRST_CONTENTHASH),
    //             test_scenario::ctx(&mut scenario),
    //         );
    //         test_scenario::return_shared(suins);
    //     };
    //     test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
    //     {
    //         let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
    //         registry::unset_data(
    //             &mut suins,
    //             utf8(FIRST_DOMAIN_NAME),
    //             utf8(CONTENTHASH),
    //             test_scenario::ctx(&mut scenario),
    //         );
    //         test_scenario::return_shared(suins);
    //     };

    //     test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
    //     {
    //         let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
    //         let contenthash = user_data::get(&suins, utf8(FIRST_DOMAIN_NAME), utf8(CONTENTHASH));
    //         assert!(contenthash == utf8(b""), 0);
    //         test_scenario::return_shared(suins);
    //     };
    //     test_scenario::end(scenario);
    // }

    // #[test, expected_failure(abort_code = sui::dynamic_field::EFieldDoesNotExist)]
    // fun test_unset_contenthash_abort_if_domain_name_not_exists() {
    //     let scenario = test_init();
    //     test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
    //     {
    //         let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
    //         registry::unset_data(
    //             &mut suins,
    //             utf8(FIRST_DOMAIN_NAME),
    //                 utf8(CONTENTHASH),
    //             test_scenario::ctx(&mut scenario),
    //         );
    //         test_scenario::return_shared(suins);
    //     };
    //     test_scenario::end(scenario);
    // }

    // #[test, expected_failure(abort_code = suins::suins::ENotRecordOwner)]
    // fun test_unset_contenthash_abort_if_unauthorized() {
    //     let scenario = test_init();
    //     registry_tests::mint_record(&mut scenario);
    //     test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
    //     {
    //         let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
    //         registry::set_data(
    //             &mut suins,
    //             utf8(FIRST_DOMAIN_NAME),
    //             utf8(CONTENTHASH),
    //             utf8(FIRST_CONTENTHASH),
    //             test_scenario::ctx(&mut scenario),
    //         );
    //         test_scenario::return_shared(suins);
    //     };

    //     test_scenario::next_tx(&mut scenario, SECOND_USER_ADDRESS);
    //     {
    //         let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
    //         registry::unset_data(
    //             &mut suins,
    //             utf8(FIRST_DOMAIN_NAME),
    //             utf8(CONTENTHASH),
    //             test_scenario::ctx(&mut scenario),
    //         );
    //         test_scenario::return_shared(suins);
    //     };

    //     test_scenario::end(scenario);
    // }

    #[test]
    fun test_all_data() {
        let scenario = test_init();
        set_default_name(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            suins::set_target_address(
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
            let record = suins::name_record(&suins, utf8(FIRST_DOMAIN_NAME));
            let (owner, target_address) = (suins::record_owner(&suins, utf8(FIRST_DOMAIN_NAME)), name_record::target_address(record));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(target_address == std::option::some(SECOND_USER_ADDRESS), 0);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = sui::dynamic_field::EFieldDoesNotExist)]
    fun test_get_all_data_aborts_if_domain_name_not_exists() {
        let scenario = test_init();
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let (_owner) = suins::record_owner(&suins, utf8(FIRST_DOMAIN_NAME));
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
            let record = suins::name_record(&suins, utf8(FIRST_DOMAIN_NAME));
            let (owner, target_address) = (suins::record_owner(&suins, utf8(FIRST_DOMAIN_NAME)), name_record::target_address(record));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(target_address == std::option::some(FIRST_USER_ADDRESS), 0);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    // #[test, expected_failure(abort_code = registry::EKeyNotExists)]
    // fun test_get_contenthash_returns_empty_if_not_being_set() {
    //     let scenario = test_init();
    //     registry_tests::mint_record(&mut scenario);
    //     test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
    //     {
    //         let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
    //         let data = user_data::get(&suins, utf8(FIRST_DOMAIN_NAME));
    //         let hash = vec_map::get(&data, utf8(CONTENTHASH));
    //         assert!(*hash == utf8(b""), 0);
    //         test_scenario::return_shared(suins);
    //     };
    //     test_scenario::end(scenario);
    // }

    #[test]
    fun test_target_address_default_to_be_the_same_as_owner() {
        let scenario = test_init();
        registry_tests::mint_record(&mut scenario);
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let addr = suins::target_address(&suins, utf8(FIRST_DOMAIN_NAME));
            assert!(addr == std::option::some(FIRST_USER_ADDRESS), 0);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_reverse_record_is_not_cleared_when_target_addr_of_different_domain_name_changes() {
        let scenario = test_init();
        set_default_name(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            suins::add_record_for_testing(
                &mut suins,
                utf8(SECOND_DOMAIN_NAME),
                FIRST_USER_ADDRESS,
            );
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let name = suins::default_domain_name(&suins, FIRST_USER_ADDRESS);
            assert!(name == utf8(FIRST_DOMAIN_NAME), 0);
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            suins::set_target_address(&mut suins, utf8(SECOND_DOMAIN_NAME), SECOND_USER_ADDRESS, test_scenario::ctx(&mut scenario));

            let reverse_registry = suins::reverse_registry(&suins);
            assert!(sui::table::contains(reverse_registry, FIRST_USER_ADDRESS), 0);
            let name = suins::default_domain_name(&suins, FIRST_USER_ADDRESS);
            assert!(name == utf8(FIRST_DOMAIN_NAME), 0);

            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_reverse_record_is_not_cleared_when_target_addr_of_different_domain_name_is_unset() {
        let scenario = test_init();
        set_default_name(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            suins::add_record_for_testing(
                &mut suins,
                utf8(SECOND_DOMAIN_NAME),
                FIRST_USER_ADDRESS,
            );
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let name = suins::default_domain_name(&suins, FIRST_USER_ADDRESS);
            assert!(name == utf8(FIRST_DOMAIN_NAME), 0);
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            suins::unset_target_address(&mut suins, utf8(SECOND_DOMAIN_NAME), test_scenario::ctx(&mut scenario));

            let reverse_registry = suins::reverse_registry(&suins);
            assert!(sui::table::contains(reverse_registry, FIRST_USER_ADDRESS), 0);
            let name = suins::default_domain_name(&suins, FIRST_USER_ADDRESS);
            assert!(name == utf8(FIRST_DOMAIN_NAME), 0);

            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_set_record_internal_clear_reverse_record() {
        let scenario = test_init();
        set_default_name(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            suins::add_record_for_testing(
                &mut suins,
                utf8(SECOND_DOMAIN_NAME),
                FIRST_USER_ADDRESS,
            );
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let name = suins::default_domain_name(&suins, FIRST_USER_ADDRESS);
            assert!(name == utf8(FIRST_DOMAIN_NAME), 0);
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            suins::add_record_for_testing(
                &mut suins,
                utf8(FIRST_DOMAIN_NAME),
                SECOND_USER_ADDRESS,
            );

            let reverse_registry = suins::reverse_registry(&suins);
            assert!(!sui::table::contains(reverse_registry, FIRST_USER_ADDRESS), 0);

            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_set_record_internal_not_clear_reverse_record_when_set_target_addr_of_different_domain_name() {
        let scenario = test_init();
        set_default_name(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            suins::add_record_for_testing(
                &mut suins,
                utf8(SECOND_DOMAIN_NAME),
                FIRST_USER_ADDRESS,
            );
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let name = suins::default_domain_name(&suins, FIRST_USER_ADDRESS);
            assert!(name == utf8(FIRST_DOMAIN_NAME), 0);
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            suins::add_record_for_testing(
                &mut suins,
                utf8(SECOND_DOMAIN_NAME),
                SECOND_USER_ADDRESS,
            );

            let reverse_registry = suins::reverse_registry(&suins);
            assert!(sui::table::contains(reverse_registry, FIRST_USER_ADDRESS), 0);
            let name = suins::default_domain_name(&suins, FIRST_USER_ADDRESS);
            assert!(name == utf8(FIRST_DOMAIN_NAME), 0);

            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }
}