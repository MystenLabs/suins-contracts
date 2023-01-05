#[test_only]
module suins::reverse_registrar_tests {

    use sui::test_scenario::{Self, Scenario};
    use suins::base_registry::{Self, Registry, AdminCap};
    use suins::reverse_registrar::{Self, ReverseRegistrar};
    use suins::base_registrar::{Self, TLDsList};
    use std::string::utf8;

    const SUINS_ADDRESS: address = @0xA001;
    const FIRST_USER_ADDRESS: address = @0xB001;
    const SECOND_USER_ADDRESS: address = @0xB002;
    const FIRST_RESOLVER_ADDRESS: address = @0xC001;
    const SECOND_RESOLVER_ADDRESS: address = @0xC002;
    const FIRST_NODE: vector<u8> = b"000000000000000000000000000000000000b001.addr.reverse";
    const SECOND_NODE: vector<u8> = b"000000000000000000000000000000000000b002.addr.reverse";

    fun test_init(): Scenario {
        let scenario = test_scenario::begin(SUINS_ADDRESS);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            base_registry::test_init(ctx);
            reverse_registrar::test_init(ctx);
            base_registrar::test_init(ctx);
        };
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let tlds_list = test_scenario::take_shared<TLDsList>(&mut scenario);

            base_registrar::new_tld(&admin_cap, &mut tlds_list, b"sui", test_scenario::ctx(&mut scenario));
            base_registrar::new_tld(&admin_cap, &mut tlds_list, b"addr.reverse", test_scenario::ctx(&mut scenario));
            base_registrar::new_tld(&admin_cap, &mut tlds_list, b"move", test_scenario::ctx(&mut scenario));
            test_scenario::return_shared(tlds_list);
            test_scenario::return_to_sender(&mut scenario, admin_cap);
        };
        scenario
    }

    #[test]
    fun test_claim_with_resolver() {
        let scenario = test_init();
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            assert!(base_registry::get_records_len(&registry) == 0, 0);
            test_scenario::return_shared(registry);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            reverse_registrar::claim_with_resolver(
                &mut registry,
                FIRST_USER_ADDRESS,
                FIRST_RESOLVER_ADDRESS,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(registry);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);

            assert!(base_registry::get_records_len(&registry) == 1, 0);
            let record = base_registry::get_record_by_key(&registry, utf8(FIRST_NODE));
            assert!(base_registry::get_record_ttl(&record) == 0, 0);
            assert!(base_registry::get_record_resolver(&record) == FIRST_RESOLVER_ADDRESS, 0);
            assert!(base_registry::get_record_owner(&record) == FIRST_USER_ADDRESS, 0);

            test_scenario::return_shared(registry);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            reverse_registrar::claim_with_resolver(
                &mut registry,
                SECOND_USER_ADDRESS,
                SECOND_RESOLVER_ADDRESS,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(registry);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);

            assert!(base_registry::get_records_len(&registry) == 1, 0);
            let record = base_registry::get_record_by_key(&registry, utf8(FIRST_NODE));
            assert!(base_registry::get_record_ttl(&record) == 0, 0);
            assert!(base_registry::get_record_resolver(&record) == SECOND_RESOLVER_ADDRESS, 0);
            assert!(base_registry::get_record_owner(&record) == SECOND_USER_ADDRESS, 0);

            test_scenario::return_shared(registry);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_claim() {
        let scenario = test_init();

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            assert!(base_registry::get_records_len(&registry) == 0, 0);
            test_scenario::return_shared(registry);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let registrar = test_scenario::take_shared<ReverseRegistrar>(&mut scenario);

            reverse_registrar::claim(
                &mut registrar,
                &mut registry,
                FIRST_USER_ADDRESS,
                test_scenario::ctx(&mut scenario),
            );

            test_scenario::return_shared(registry);
            test_scenario::return_shared(registrar);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            assert!(base_registry::get_records_len(&registry) == 1, 0);
            let record = base_registry::get_record_by_key(&registry, utf8(FIRST_NODE));
            assert!(base_registry::get_record_ttl(&record) == 0, 0);
            assert!(base_registry::get_record_resolver(&record) == @0x0, 0);
            assert!(base_registry::get_record_owner(&record) == FIRST_USER_ADDRESS, 0);

            test_scenario::return_shared(registry);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_set_default_resolver() {
        let scenario = test_init();

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let registrar = test_scenario::take_shared<ReverseRegistrar>(&mut scenario);

            let default_resolver = reverse_registrar::get_default_resolver(&registrar);
            assert!(default_resolver == @0x0, 0);

            test_scenario::return_shared(registrar);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let registrar = test_scenario::take_shared<ReverseRegistrar>(&mut scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);

            reverse_registrar::set_default_resolver(
                &admin_cap,
                &mut registrar,
                FIRST_RESOLVER_ADDRESS,
            );

            test_scenario::return_shared(registrar);
            test_scenario::return_to_sender(&mut scenario, admin_cap);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let registrar = test_scenario::take_shared<ReverseRegistrar>(&mut scenario);

            let default_resolver = reverse_registrar::get_default_resolver(&registrar);
            assert!(default_resolver == FIRST_RESOLVER_ADDRESS, 0);

            test_scenario::return_shared(registrar);
       };
        test_scenario::end(scenario);
    }
}
