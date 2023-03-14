#[test_only]
module suins::resolver_tests {

    use sui::test_scenario::{Self, Scenario};
    use sui::vec_map;
    use sui::dynamic_field;
    use suins::registry;
    use suins::resolver::{Self, Resolver};
    use suins::registry_tests;
    use suins::entity::{Self, SuiNS};
    use suins::converter::address_to_string;
    use suins::converter;
    use std::string::utf8;

    const SUINS_ADDRESS: address = @0xA001;
    const FIRST_NAME: vector<u8> = b"sui";
    const SECOND_NAME: vector<u8> = b"move";
    const FIRST_USER_ADDRESS: address = @0xB001;
    const SECOND_USER_ADDRESS: address = @0xB002;
    const ADDR_REVERSE_BASE_NODE: vector<u8> = b"addr.reverse";
    const FIRST_SUB_NODE: vector<u8> = b"eastagile.sui";
    const SECOND_SUB_NODE: vector<u8> = b"suins.sui";
    const FIRST_AVATAR: vector<u8> = b"QmfWrgbTZqwzqsvdeNc3NKacggMuTaN83sQ8V7Bs2nXKRD";
    const FIRST_CONTENTHASH: vector<u8> = b"QmfWrgbTZqwzqsvdeNc3NKacggMuTaN83sQ8V7Bs2nXKRD";
    const ADDR: vector<u8> = b"addr";
    const CUSTOM_KEY: vector<u8> = b"custom_key";
    const FIRST_CONTENT_HASH: vector<u8> = b"mtwirsqawjuoloq2gvtyug2tc3jbf5htm2zeo4rsknfiv3fdp46a";

    fun test_init(): Scenario {
        let scenario = test_scenario::begin(SUINS_ADDRESS);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            registry::test_init(ctx);
            entity::test_init(ctx);
            resolver::test_init(ctx);
        };
        scenario
    }

    fun set_name(scenario: &mut Scenario) {
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let node = registry::make_node(
                converter::address_to_string(FIRST_USER_ADDRESS),
                utf8(ADDR_REVERSE_BASE_NODE),
            );
            registry::new_record_test(&mut suins, node, FIRST_USER_ADDRESS);
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let resolver = test_scenario::take_shared<Resolver>( scenario);
            resolver::set_name(&mut resolver, &suins, FIRST_USER_ADDRESS, FIRST_NAME, test_scenario::ctx(scenario));
            test_scenario::return_shared(suins);
            test_scenario::return_shared(resolver);
        };
    }

    #[test]
    fun test_get_name_returns_empty_if_addr_not_exists() {
        let scenario = test_init();

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            let name = resolver::name(&resolver, FIRST_USER_ADDRESS);
            assert!(name == utf8(b""), 0);
            test_scenario::return_shared(resolver);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_set_name() {
        let scenario = test_init();
        set_name(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            let name= resolver::name(&resolver, FIRST_USER_ADDRESS);
            assert!(name == utf8(FIRST_NAME), 0);
            test_scenario::return_shared(resolver);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_name_aborts_if_already_being_removed() {
        let scenario = test_init();
        set_name(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            resolver::unset_name(&mut resolver, &suins, FIRST_USER_ADDRESS, test_scenario::ctx(&mut scenario));
            test_scenario::return_shared(resolver);
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            let name = resolver::name(&resolver, FIRST_USER_ADDRESS);
            assert!(name == utf8(b""), 0);
            test_scenario::return_shared(resolver);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registry::EUnauthorized)]
    fun test_unset_name_abort_if_unauthorized() {
        let scenario = test_init();
        set_name(&mut scenario);

        test_scenario::next_tx(&mut scenario, SECOND_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            resolver::unset_name(&mut resolver, &suins, FIRST_USER_ADDRESS, test_scenario::ctx(&mut scenario));
            test_scenario::return_shared(resolver);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = vec_map::EKeyDoesNotExist)]
    fun test_unset_name_abort_if_name_not_exists() {
        let scenario = test_init();
        set_name(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);

            resolver::unset_name(&mut resolver, &suins, FIRST_USER_ADDRESS, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(resolver);
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);

            resolver::unset_name(&mut resolver, &suins, FIRST_USER_ADDRESS, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(resolver);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_set_name_override_value_if_exists() {
        let scenario = test_init();
        set_name(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            resolver::set_name(
                &mut resolver,
                &suins,
                FIRST_USER_ADDRESS,
                SECOND_NAME,
                test_scenario::ctx(&mut scenario)
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(resolver);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);

            let name = resolver::name(&resolver, FIRST_USER_ADDRESS);
            assert!(name == utf8(SECOND_NAME), 0);

            test_scenario::return_shared(resolver);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = dynamic_field::EFieldDoesNotExist)]
    fun test_set_name_abort_if_addr_not_exists_in_registry() {
        let scenario = test_init();

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);

            resolver::set_name(&mut resolver, &suins, FIRST_USER_ADDRESS, FIRST_NAME, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(suins);
            test_scenario::return_shared(resolver);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registry::EUnauthorized)]
    fun test_set_name_abort_if_unauthorized() {
        let scenario = test_init();

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let node = registry::make_node(
                converter::address_to_string(FIRST_USER_ADDRESS),
                utf8(ADDR_REVERSE_BASE_NODE),
            );
            registry::new_record_test(&mut suins, node, FIRST_USER_ADDRESS);
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, SECOND_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            resolver::set_name(&mut resolver, &suins, FIRST_USER_ADDRESS, FIRST_NAME, test_scenario::ctx(&mut scenario));
            test_scenario::return_shared(suins);
            test_scenario::return_shared(resolver);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_get_addr_returns_empty_if_node_not_exists() {
        let scenario = test_init();
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            let addr = resolver::addr(&resolver, FIRST_SUB_NODE);
            assert!(addr == utf8(b""), 0);
            test_scenario::return_shared(resolver);
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
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            resolver::set_addr(
                &mut resolver,
                &suins,
                FIRST_SUB_NODE,
                FIRST_USER_ADDRESS,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(resolver);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            let addr = resolver::addr(&resolver, FIRST_SUB_NODE);
            assert!(addr == utf8(address_to_string(FIRST_USER_ADDRESS)), 0);
            test_scenario::return_shared(resolver);
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
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            resolver::set_addr(
                &mut resolver,
                &suins,
                FIRST_SUB_NODE,
                FIRST_USER_ADDRESS,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(resolver);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            resolver::set_addr(
                &mut resolver,
                &suins,
                FIRST_SUB_NODE,
                SECOND_USER_ADDRESS,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(resolver);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            let addr = resolver::addr(&resolver, FIRST_SUB_NODE);
            assert!(addr == utf8(address_to_string(SECOND_USER_ADDRESS)), 0);
            test_scenario::return_shared(resolver);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registry::EUnauthorized)]
    fun test_set_avatar_abort_if_unauthorized() {
        let scenario = test_init();
        registry_tests::mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            resolver::set_avatar(
                &mut resolver,
                &suins,
                FIRST_SUB_NODE,
                FIRST_AVATAR,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(resolver);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registry::EUnauthorized)]
    fun test_resolved_address_not_allowed_to_set_new_addr() {
        let scenario = test_init();
        registry_tests::mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            resolver::set_addr(
                &mut resolver,
                &suins,
                FIRST_SUB_NODE,
                FIRST_USER_ADDRESS,
                test_scenario::ctx(&mut scenario)
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(resolver);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            resolver::set_addr(
                &mut resolver,
                &suins,
                FIRST_SUB_NODE,
                SECOND_USER_ADDRESS,
                test_scenario::ctx(&mut scenario)
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(resolver);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_set_avatar() {
        let scenario = test_init();
        registry_tests::mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            resolver::set_avatar(
                &mut resolver,
                &suins,
                FIRST_SUB_NODE,
                FIRST_AVATAR,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(resolver);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            let avatar = resolver::avatar(&resolver, FIRST_SUB_NODE);
            assert!(avatar == utf8(FIRST_AVATAR), 0);
            test_scenario::return_shared(resolver);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_set_avatar_returns_empty_with_wrong_node() {
        let scenario = test_init();
        registry_tests::mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            resolver::set_avatar(
                &mut resolver,
                &suins,
                FIRST_SUB_NODE,
                FIRST_AVATAR,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(resolver);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            let avatar = resolver::avatar(&resolver, SECOND_SUB_NODE);
            assert!(avatar == utf8(b""), 0);
            test_scenario::return_shared(resolver);
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
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            resolver::set_contenthash(
                &mut resolver,
                &suins,
                FIRST_SUB_NODE,
                FIRST_CONTENT_HASH,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(resolver);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            let hash = resolver::contenthash(&resolver, FIRST_SUB_NODE);
            assert!(hash == utf8(FIRST_CONTENT_HASH), 0);
            test_scenario::return_shared(resolver);
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
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            resolver::set_contenthash(
                &mut resolver,
                &suins,
                FIRST_SUB_NODE,
                FIRST_CONTENT_HASH,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(resolver);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = dynamic_field::EFieldDoesNotExist)]
    fun test_set_contenthash_abort_if_node_not_exists() {
        let scenario = test_init();

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            resolver::set_contenthash(
                &mut resolver,
                &suins,
                FIRST_SUB_NODE,
                FIRST_CONTENT_HASH,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(resolver);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_get_contenthash_returns_empty_if_node_not_exists() {
        let scenario = test_init();
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            let contenthash = resolver::contenthash(&resolver, FIRST_SUB_NODE);
            assert!(contenthash == utf8(b""), 0);
            test_scenario::return_shared(resolver);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_set_text_record_with_new_key() {
        let scenario = test_init();
        registry_tests::mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            resolver::set_text(
                &mut resolver,
                &suins,
                FIRST_SUB_NODE,
                b"newkey",
                FIRST_CONTENT_HASH,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(resolver);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            let text = resolver::text(&resolver, FIRST_SUB_NODE, b"newkey");
            assert!(text == utf8(FIRST_CONTENT_HASH), 0);
            test_scenario::return_shared(resolver);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_get_text_returns_empty_if_wrong_key() {
        let scenario = test_init();
        registry_tests::mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            resolver::set_text(
                &mut resolver,
                &suins,
                FIRST_SUB_NODE,
                CUSTOM_KEY,
                FIRST_AVATAR,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(resolver);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            let text = resolver::text(&resolver, FIRST_SUB_NODE, b"wrongkey");
            assert!(text == utf8(b""), 0);
            test_scenario::return_shared(resolver);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_get_contenthash_abort_with_wrong_node() {
        let scenario = test_init();
        registry_tests::mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            resolver::set_contenthash(
                &mut resolver,
                &suins,
                FIRST_SUB_NODE,
                FIRST_CONTENTHASH,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(resolver);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            let content_hash = resolver::contenthash(&resolver, SECOND_SUB_NODE);
            assert!(content_hash == utf8(b""), 0);
            test_scenario::return_shared(resolver);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = dynamic_field::EFieldDoesNotExist)]
    fun test_set_avatar_abort_if_node_not_exists() {
        let scenario = test_init();

        test_scenario::next_tx(&mut scenario, SECOND_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            resolver::set_avatar(
                &mut resolver,
                &suins,
                FIRST_SUB_NODE,
                FIRST_AVATAR,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(resolver);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_set_then_unset_contenthash() {
        let scenario = test_init();
        registry_tests::mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            resolver::set_contenthash(
                &mut resolver,
                &suins,
                FIRST_SUB_NODE,
                FIRST_CONTENTHASH,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(resolver);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            assert!(resolver::is_contenthash_existed(&resolver, FIRST_SUB_NODE), 0);
            test_scenario::return_shared(resolver);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            resolver::unset_contenthash(
                &mut resolver,
                &suins,
                FIRST_SUB_NODE,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(resolver);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            assert!(!resolver::is_contenthash_existed(&resolver, FIRST_SUB_NODE), 0);
            test_scenario::return_shared(resolver);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = dynamic_field::EFieldDoesNotExist)]
    fun test_unset_contenthash_abort_if_node_not_exists() {
        let scenario = test_init();

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            resolver::unset_contenthash(
                &mut resolver,
                &suins,
                FIRST_SUB_NODE,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(resolver);
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
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            resolver::set_contenthash(
                &mut resolver,
                &suins,
                FIRST_SUB_NODE,
                FIRST_CONTENTHASH,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(resolver);
        };

        test_scenario::next_tx(&mut scenario, SECOND_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            resolver::unset_contenthash(
                &mut resolver,
                &suins,
                FIRST_SUB_NODE,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(resolver);
        };

        test_scenario::end(scenario);
    }

    #[test]
    fun test_set_contenthash_if_node_exists_but_contenthash_field_not() {
        let scenario = test_init();
        registry_tests::mint_record(&mut scenario);

        // create `FIRST_SUB_NODE` record
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            resolver::set_addr(
                &mut resolver,
                &suins,
                FIRST_SUB_NODE,
                FIRST_USER_ADDRESS,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(resolver);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            resolver::set_contenthash(
                &mut resolver,
                &suins,
                FIRST_SUB_NODE,
                FIRST_CONTENT_HASH,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(resolver);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            let hash = resolver::contenthash(&resolver, FIRST_SUB_NODE);
            assert!(hash == utf8(FIRST_CONTENT_HASH), 0);
            test_scenario::return_shared(resolver);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_set_avatar_if_node_exists_but_text_field_does_not() {
        let scenario = test_init();
        registry_tests::mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            resolver::set_addr(
                &mut resolver,
                &suins,
                FIRST_SUB_NODE,
                FIRST_USER_ADDRESS,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(resolver);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            resolver::set_avatar(
                &mut resolver,
                &suins,
                FIRST_SUB_NODE,
                FIRST_AVATAR,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(resolver);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            let avatar = resolver::avatar(&resolver, FIRST_SUB_NODE);
            assert!(avatar == utf8(FIRST_AVATAR), 0);
            test_scenario::return_shared(resolver);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_set_addr_if_node_exists_but_addr_field_not() {
        let scenario = test_init();
        registry_tests::mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            resolver::set_avatar(
                &mut resolver,
                &suins,
                FIRST_SUB_NODE,
                FIRST_AVATAR,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(resolver);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            resolver::set_addr(
                &mut resolver,
                &suins,
                FIRST_SUB_NODE,
                FIRST_USER_ADDRESS,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(resolver);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            let addr = resolver::addr(&resolver, FIRST_SUB_NODE);
            assert!(addr == utf8(address_to_string(FIRST_USER_ADDRESS)), 0);
            test_scenario::return_shared(resolver);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_all_data() {
        let scenario = test_init();
        registry_tests::mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            resolver::set_addr(
                &mut resolver,
                &suins,
                FIRST_SUB_NODE,
                FIRST_USER_ADDRESS,
                test_scenario::ctx(&mut scenario),
            );
            resolver::set_avatar(
                &mut resolver,
                &suins,
                FIRST_SUB_NODE,
                FIRST_AVATAR,
                test_scenario::ctx(&mut scenario),
            );
            resolver::set_contenthash(
                &mut resolver,
                &suins,
                FIRST_SUB_NODE,
                FIRST_CONTENT_HASH,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(resolver);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            let (contenthash, addr, avatar, name) = resolver::all_data(&resolver, FIRST_SUB_NODE);
            assert!(avatar == utf8(FIRST_AVATAR), 0);
            assert!(name == utf8(b""), 0);
            assert!(addr == utf8(address_to_string(FIRST_USER_ADDRESS)), 0);
            assert!(contenthash == utf8(FIRST_CONTENT_HASH), 0);
            test_scenario::return_shared(resolver);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_get_all_data_returns_empty_if_node_not_exists() {
        let scenario = test_init();
        registry_tests::mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            let (contenthash, addr, avatar, name) = resolver::all_data(&resolver, FIRST_SUB_NODE);
            assert!(avatar == utf8(b""), 0);
            assert!(name == utf8(b""), 0);
            assert!(addr == utf8(b""), 0);
            assert!(contenthash == utf8(b""), 0);
            test_scenario::return_shared(resolver);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_get_full_data_returns_empty_for_non_existed_field() {
        let scenario = test_init();
        registry_tests::mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            resolver::set_avatar(
                &mut resolver,
                &suins,
                FIRST_SUB_NODE,
                FIRST_AVATAR,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(resolver);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            let (contenthash, addr, avatar, name) = resolver::all_data(&resolver, FIRST_SUB_NODE);
            assert!(avatar == utf8(FIRST_AVATAR), 0);
            assert!(addr == utf8(b""), 0);
            assert!(contenthash == utf8(b""), 0);
            assert!(name == utf8(b""), 0);
            test_scenario::return_shared(resolver);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_get_full_data_returns_empty_for_non_existed_field2() {
        let scenario = test_init();
        registry_tests::mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            resolver::set_addr(
                &mut resolver,
                &suins,
                FIRST_SUB_NODE,
                FIRST_USER_ADDRESS,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(resolver);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            let (contenthash, addr, avatar, name) = resolver::all_data(&resolver, FIRST_SUB_NODE);
            assert!(avatar == utf8(b""), 0);
            assert!(name == utf8(b""), 0);
            assert!(addr == utf8(address_to_string(FIRST_USER_ADDRESS)), 0);
            assert!(contenthash == utf8(b""), 0);
            test_scenario::return_shared(resolver);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_get_full_data_returns_empty_for_non_existed_fiel3() {
        let scenario = test_init();
        registry_tests::mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            resolver::set_contenthash(
                &mut resolver,
                &suins,
                FIRST_SUB_NODE,
                FIRST_CONTENTHASH,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(resolver);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            let (contenthash, addr, avatar, name) = resolver::all_data(&resolver, FIRST_SUB_NODE);
            assert!(addr == utf8(b""), 0);
            assert!(avatar == utf8(b""), 0);
            assert!(name == utf8(b""), 0);
            assert!(contenthash == utf8(FIRST_CONTENTHASH), 0);
            test_scenario::return_shared(resolver);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_get_contenthash_returns_empty_if_not_being_set() {
        let scenario = test_init();
        registry_tests::mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            resolver::set_addr(
                &mut resolver,
                &suins,
                FIRST_SUB_NODE,
                FIRST_USER_ADDRESS,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(resolver);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            let hash = resolver::contenthash(&resolver, FIRST_SUB_NODE);
            assert!(hash == utf8(b""), 0);
            test_scenario::return_shared(resolver);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_get_addr_returns_empty_if_not_being_set() {
        let scenario = test_init();
        registry_tests::mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            resolver::set_contenthash(
                &mut resolver,
                &suins,
                FIRST_SUB_NODE,
                FIRST_CONTENTHASH,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(resolver);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            let hash = resolver::addr(&resolver, FIRST_SUB_NODE);
            assert!(hash == utf8(b""), 0);
            test_scenario::return_shared(resolver);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_get_text_returns_empty_if_not_being_set() {
        let scenario = test_init();
        registry_tests::mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            resolver::set_contenthash(
                &mut resolver,
                &suins,
                FIRST_SUB_NODE,
                FIRST_CONTENTHASH,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(resolver);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            let avatar = resolver::text(&resolver, FIRST_SUB_NODE, CUSTOM_KEY);
            assert!(avatar == utf8(b""), 0);
            test_scenario::return_shared(resolver);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_get_text_returns_empty_if_record_not_exists() {
        let scenario = test_init();
        registry_tests::mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            let avatar = resolver::text(&resolver, FIRST_SUB_NODE, CUSTOM_KEY);
            assert!(avatar == utf8(b""), 0);
            test_scenario::return_shared(resolver);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_get_addr_returns_empty_if_record_not_exists() {
        let scenario = test_init();
        registry_tests::mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            let hash = resolver::addr(&resolver, FIRST_SUB_NODE);
            assert!(hash == utf8(b""), 0);
            test_scenario::return_shared(resolver);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_get_contenthash_returns_empty_if_record_not_exissts() {
        let scenario = test_init();
        registry_tests::mint_record(&mut scenario);
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let resolver = test_scenario::take_shared<Resolver>(&mut scenario);
            let hash = resolver::contenthash(&resolver, FIRST_SUB_NODE);
            assert!(hash == utf8(b""), 0);
            test_scenario::return_shared(resolver);
        };
        test_scenario::end(scenario);
    }
}
