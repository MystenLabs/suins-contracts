#[test_only]
module suins::registry_tests {
    use sui::test_scenario::{Self, Scenario};
    use suins::base_registry::{Self, AdminCap, Registry, RecordNFT};
    use std::string;

    const SUINS_ADDRESS: address = @0xA001;
    const FIRST_USER_ADDRESS: address = @0xB001;
    const SECOND_USER_ADDRESS: address = @0xB002;
    const FIRST_RESOLVER_ADDRESS: address = @0xC001;
    const SECOND_RESOLVER_ADDRESS: address = @0xC002;
    const NODE: vector<u8> = b"suins.sui";

    fun init(): Scenario {
        let scenario = test_scenario::begin(&SUINS_ADDRESS);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            base_registry::test_init(ctx);
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

            assert!(base_registry::get_registry_len(registry_test) == 0, 0);
            base_registry::mint(&admin_cap, registry_test, NODE, FIRST_USER_ADDRESS, FIRST_RESOLVER_ADDRESS, 10, ctx);
            assert!(base_registry::get_registry_len(registry_test) == 1, 0);

            test_scenario::return_owned(scenario, admin_cap);
            test_scenario::return_shared(scenario, registry_wrapper);
        };
    }

    // TODO: test for emitted events
    #[test]
    fun test_mint() {
        let scenario = init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            assert!(test_scenario::can_take_owned<RecordNFT>(&mut scenario), 0);
            let record = test_scenario::take_owned<RecordNFT>(&mut scenario);

            assert!(base_registry::get_record_node(&record) == string::utf8(NODE), 0);
            assert!(base_registry::get_record_owner(&record) == FIRST_USER_ADDRESS, 0);
            assert!(base_registry::get_record_resolver(&record) == FIRST_RESOLVER_ADDRESS, 0);
            assert!(base_registry::get_record_ttl(&record) == 10, 0);

            test_scenario::return_owned(&mut scenario, record);
        };

        test_scenario::next_tx(&mut scenario, &SECOND_USER_ADDRESS);
        {
            assert!(!test_scenario::can_take_owned<RecordNFT>(&mut scenario), 0);
        }
    }

    #[test]
    fun test_change_record_owner() {
        let scenario = init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, &SECOND_USER_ADDRESS);
        {
            assert!(!test_scenario::can_take_owned<RecordNFT>(&mut scenario), 0);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let record = test_scenario::take_owned<RecordNFT>(&mut scenario);
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry_test = test_scenario::borrow_mut(&mut registry_wrapper);
            let ctx = test_scenario::ctx(&mut scenario);

            base_registry::setOwner(registry_test, record, SECOND_USER_ADDRESS, ctx);

            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            assert!(!test_scenario::can_take_owned<RecordNFT>(&mut scenario), 0);
        };

        test_scenario::next_tx(&mut scenario, &SECOND_USER_ADDRESS);
        {
            assert!(test_scenario::can_take_owned<RecordNFT>(&mut scenario), 0);
            let record = test_scenario::take_owned<RecordNFT>(&mut scenario);

            assert!(base_registry::get_record_node(&record) == string::utf8(NODE), 0);
            assert!(base_registry::get_record_owner(&record) == SECOND_USER_ADDRESS, 0);
            assert!(base_registry::get_record_resolver(&record) == FIRST_RESOLVER_ADDRESS, 0);
            assert!(base_registry::get_record_ttl(&record) == 10, 0);

            test_scenario::return_owned(&mut scenario, record);
        };
    }

    #[test]
    fun test_change_record_resolver() {
        let scenario = init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let record = test_scenario::take_owned<RecordNFT>(&mut scenario);

            base_registry::setResolver(&mut record, SECOND_RESOLVER_ADDRESS);
            test_scenario::return_owned<RecordNFT>(&mut scenario, record);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let record = test_scenario::take_owned<RecordNFT>(&mut scenario);

            assert!(base_registry::get_record_resolver(&record) == SECOND_RESOLVER_ADDRESS, 0);

            test_scenario::return_owned(&mut scenario, record);
        };
    }

    #[test]
    fun test_change_record_ttl() {
        let scenario = init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let record = test_scenario::take_owned<RecordNFT>(&mut scenario);

            base_registry::setTTL(&mut record, 20);
            test_scenario::return_owned<RecordNFT>(&mut scenario, record);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let record = test_scenario::take_owned<RecordNFT>(&mut scenario);

            assert!(base_registry::get_record_ttl(&record) == 20, 0);

            test_scenario::return_owned(&mut scenario, record);
        };
    }
}
