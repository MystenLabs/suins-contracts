// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// A module that allows purchasing names in a different price by presenting a reference of type T.
/// Each `T` can have a separate configuration for a discount percentage.
/// If a `T` doesn't exist, registration will fail.
///
/// Can be called only when promotions are active for a specific type T.
/// Activation / deactivation happens through PTBs.
module discounts::discounts {

    use std::string::{Self, String};
    use std::type_name::{Self as type};

    use sui::object::{Self, UID};
    use sui::tx_context::{TxContext};
    use sui::transfer;
    use sui::dynamic_field::{Self as df};
    use sui::clock::{Clock};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;

    use suins::domain;
    use suins::registry::{Self, Registry};
    use suins::suins::{Self, AdminCap, SuiNS};
    use suins::config::{Self};
    use suins::suins_registration::SuinsRegistration;

    use day_one::day_one::{DayOne, is_active};

    /// A configuration already exists
    const EConfigExists: u64 = 1;
    /// A configuration doesn't exist
    const EConfigNotExists: u64 = 2;
    /// Invalid years input
    const EInvalidYearsArgument: u64 = 3;
    /// Invalid payment value
    const EIncorrectAmount: u64 = 4;
    /// Tries to use DayOne on regular register flow.
    const ENotValidForDayOne: u64 = 5;
    /// Tries to claim with a non active DayOne
    const ENotActiveDayOne: u64 = 6;
    /// Tries to register with invalid version of the app
    const ENotValidVersion: u64 = 7;

    /// A version handler that allows us to upgrade the app in the future.
    const VERSION: u8 = 1;

    /// A key to authorize DiscountHouse to register names on SuiNS.
    struct DiscountHouseApp has drop {}

    /// A key that opens up discounts for type T.
    struct DiscountKey<phantom T> has copy, store, drop {}

    /// The Discount config for type T. 
    /// We save the discount config for each letter configuration (3 chars, 4 chars, 5+ chars)
    /// We can have fixed price sale or percentage discount. (0, 1)
    struct DiscountConfig has copy, store, drop {
        three_char_price: u64,
        four_char_price: u64,
        five_plus_char_price: u64,
    }

    // The Shared object responsible for the discounts.
    struct DiscountHouse has key, store {
        id: UID,
        version: u8
    }

    /// Share the house.
    /// This will hold DFs with the configuration for different types.
    fun init(ctx: &mut TxContext){
        transfer::public_share_object(DiscountHouse {
            id: object::new(ctx),
            version: VERSION
        })
    }

    /// A function to register a name with a discount using type `T`.
    public fun register<T>(
        self: &mut DiscountHouse,
        suins: &mut SuiNS,
        domain_name: String,
        no_years: u8,
        payment: Coin<SUI>,
        clock: &Clock,
        _: &T,
        ctx: &mut TxContext
    ): SuinsRegistration {
        // For normal flow, we do not allow DayOne to be used.
        // DayOne can only be used on `register_with_day_one` function.
        assert!(type::into_string(type::get<T>()) != type::into_string(type::get<DayOne>()), ENotValidForDayOne);
        internal_register_name<T>(self, suins, domain_name, no_years, payment, clock, ctx)
    }
    
    /// A special function for DayOne registration.
    /// We separate it from the normal registration flow because we only want it to be usable
    /// from activated DayOnes.
    public fun register_with_day_one(
        self: &mut DiscountHouse,
        suins: &mut SuiNS,
        domain_name: String,
        no_years: u8,
        payment: Coin<SUI>,
        clock: &Clock,
        day_one: &DayOne,
        ctx: &mut TxContext
    ): SuinsRegistration {
        assert!(is_active(day_one), ENotActiveDayOne);
        internal_register_name<DayOne>(self, suins, domain_name, no_years, payment, clock, ctx)
    }

    /// Internal helper to handle the registration process
    fun internal_register_name<T>(
        self: &mut DiscountHouse, 
        suins: &mut SuiNS, 
        domain_name: String, 
        no_years: u8, 
        payment: Coin<SUI>, 
        clock: &Clock, 
        ctx: &mut TxContext
    ): SuinsRegistration {
        /// Validate that the version of the app is the latest.
        assert!(self.version == VERSION, ENotValidVersion);

        // validate that there's a configuration for type T.
        assert_config_exists<T>(self);

        // Verify that app is authorized to register names.
        suins::assert_app_is_authorized<DiscountHouseApp>(suins);

        let domain = domain::new(domain_name);
        config::assert_valid_user_registerable_domain(&domain);

        let price = calculate_price(df::borrow(&mut self.id, DiscountKey<T>{}), (string::length(domain::sld(&domain)) as u8), no_years);
        
        assert!(coin::value(&payment) == price, EIncorrectAmount);

        suins::app_add_balance(DiscountHouseApp {}, suins, coin::into_balance(payment));
    
        let registry = suins::app_registry_mut<DiscountHouseApp, Registry>(DiscountHouseApp {}, suins);
        registry::add_record(registry, domain, no_years, clock, ctx)
    }

    /// An admin action to deauthorize a type T from discounts.
    public fun authorize_type<T>(
        _: &AdminCap, 
        self: &mut DiscountHouse, 
        three_char_price: u64, 
        four_char_price: u64, 
        five_plus_char_price: u64
    ) {
        assert!(!df::exists_(&mut self.id, DiscountKey<T> {}), EConfigNotExists);

        df::add(&mut self.id, DiscountKey<T>{}, DiscountConfig { 
            three_char_price,
            four_char_price,
            five_plus_char_price
        });
    }

    /// An admin action to deauthorize type T from getting discounts.
    public fun deauthorize_type<T>(_: &AdminCap, self: &mut DiscountHouse) {
        assert_config_exists<T>(self);
        df::remove_if_exists<DiscountKey<T>, DiscountConfig>(&mut self.id, DiscountKey<T>{});
    }

    /// An admin helper to set the version of the shared object.
    /// Registrations are only possible if the latest version is being used.
    public fun set_version(_: &AdminCap, self: &mut DiscountHouse, version: u8) {
        self.version = version;
    }


    /// Calculate the price of a label.
    public fun calculate_price(self: &DiscountConfig, length: u8, years: u8): u64 {
        assert!(0 < years && years <= 5, EInvalidYearsArgument);

        let price = if (length == 3) {
            self.three_char_price
        } else if (length == 4) {
            self.four_char_price
        } else {
            self.five_plus_char_price
        };

        ((price as u64) * (years as u64))
    }

    fun assert_config_exists<T>(self: &mut DiscountHouse) {
        assert!(df::exists_(&mut self.id, DiscountKey<T> {}), EConfigNotExists);
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx);
    }
}
