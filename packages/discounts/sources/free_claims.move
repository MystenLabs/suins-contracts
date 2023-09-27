// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// A module that allows claiming names of a set length for free by presenting an object T.
/// Each `T` can have a separate configuration for a discount percentage.
/// If a `T` doesn't exist, registration will fail.
///
/// Can be called only when promotions are active for a specific type T.
/// Activation / deactivation happens through PTBs.
module discounts::free_claims {

    use std::vector;
    use std::string;

    use std::string::{String};
    use std::type_name::{Self as type};

    use sui::object::{Self, UID, ID};
    use sui::tx_context::{TxContext};

    use sui::dynamic_field::{Self as df};
    use sui::clock::{Clock};
    use sui::table::{Self, Table};

    use suins::domain::{Self, Domain};
    use suins::suins::{AdminCap, SuiNS};
    use suins::suins_registration::SuinsRegistration;

    use discounts::house::{Self, DiscountHouse};

    use day_one::day_one::{DayOne, is_active};

    /// A configuration already exists
    const EConfigExists: u64 = 1;
    /// A configuration doesn't exist
    const EConfigNotExists: u64 = 2;
    /// Invalid length array
    const EInvalidCharacterRange: u64 = 3;
    /// Tries to use DayOne on regular register flow.
    const ENotValidForDayOne: u64 = 5;
    /// Tries to claim with a non active DayOne
    const ENotActiveDayOne: u64 = 6;

    /// A key to authorize DiscountHouse to register names on SuiNS.
    struct FreeClaimsApp has drop {}

    /// A key that opens up free claims for type T.
    struct FreeClaimsKey<phantom T> has copy, store, drop {}

    struct FreeClaimsConfig has copy, store, drop {
        domain_length_range: vector<u8>,
    }

    /// A function to register a name with a discount using type `T`.
    public fun free_claim<T: key>(
        self: &mut DiscountHouse,
        suins: &mut SuiNS,
        object: &T,
        domain_name: String,
        _no_years: u8,
        clock: &Clock,
        ctx: &mut TxContext
    ): SuinsRegistration {
        // For normal flow, we do not allow DayOne to be used.
        // DayOne can only be used on `register_with_day_one` function.
        assert!(type::into_string(type::get<T>()) != type::into_string(type::get<DayOne>()), ENotValidForDayOne);

        internal_claim_free_name<T>(self, suins, domain_name, clock, object, ctx)
    }

    // A function to register a free name using `DayOne`.
    public fun free_claim_with_day_one(
        self: &mut DiscountHouse,
        suins: &mut SuiNS,
        day_one: &DayOne,
        domain_name: String,
        clock: &Clock,
        ctx: &mut TxContext
    ): SuinsRegistration {
        assert!(is_active(day_one), ENotActiveDayOne);
        internal_claim_free_name<DayOne>(self, suins, domain_name, clock, day_one, ctx)
    }


    /// Internal helper that checks if there's a valid configuration for T,
    /// validates that the domain name is of vlaid length, and then does the registration.
    fun internal_claim_free_name<T: key>(
        self: &mut DiscountHouse,
        suins: &mut SuiNS,
        domain_name: String,
        clock: &Clock,
        object: &T,
        ctx: &mut TxContext
    ): SuinsRegistration {
        house::assert_version_is_valid(self);
        // validate that there's a configuration for type T.
        assert_config_exists<T>(self);

        // We only allow one free registration per object.
        // We shall check the id hasn't been used before first.
        let _id = object::id<T>(object);

        // Now validate the domain, and that the rule applies here.
        let domain = domain::new(domain_name);
        let config: &FreeClaimsConfig = df::borrow(house::uid_mut(self), FreeClaimsKey<T>{});
        assert_domain_length_eligible(&domain, config);

        // TODO: Check for configuration
        // After checking, validate that the domain name is of valid length for that config.
        // Then, finally, register the name and attach the DF to the object.

        house::friend_add_registry_entry(suins, domain, 1, clock, ctx)
    }

    /// An admin action to authorize a type T for special pricing.
    public fun authorize_type<T: key>(
        _: &AdminCap, 
        self: &mut DiscountHouse,
        domain_length_range: vector<u8>
    ) {
        assert!(!df::exists_(house::uid_mut(self), FreeClaimsKey<T> {}), EConfigExists);

        // validate the range is valid.
        assert_valid_length_setup(&domain_length_range);

        df::add(house::uid_mut(self), FreeClaimsKey<T>{}, FreeClaimsConfig {
            domain_length_range
        });
    }
    
    /// An admin action to deauthorize type T from getting discounts.
    public fun deauthorize_type<T>(_: &AdminCap, self: &mut DiscountHouse) {
        assert_config_exists<T>(self);
        df::remove_if_exists<FreeClaimsKey<T>, vector<u8>>(house::uid_mut(self), FreeClaimsKey<T>{});
    }

    // Validate that there is a config for `T`
    fun assert_config_exists<T>(self: &mut DiscountHouse) {
        assert!(df::exists_(house::uid_mut(self), FreeClaimsKey<T> {}), EConfigNotExists);
    }

    /// Validate that the domain length is valid for the passed configuration.
    fun assert_domain_length_eligible(domain: &Domain, config: &FreeClaimsConfig) {
        let domain_length = (string::length(domain::sld(domain)) as u8);
        let from = *vector::borrow(&config.domain_length_range, 0);
        let to = *vector::borrow(&config.domain_length_range, 1);

        assert!(domain_length >= from && domain_length <= to, EInvalidCharacterRange);
    }


    // Validate that our range setup is right.
    fun assert_valid_length_setup(domain_length_range: &vector<u8>) {
        assert!(vector::length(domain_length_range) == 2, EInvalidCharacterRange);

        let from = *vector::borrow(domain_length_range, 0);
        let to = *vector::borrow(domain_length_range, 1);

        assert!(from > to, EInvalidCharacterRange);
    }
}
