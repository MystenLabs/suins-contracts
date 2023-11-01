// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module reserved::reserved_names_tests {
    use std::vector;
    use std::string::{utf8, String};

    use sui::tx_context::{TxContext};
    use sui::test_scenario::{Self as ts, ctx};

    use reserved::reserved_names::{Self, ReservedList, ReservedListCap};

    const ADDR: address = @0x0;

    fun prepare_data(ctx: &mut TxContext): (ReservedList, ReservedListCap) {
        let names = reserved_names::list_for_testing(ctx);
        let cap = reserved_names::cap_for_testing(ctx);

        reserved_names::add_reserved_names(&mut names, &cap, some_reserved_names());
        reserved_names::add_offensive_names(&mut names, &cap, some_offensive_names());

        (names, cap)
    }

    fun wrap(list: ReservedList, cap: ReservedListCap) {
        reserved_names::burn_cap_for_testing(cap);
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

    #[test]
    fun test() {
        let scenario_val = ts::begin(ADDR);
        let scenario = &mut scenario_val;

        let (names, cap) = prepare_data(ctx(scenario));
    
        assert!(reserved_names::is_reserved_name(&names, utf8(b"test")), 0);
        assert!(!reserved_names::is_reserved_name(&names, utf8(b"non")), 0);

        // remove a name for test

        reserved_names::remove_reserved_names(&mut names, &cap, vector[utf8(b"test")]);
         assert!(!reserved_names::is_reserved_name(&names, utf8(b"test")), 0);
         
        wrap(names, cap);
        ts::end(scenario_val);
    }

    #[test, expected_failure(abort_code = reserved::reserved_names::EOffensiveName)]
    fun test_offensive_failure(){
        let scenario_val = ts::begin(ADDR);
        let scenario = &mut scenario_val;
        
        let (names, _cap) = prepare_data(ctx(scenario));

        reserved_names::assert_is_not_offensive_name(&names, utf8(b"bad_test"));

        abort 1337
    }

    #[test, expected_failure(abort_code = reserved::reserved_names::EReservedName)]
    fun test_reserved_failure(){
        let scenario_val = ts::begin(ADDR);
        let scenario = &mut scenario_val;
        
        let (names, _cap) = prepare_data(ctx(scenario));

        reserved_names::assert_is_not_reserved_name(&names, utf8(b"test"));

        abort 1337
    }


    #[test, expected_failure(abort_code = reserved::reserved_names::ENoWordsInList)]
    fun test_empty_addition_failure(){
        let scenario_val = ts::begin(ADDR);
        let scenario = &mut scenario_val;
        
        let (names, cap) = prepare_data(ctx(scenario));

        reserved_names::add_reserved_names(&mut names, &cap, vector[]);

        abort 1337
    }
}
