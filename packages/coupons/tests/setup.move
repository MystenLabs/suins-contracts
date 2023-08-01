
#[test_only]
module coupons::setup {
    use sui::clock::{Self};
    use sui::test_scenario::{Self, Scenario, ctx};
    use coupons::coupons::{Self, CouponsApp, CouponHouse};

    struct TestApp has drop {}
    
    struct UnauthorizedTestApp has drop {}

    const ADMIN_ADDRESS: address = @0xA001;
    const USER_ADDRESS: address =  @0xA002;

    use suins::suins::{Self, AdminCap};
    
    public fun test_init(): Scenario {
        let scenario_val = test_scenario::begin(ADMIN_ADDRESS);
        let scenario = &mut scenario_val;
        {
            let suins = suins::init_for_testing(ctx(scenario));
            // initialize coupon data.
            coupons::init_for_testing(ctx(scenario));
            suins::authorize_app_for_testing<CouponsApp>(&mut suins);
            suins::share_for_testing(suins);
            let clock = clock::create_for_testing(ctx(scenario));
            clock::share_for_testing(clock);
        
        };
        {
            test_scenario::next_tx(scenario, ADMIN_ADDRESS);
            let coupon_house = test_scenario::take_shared<CouponHouse>(scenario);
            // get admin cap
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            // authorize TestApp to CouponHouse.
            coupons::authorize_app<TestApp>(&admin_cap, &mut coupon_house);
            test_scenario::return_to_sender(scenario, admin_cap);
            test_scenario::return_shared(coupon_house);
        };
        scenario_val
    }

    public fun admin_address(): address {
        ADMIN_ADDRESS
    }
    public fun user_address(): address { 
        USER_ADDRESS
    }

    // global getters.

    public fun test_app(): TestApp {
        TestApp {}
    }

    public fun unauthorized_test_app(): UnauthorizedTestApp {
        UnauthorizedTestApp {}
    }
}
