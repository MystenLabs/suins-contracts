// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module discounts::free_claims_tests {

    use std::string::{utf8, String};

    use sui::object::{Self, UID};
    use sui::test_scenario::{Self as ts, Scenario, ctx};
    use sui::clock::{Self, Clock};
    use sui::transfer;

    use suins::suins::{Self, SuiNS, AdminCap};
    use suins::registry;
    
    use discounts::house::{Self, DiscountHouse, DiscountHouseApp};
    use discounts::free_claims;

    use day_one::day_one::{Self, DayOne};

    // An authorized type to test.
    struct TestAuthorized has key, store { id: UID }

    // An unauthorized type to test.
    struct TestUnauthorized has key { id: UID }

    const SUINS_ADDRESS: address = @0xA001;
    const USER_ADDRESS: address = @0xA002;

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
            free_claims::authorize_type<TestAuthorized>(&admin_cap, &mut discount_house, vector[10,63], ctx(scenario));
            free_claims::authorize_type<DayOne>(&admin_cap, &mut discount_house, vector[10,63], ctx(scenario));
            registry::init_for_testing(&admin_cap, &mut suins, ctx(scenario));

            ts::return_shared(discount_house);
            ts::return_shared(suins);
            ts::return_to_sender(scenario, admin_cap);
        };
        scenario_val
    }

    fun test_end(scenario_val: Scenario) {
        let scenario = &mut scenario_val;
        {
            ts::next_tx(scenario, SUINS_ADDRESS);
            let admin_cap = ts::take_from_sender<AdminCap>(scenario);
            let discount_house = ts::take_shared<DiscountHouse>(scenario);
            free_claims::deauthorize_type<TestAuthorized>(&admin_cap, &mut discount_house);
            free_claims::deauthorize_type<DayOne>(&admin_cap, &mut discount_house);
            ts::return_shared(discount_house);
            ts::return_to_sender(scenario, admin_cap);

        };
        ts::end(scenario_val);
    }

    fun burn_authorized(authorized: TestAuthorized) {
        let TestAuthorized { id } = authorized;
        object::delete(id);
    }

    fun free_claim_with_type<T: key>(
        item: &T, 
        scenario: &mut Scenario, 
        domain_name: String, 
        user: address
    ) {
        ts::next_tx(scenario, user);
        let suins = ts::take_shared<SuiNS>(scenario);
        let discount_house = ts::take_shared<DiscountHouse>(scenario);
        let clock = ts::take_shared<Clock>(scenario);

        let name = free_claims::free_claim<T>(&mut discount_house, &mut suins, item, domain_name, &clock, ctx(scenario));

        transfer::public_transfer(name, user);

        ts::return_shared(discount_house);
        ts::return_shared(suins);
        ts::return_shared(clock);
    }

    fun free_claim_with_day_one(
        item: &DayOne, 
        scenario: &mut Scenario, 
        domain_name: String,  
        user: address
    ) {
        ts::next_tx(scenario, user);
        let suins = ts::take_shared<SuiNS>(scenario);
        let discount_house = ts::take_shared<DiscountHouse>(scenario);
        let clock = ts::take_shared<Clock>(scenario);

        let name = free_claims::free_claim_with_day_one(&mut discount_house, &mut suins, item, domain_name, &clock, ctx(scenario));

        transfer::public_transfer(name, user);

        ts::return_shared(discount_house);
        ts::return_shared(suins);
        ts::return_shared(clock);
    }

    #[test]
    fun test_e2e() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;

        let test_item = TestAuthorized {
            id: object::new(ctx(scenario)) 
        };

        free_claim_with_type<TestAuthorized>(
            &test_item,
            scenario,
            utf8(b"01234567890.sui"),
            USER_ADDRESS
        );

        burn_authorized(test_item);
        test_end(scenario_val);
    }

    #[test]
    fun use_day_one(){
        let scenario_val = test_init();
        let scenario = &mut scenario_val;

        let day_one = day_one::mint_for_testing(ctx(scenario));
        day_one::set_is_active_for_testing(&mut day_one, true);

        free_claim_with_day_one(
            &day_one,
            scenario,
            utf8(b"0123456789.sui"),
            USER_ADDRESS
        );

        day_one::burn_for_testing(day_one);
        test_end(scenario_val);
    }

    #[test, expected_failure(abort_code = discounts::free_claims::EAlreadyClaimed)]
    fun test_tries_to_claim_again_with_same_object_failure() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;

        let test_item = TestAuthorized {
            id: object::new(ctx(scenario)) 
        };

        free_claim_with_type<TestAuthorized>(
            &test_item,
            scenario,
            utf8(b"01234567890.sui"),
            USER_ADDRESS
        );

        // tries to claim again using the same test_item.
        free_claim_with_type<TestAuthorized>(
            &test_item,
            scenario,
            utf8(b"01234567891.sui"),
            USER_ADDRESS
        );

        burn_authorized(test_item);
        test_end(scenario_val);
    }

    #[test, expected_failure(abort_code = discounts::free_claims::EInvalidCharacterRange)]
    fun test_invalid_size_failure() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;

        let test_item = TestAuthorized {
            id: object::new(ctx(scenario)) 
        };

        free_claim_with_type<TestAuthorized>(
            &test_item,
            scenario,
            utf8(b"012345678.sui"),
            USER_ADDRESS
        );

        burn_authorized(test_item);
        test_end(scenario_val);
    }

    #[test, expected_failure(abort_code = discounts::free_claims::EConfigNotExists)]
    fun register_with_unauthorized_type() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;

        let test_item = TestUnauthorized {
            id: object::new(ctx(scenario))
        };

        free_claim_with_type<TestUnauthorized>(
            &test_item,
            scenario,
            utf8(b"test.sui"),
            USER_ADDRESS
        );

        abort 1337
    }
}
