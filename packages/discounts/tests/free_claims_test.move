// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module discounts::free_claims_test;

use day_one::day_one::{Self, DayOne};
use discounts::free_claims::{Self, FreeClaimsApp};
use discounts::house::{Self, DiscountHouse};
use sui::clock;
use sui::test_scenario::{Self as ts, Scenario, ctx};
use sui::test_utils::{destroy, assert_eq};
use suins::constants;
use suins::payment::{Self, PaymentIntent};
use suins::pricing_config;
use suins::registry;
use suins::suins::{Self, SuiNS, AdminCap};

// an authorized type to test.
public struct TestAuthorized has key, store {
    id: UID,
}

// another authorized type to test.
public struct AnotherAuthorized has key {
    id: UID,
}

// an unauthorized type to test.
public struct TestUnauthorized has key {
    id: UID,
}

const SUINS_ADDRESS: address = @0xA001;
const USER_ADDRESS: address = @0xA002;

fun test_init(): Scenario {
    let mut scenario_val = ts::begin(SUINS_ADDRESS);
    let scenario = &mut scenario_val;
    {
        let mut suins = suins::init_for_testing(scenario.ctx());
        suins.authorize_app_for_testing<FreeClaimsApp>();
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
        free_claims::authorize_type<TestAuthorized>(
            &mut discount_house,
            &admin_cap,
            pricing_config::new_range(vector[5, 63]), // only 5+ letter names
            scenario.ctx(),
        );
        // a much cheaper price for another type.
        free_claims::authorize_type<AnotherAuthorized>(
            &mut discount_house,
            &admin_cap,
            pricing_config::new_range(vector[
                3,
                4,
            ]), // only 3 and 4 letter names
            scenario.ctx(),
        );

        free_claims::authorize_type<DayOne>(
            &mut discount_house,
            &admin_cap,
            pricing_config::new_range(vector[3, 63]), // any actual
            scenario.ctx(),
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
    init_purchase!(
        USER_ADDRESS,
        b"fivel.sui",
        |discount_house, suins, intent, scenario| {
            assert_eq(
                intent.request_data().base_amount(),
                50 * constants::mist_per_sui(),
            );

            let obj = TestAuthorized { id: object::new(scenario.ctx()) };

            free_claims::free_claim(
                discount_house,
                suins,
                intent,
                &obj,
                scenario.ctx(),
            );

            assert_eq(intent.request_data().base_amount(), 0);
            assert_eq(intent.request_data().discounts_applied().size(), 1);
            assert_eq(intent.request_data().discount_applied(), true);
            destroy(obj);
        },
    );
}

#[test]
fun register_day_one() {
    init_purchase!(
        USER_ADDRESS,
        b"wow.sui",
        |discount_house, suins, intent, scenario| {
            assert_eq(
                intent.request_data().base_amount(),
                1200 * constants::mist_per_sui(),
            );

            let mut day_one = day_one::mint_for_testing(scenario.ctx());
            day_one.set_is_active_for_testing(true);

            free_claims::free_claim_with_day_one(
                discount_house,
                suins,
                intent,
                &day_one,
                scenario.ctx(),
            );

            assert_eq(intent.request_data().base_amount(), 0);
            assert_eq(intent.request_data().discounts_applied().size(), 1);
            assert_eq(intent.request_data().discount_applied(), true);

            day_one.burn_for_testing();
        },
    );
}

#[test]
fun test_deauthorize_discount() {
    let mut scenario = test_init();
    scenario.next_tx(SUINS_ADDRESS);
    let mut discount_house = scenario.take_shared<DiscountHouse>();
    let admin_cap = scenario.take_from_sender<AdminCap>();

    let table = free_claims::deauthorize_type<TestAuthorized>(
        &mut discount_house,
        &admin_cap,
    );
    sui::transfer::public_transfer(table, scenario.ctx().sender());

    ts::return_shared(discount_house);
    scenario.return_to_sender(admin_cap);

    scenario.end();
}

#[
    test,
    expected_failure(
        abort_code = ::discounts::free_claims::EConfigNotExists,
    ),
]
fun register_with_unauthorized_type() {
    init_purchase!(
        USER_ADDRESS,
        b"fivel.sui",
        |discount_house, suins, intent, scenario| {
            let unauthorized = TestUnauthorized {
                id: object::new(scenario.ctx()),
            };
            free_claims::free_claim(
                discount_house,
                suins,
                intent,
                &unauthorized,
                scenario.ctx(),
            );
            destroy(unauthorized);
        },
    );
}

#[
    test,
    expected_failure(
        abort_code = ::discounts::free_claims::EAlreadyClaimed,
    ),
]
#[allow(dead_code)]
fun test_already_claimed() {
    init_purchase!(
        USER_ADDRESS,
        b"fivel.sui",
        |discount_house, suins, intent, scenario| {
            assert_eq(
                intent.request_data().base_amount(),
                50 * constants::mist_per_sui(),
            );

            let obj = TestAuthorized { id: object::new(scenario.ctx()) };

            free_claims::free_claim(
                discount_house,
                suins,
                intent,
                &obj,
                scenario.ctx(),
            );

            free_claims::free_claim(
                discount_house,
                suins,
                intent,
                &obj,
                scenario.ctx(),
            );
            abort 1337
        },
    );
}

#[
    test,
    expected_failure(
        abort_code = ::discounts::free_claims::EInvalidCharacterRange,
    ),
]
#[allow(dead_code)]
fun test_domain_out_of_range() {
    init_purchase!(
        USER_ADDRESS,
        b"fiv.sui",
        |discount_house, suins, intent, scenario| {
            let obj = TestAuthorized { id: object::new(scenario.ctx()) };

            free_claims::free_claim(
                discount_house,
                suins,
                intent,
                &obj,
                scenario.ctx(),
            );

            abort 1337
        },
    );
}

#[test, expected_failure(abort_code = ::discounts::free_claims::EConfigExists)]
fun test_authorize_config_twice() {
    let mut scenario = test_init();
    scenario.next_tx(SUINS_ADDRESS);
    let mut discount_house = scenario.take_shared<DiscountHouse>();
    let admin_cap = scenario.take_from_sender<AdminCap>();

    free_claims::authorize_type<TestAuthorized>(
        &mut discount_house,
        &admin_cap,
        pricing_config::new_range(vector[5, 63]),
        scenario.ctx(),
    );

    abort 1337
}

#[test, expected_failure(abort_code = ::discounts::house::EInvalidVersion)]
fun test_version_togge() {
    let mut scenario = test_init();
    scenario.next_tx(SUINS_ADDRESS);
    let mut discount_house = scenario.take_shared<DiscountHouse>();
    let admin_cap = scenario.take_from_sender<AdminCap>();

    discount_house.set_version(&admin_cap, 255);

    discount_house.assert_version_is_valid();

    abort 1337
}

#[
    test,
    expected_failure(
        abort_code = ::discounts::free_claims::EConfigNotExists,
    ),
]
fun test_deauthorize_non_existing_config() {
    let mut scenario = test_init();
    scenario.next_tx(SUINS_ADDRESS);
    let mut discount_house = scenario.take_shared<DiscountHouse>();
    let admin_cap = scenario.take_from_sender<AdminCap>();

    let _table = free_claims::deauthorize_type<TestUnauthorized>(
        &mut discount_house,
        &admin_cap,
    );

    abort 1337
}

#[
    test,
    expected_failure(
        abort_code = ::discounts::free_claims::ENotValidForDayOne,
    ),
]
fun use_day_one_for_casual_flow_failure() {
    init_purchase!(
        USER_ADDRESS,
        b"fivel.sui",
        |discount_house, suins, intent, scenario| {
            let day_one = day_one::mint_for_testing(scenario.ctx());

            free_claims::free_claim(
                discount_house,
                suins,
                intent,
                &day_one,
                scenario.ctx(),
            );
            day_one.burn_for_testing();
        },
    );
}

#[
    test,
    expected_failure(
        abort_code = ::discounts::free_claims::ENotActiveDayOne,
    ),
]
fun use_inactive_day_one_failure() {
    init_purchase!(
        USER_ADDRESS,
        b"fivel.sui",
        |discount_house, suins, intent, scenario| {
            let mut day_one = day_one::mint_for_testing(scenario.ctx());
            day_one.set_is_active_for_testing(false);

            free_claims::free_claim_with_day_one(
                discount_house,
                suins,
                intent,
                &day_one,
                scenario.ctx(),
            );
            day_one.burn_for_testing();
        },
    );
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
