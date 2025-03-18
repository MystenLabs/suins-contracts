// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

// A set of tests for the authorization of different apps in the CouponHouse.
#[test_only]
module coupons::app_authorization_tests;

use coupons::{
    coupon_house::{Self, deauthorize_app},
    setup::{Self, TestApp, admin, user, test_init}
};
use sui::test_scenario::{return_shared, return_to_sender, end};
use suins::suins::SuiNS;

#[test]
fun admin_get_app_success() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;
    // auth style as authorized app
    {
        scenario.next_tx(user());
        let mut suins = scenario.take_shared<SuiNS>();
        coupon_house::app_data_mut<TestApp>(&mut suins, setup::test_app());
        return_shared(suins);
    };

    end(scenario_val);
}

#[test]
fun authorized_app_get_app_success() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;
    {
        scenario.next_tx(admin());

        let mut coupon_house = scenario.take_shared();
        let admin_cap = scenario.take_from_sender();

        // test app deauthorization.
        deauthorize_app<TestApp>(&admin_cap, &mut coupon_house);

        // test that the app is indeed non authorized
        assert!(!coupon_house.is_app_authorized<TestApp>(), 0);

        return_to_sender(scenario, admin_cap);
        return_shared(coupon_house);
    };
    end(scenario_val);
}

#[test, expected_failure(abort_code = ::coupons::coupon_house::EAppNotAuthorized)]
fun unauthorized_app_failure() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;
    {
        scenario.next_tx(user());
        let mut suins = scenario.take_shared<SuiNS>();
        coupon_house::app_data_mut(&mut suins, setup::unauthorized_test_app());
        return_shared(suins);
    };
    end(scenario_val);
}
