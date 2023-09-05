// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

// A module with a couple of helpers for validation of coupons
// validation of names etc.
module coupons::rules {

    use std::vector;
    use std::option::{Self, Option};

    use sui::clock::{Self, Clock};

    use coupons::constants;

    // Errors
    /// Error when you try to create a DomainLengthRule with invalid type.
    const EInvalidRuleCode: u64 = 0;
    /// Error when you try to use a coupon that isn't valid for these years.
    const ENotValidYears: u64 = 1;
    /// Error when you try to use a coupon which doesn't match to the domain's size.
    const EInvalidForDomainLength: u64 = 2;
    /// Error when you try to use a domain that has used all it's available claims.
    const ENoMoreAvailableClaims: u64 = 3;
    /// Error when you try to create a percentage discount coupon with invalid percentage amount.
    const EInvalidAmount: u64 = 4;
    /// Error when you try to create a coupon with invalid type.
    const EInvalidType: u64 = 5;
    /// Error when you try to use a coupon without the matching address
    const EInvalidUser: u64 = 6;
    /// Error when coupon has expired
    const ECouponExpired: u64 = 7;

    /// Constants
    // A rule that allows any length
    const ANY_NAME_RULE: u8 = 0;
    // Allow only the length of a specific size (e..g only 20 digits)
    const FIXED_LENGTH_RULE: u8 = 1;
    // Allow only the length >= size (e.g. >= 20 digits)
    const MIN_CHAR_RULE: u8 = 2;
    // Allow only the length <= size (e.g. <=4 digits)
    const MAX_CHAR_RULE: u8 = 3;

    /// The Struct that holds the coupon's rules.
    /// All rules are combined in `AND` fashion. 
    /// All of the checks have to pass for a coupon to be used.
    struct CouponRules has copy, store, drop {
        size_rule: Option<DomainLengthRule>,
        available_claims: Option<u16>,
        user: Option<address>,
        expiration: Option<u64>,
        max_years: Option<u8>
    }

     /// A simple struct that contains a characters rule
     /// Using this format, we can create all the possible combinations on teh domain length.
     /// `any_name_rule`: allows the coupon to be claimable for all domain lengths
     /// `fixed_length_rule`: allows the coupon to be claimable only for domains equal to `length`.
     /// `min_char_rule`: allows the coupon to be claimable only for domains >= `length`
     /// `max_char_rule`: allows the coupon to be claimable only for domains <= `length`
    struct DomainLengthRule has copy, store, drop {
        type: u8, // any of the length rule types [fixed_legth_rule, min_char_rule, max_char_rule]. Could have been enum.
        length: u8 // Our names are [3,64] length.
    }

    // Used in PTB when creating a coupon
    public fun domain_size_rule(type: u8, length: u8): DomainLengthRule {
        assert!(vector::contains(&constants::name_rules(), &type), EInvalidRuleCode);

        DomainLengthRule {
            type,
            length
        }
    }

    /// This is used in a PTB when creating a coupon.
    /// Creates a CouponRules object to be used to create a coupon.
    /// We have a fixed set of Rules for our coupons:
    /// 1. Length rule (described on constants file)
    /// All the other cases are optional, and work in `AND` fashion (all these must be valid for a coupon to be claimable)
    /// 2. Max available claims 
    /// 3. Only for a specific address
    /// 4. Might have an expiration date.
    /// 5. Might be valid only for registrations up to a maximum year.
    public fun new_coupon_rules(
        size_rule: Option<DomainLengthRule>,
        available_claims: Option<u16>,
        user: Option<address>,
        expiration: Option<u64>,
        max_years: Option<u8>
    ): CouponRules {
        CouponRules {
            size_rule, available_claims, user, expiration, max_years
        }
    }

    // A convenient helper to create a zero rule `CouponRules` object.
    // This helps generate a coupon that can be used without any of the restrictions.
    public fun new_empty_rules(): CouponRules {
        CouponRules {
            size_rule: option::none(),
            available_claims: option::none(),
            user: option::none(),
            expiration: option::none(),
            max_years: option::none()
        }
    }

    /// If the rules count `available_claims`, we decrease it.
    /// Aborts if there are no more available claims on that coupon. 
    /// We shouldn't get here ever, as we're checking this on the coupon creation, but
    /// keeping it as a sanity check (e.g. created a coupon with 0 available claims).
    public fun decrease_available_claims(rules: &mut CouponRules) {
        if(option::is_some(&rules.available_claims)){
            assert!(has_available_claims(rules), ENoMoreAvailableClaims);
               // Decrease available claims by 1.
            let available_claims = *option::borrow(&rules.available_claims);
            option::swap(&mut rules.available_claims, available_claims - 1);
        }
    }

    // Checks whether a coupon has available claims. 
    // Returns true if the rule is not set OR it has used all the available claims.
    public fun has_available_claims(rules: &CouponRules): bool {
        if(option::is_none(&rules.available_claims)) return true;
        *option::borrow(&rules.available_claims) > 0
    }

    // Assertion helper for the validity of years.
    public fun assert_coupon_valid_for_domain_years(rules: &CouponRules, target: u8) {
        assert!(is_coupon_valid_for_domain_years(rules, target), ENotValidYears);
    }

    // Checks if a target amount of years is valid for claim.
    public fun is_coupon_valid_for_domain_years(rules: &CouponRules, target: u8): bool {
        if(option::is_none(&rules.max_years)) return true;
        return target <= *option::borrow(&rules.max_years)
    }

    public fun assert_is_valid_discount_type(type: u8) {
        assert!(vector::contains(&constants::discount_rule_types(), &type), EInvalidType);
    }
    
    // verify that we are creating the coupons correctly (based on amount & type).
    // for amounts, if we have a percentage discount, our max num is 100.
    public fun assert_is_valid_amount(type: u8, amount: u64) {
        assert!(amount > 0, EInvalidAmount); // protect from division by 0. 0 doesn't make sense in any scenario.
        if(type == constants::percentage_discount_type()){
            assert!(amount<=100, EInvalidAmount)
        }
    }

    // We check a DomainSize Rule against the length of a domain.
    // We return if the length is valid based on that.
    public fun assert_coupon_valid_for_domain_size(rules: &CouponRules, length: u8) {
        assert!(is_coupon_valid_for_domain_size(rules, length), EInvalidForDomainLength)
    }
    /// We check the length of the name based on the domain length rule
    public fun is_coupon_valid_for_domain_size(rules: &CouponRules, length: u8): bool {
        let optional_rule = &rules.size_rule;

        // If the DomainLengthRule is not set, we pass this rule test.
        if(!option::is_some(optional_rule)) return true;

        // Get rule.
        let rule = *option::borrow(optional_rule);

        // fixed name rule -> length must be equal to the rule's size
        if(rule.type == constants::fixed_length_rule()) return length == rule.length;
        // min characters rule -> Length of the name must be greater or equal to the rule's length
        if(rule.type == constants::min_char_rule()) return length >= rule.length;
        // max characters rule -> Length of the name must be less than or equal to the rule's length
        if(rule.type == constants::max_char_rule()) return length <= rule.length;

        // We default to fault!
        false
    }


    // We check that the coupon is valid for the specified address.
    /// Throws `EInvalidUser` error if it has expired.
    public fun assert_coupon_valid_for_address(rules: &CouponRules, user: address) {
        assert!(is_coupon_valid_for_address(rules, user), EInvalidUser);
    }
    /// Check that the domain is valid for the specified address
    public fun is_coupon_valid_for_address(rules: &CouponRules, user: address): bool {
        if(option::is_none(&rules.user)) return true;
        *option::borrow(&rules.user) == user
    }

    /// Simple assertion for the coupon expiration. 
    /// Throws `ECouponExpired` error if it has expired.
    public fun assert_coupon_is_not_expired(rules: &CouponRules, clock: &Clock) {
        assert!(!is_coupon_expired(rules, clock), ECouponExpired);
    }

    /// Check whether a coupon has expired 
    public fun is_coupon_expired(rules: &CouponRules, clock: &Clock): bool {
        if(option::is_none(&rules.expiration)) return false;

        clock::timestamp_ms(clock) > *option::borrow(&rules.expiration)
    }
}
