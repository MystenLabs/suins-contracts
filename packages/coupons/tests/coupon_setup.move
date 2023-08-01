

#[test_only]
module coupons::coupon_setup{
    use std::option;

    use coupons::coupons::{Self, Coupon};
    use coupons::constants;
    use coupons::helpers;

    // A simple 10% discount coupon usable in ANY length
    public fun general_percentage_coupon(): Coupon {
        coupons::new_coupon(
            constants::percentage_discount_type(),
            10,
            helpers::domain_size_rule(1,0),
            option::none(),
            option::none(),
            option::none(),
            option::none(),
        )
    }
    
    // A fixed price coupon working in ANY length, no limits etc.
    public fun fixed_price_coupon(): Coupon {
        coupons::new_coupon(
            constants::fixed_price_discount_type(),
            1_000_000_000,
            helpers::domain_size_rule(1,0),
            option::none(),
            option::none(),
            option::none(),
            option::none(),
        )
    }

    // This coupon is only claimable once.
    public fun max_claims_coupon(): Coupon {
        coupons::new_coupon(
            constants::percentage_discount_type(),
            10,
            helpers::domain_size_rule(1,0),
            option::some(1),
            option::none(),
            option::none(),
            option::none(),
        )
    }
}
