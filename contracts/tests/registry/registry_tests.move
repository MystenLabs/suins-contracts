#[test_only]
module suins::registry_tests {

    use sui::test_scenario::{Self, Scenario};
    use suins::registry::{Self, AdminCap};
    use suins::registrar;
    use std::string::utf8;
    use suins::entity::SuiNS;
    use suins::entity;

    friend suins::registry_tests_2;

    const SUINS_ADDRESS: address = @0xA001;
    const FIRST_USER_ADDRESS: address = @0xB001;
    const SECOND_USER_ADDRESS: address = @0xB002;
    const FIRST_DOMAIN_NAME: vector<u8> = b"eastagile.sui";
    const SECOND_DOMAIN_NAME: vector<u8> = b"secondsuitest.sui";
    const THIRD_DOMAIN_NAME: vector<u8> = b"ea.eastagile.sui";

    fun test_init(): Scenario {
        let scenario = test_scenario::begin(SUINS_ADDRESS);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            registry::test_init(ctx);
            entity::test_init(ctx);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            registrar::new_tld(&admin_cap, &mut suins, utf8(b"sui"), test_scenario::ctx(&mut scenario));
            registrar::new_tld(&admin_cap, &mut suins, utf8(b"addr.reverse"), test_scenario::ctx(&mut scenario));
            registrar::new_tld(&admin_cap, &mut suins, utf8(b"move"), test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(suins);
            test_scenario::return_to_sender(&mut scenario, admin_cap);
        };
        scenario
    }

    public(friend) fun mint_record(scenario: &mut Scenario) {
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            registry::set_record_internal(
                &mut suins,
                utf8(FIRST_DOMAIN_NAME),
                FIRST_USER_ADDRESS,
                10,
                test_scenario::ctx(scenario),
            );
            test_scenario::return_shared(suins);
        };
    }

    // TODO: test for emitted events
    #[test]
    fun test_set_record_internal() {
        let scenario = test_init();
        mint_record(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            assert!(registry::owner(&suins, utf8(FIRST_DOMAIN_NAME)) == FIRST_USER_ADDRESS, 0);
            assert!(registry::ttl(&suins, utf8(FIRST_DOMAIN_NAME)) == 10, 0);

            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::set_record_internal(
                &mut suins,
                utf8(FIRST_DOMAIN_NAME),
                SECOND_USER_ADDRESS,
                20,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let (owner, linked_addr, ttl, name) = registry::get_name_record_all_fields(&suins, utf8(FIRST_DOMAIN_NAME));

            assert!(owner == SECOND_USER_ADDRESS, 0);
            assert!(linked_addr == SECOND_USER_ADDRESS, 0);
            assert!(ttl == 20, 0);
            assert!(name == utf8(b""), 0);

            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_set_owner() {
        let scenario = test_init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::set_owner(
                &mut suins,
                utf8(FIRST_DOMAIN_NAME),
                SECOND_USER_ADDRESS,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, SECOND_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            assert!(registry::owner(&suins, utf8(FIRST_DOMAIN_NAME)) == SECOND_USER_ADDRESS, 0);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registry::EDomainNameNotExists)]
    fun test_set_owner_abort_if_domain_name_not_exists() {
        let scenario = test_init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            registry::set_owner(
                &mut suins,
                utf8(SECOND_DOMAIN_NAME),
                SECOND_USER_ADDRESS,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registry::EUnauthorized)]
    fun test_set_owner_abort_if_unauthorised() {
        let scenario = test_init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, SECOND_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::set_owner(
                &mut suins,
                utf8(FIRST_DOMAIN_NAME),
                SECOND_USER_ADDRESS,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }
    
    #[test]
    fun test_set_ttl() {
        let scenario = test_init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::set_ttl(&mut suins, utf8(FIRST_DOMAIN_NAME), 20, test_scenario::ctx(&mut scenario));
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            assert!(registry::ttl(&suins, utf8(FIRST_DOMAIN_NAME)) == 20, 0);
            test_scenario::return_shared(suins);
        };

        // new ttl == current ttl
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::set_ttl(&mut suins, utf8(FIRST_DOMAIN_NAME), 20, test_scenario::ctx(&mut scenario));
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            assert!(registry::ttl(&suins, utf8(FIRST_DOMAIN_NAME)) == 20, 0);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registry::EUnauthorized)]
    fun test_set_ttl_abort_if_unauthorised() {
        let scenario = test_init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, SECOND_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            registry::set_ttl(&mut suins, utf8(FIRST_DOMAIN_NAME), 20, test_scenario::ctx(&mut scenario));
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registry::EDomainNameNotExists)]
    fun test_set_ttl_abort_if_domain_name_not_exists() {
        let scenario = test_init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::set_ttl(&mut suins, utf8(SECOND_DOMAIN_NAME), 20, test_scenario::ctx(&mut scenario));
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_get_ttl() {
        let scenario = test_init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let ttl = registry::ttl(&suins, utf8(FIRST_DOMAIN_NAME));
            assert!(ttl == 10, 0);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registry::EDomainNameNotExists)]
    fun test_get_ttl_if_domain_name_not_exists() {
        let scenario = test_init();
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registry::ttl(&suins, utf8(FIRST_DOMAIN_NAME));
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }
}
