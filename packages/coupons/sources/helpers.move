// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

// A module with a couple of helpers for validation of coupons
// validation of names etc.
module coupons::helpers {

    use std::vector;
    use std::option::{Self, Option};

    use coupons::constants;

    // Errors
    const EInvalidRuleCode: u64 = 0;
    const ENotValidYears: u64 = 1;
    const ENotValidCouponForDomain: u64 = 2;

     // A simple struct that contains a characters rule
    struct DomainSizeRule has copy, store, drop {
        type: u8, // any of the types [any_name_rule, fixed_legth_rule, min_char_rule, max_char_rule]. Could have been enum :)
        length: u8 // Our names are [3,64] length anyways.
    }

    // Can be used in PTB when creating a coupon.
    public fun domain_size_rule(type: u8, length: u8): DomainSizeRule {
        assert!(vector::contains(&constants::name_rules(), &type), EInvalidRuleCode);

        DomainSizeRule {
            type,
            length
        }
    }


    // Assertion helper for the validity of years.
    public fun assert_is_coupon_valid_for_domain_years(target: u8, max_value: Option<u8>) {
        assert!(is_coupon_valid_for_domain_years(target, max_value), ENotValidYears);
    }
    // Checks if a target amount of years is valid for claim.
    public fun is_coupon_valid_for_domain_years(target: u8, max_value: Option<u8>): bool {
        if(option::is_none(&max_value)) return true;
        return target < *option::borrow(&max_value)
    }


    // verify that we are creating the coupons correctly (based on amount & type).
    // for amounts, if we have a percentage discount, our max num is 100.
    public fun is_valid_amount(type: u8, amount: u64): bool {
        if(type == constants::percentage_discount_type()) return amount <= 100;
        true
    }

    // We check a DomainSize Rule against the length of a domain.
    // We return if the length is valid based on that.
    public fun assert_is_coupon_valid_for_domain_size(length: u8, rule: DomainSizeRule) {
        assert!(is_coupon_valid_for_domain_size(length, rule), ENotValidCouponForDomain)
    }
    public fun is_coupon_valid_for_domain_size(length: u8, rule: DomainSizeRule): bool {
        if(rule.type == constants::any_name_rule()) return true;
        if(rule.type == constants::fixed_length_rule()) return length == rule.length;
        if(rule.type == constants::min_char_rule()) return length >= rule.length;
        if(rule.type == constants::max_char_rule()) return length <= rule.length;

        false
    }
}
