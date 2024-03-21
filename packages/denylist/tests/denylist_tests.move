// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module denylist::denylist_tests {
    use std::vector;
    use std::string::{utf8, String};

    use sui::test_scenario::{Self as ts, ctx, Scenario};

    use suins::suins::{Self, SuiNS};

    use denylist::denylist::{Self, DenyListAuth};

    const ADDR: address = @0x0;

    #[test]
    fun test() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADDR);
        let mut suins = ts::take_shared<SuiNS>(scenario);
        let cap = suins::create_admin_cap_for_testing(ctx(scenario));

        denylist::add_reserved_names(&mut suins, &cap, some_reserved_names());
        denylist::add_blocked_names(&mut suins, &cap, some_offensive_names());


        assert!(denylist::is_reserved_name(&suins, utf8(b"test")), 0);
        assert!(denylist::is_reserved_name(&suins, utf8(b"test2")), 0);
    
        assert!(denylist::is_blocked_name(&suins, utf8(b"bad_test")), 0);

        assert!(!denylist::is_blocked_name(&suins, utf8(b"example")), 0);

        assert!(!denylist::is_reserved_name(&suins, utf8(b"example")), 0);

        suins::burn_admin_cap_for_testing(cap);

        ts::return_shared(suins);
        ts::end(scenario_val);
    }

    #[test, expected_failure(abort_code = ::denylist::denylist::ENoWordsInList)]
    fun test_empty_addition_failure(){
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADDR);
        let mut suins = ts::take_shared<SuiNS>(scenario);
        let cap = suins::create_admin_cap_for_testing(ctx(scenario));

        denylist::add_reserved_names(&mut suins, &cap, vector[]);

        abort 1337
    }

    // coverage.. :) 
    #[test, expected_failure(abort_code = ::denylist::denylist::ENoWordsInList)]
    fun test_empty_addition_blocked_failure(){
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADDR);
        let mut suins = ts::take_shared<SuiNS>(scenario);
        let cap = suins::create_admin_cap_for_testing(ctx(scenario));

        denylist::add_blocked_names(&mut suins, &cap, vector[]);

        abort 1337
    }

    #[test]
    fun remove_blocked_word(){
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADDR);
        let mut suins = ts::take_shared<SuiNS>(scenario);
        let cap = suins::create_admin_cap_for_testing(ctx(scenario));

        denylist::add_blocked_names(&mut suins, &cap, some_offensive_names());

        assert!(denylist::is_blocked_name(&suins, utf8(b"bad_test")), 0);

        denylist::remove_blocked_names(&mut suins, &cap, vector[utf8(b"bad_test")]);

        assert!(!denylist::is_blocked_name(&suins, utf8(b"bad_test")), 0);

        suins::burn_admin_cap_for_testing(cap);

        ts::return_shared(suins);
        ts::end(scenario_val);
    }

    #[test]
    fun remove_reserved_word(){
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADDR);
        let mut suins = ts::take_shared<SuiNS>(scenario);
        let cap = suins::create_admin_cap_for_testing(ctx(scenario));

        denylist::add_reserved_names(&mut suins, &cap, some_reserved_names());

        let name = utf8(b"test");

        assert!(denylist::is_reserved_name(&suins, name), 0);

        denylist::remove_reserved_names(&mut suins, &cap, vector[name]);

        assert!(!denylist::is_reserved_name(&suins, name), 0);

        suins::burn_admin_cap_for_testing(cap);

        ts::return_shared(suins);
        ts::end(scenario_val);
    }

    // data preparation

    public fun test_init(): (Scenario) {
        let mut scenario = ts::begin(ADDR);
        {
            ts::next_tx(&mut scenario, ADDR);

            let (mut suins, cap) = suins::new_for_testing(ctx(&mut scenario));

            suins::authorize_app_for_testing<DenyListAuth>(&mut suins);

            denylist::setup(&mut suins, &cap, ctx(&mut scenario));

            suins::share_for_testing(suins);
        
            suins::burn_admin_cap_for_testing(cap);
        };

        scenario
    }

    fun some_reserved_names(): vector<String> {
        let mut vec: vector<String> = vector::empty();

        vector::push_back(&mut vec, utf8(b"test"));
        vector::push_back(&mut vec, utf8(b"test2"));
        vector::push_back(&mut vec, utf8(b"test3"));
        vec
    }

    fun some_offensive_names(): vector<String> {
        let mut vec: vector<String> = vector::empty();
        vector::push_back(&mut vec, utf8(b"bad_test"));
        vector::push_back(&mut vec, utf8(b"bad_test2"));
        vector::push_back(&mut vec, utf8(b"bad_test3"));
        vec
    }
}
