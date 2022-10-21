#[test_only]
module suins::name_resolver_tests {

    use sui::test_scenario::{Self, Scenario};
    use suins::base_registry::{Self, Registry};
    use suins::name_resolver::{Self, NameResolver};
    use suins::converter;
    use std::string;

    const SUINS_ADDRESS: address = @0xA001;
    const FIRST_NAME: vector<u8> = b"sui";
    const SECOND_NAME: vector<u8> = b"move";
    const FIRST_USER_ADDRESS: address = @0xB001;
    const SECOND_USER_ADDRESS: address = @0xB002;
    const ADDR_REVERSE_BASE_NODE: vector<u8> = b"addr.reverse";

    fun init(): Scenario {
        let scenario = test_scenario::begin(SUINS_ADDRESS);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            base_registry::test_init(ctx);
            name_resolver::test_init(ctx);
        };
        scenario
    }

    fun set_name(scenario: &mut Scenario) {
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(scenario);

            let node = base_registry::make_node(
                converter::address_to_string(FIRST_USER_ADDRESS),
                string::utf8(ADDR_REVERSE_BASE_NODE),
            );
            base_registry::new_record_test(&mut registry, node, FIRST_USER_ADDRESS);

            test_scenario::return_shared(registry);
        };

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(scenario);
            let resolver = test_scenario::take_shared<NameResolver>( scenario);

            name_resolver::set_name(&mut resolver, &registry, FIRST_USER_ADDRESS, FIRST_NAME, test_scenario::ctx(scenario));

            test_scenario::return_shared(registry);
            test_scenario::return_shared(resolver);
        };
    }

    #[test]
    #[expected_failure(abort_code = 1)]
    fun test_get_name_abort_if_addr_not_exists() {
        let scenario = init();

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let resolver = test_scenario::take_shared<NameResolver>(&mut scenario);

            name_resolver::name(&resolver, FIRST_USER_ADDRESS);

            test_scenario::return_shared(resolver);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_set_name() {
        let scenario = init();
        set_name(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let resolver = test_scenario::take_shared<NameResolver>(&mut scenario);

            let name= name_resolver::name(&resolver, FIRST_USER_ADDRESS);
            assert!(name == string::utf8(FIRST_NAME), 0);

            test_scenario::return_shared(resolver);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1)]
    fun test_unset_name() {
        let scenario = init();
        set_name(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let resolver = test_scenario::take_shared<NameResolver>(&mut scenario);

            name_resolver::unset(&mut resolver, &registry, FIRST_USER_ADDRESS, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(resolver);
            test_scenario::return_shared(registry);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let resolver = test_scenario::take_shared<NameResolver>(&mut scenario);

            name_resolver::name(&resolver, FIRST_USER_ADDRESS);

            test_scenario::return_shared(resolver);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 101)]
    fun test_unset_name_abort_if_unauthorized() {
        let scenario = init();
        set_name(&mut scenario);

        test_scenario::next_tx(&mut scenario, SECOND_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let resolver = test_scenario::take_shared<NameResolver>(&mut scenario);

            name_resolver::unset(&mut resolver, &registry, FIRST_USER_ADDRESS, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(resolver);
            test_scenario::return_shared(registry);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1)]
    fun test_unset_name_abort_if_name_not_exists() {
        let scenario = init();
        set_name(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let resolver = test_scenario::take_shared<NameResolver>(&mut scenario);

            name_resolver::unset(&mut resolver, &registry, FIRST_USER_ADDRESS, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(resolver);
            test_scenario::return_shared(registry);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let resolver = test_scenario::take_shared<NameResolver>(&mut scenario);

            name_resolver::unset(&mut resolver, &registry, FIRST_USER_ADDRESS, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(resolver);
            test_scenario::return_shared(registry);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_set_name_override_value_if_exists() {
        let scenario = init();
        set_name(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let resolver = test_scenario::take_shared<NameResolver>(&mut scenario);

            name_resolver::set_name(&mut resolver, &registry, FIRST_USER_ADDRESS, SECOND_NAME, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(registry);
            test_scenario::return_shared(resolver);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let resolver = test_scenario::take_shared<NameResolver>(&mut scenario);

            let name = name_resolver::name(&resolver, FIRST_USER_ADDRESS);
            assert!(name == string::utf8(SECOND_NAME), 0);

            test_scenario::return_shared(resolver);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 102)]
    fun test_set_name_abort_if_addr_not_exists_in_registry() {
        let scenario = init();

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let resolver = test_scenario::take_shared<NameResolver>(&mut scenario);

            name_resolver::set_name(&mut resolver, &registry, FIRST_USER_ADDRESS, FIRST_NAME, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(registry);
            test_scenario::return_shared(resolver);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 101)]
    fun test_set_name_abort_if_unauthorized() {
        let scenario = init();

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);

            let node = base_registry::make_node(
                converter::address_to_string(FIRST_USER_ADDRESS),
                string::utf8(ADDR_REVERSE_BASE_NODE),
            );
            base_registry::new_record_test(&mut registry, node, FIRST_USER_ADDRESS);

            test_scenario::return_shared(registry);
        };

        test_scenario::next_tx(&mut scenario, SECOND_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let resolver = test_scenario::take_shared<NameResolver>(&mut scenario);

            name_resolver::set_name(&mut resolver, &registry, FIRST_USER_ADDRESS, FIRST_NAME, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(registry);
            test_scenario::return_shared(resolver);
        };
        test_scenario::end(scenario);
    }
}
