#[test_only]
module suins::registry_tests {
    use suins::registry::{Self, AdminCap, Record, Registry};
    use sui::test_scenario::{Self, Scenario};

    const SUINS_ADDRESS: address = @0xA001;
    const FIRST_USER_ADDRESS: address = @0xB001;
    const SECOND_USER_ADDRESS: address = @0xB002;
    const FIRST_RESOLVER_ADDRESS: address = @0xC001;
    const SECOND_RESOLVER_ADDRESS: address = @0xC002;
    const DOMAIN: vector<u8> = b"suins.sui";

    fun init(): Scenario {
        let scenario = test_scenario::begin(&SUINS_ADDRESS);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            registry::test_init(ctx);
        };
        scenario
    }

    fun mint_record(scenario: &mut Scenario) {
        test_scenario::next_tx(scenario, &SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_owned<AdminCap>(scenario);
            let registry_wrapper = test_scenario::take_shared<Registry>(scenario);
            let registry_test = test_scenario::borrow_mut(&mut registry_wrapper);
            let ctx = test_scenario::ctx(scenario);

            assert!(registry::get_registry_len(registry_test) == 0, 0);
            registry::mint(&admin_cap, registry_test, DOMAIN, FIRST_USER_ADDRESS, FIRST_RESOLVER_ADDRESS, 10, ctx);
            assert!(registry::get_registry_len(registry_test) == 1, 0);

            test_scenario::return_owned(scenario, admin_cap);
            test_scenario::return_shared(scenario, registry_wrapper);
        };
    }

    #[test]
    fun test_mint() {
        let scenario = init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            assert!(test_scenario::can_take_owned<Record>(&mut scenario), 0);
            let record = test_scenario::take_owned<Record>(&mut scenario);

            assert!(registry::get_record_domain(&record) == DOMAIN, 0);
            assert!(registry::get_record_owner(&record) == FIRST_USER_ADDRESS, 0);
            assert!(registry::get_record_resolver(&record) == FIRST_RESOLVER_ADDRESS, 0);
            assert!(registry::get_record_ttl(&record) == 10, 0);

            test_scenario::return_owned(&mut scenario, record);
        };

        test_scenario::next_tx(&mut scenario, &SECOND_USER_ADDRESS);
        {
            assert!(!test_scenario::can_take_owned<Record>(&mut scenario), 0);
        }
    }

    #[test]
    fun test_change_record_owner() {
        let scenario = init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, &SECOND_USER_ADDRESS);
        {
            assert!(!test_scenario::can_take_owned<Record>(&mut scenario), 0);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let record = test_scenario::take_owned<Record>(&mut scenario);
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry_test = test_scenario::borrow_mut(&mut registry_wrapper);
            let ctx = test_scenario::ctx(&mut scenario);

            registry::setOwner(registry_test, record, SECOND_USER_ADDRESS, ctx);

            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            assert!(!test_scenario::can_take_owned<Record>(&mut scenario), 0);
        };

        test_scenario::next_tx(&mut scenario, &SECOND_USER_ADDRESS);
        {
            assert!(test_scenario::can_take_owned<Record>(&mut scenario), 0);
            let record = test_scenario::take_owned<Record>(&mut scenario);

            assert!(registry::get_record_domain(&record) == DOMAIN, 0);
            assert!(registry::get_record_owner(&record) == SECOND_USER_ADDRESS, 0);
            assert!(registry::get_record_resolver(&record) == FIRST_RESOLVER_ADDRESS, 0);
            assert!(registry::get_record_ttl(&record) == 10, 0);

            test_scenario::return_owned(&mut scenario, record);
        };
    }

    #[test]
    #[expected_failure(abort_code = 1)]
    fun test_change_record_owner_fails_wtih_same_owner() {
        let scenario = init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let record = test_scenario::take_owned<Record>(&mut scenario);
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry_test = test_scenario::borrow_mut(&mut registry_wrapper);
            let ctx = test_scenario::ctx(&mut scenario);

            registry::setOwner(registry_test, record, FIRST_USER_ADDRESS, ctx);

            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };
    }

    #[test]
    fun test_change_record_resolver() {
        let scenario = init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let record = test_scenario::take_owned<Record>(&mut scenario);

            registry::setResolver(&mut record, SECOND_RESOLVER_ADDRESS);
            test_scenario::return_owned<Record>(&mut scenario, record);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let record = test_scenario::take_owned<Record>(&mut scenario);

            assert!(registry::get_record_resolver(&record) == SECOND_RESOLVER_ADDRESS, 0);

            test_scenario::return_owned(&mut scenario, record);
        };
    }

    #[test]
    #[expected_failure(abort_code = 2)]
    fun test_change_record_resolver_fails_wtih_same_resolver() {
        let scenario = init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let record = test_scenario::take_owned<Record>(&mut scenario);

            registry::setResolver(&mut record, FIRST_RESOLVER_ADDRESS);
            test_scenario::return_owned<Record>(&mut scenario, record);
        };
    }

    #[test]
    fun test_change_record_ttl() {
        let scenario = init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let record = test_scenario::take_owned<Record>(&mut scenario);

            registry::setTTL(&mut record, 20);
            test_scenario::return_owned<Record>(&mut scenario, record);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let record = test_scenario::take_owned<Record>(&mut scenario);

            assert!(registry::get_record_ttl(&record) == 20, 0);

            test_scenario::return_owned(&mut scenario, record);
        };
    }

    #[test]
    #[expected_failure(abort_code = 3)]
    fun test_change_record_ttl_with_same_ttl() {
        let scenario = init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let record = test_scenario::take_owned<Record>(&mut scenario);

            registry::setTTL(&mut record, 10);
            test_scenario::return_owned<Record>(&mut scenario, record);
        };
    }
}
