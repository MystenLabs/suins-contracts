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

    use sui::object::{Self, ID};
    use sui::tx_context::{TxContext};

    use sui::dynamic_field::{Self as df};
    use sui::clock::{Clock};
    use sui::linked_table::{Self, LinkedTable};

    use suins::domain::{Self, Domain};
    use suins::suins::{AdminCap, SuiNS};
    use suins::suins_registration::SuinsRegistration;

    use discounts::house::{Self, DiscountHouse};

    use day_one::day_one::{DayOne, is_active};

    use reserved::reserved_names::{Self, ReservedList};

    /// A configuration already exists
    const EConfigExists: u64 = 1;
    /// A configuration doesn't exist
    const EConfigNotExists: u64 = 2;
    /// Invalid length array
    const EInvalidCharacterRange: u64 = 3;
    /// Object has already been used in this promotion.
    const EAlreadyClaimed: u64 = 4;
    /// Tries to use DayOne on regular register flow.
    const ENotValidForDayOne: u64 = 5;
    /// Tries to claim with a non active DayOne
    const ENotActiveDayOne: u64 = 6;

    /// A key to authorize DiscountHouse to register names on SuiNS.
    struct FreeClaimsApp has drop {}

    /// A key that opens up free claims for type T.
    struct FreeClaimsKey<phantom T> has copy, store, drop {}

    /// We hold the configuration for the promotion
    /// We only allow 1 claim / per configuration / per promotion.
    /// We keep the used ids as a LinkedTable so we can get our rebates when closing the promotion.
    struct FreeClaimsConfig has store {
        domain_length_range: vector<u8>,
        used_objects: LinkedTable<ID, bool>
    }

    /// A function to register a name with a discount using type `T`.
    public fun free_claim<T: key>(
        self: &mut DiscountHouse,
        suins: &mut SuiNS,
        reserved: &ReservedList,
        object: &T,
        domain_name: String,
        clock: &Clock,
        ctx: &mut TxContext
    ): SuinsRegistration {
        // For normal flow, we do not allow DayOne to be used.
        // DayOne can only be used on `register_with_day_one` function.
        assert!(type::into_string(type::get<T>()) != type::into_string(type::get<DayOne>()), ENotValidForDayOne);

        internal_claim_free_name<T>(self, suins, reserved, domain_name, clock, object, ctx)
    }

    // A function to register a free name using `DayOne`.
    public fun free_claim_with_day_one(
        self: &mut DiscountHouse,
        suins: &mut SuiNS,
        reserved: &ReservedList,
        day_one: &DayOne,
        domain_name: String,
        clock: &Clock,
        ctx: &mut TxContext
    ): SuinsRegistration {
        assert!(is_active(day_one), ENotActiveDayOne);
        internal_claim_free_name<DayOne>(self, suins, reserved, domain_name, clock, day_one, ctx)
    }


    /// Internal helper that checks if there's a valid configuration for T,
    /// validates that the domain name is of vlaid length, and then does the registration.
    fun internal_claim_free_name<T: key>(
        self: &mut DiscountHouse,
        suins: &mut SuiNS,
        reserved: &ReservedList,
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
        let id = object::id<T>(object);

        // validate that the supplied object hasn't been used to claim a free name.
        let config = df::borrow_mut<FreeClaimsKey<T>, FreeClaimsConfig>(house::uid_mut(self), FreeClaimsKey<T>{});
        assert!(!linked_table::contains(&config.used_objects, id), EAlreadyClaimed);

        // add the supplied object's id to the used objects list.
        linked_table::push_back(&mut config.used_objects, id, true);

        // Now validate the domain, and that the rule applies here.
        let domain = domain::new(domain_name);

        reserved_names::assert_is_not_reserved_name(reserved, *domain::sld(&domain));
        reserved_names::assert_is_not_offensive_name(reserved, *domain::sld(&domain));

        assert_domain_length_eligible(&domain, config);

        house::friend_add_registry_entry(suins, domain, clock, ctx)
    }

    /// An admin action to authorize a type T for free claiming of names by presenting
    /// an object of type `T`.
    public fun authorize_type<T: key>(
        _: &AdminCap, 
        self: &mut DiscountHouse,
        domain_length_range: vector<u8>,
        ctx: &mut TxContext
    ) {
        house::assert_version_is_valid(self);
        assert!(!df::exists_(house::uid_mut(self), FreeClaimsKey<T> {}), EConfigExists);

        // validate the range is valid.
        assert_valid_length_setup(&domain_length_range);

        df::add(house::uid_mut(self), FreeClaimsKey<T>{}, FreeClaimsConfig {
            domain_length_range,
            used_objects: linked_table::new(ctx)
        });
    }
    
    /// An admin action to deauthorize type T from getting discounts.
    /// Deauthorization also brings storage rebates by destroying the table of used objects.
    /// If we re-authorize a type, objects can be re-used, but that's considered a separate promotion.
    public fun deauthorize_type<T>(_: &AdminCap, self: &mut DiscountHouse) {
        house::assert_version_is_valid(self);
        assert_config_exists<T>(self);
        let FreeClaimsConfig { used_objects, domain_length_range: _ } = df::remove<FreeClaimsKey<T>, FreeClaimsConfig>(house::uid_mut(self), FreeClaimsKey<T>{});

        // parse each entry and remove it. Gives us storage rebates.
        while(linked_table::length(&used_objects) > 0) {
            linked_table::pop_front(&mut used_objects);
        };

        linked_table::destroy_empty(used_objects);
    }

    /// Worried by the 1000 DFs load limit, I introduce a `drop_type` function now
    /// to make sure we can force-finish a promotion for type `T`.
    public fun force_deauthorize_type<T>(_: &AdminCap, self: &mut DiscountHouse) {
        house::assert_version_is_valid(self);
        assert_config_exists<T>(self);
        let FreeClaimsConfig { used_objects, domain_length_range: _ } = df::remove<FreeClaimsKey<T>, FreeClaimsConfig>(house::uid_mut(self), FreeClaimsKey<T>{});
        linked_table::drop(used_objects);
    }

    // Validate that there is a config for `T`
    fun assert_config_exists<T>(self: &mut DiscountHouse) {
        assert!(df::exists_with_type<FreeClaimsKey<T>, FreeClaimsConfig>(house::uid_mut(self), FreeClaimsKey<T> {}), EConfigNotExists);
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

        assert!(to >= from, EInvalidCharacterRange);
    }
}
