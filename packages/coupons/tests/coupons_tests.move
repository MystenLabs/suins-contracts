

module coupons::coupon_tests {
    use sui::test_scenario::{Self, Scenario};

    use coupons::coupons::{Self, CouponHouse};

    // test dependencies.
    use coupons::setup::{Self, TestApp};
    use coupons::coupon_setup;

    // populate some coupons in the test_scenario.
    fun populate_coupons(scenario: &mut Scenario) {
         {
            test_scenario::next_tx(scenario, setup::user_address());
            let coupon_house = test_scenario::take_shared<CouponHouse>(scenario);

            coupons::app_data_mut<TestApp>(setup::test_app(), &mut coupon_house);

            // coupon_setup::general_percentage_coupon();

            test_scenario::return_shared(coupon_house);
        };
    }

    // test the e2e experience for coupons!
    #[test]
    fun test_e2e() {
        let scenario_val = setup::test_init();
        let scenario = &mut scenario_val;
        {
            test_scenario::next_tx(scenario, setup::user_address());
            let coupon_house = test_scenario::take_shared<CouponHouse>(scenario);

            // let app = coupons::app_data_mut<TestApp>(setup::test_app(), &mut coupon_house);

            // let coupon = coupon_setup::general_percentage_coupon();

            test_scenario::return_shared(coupon_house);
        };
        test_scenario::end(scenario_val);
    }
}
