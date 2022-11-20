#[test_only]
module suins::resolver_tests {

    use sui::test_scenario::{Self, Scenario};
    use suins::base_registry::{Self, Registry};
    use suins::resolver::{Self, BaseResolver};
    use suins::converter;
    use suins::base_registrar;
    use suins::base_registry_tests;
    use std::string::utf8;

    const SUINS_ADDRESS: address = @0xA001;
    const FIRST_NAME: vector<u8> = b"sui";
    const SECOND_NAME: vector<u8> = b"move";
    const FIRST_USER_ADDRESS: address = @0xB001;
    const SECOND_USER_ADDRESS: address = @0xB002;
    const ADDR_REVERSE_BASE_NODE: vector<u8> = b"addr.reverse";
    const FIRST_SUB_NODE: vector<u8> = b"eastagile.sui";
    const SECOND_SUB_NODE: vector<u8> = b"suins.sui";
    const FIRST_AVATAR: vector<u8> = b"ipfs://QmfWrgbTZqwzqsvdeNc3NKacggMuTaN83sQ8V7Bs2nXKRD";
    const AVATAR: vector<u8> = b"avatar";
    const ADDR: vector<u8> = b"addr";
    const FIRST_CONTENT_HASH: vector<u8> = b"mtwirsqawjuoloq2gvtyug2tc3jbf5htm2zeo4rsknfiv3fdp46a";

    fun test_init(): Scenario {
        let scenario = test_scenario::begin(SUINS_ADDRESS);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            base_registry::test_init(ctx);
            base_registrar::test_init(ctx);
            resolver::test_init(ctx);
        };
        scenario
    }

    fun set_name(scenario: &mut Scenario) {
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(scenario);

            let node = base_registry::make_node(
                converter::address_to_string(FIRST_USER_ADDRESS),
                utf8(ADDR_REVERSE_BASE_NODE),
            );
            base_registry::new_record_test(&mut registry, node, FIRST_USER_ADDRESS);

            test_scenario::return_shared(registry);
        };

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(scenario);
            let resolver = test_scenario::take_shared<BaseResolver>( scenario);

            resolver::set_name(&mut resolver, &registry, FIRST_USER_ADDRESS, FIRST_NAME, test_scenario::ctx(scenario));

            test_scenario::return_shared(registry);
            test_scenario::return_shared(resolver);
        };
    }

    #[test]
    #[expected_failure(abort_code = 1)]
    fun test_get_name_abort_if_addr_not_exists() {
        let scenario = test_init();

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let resolver = test_scenario::take_shared<BaseResolver>(&mut scenario);
            resolver::name(&resolver, FIRST_USER_ADDRESS);
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
            let resolver = test_scenario::take_shared<BaseResolver>(&mut scenario);
            let name= resolver::name(&resolver, FIRST_USER_ADDRESS);
            assert!(name == utf8(FIRST_NAME), 0);
            test_scenario::return_shared(resolver);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1)]
    fun test_unset_name() {
        let scenario = test_init();
        set_name(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let resolver = test_scenario::take_shared<BaseResolver>(&mut scenario);
            resolver::unset_name(&mut resolver, &registry, FIRST_USER_ADDRESS, test_scenario::ctx(&mut scenario));
            test_scenario::return_shared(resolver);
            test_scenario::return_shared(registry);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let resolver = test_scenario::take_shared<BaseResolver>(&mut scenario);
            resolver::name(&resolver, FIRST_USER_ADDRESS);
            test_scenario::return_shared(resolver);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 101)]
    fun test_unset_name_abort_if_unauthorized() {
        let scenario = test_init();
        set_name(&mut scenario);

        test_scenario::next_tx(&mut scenario, SECOND_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let resolver = test_scenario::take_shared<BaseResolver>(&mut scenario);

            resolver::unset_name(&mut resolver, &registry, FIRST_USER_ADDRESS, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(resolver);
            test_scenario::return_shared(registry);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1)]
    fun test_unset_name_abort_if_name_not_exists() {
        let scenario = test_init();
        set_name(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let resolver = test_scenario::take_shared<BaseResolver>(&mut scenario);

            resolver::unset_name(&mut resolver, &registry, FIRST_USER_ADDRESS, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(resolver);
            test_scenario::return_shared(registry);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let resolver = test_scenario::take_shared<BaseResolver>(&mut scenario);

            resolver::unset_name(&mut resolver, &registry, FIRST_USER_ADDRESS, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(resolver);
            test_scenario::return_shared(registry);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_set_name_override_value_if_exists() {
        let scenario = test_init();
        set_name(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let resolver = test_scenario::take_shared<BaseResolver>(&mut scenario);
            resolver::set_name(
                &mut resolver,
                &registry,
                FIRST_USER_ADDRESS,
                SECOND_NAME,
                test_scenario::ctx(&mut scenario)
            );
            test_scenario::return_shared(registry);
            test_scenario::return_shared(resolver);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let resolver = test_scenario::take_shared<BaseResolver>(&mut scenario);

            let name = resolver::name(&resolver, FIRST_USER_ADDRESS);
            assert!(name == utf8(SECOND_NAME), 0);

            test_scenario::return_shared(resolver);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1)]
    fun test_set_name_abort_if_addr_not_exists_in_registry() {
        let scenario = test_init();

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let resolver = test_scenario::take_shared<BaseResolver>(&mut scenario);

            resolver::set_name(&mut resolver, &registry, FIRST_USER_ADDRESS, FIRST_NAME, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(registry);
            test_scenario::return_shared(resolver);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 101)]
    fun test_set_name_abort_if_unauthorized() {
        let scenario = test_init();

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);

            let node = base_registry::make_node(
                converter::address_to_string(FIRST_USER_ADDRESS),
                utf8(ADDR_REVERSE_BASE_NODE),
            );
            base_registry::new_record_test(&mut registry, node, FIRST_USER_ADDRESS);

            test_scenario::return_shared(registry);
        };

        test_scenario::next_tx(&mut scenario, SECOND_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let resolver = test_scenario::take_shared<BaseResolver>(&mut scenario);
            resolver::set_name(&mut resolver, &registry, FIRST_USER_ADDRESS, FIRST_NAME, test_scenario::ctx(&mut scenario));
            test_scenario::return_shared(registry);
            test_scenario::return_shared(resolver);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1)]
    fun test_get_addr_abort_if_node_not_exists() {
        let scenario = test_init();
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let resolver = test_scenario::take_shared<BaseResolver>(&mut scenario);
            resolver::addr(&resolver, FIRST_SUB_NODE);
            test_scenario::return_shared(resolver);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_set_addr() {
        let scenario = test_init();
        base_registry_tests::mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let resolver = test_scenario::take_shared<BaseResolver>(&mut scenario);
            resolver::set_addr(
                &mut resolver,
                &registry,
                FIRST_SUB_NODE,
                FIRST_USER_ADDRESS,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(registry);
            test_scenario::return_shared(resolver);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let resolver = test_scenario::take_shared<BaseResolver>(&mut scenario);
            let addr = resolver::addr(&resolver, FIRST_SUB_NODE);
            assert!(addr == FIRST_USER_ADDRESS, 0);
            test_scenario::return_shared(resolver);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_set_addr_override_value_if_exists() {
        let scenario = test_init();
        base_registry_tests::mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let resolver = test_scenario::take_shared<BaseResolver>(&mut scenario);
            resolver::set_addr(
                &mut resolver,
                &registry,
                FIRST_SUB_NODE,
                FIRST_USER_ADDRESS,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(registry);
            test_scenario::return_shared(resolver);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let resolver = test_scenario::take_shared<BaseResolver>(&mut scenario);
            resolver::set_addr(
                &mut resolver,
                &registry,
                FIRST_SUB_NODE,
                SECOND_USER_ADDRESS,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(registry);
            test_scenario::return_shared(resolver);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let resolver = test_scenario::take_shared<BaseResolver>(&mut scenario);
            let addr = resolver::addr(&resolver, FIRST_SUB_NODE);
            assert!(addr == SECOND_USER_ADDRESS, 0);
            test_scenario::return_shared(resolver);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 101)]
    fun test_set_addr_abort_if_unauthorized() {
        let scenario = test_init();
        base_registry_tests::mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let resolver = test_scenario::take_shared<BaseResolver>(&mut scenario);
            resolver::set_text(
                &mut resolver,
                &registry,
                FIRST_SUB_NODE,
                AVATAR,
                FIRST_AVATAR,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(registry);
            test_scenario::return_shared(resolver);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 101)]
    fun test_resolved_address_not_allowed_to_set_new_addr() {
        let scenario = test_init();
        base_registry_tests::mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let resolver = test_scenario::take_shared<BaseResolver>(&mut scenario);
            resolver::set_addr(
                &mut resolver,
                &registry,
                FIRST_SUB_NODE,
                FIRST_USER_ADDRESS,
                test_scenario::ctx(&mut scenario)
            );
            test_scenario::return_shared(registry);
            test_scenario::return_shared(resolver);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let resolver = test_scenario::take_shared<BaseResolver>(&mut scenario);
            resolver::set_addr(
                &mut resolver,
                &registry,
                FIRST_SUB_NODE,
                SECOND_USER_ADDRESS,
                test_scenario::ctx(&mut scenario)
            );
            test_scenario::return_shared(registry);
            test_scenario::return_shared(resolver);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_set_avatar() {
        let scenario = test_init();
        base_registry_tests::mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let resolver = test_scenario::take_shared<BaseResolver>(&mut scenario);
            resolver::set_text(
                &mut resolver,
                &registry,
                FIRST_SUB_NODE,
                AVATAR,
                FIRST_AVATAR,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(registry);
            test_scenario::return_shared(resolver);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let resolver = test_scenario::take_shared<BaseResolver>(&mut scenario);
            let text = resolver::text(&resolver, FIRST_SUB_NODE, AVATAR);
            assert!(text == utf8(FIRST_AVATAR), 0);
            test_scenario::return_shared(resolver);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1)]
    fun test_set_avatar_abort_with_wrong_node() {
        let scenario = test_init();
        base_registry_tests::mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let resolver = test_scenario::take_shared<BaseResolver>(&mut scenario);
            resolver::set_text(
                &mut resolver,
                &registry,
                FIRST_SUB_NODE,
                AVATAR,
                FIRST_AVATAR,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(registry);
            test_scenario::return_shared(resolver);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let resolver = test_scenario::take_shared<BaseResolver>(&mut scenario);
            resolver::text(&resolver, SECOND_SUB_NODE, AVATAR);
            test_scenario::return_shared(resolver);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_set_contenthash() {
        let scenario = test_init();
        base_registry_tests::mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let resolver = test_scenario::take_shared<BaseResolver>(&mut scenario);
            resolver::set_contenthash(
                &mut resolver,
                &registry,
                FIRST_SUB_NODE,
                FIRST_CONTENT_HASH,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(registry);
            test_scenario::return_shared(resolver);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let resolver = test_scenario::take_shared<BaseResolver>(&mut scenario);
            let hash = resolver::contenthash(&resolver, FIRST_SUB_NODE);
            assert!(hash == utf8(FIRST_CONTENT_HASH), 0);
            test_scenario::return_shared(resolver);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 101)]
    fun test_set_contenthash_abort_if_unauthorized() {
        let scenario = test_init();
        base_registry_tests::mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, SECOND_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let resolver = test_scenario::take_shared<BaseResolver>(&mut scenario);
            resolver::set_contenthash(
                &mut resolver,
                &registry,
                FIRST_SUB_NODE,
                FIRST_CONTENT_HASH,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(registry);
            test_scenario::return_shared(resolver);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1)]
    fun test_set_contenthash_abort_if_node_not_exists() {
        let scenario = test_init();

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let resolver = test_scenario::take_shared<BaseResolver>(&mut scenario);
            resolver::set_contenthash(
                &mut resolver,
                &registry,
                FIRST_SUB_NODE,
                FIRST_CONTENT_HASH,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(registry);
            test_scenario::return_shared(resolver);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1)]
    fun test_get_contenthash_abort_if_node_not_exists() {
        let scenario = test_init();
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let resolver = test_scenario::take_shared<BaseResolver>(&mut scenario);
            resolver::contenthash(&resolver, FIRST_SUB_NODE);
            test_scenario::return_shared(resolver);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_set_text_record_with_new_key() {
        let scenario = test_init();
        base_registry_tests::mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let resolver = test_scenario::take_shared<BaseResolver>(&mut scenario);
            resolver::set_text(
                &mut resolver,
                &registry,
                FIRST_SUB_NODE,
                b"newkey",
                FIRST_CONTENT_HASH,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(registry);
            test_scenario::return_shared(resolver);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let resolver = test_scenario::take_shared<BaseResolver>(&mut scenario);
            let text = resolver::text(&resolver, FIRST_SUB_NODE, b"newkey");
            assert!(text == utf8(FIRST_CONTENT_HASH), 0);
            test_scenario::return_shared(resolver);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1)]
    fun test_get_text_abort_if_wrong_key() {
        let scenario = test_init();
        base_registry_tests::mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let resolver = test_scenario::take_shared<BaseResolver>(&mut scenario);
            resolver::set_text(
                &mut resolver,
                &registry,
                FIRST_SUB_NODE,
                AVATAR,
                FIRST_AVATAR,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(registry);
            test_scenario::return_shared(resolver);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let resolver = test_scenario::take_shared<BaseResolver>(&mut scenario);
            resolver::text(&resolver, FIRST_SUB_NODE, b"wrongkey");
            test_scenario::return_shared(resolver);
        };
        test_scenario::end(scenario);
    }
}
