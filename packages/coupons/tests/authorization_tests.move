// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

// A set of tests for the authorization of different apps in the CouponHouse.
#[test_only]
module coupons::app_authorization_tests {

    // use std::string::{utf8, String};
    use sui::test_scenario::{Self};

    use coupons::coupons::{Self, CouponHouse};
    use suins::suins::{AdminCap};
    use coupons::setup::{Self, UnauthorizedTestApp, TestApp, admin, user};

    #[test]
    fun admin_get_app_success() {
        let scenario_val = setup::test_init();
        let scenario = &mut scenario_val;
        // auth style as authorized app
        {
            test_scenario::next_tx(scenario, user());
            let coupon_house = test_scenario::take_shared<CouponHouse>(scenario);
            coupons::app_data_mut<TestApp>(setup::test_app(), &mut coupon_house);
            test_scenario::return_shared(coupon_house);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    fun authorized_app_get_app_success(){
        let scenario_val = setup::test_init();
        let scenario = &mut scenario_val;
        {
            test_scenario::next_tx(scenario, admin());

            let coupon_house = test_scenario::take_shared<CouponHouse>(scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            
            // test app deauthorization.
            coupons::deauthorize_app<TestApp>(&admin_cap, &mut coupon_house);

            // test that the app is indeed non authorized
            assert!(!coupons::is_app_authorized<TestApp>(&coupon_house), 0);
        
            test_scenario::return_to_sender(scenario, admin_cap);
            test_scenario::return_shared(coupon_house);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code=coupons::coupons::EAppNotAuthorized)]
    fun unauthorized_app_failure() {
        let scenario_val = setup::test_init();
        let scenario = &mut scenario_val;
        {
            test_scenario::next_tx(scenario, user());
            let coupon_house = test_scenario::take_shared<CouponHouse>(scenario);
            coupons::app_data_mut<UnauthorizedTestApp>(setup::unauthorized_test_app(), &mut coupon_house);
            test_scenario::return_shared(coupon_house);
        };
        test_scenario::end(scenario_val);
    }
    
}
