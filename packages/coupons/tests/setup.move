// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module coupons::setup {
    use std::option;
    use std::string::{utf8, String};

    use sui::clock::{Self, Clock};
    use sui::test_scenario::{Self, Scenario, ctx};
    use sui::tx_context::{TxContext};
    use sui::sui::SUI;
    use sui::coin::{Self};
    use sui::transfer;
    
    use coupons::coupons::{Self, CouponsApp,Data, CouponHouse};
    use coupons::rules::{Self};
    use coupons::constants;
    use coupons::range;

    public struct TestApp has drop {}
    
    public struct UnauthorizedTestApp has drop {}

    const MIST_PER_SUI: u64 = 1_000_000_000;

    const ADMIN_ADDRESS: address = @0xA001;
    const USER_ADDRESS: address =  @0xA002;
    const USER_2_ADDRESS: address = @0xA003;

    use suins::suins::{Self, AdminCap, SuiNS};
    use suins::registry;
    
    public fun test_init(): Scenario {
        let mut scenario_val = test_scenario::begin(ADMIN_ADDRESS);
        let scenario = &mut scenario_val;
        {
            let mut suins = suins::init_for_testing(ctx(scenario));
            // initialize coupon data.
            coupons::init_for_testing(ctx(scenario));
            suins::authorize_app_for_testing<CouponsApp>(&mut suins);
            suins::share_for_testing(suins);
            let clock = clock::create_for_testing(ctx(scenario));
            clock::share_for_testing(clock);
        };
        {
            test_scenario::next_tx(scenario, ADMIN_ADDRESS);
            let mut coupon_house = test_scenario::take_shared<CouponHouse>(scenario);
        
            // get admin cap
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let mut suins = test_scenario::take_shared<SuiNS>(scenario);
            registry::init_for_testing(&admin_cap, &mut suins, ctx(scenario));
            // authorize TestApp to CouponHouse.
            coupons::authorize_app<TestApp>(&admin_cap, &mut coupon_house);
            test_scenario::return_to_sender(scenario, admin_cap);
            test_scenario::return_shared(coupon_house);
            test_scenario::return_shared(suins);
        };
        scenario_val
    }


    public fun admin(): address {
        ADMIN_ADDRESS
    }
    public fun user(): address { 
        USER_ADDRESS
    }
    public fun user_two(): address {
        USER_2_ADDRESS
    }
    public fun mist_per_sui(): u64 {
        MIST_PER_SUI
    }

    // global getters.

    public fun test_app(): TestApp {
        TestApp {}
    }

    public fun unauthorized_test_app(): UnauthorizedTestApp {
        UnauthorizedTestApp {}
    }

       /// A helper to add a bunch of coupons (with different setups) that we can use on the coupon tests.
    public fun populate_coupons(data_mut: &mut Data, ctx: &mut TxContext) {

        // 5 SUI DISCOUNT, ONLY CLAIMABLE TWICE
        coupons::app_add_coupon(
            data_mut, 
            utf8(b"5_SUI_DISCOUNT"), 
            constants::fixed_price_discount_type(),
            5 * MIST_PER_SUI,
            rules::new_coupon_rules(
                option::none(), // domain length rule,
                option::some(2), // available claims
                option::none(), // user specific
                option::none(), // expiration timestamp
                option::none() // available years
            ),
            ctx
        );

        // 25% DISCOUNT, ONLY FOR 2 YEARS OR LESS REGISTRATIONS
        coupons::app_add_coupon(
            data_mut, 
            utf8(b"25_PERCENT_DISCOUNT_MAX_2_YEARS"), 
            constants::percentage_discount_type(), 
            25, // 25%
            rules::new_coupon_rules(
                option::none(), // domain length rule,
                option::none(), // claimable as many times as needed
                option::none(), // user specific
                option::none(), // expiration timestamp
                option::some(range::new(1,2)) // Maximum of 2 years
            ),
            ctx
        );

        // 25% DISCOUNT, only claimable ONCE by a specific user
        coupons::app_add_coupon(
            data_mut,
            utf8(b"25_PERCENT_DISCOUNT_USER_ONLY"),
            constants::percentage_discount_type(),
            25, // 25%
            rules::new_coupon_rules(
                option::none(), // domain length rule,
                option::some(1), // claimable once.
                option::some(user()), // ONLY CLAIMABLE BY SPECIFIC USER
                option::none(), // expiration timestamp
                option::none() // any years
            ),
            ctx
        );

        // 50% DISCOUNT, only claimable only for names > 5 digits
        coupons::app_add_coupon(
            data_mut,
            utf8(b"50_PERCENT_5_PLUS_NAMES"),
            constants::percentage_discount_type(),
            50, // 25%
            rules::new_coupon_rules(
                // Only usable for domains with length >= 5. This discount wouldn't be applicable for others.
                option::some(range::new(5, 63)), // domain length rule,
                option::some(1), // claimable once.
                option::none(), // claimable by anyone
                option::none(), // expiration timestamp
                option::none() // Maximum of 2 years
            ),
            ctx
        );

        // 50% DISCOUNT, only for 3 digit names
        coupons::app_add_coupon(
            data_mut,
            utf8(b"50_PERCENT_3_DIGITS"),
            constants::percentage_discount_type(),
            50, // 50%
            rules::new_coupon_rules(
                // Only usable for domains with fixed length of 3 digits.
                option::some(range::new(3,3)), // domain length rule,
                option::none(), // claimable once.
                option::none(), // claimable by anyone
                option::some(1), // expiration timestamp.
                option::none() // no maximum set
            ),
            ctx
        );

        // 50% DISCOUNT, has all rules so we can test combinations!
        coupons::app_add_coupon(
            data_mut,
            utf8(b"50_DISCOUNT_SALAD"),
            constants::percentage_discount_type(),
            50, // 50%
            rules::new_coupon_rules(
                // Only usable for 3 or 4 digit names (max char = 4)
                option::some(range::new(3,4)), // domain length rule,
                option::some(1), // claimable once.
                option::some(user()), // claimable a specific address
                option::some(1), // expires at 1 clock tick
                option::some(range::new(1, 2)) // Maximum of 2 years
            ),
            ctx
        );

        // THESE last two are just for easy coverage.
        // We just add + remove the coupon immediately.
        coupons::app_add_coupon(data_mut, utf8(b"REMOVE_FOR_COVERAGE"), constants::percentage_discount_type(), 50, rules::new_empty_rules(), ctx);
        coupons::app_remove_coupon(data_mut, utf8(b"REMOVE_FOR_COVERAGE"));
    }

    // Adds a 0 rule coupon that gives 15% discount to test admin additions.
    public fun admin_add_coupon(code_name: String, `type`: u8, value: u64, scenario: &mut Scenario) {
        test_scenario::next_tx(scenario, admin());
        let mut coupon_house = test_scenario::take_shared<CouponHouse>(scenario);
        let cap = test_scenario::take_from_sender<AdminCap>(scenario);
        coupons::admin_add_coupon(
            &cap,
            &mut coupon_house,
            code_name,
            `type`,
            value,
            rules::new_empty_rules(),
            ctx(scenario)
        );
        test_scenario::return_to_sender(scenario, cap);
        test_scenario::return_shared(coupon_house);
    }
    // Adds a 0 rule coupon that gives 15% discount to test admin additions.
    public fun admin_remove_coupon(code_name: String, scenario: &mut Scenario) {
        test_scenario::next_tx(scenario, admin());
        let mut coupon_house = test_scenario::take_shared<CouponHouse>(scenario);
        let cap = test_scenario::take_from_sender<AdminCap>(scenario);
        coupons::admin_remove_coupon(
            &cap,
            &mut coupon_house,
            code_name
        );
        test_scenario::return_to_sender(scenario, cap);
        test_scenario::return_shared(coupon_house);
    }

    // Internal helper that tries to claim a name using a coupon.
    // Test prices are:
    // 3 digit -> 1200
    // 4 digit -> 200
    // 5 digit -> 50
    // A helper to easily register a name with a coupon code.
    public fun register_with_coupon(coupon_code: String, domain_name: String, no_years: u8, amount: u64, clock_value: u64, user: address, scenario: &mut Scenario) {
        test_scenario::next_tx(scenario, user);
        let mut clock = test_scenario::take_shared<Clock>(scenario);
        clock::increment_for_testing(&mut clock, clock_value);
        let mut coupon_house = test_scenario::take_shared<CouponHouse>(scenario);
        let mut suins = test_scenario::take_shared<SuiNS>(scenario);

        let payment = coin::mint_for_testing<SUI>(amount, ctx(scenario));

        let nft = coupons::register_with_coupon(
            &mut coupon_house, 
            &mut suins, 
            coupon_code, 
            domain_name, 
            no_years,
            payment,
            &clock,
            ctx(scenario)
        );

        transfer::public_transfer(nft, user);
        test_scenario::return_shared(coupon_house);
        test_scenario::return_shared(suins);
        test_scenario::return_shared(clock);
    }
}
