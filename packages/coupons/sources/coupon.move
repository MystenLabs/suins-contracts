module coupons::coupon {

    use coupons::{
        rules::{Self, CouponRules},
        constants
    };

    /// A Coupon has a type, a value and a ruleset.
    /// - `Rules` are defined on the module `rules`, and covers a variety of everything we needed for the service.
    /// - `kind` is a u8 constant, defined on `constants` which makes a coupon fixed price or discount percentage
    /// - `value` is a u64 constant, which can be in the range of (0,100] for discount percentage, or any value > 0 for fixed price.
    public struct Coupon has copy, store, drop {
        kind: u8, // 0 -> Percentage Discount | 1 -> Fixed Discount
        amount: u64, // if type == 0, we need it to be between 0, 100. We only allow int stlye (not 0.5% discount).
        rules: CouponRules, // A list of base Rules for the coupon.
    }

    /// An internal function to create a coupon object.
    public(package) fun new(
        kind: u8,
        amount: u64,
        rules: CouponRules,
        _ctx: &mut TxContext
    ): Coupon {
        rules::assert_is_valid_amount(kind, amount);
        rules::assert_is_valid_discount_type(kind);
        Coupon {
            kind, amount, rules
        }
    }

    public(package) fun rules(coupon: &Coupon): &CouponRules {
        &coupon.rules
    }

    public(package) fun rules_mut(coupon: &mut Coupon): &mut CouponRules {
        &mut coupon.rules
    }

    /// A helper to calculate the final price after the discount.
    public(package) fun calculate_sale_price(coupon: &Coupon, price: u64): u64 {
        // If it's fixed price, we just deduce the amount.
        if(coupon.kind == constants::fixed_price_discount_type()){
            if(coupon.amount > price) return 0; // protect underflow case.
            return price - coupon.amount
        };

        // If it's discount price, we calculate the discount 
        let discount =  (((price as u128) * (coupon.amount as u128) / 100) as u64);
        // then remove it from the sale price.
        price - discount
    }
}
