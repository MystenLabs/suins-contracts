// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module discounts::discount_tests;

use day_one::day_one::{Self, DayOne};
use discounts::{discounts::{Self, RegularDiscountsApp}, house::{Self, DiscountHouse}};
use sui::{clock, test_scenario::{Self as ts, Scenario, ctx}, test_utils::{destroy, assert_eq}};
use suins::{
    constants,
    payment::{Self, PaymentIntent},
    pricing_config::{Self, PricingConfig},
    registry,
    suins::{Self, SuiNS, AdminCap}
};

// an authorized type to test.
public struct TestAuthorized has copy, drop, store {}

// another authorized type to test.
public struct AnotherAuthorized has copy, drop, store {}

// an unauthorized type to test.
public struct TestUnauthorized has copy, drop, store {}

const SUINS_ADDRESS: address = @0xA001;
const USER_ADDRESS: address = @0xA002;

fun test_init(): Scenario {
    let mut scenario_val = ts::begin(SUINS_ADDRESS);
    let scenario = &mut scenario_val;
    {
        let mut suins = suins::init_for_testing(scenario.ctx());
        suins.authorize_app_for_testing<RegularDiscountsApp>();
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
        discounts::authorize_type<TestAuthorized>(
            &mut discount_house,
            &admin_cap,
            test_config(false), // we get 5, 3, 2% discounts for 3, 4, 5+ chars.
        );
        // a much cheaper price for another type.
        discounts::authorize_type<AnotherAuthorized>(
            &mut discount_house,
            &admin_cap,
            test_config(
                true,
            ), // we get 50, 30, 20% discounts for 3, 4, 5+ chars.
        );
        discounts::authorize_type<DayOne>(
            &mut discount_house,
            &admin_cap,
            test_config(
                true,
            ), // we get 50, 30, 20% discounts for 3, 4, 5+ chars.
        );

        registry::init_for_testing(&admin_cap, &mut suins, scenario.ctx());

        ts::return_shared(discount_house);
        ts::return_shared(suins);
        scenario.return_to_sender(admin_cap);
    };
    scenario_val
}

#[test]
fun test_e2e() {
    init_purchase!(USER_ADDRESS, b"fivel.sui", |discount_house, suins, intent, scenario| {
        assert_eq(
            intent.request_data().base_amount(),
            50 * constants::mist_per_sui(),
        );

        discounts::apply_percentage_discount(
            discount_house,
            intent,
            suins,
            &mut TestAuthorized {},
            scenario.ctx(),
        );

        assert_eq(
            intent.request_data().base_amount(),
            40 * constants::mist_per_sui(),
        );
        assert_eq(intent.request_data().discounts_applied().size(), 1);
        assert_eq(intent.request_data().discount_applied(), true);
    });
}

#[test]
fun register_day_one() {
    init_purchase!(USER_ADDRESS, b"wow.sui", |discount_house, suins, intent, scenario| {
        assert_eq(
            intent.request_data().base_amount(),
            1200 * constants::mist_per_sui(),
        );

        let mut day_one = day_one::mint_for_testing(scenario.ctx());
        day_one.set_is_active_for_testing(true);

        discounts::apply_day_one_discount(
            discount_house,
            intent,
            suins,
            &mut day_one,
            scenario.ctx(),
        );

        assert_eq(
            intent.request_data().base_amount(),
            840 * constants::mist_per_sui(),
        );
        assert_eq(intent.request_data().discounts_applied().size(), 1);
        assert_eq(intent.request_data().discount_applied(), true);

        day_one.burn_for_testing();
    });
}

#[test, expected_failure(abort_code = ::discounts::discounts::EConfigNotExists)]
fun register_with_unauthorized_type() {
    init_purchase!(USER_ADDRESS, b"fivel.sui", |discount_house, suins, intent, scenario| {
        discounts::apply_percentage_discount(
            discount_house,
            intent,
            suins,
            &mut TestUnauthorized {},
            scenario.ctx(),
        );
    });
}

#[test, expected_failure(abort_code = ::discounts::discounts::ENotValidForDayOne)]
fun use_day_one_for_casual_flow_failure() {
    init_purchase!(USER_ADDRESS, b"fivel.sui", |discount_house, suins, intent, scenario| {
        let mut day_one = day_one::mint_for_testing(scenario.ctx());

        discounts::apply_percentage_discount(
            discount_house,
            intent,
            suins,
            &mut day_one,
            scenario.ctx(),
        );
        day_one.burn_for_testing();
    });
}

#[test, expected_failure(abort_code = ::discounts::discounts::ENotActiveDayOne)]
fun use_inactive_day_one_failure() {
    init_purchase!(USER_ADDRESS, b"fivel.sui", |discount_house, suins, intent, scenario| {
        let mut day_one = day_one::mint_for_testing(scenario.ctx());
        day_one.set_is_active_for_testing(false);

        discounts::apply_day_one_discount(
            discount_house,
            intent,
            suins,
            &mut day_one,
            scenario.ctx(),
        );
        day_one.burn_for_testing();
    });
}

macro fun init_purchase(
    $addr: address,
    $domain_name: vector<u8>,
    $f: |&mut DiscountHouse, &mut SuiNS, &mut PaymentIntent, &mut Scenario|,
) {
    let addr = $addr;
    let dm = $domain_name;

    let mut scenario = test_init();
    scenario.next_tx(addr);

    // take the discount house
    let mut discount_house = scenario.take_shared<DiscountHouse>();
    let mut suins = scenario.take_shared<SuiNS>();
    let mut intent = payment::init_registration(&mut suins, dm.to_string());

    $f(&mut discount_house, &mut suins, &mut intent, &mut scenario);

    destroy(intent);
    destroy(discount_house);
    destroy(suins);

    scenario.end();
}

fun test_config(is_large: bool): PricingConfig {
    let multiply = if (is_large) {
        3
    } else {
        1
    };

    pricing_config::new(
        vector[
            pricing_config::new_range(vector[3, 3]),
            pricing_config::new_range(vector[4, 4]),
            pricing_config::new_range(vector[5, 63]),
        ],
        vector[10 * multiply, 15 * multiply, 20 * multiply],
    )
}
