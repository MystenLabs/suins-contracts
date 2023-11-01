// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module discounts::discount_tests {
    use std::option;
    use std::string::{utf8, String};

    use sui::test_scenario::{Self as ts, Scenario, ctx};
    use sui::clock::{Self, Clock};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::transfer;

    use suins::suins::{Self, SuiNS, AdminCap};
    use suins::registry;
    
    use discounts::house::{Self, DiscountHouse, DiscountHouseApp};
    use discounts::discounts;

    use day_one::day_one::{Self, DayOne};

    use reserved::reserved_names;

    // an authorized type to test.
    struct TestAuthorized has copy, store, drop {}

    // another authorized type to test.
    struct AnotherAuthorized has copy, store, drop {}

    // an unauthorized type to test.
    struct TestUnauthorized has copy, store, drop {}

    const SUINS_ADDRESS: address = @0xA001;
    const USER_ADDRESS: address = @0xA002;

    const MIST_PER_SUI: u64 = 1_000_000_000;

    fun test_init(): Scenario {
        let scenario_val = ts::begin(SUINS_ADDRESS);
        let scenario = &mut scenario_val;
        {
            let suins = suins::init_for_testing(ctx(scenario));
            suins::authorize_app_for_testing<DiscountHouseApp>(&mut suins);
            suins::share_for_testing(suins);
            house::init_for_testing(ctx(scenario));
            let clock = clock::create_for_testing(ctx(scenario));
            clock::share_for_testing(clock);
        };
        {
            ts::next_tx(scenario, SUINS_ADDRESS);
            let admin_cap = ts::take_from_sender<AdminCap>(scenario);
            let suins = ts::take_shared<SuiNS>(scenario);
            let discount_house = ts::take_shared<DiscountHouse>(scenario);

            // a more expensive alternative.
            discounts::authorize_type<TestAuthorized>(&admin_cap, &mut discount_house, 3*MIST_PER_SUI, 2*MIST_PER_SUI, 1*MIST_PER_SUI);
            // a much cheaper price for another type.
            discounts::authorize_type<AnotherAuthorized>(&admin_cap, &mut discount_house, MIST_PER_SUI / 20, MIST_PER_SUI / 10, MIST_PER_SUI / 5);
            discounts::authorize_type<DayOne>(&admin_cap, &mut discount_house, MIST_PER_SUI, MIST_PER_SUI, MIST_PER_SUI);

            registry::init_for_testing(&admin_cap, &mut suins, ctx(scenario));

            ts::return_shared(discount_house);
            ts::return_shared(suins);
            ts::return_to_sender(scenario, admin_cap);
        };
        scenario_val
    }

    fun register_with_type<T>(
        item: &T, 
        scenario: &mut Scenario, 
        domain_name: String, 
        payment: Coin<SUI>, 
        user: address
    ) {
        ts::next_tx(scenario, user);

        let reserved = reserved_names::list_for_testing(ctx(scenario));
        let suins = ts::take_shared<SuiNS>(scenario);
        let discount_house = ts::take_shared<DiscountHouse>(scenario);
        let clock = ts::take_shared<Clock>(scenario);

        let name = discounts::register<T>(&mut discount_house, &mut suins, &reserved, item, domain_name, payment, &clock, option::none(), ctx(scenario));

        transfer::public_transfer(name, user);

        ts::return_shared(discount_house);
        ts::return_shared(suins);
        ts::return_shared(clock);
        reserved_names::burn_list_for_testing(reserved);
    }

    fun register_with_day_one(
        item: &DayOne, 
        scenario: &mut Scenario, 
        domain_name: String,  
        payment: Coin<SUI>, 
        user: address
    ) {
        ts::next_tx(scenario, user);
        let reserved = reserved_names::list_for_testing(ctx(scenario));
        let suins = ts::take_shared<SuiNS>(scenario);
        let discount_house = ts::take_shared<DiscountHouse>(scenario);
        let clock = ts::take_shared<Clock>(scenario);

        let name = discounts::register_with_day_one(&mut discount_house, &mut suins, &reserved, item, domain_name, payment, &clock, option::none(), ctx(scenario));

        transfer::public_transfer(name, user);

        ts::return_shared(discount_house);
        ts::return_shared(suins);
        ts::return_shared(clock);
        reserved_names::burn_list_for_testing(reserved);
    }

    #[test]
    fun test_e2e() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;

        let test_item = TestAuthorized {};
        let payment: Coin<SUI> = coin::mint_for_testing(2*MIST_PER_SUI, ctx(scenario));

        register_with_type<TestAuthorized>(
            &test_item,
            scenario,
            utf8(b"test.sui"),
            payment,
            USER_ADDRESS
        );

        ts::end(scenario_val);
    }

    #[test, expected_failure(abort_code = discounts::discounts::EConfigNotExists)]
    fun register_with_unauthorized_type() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;

        let test_item = TestUnauthorized {};
        let payment: Coin<SUI> = coin::mint_for_testing(2*MIST_PER_SUI, ctx(scenario));

        register_with_type<TestUnauthorized>(
            &test_item,
            scenario,
            utf8(b"test.sui"),
            payment,
            USER_ADDRESS
        );
        ts::end(scenario_val);
    }

    #[test]
    fun use_day_one(){
        let scenario_val = test_init();
        let scenario = &mut scenario_val;

        let day_one = day_one::mint_for_testing(ctx(scenario));
        day_one::set_is_active_for_testing(&mut day_one, true);
        let payment: Coin<SUI> = coin::mint_for_testing(MIST_PER_SUI, ctx(scenario));

        register_with_day_one(
            &day_one,
            scenario,
            utf8(b"test.sui"),
            payment,
            USER_ADDRESS
        );

        day_one::burn_for_testing(day_one);
        ts::end(scenario_val);
    }

    #[test, expected_failure(abort_code = discounts::discounts::ENotValidForDayOne)]
    fun use_day_one_for_casual_flow_failure(){
        let scenario_val = test_init();
        let scenario = &mut scenario_val;

        let day_one = day_one::mint_for_testing(ctx(scenario));
        day_one::set_is_active_for_testing(&mut day_one, true);
        let payment: Coin<SUI> = coin::mint_for_testing(MIST_PER_SUI, ctx(scenario));

        register_with_type<DayOne>(
            &day_one,
            scenario,
            utf8(b"test.sui"),
            payment,
            USER_ADDRESS
        );

        day_one::burn_for_testing(day_one);
        ts::end(scenario_val);
    }

    #[test, expected_failure(abort_code = discounts::discounts::ENotActiveDayOne)]
    fun use_inactive_day_one_failure(){
        let scenario_val = test_init();
        let scenario = &mut scenario_val;

        let day_one = day_one::mint_for_testing(ctx(scenario));
        let payment: Coin<SUI> = coin::mint_for_testing(MIST_PER_SUI, ctx(scenario));

        register_with_day_one(
            &day_one,
            scenario,
            utf8(b"test.sui"),
            payment,
            USER_ADDRESS
        );

        day_one::burn_for_testing(day_one);
        ts::end(scenario_val);
    }
}
