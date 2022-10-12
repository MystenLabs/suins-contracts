#[test_only]
module suins::addr_resolver_tests {

    use sui::test_scenario::Scenario;
    use sui::test_scenario;
    use suins::addr_resolver;
    use suins::base_registry::Registry;
    use suins::addr_resolver::AddrResolver;
    use suins::base_registry;

    const SUINS_ADDRESS: address = @0xA001;
    const SUI_NODE: vector<u8> = b"sui";
    const FIRST_USER_ADDRESS: address = @0xB001;
    const SECOND_USER_ADDRESS: address = @0xB002;

    fun init(): Scenario {
        let scenario = test_scenario::begin(&SUINS_ADDRESS);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            base_registry::test_init(ctx);
            addr_resolver::test_init(ctx);
        };
        scenario
    }

    #[test]
    #[expected_failure(abort_code = 1)]
    fun test_get_addr_abort_if_node_not_exists() {
        let scenario = init();

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let resolver_wrapper = test_scenario::take_shared<AddrResolver>(&mut scenario);
            let resolver = test_scenario::borrow_mut(&mut resolver_wrapper);

            let addr = addr_resolver::addr(resolver, SUI_NODE);
            assert!(addr == FIRST_USER_ADDRESS, 0);

            test_scenario::return_shared(&mut scenario, resolver_wrapper);
        };
    }

    #[test]
    fun test_set_addr() {
        let scenario = init();

        test_scenario::next_tx(&mut scenario, &SUINS_ADDRESS);
        {
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);
            let resolver_wrapper = test_scenario::take_shared<AddrResolver>(&mut scenario);
            let resolver = test_scenario::borrow_mut(&mut resolver_wrapper);

            addr_resolver::set_addr(resolver, registry, SUI_NODE, FIRST_USER_ADDRESS, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(&mut scenario, registry_wrapper);
            test_scenario::return_shared(&mut scenario, resolver_wrapper);
        };

        test_scenario::next_tx(&mut scenario, &SUINS_ADDRESS);
        {
            let resolver_wrapper = test_scenario::take_shared<AddrResolver>(&mut scenario);
            let resolver = test_scenario::borrow_mut(&mut resolver_wrapper);

            let addr = addr_resolver::addr(resolver, SUI_NODE);
            assert!(addr == FIRST_USER_ADDRESS, 0);

            test_scenario::return_shared(&mut scenario, resolver_wrapper);
        };
    }

    #[test]
    fun test_set_addr_override_value_if_exists() {
        let scenario = init();

        test_scenario::next_tx(&mut scenario, &SUINS_ADDRESS);
        {
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);
            let resolver_wrapper = test_scenario::take_shared<AddrResolver>(&mut scenario);
            let resolver = test_scenario::borrow_mut(&mut resolver_wrapper);

            addr_resolver::set_addr(resolver, registry, SUI_NODE, FIRST_USER_ADDRESS, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(&mut scenario, registry_wrapper);
            test_scenario::return_shared(&mut scenario, resolver_wrapper);
        };

        test_scenario::next_tx(&mut scenario, &SUINS_ADDRESS);
        {
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);
            let resolver_wrapper = test_scenario::take_shared<AddrResolver>(&mut scenario);
            let resolver = test_scenario::borrow_mut(&mut resolver_wrapper);

            addr_resolver::set_addr(resolver, registry, SUI_NODE, SECOND_USER_ADDRESS, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(&mut scenario, registry_wrapper);
            test_scenario::return_shared(&mut scenario, resolver_wrapper);
        };

        test_scenario::next_tx(&mut scenario, &SUINS_ADDRESS);
        {
            let resolver_wrapper = test_scenario::take_shared<AddrResolver>(&mut scenario);
            let resolver = test_scenario::borrow_mut(&mut resolver_wrapper);

            let addr = addr_resolver::addr(resolver, SUI_NODE);
            assert!(addr == SECOND_USER_ADDRESS, 0);

            test_scenario::return_shared(&mut scenario, resolver_wrapper);
        };
    }

    #[test]
    #[expected_failure(abort_code = 401)]
    fun test_set_addr_abort_if_unauthorized() {
        let scenario = init();

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);
            let resolver_wrapper = test_scenario::take_shared<AddrResolver>(&mut scenario);
            let resolver = test_scenario::borrow_mut(&mut resolver_wrapper);

            addr_resolver::set_addr(resolver, registry, SUI_NODE, FIRST_USER_ADDRESS, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(&mut scenario, registry_wrapper);
            test_scenario::return_shared(&mut scenario, resolver_wrapper);
        };
    }

    #[test]
    #[expected_failure(abort_code = 401)]
    fun test_resolved_address_not_allowed_to_set_new_addr() {
        let scenario = init();

        test_scenario::next_tx(&mut scenario, &SUINS_ADDRESS);
        {
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);
            let resolver_wrapper = test_scenario::take_shared<AddrResolver>(&mut scenario);
            let resolver = test_scenario::borrow_mut(&mut resolver_wrapper);

            addr_resolver::set_addr(resolver, registry, SUI_NODE, FIRST_USER_ADDRESS, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(&mut scenario, registry_wrapper);
            test_scenario::return_shared(&mut scenario, resolver_wrapper);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);
            let resolver_wrapper = test_scenario::take_shared<AddrResolver>(&mut scenario);
            let resolver = test_scenario::borrow_mut(&mut resolver_wrapper);

            addr_resolver::set_addr(resolver, registry, SUI_NODE, SECOND_USER_ADDRESS, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(&mut scenario, registry_wrapper);
            test_scenario::return_shared(&mut scenario, resolver_wrapper);
        };
    }
}
