// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module suins::reserved_name_tests {

    use std::vector;
    use std::string::{utf8, String};

    use sui::tx_context::{TxContext};
    use sui::test_scenario::{Self as ts, ctx};

    use suins::suins;
    use suins::reserved_names::{Self, ReservedNames};

    const ADDR: address = @0x0;

    #[test]
    fun test() {
        let scenario_val = ts::begin(ADDR);
        let scenario = &mut scenario_val;

        let names = prepare_data(0, ctx(scenario));

        assert!(reserved_names::is_reserved_name(&names, utf8(b"test")), 0);
        assert!(!reserved_names::is_reserved_name(&names, utf8(b"non")), 0);

        // remove a name for test

        reserved_names::remove_reserved_names(&mut names, vector[utf8(b"test")]);
        assert!(!reserved_names::is_reserved_name(&names, utf8(b"test")), 0);

        wrap(names);
        ts::end(scenario_val);
    }

    #[test]
    fun test_with_freezing() {
        let scenario_val = ts::begin(ADDR);
        let scenario = &mut scenario_val;

        let names = prepare_data(0, ctx(scenario));

        reserved_names::freeze_list(names);

        ts::next_tx(scenario, ADDR);

        let list = ts::take_immutable<ReservedNames>(scenario);

        assert!(reserved_names::is_reserved_name(&list, utf8(b"test")), 0);
        assert!(!reserved_names::is_reserved_name(&list, utf8(b"non")), 0);

        ts::return_immutable(list);
        
        ts::end(scenario_val);
    }

    #[test, expected_failure(abort_code = suins::reserved_names::EInvalidVersion)]
    fun test_against_invalid_version() {
        let scenario_val = ts::begin(ADDR);
        let scenario = &mut scenario_val;

        reserved_names::freeze_list(prepare_data(0, ctx(scenario)));

        ts::next_tx(scenario, ADDR);
        let list = ts::take_immutable<ReservedNames>(scenario);

        reserved_names::assert_is_not_offensive_name(&list, utf8(b"test"), 1);

        abort 1337
    }

    #[test, expected_failure(abort_code = suins::reserved_names::EOffensiveName)]
    fun test_offensive_failure(){
        let scenario_val = ts::begin(ADDR);
        let scenario = &mut scenario_val;

        let names  = prepare_data(0, ctx(scenario));

        reserved_names::assert_is_not_offensive_name(&names, utf8(b"bad_test"), 0);

        abort 1337
    }

    #[test, expected_failure(abort_code = suins::reserved_names::EReservedName)]
    fun test_reserved_failure(){
        let scenario_val = ts::begin(ADDR);
        let scenario = &mut scenario_val;

        let names  = prepare_data(0, ctx(scenario));

        reserved_names::assert_is_not_reserved_name(&names, utf8(b"test"), 0);

        abort 1337
    }


    #[test, expected_failure(abort_code = suins::reserved_names::ENoWordsInList)]
    fun test_empty_addition_failure(){
        let scenario_val = ts::begin(ADDR);
        let scenario = &mut scenario_val;

        let names = prepare_data(0, ctx(scenario));

        reserved_names::add_reserved_names(&mut names, vector[]);

        abort 1337
    }

    // data preparation
    fun prepare_data(version: u32, ctx: &mut TxContext): ReservedNames {
        let admin_cap = suins::create_admin_cap_for_testing(ctx);

        let names = reserved_names::new(&admin_cap, version, ctx);

        reserved_names::add_reserved_names(&mut names, some_reserved_names());
        reserved_names::add_offensive_names(&mut names, some_offensive_names());

        suins::burn_admin_cap_for_testing(admin_cap);

        names
    }

    fun wrap(list: ReservedNames) {
        reserved_names::burn_list_for_testing(list);
    }

    fun some_reserved_names(): vector<String> {
        let vec: vector<String> = vector::empty();

        vector::push_back(&mut vec, utf8(b"test"));
        vector::push_back(&mut vec, utf8(b"test2"));
        vector::push_back(&mut vec, utf8(b"test3"));
        vec
    }

    fun some_offensive_names(): vector<String> {
        let vec: vector<String> = vector::empty();
        vector::push_back(&mut vec, utf8(b"bad_test"));
        vector::push_back(&mut vec, utf8(b"bad_test2"));
        vector::push_back(&mut vec, utf8(b"bad_test3"));
        vec
    }

}
