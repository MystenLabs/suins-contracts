// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module discounts::discount_tests {
    use std::string::{utf8, String};

    use sui::{test_scenario::{Self as ts, Scenario, ctx}, clock::{Self, Clock}, coin::{Self, Coin}, sui::SUI};

    use suins::{suins::{Self, SuiNS, AdminCap}, registry};
    
    use discounts::{house::{Self, DiscountHouse, DiscountHouseApp}, discounts};

    use day_one::day_one::{Self, DayOne};

    // an authorized type to test.
    public struct TestAuthorized has copy, store, drop {}

    // another authorized type to test.
    public struct AnotherAuthorized has copy, store, drop {}

    // an unauthorized type to test.
    public struct TestUnauthorized has copy, store, drop {}

    const SUINS_ADDRESS: address = @0xA001;
    const USER_ADDRESS: address = @0xA002;

    const MIST_PER_SUI: u64 = 1_000_000_000;

    fun test_init(): Scenario {
        let mut scenario_val = ts::begin(SUINS_ADDRESS);
        let scenario = &mut scenario_val;
        {
            let mut suins = suins::init_for_testing(scenario.ctx());
            suins.authorize_app_for_testing<DiscountHouseApp>();
            suins.share_for_testing();
            house::init_for_testing(scenario.ctx());
            let clock = clock::create_for_testing(scenario.ctx());
            clock.share_for_testing();
        };
        {
            scenario.next_tx(SUINS_ADDRESS);
            let admin_cap = scenario.take_from_sender<AdminCap>();
            let mut suins = scenario.take_shared<SuiNS>();
            let mut discount_house = scenario.take_shared<DiscountHouse>();

            // a more expensive alternative.
            discounts::authorize_type<TestAuthorized>(&admin_cap, &mut discount_house, 3*MIST_PER_SUI, 2*MIST_PER_SUI, 1*MIST_PER_SUI);
            // a much cheaper price for another type.
            discounts::authorize_type<AnotherAuthorized>(&admin_cap, &mut discount_house, MIST_PER_SUI / 20, MIST_PER_SUI / 10, MIST_PER_SUI / 5);
            discounts::authorize_type<DayOne>(&admin_cap, &mut discount_house, MIST_PER_SUI, MIST_PER_SUI, MIST_PER_SUI);

            registry::init_for_testing(&admin_cap, &mut suins, scenario.ctx());

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
        scenario.next_tx(user);
        let mut suins = scenario.take_shared<SuiNS>();
        let mut discount_house = scenario.take_shared<DiscountHouse>();
        let clock = scenario.take_shared<Clock>();

        let name = discounts::register<T>(&mut discount_house, &mut suins, item, domain_name, payment, &clock, option::none(), scenario.ctx());

        transfer::public_transfer(name, user);

        ts::return_shared(discount_house);
        ts::return_shared(suins);
        ts::return_shared(clock);
    }

    fun register_with_day_one(
        item: &DayOne, 
        scenario: &mut Scenario, 
        domain_name: String,  
        payment: Coin<SUI>, 
        user: address
    ) {
        scenario.next_tx(user);
        let mut suins = scenario.take_shared<SuiNS>();
        let mut discount_house = scenario.take_shared<DiscountHouse>();
        let clock = scenario.take_shared<Clock>();

        let name = discounts::register_with_day_one(&mut discount_house, &mut suins, item, domain_name, payment, &clock, option::none(), scenario.ctx());

        transfer::public_transfer(name, user);

        ts::return_shared(discount_house);
        ts::return_shared(suins);
        ts::return_shared(clock);
    }

    #[test]
    fun test_e2e() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;

        let test_item = TestAuthorized {};
        let payment: Coin<SUI> = coin::mint_for_testing(2*MIST_PER_SUI, scenario.ctx());

        register_with_type<TestAuthorized>(
            &test_item,
            scenario,
            utf8(b"test.sui"),
            payment,
            USER_ADDRESS
        );

        scenario_val.end();
    }

    #[test, expected_failure(abort_code = ::discounts::discounts::EConfigNotExists)]
    fun register_with_unauthorized_type() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;

        let test_item = TestUnauthorized {};
        let payment: Coin<SUI> = coin::mint_for_testing(2*MIST_PER_SUI, scenario.ctx());

        register_with_type<TestUnauthorized>(
            &test_item,
            scenario,
            utf8(b"test.sui"),
            payment,
            USER_ADDRESS
        );
        scenario_val.end();
    }

    #[test]
    fun use_day_one(){
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;

        let mut day_one = day_one::mint_for_testing(scenario.ctx());
        day_one::set_is_active_for_testing(&mut day_one, true);
        let payment: Coin<SUI> = coin::mint_for_testing(MIST_PER_SUI, scenario.ctx());

        register_with_day_one(
            &day_one,
            scenario,
            utf8(b"test.sui"),
            payment,
            USER_ADDRESS
        );

        day_one.burn_for_testing();
        scenario_val.end();
    }

    #[test, expected_failure(abort_code = ::discounts::discounts::ENotValidForDayOne)]
    fun use_day_one_for_casual_flow_failure(){
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;

        let mut day_one = day_one::mint_for_testing(scenario.ctx());
        day_one::set_is_active_for_testing(&mut day_one, true);
        let payment: Coin<SUI> = coin::mint_for_testing(MIST_PER_SUI, scenario.ctx());

        register_with_type<DayOne>(
            &day_one,
            scenario,
            utf8(b"test.sui"),
            payment,
            USER_ADDRESS
        );

        day_one.burn_for_testing();
        scenario_val.end();
    }

    #[test, expected_failure(abort_code = ::discounts::discounts::ENotActiveDayOne)]
    fun use_inactive_day_one_failure(){
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;

        let day_one = day_one::mint_for_testing(scenario.ctx());
        let payment: Coin<SUI> = coin::mint_for_testing(MIST_PER_SUI, scenario.ctx());

        register_with_day_one(
            &day_one,
            scenario,
            utf8(b"test.sui"),
            payment,
            USER_ADDRESS
        );

        day_one.burn_for_testing();
        scenario_val.end();
    }
}
