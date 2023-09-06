// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// A module to support coupons for SuiNS.
/// This module allows secondary modules (e.g. Discord) to add or remove coupons too.
/// This allows for separation of logic & ease of de-authorization in case we don't want some functionality anymore.
/// 
/// Coupons are unique string codes, that can be used (based on the business rules) to claim discounts in the app.
/// Each coupon is validated towards a list of rules. View `rules` module for explanation.
/// The app is authorized on `SuiNS` to be able to claim names and add earnings to the registry.
module coupons::coupons {
    use std::string::{Self, String};

    use sui::table::{Self, Table};
    use sui::tx_context::{TxContext, sender};
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::dynamic_field::{Self as df};
    use sui::clock::Clock;
    use sui::sui::SUI;
    use sui::coin::{Self, Coin};

    use coupons::rules::{Self, CouponRules};
    use coupons::constants;

    /// Coupon already exists
    const ECouponAlreadyExists: u64 = 0;
    /// An app that's not authorized tries to access private data.
    const EAppNotAuthorized: u64 = 1;
    /// Tries to use app on an invalid version.
    const EInvalidVersion: u64 = 2;

    /// These errors are claim errors.
    /// Number of years passed is not within [1-5] interval.
    const EInvalidYearsArgument: u64 = 3;
    /// The payment does not match the price for the domain.
    const EIncorrectAmount: u64 = 4;
    /// Coupon doesn't exist.
    const ECouponNotExists: u64 = 5;

    // use suins::config;
    use suins::domain;
    use suins::suins::{Self, AdminCap, SuiNS}; // re-use AdminCap for creating new coupons.
    use suins::suins_registration::SuinsRegistration;
    use suins::config::{Self, Config};
    use suins::registry::{Self, Registry};

    // Authorization for the Coupons on SuiNS, to be able to register names on the app.
    struct CouponsApp has drop {}
    /// Authorization Key for secondary apps (e.g. Discord) connected to this module.
    struct AppKey<phantom App: drop> has copy, store, drop {}

    /// Create a `Data` struct that only authorized apps can get mutable access to.
    /// We don't save the coupon's table directly on the shared object, because we want authorized apps to only perform
    /// certain actions with the table (and not give full `mut` access to it).
    struct Data has store {
        // hold a list of all coupons in the system.
        coupons: Table<String, Coupon>
    }

    /// The CouponHouse Shared Object which holds a table of coupon codes available for claim.
    struct CouponHouse has key, store {
        id: UID,
        data: Data,
    }

    /// A Coupon has a type, a value and a ruleset.
    /// - `Rules` are defined on the module `rules`, and covers a variety of everything we needed for the service.
    /// - `type` is a u8 constant, defined on `constants` which makes a coupon fixed price or discount percentage
    /// - `value` is a u64 constant, which can be in the range of (0,100] for discount percentage, or any value > 0 for fixed price.
    struct Coupon has copy, store, drop {
        type: u8, // 0 -> Percentage Discount | 1 -> Fixed Discount
        amount: u64, // if type == 0, we need it to be between 0, 100. We only allow int stlye (not 0.5% discount).
        rules: CouponRules, // A list of base Rules for the coupon.
    }

    // Initialization function.
    // Share the CouponHouse.
    fun init(ctx: &mut TxContext){
        transfer::share_object(CouponHouse {
            id: object::new(ctx),
            data: Data { coupons: table::new(ctx) }
        });
    }

    /// Register a name using a coupon code.
    public fun register_with_coupon(
        self: &mut CouponHouse,
        suins: &mut SuiNS,
        coupon_code: String,
        domain_name: String,
        no_years: u8,
        payment: Coin<SUI>,
        clock: &Clock,
        ctx: &mut TxContext
    ): SuinsRegistration {
        // Validate that specified coupon is valid.
        assert!(table::contains(&mut self.data.coupons, coupon_code), ECouponNotExists);

        // Verify coupon house is authorized to buy names.
        suins::assert_app_is_authorized<CouponsApp>(suins);

        // Validate registration years are in [0,5] range.
        assert!(no_years > 0 && no_years <= 5, EInvalidYearsArgument);

        let config = suins::get_config<Config>(suins);
        let domain = domain::new(domain_name);
        let label = domain::sld(&domain);
        
        let domain_length = (string::length(label) as u8);

        // Borrow coupon from the table.
        let coupon = table::borrow_mut(&mut self.data.coupons, coupon_code);

        // We need to do a total of 5 checks, based on `CouponRules`
        // Our checks work with `AND`, all of the conditions must pass for a coupon to be used.
        // 1. Validate domain size.
        rules::assert_coupon_valid_for_domain_size(&coupon.rules, domain_length);
        // 2. Decrease available claims. Will ABORT if the coupon doesn't have enough available claims.
        rules::decrease_available_claims(&mut coupon.rules);
        // 3. Validate the coupon is valid for the specified user.
        rules::assert_coupon_valid_for_address(&coupon.rules, sender(ctx));
        // 4. Validate the coupon hasn't expired (Based on clock)
        rules::assert_coupon_is_not_expired(&coupon.rules, clock);
        // 5. Validate years are valid for the coupon.
        rules::assert_coupon_valid_for_domain_years(&coupon.rules, no_years);

        // Validate name can be registered (is main domain (no subdomain) and length is valid)
        config::assert_valid_user_registerable_domain(&domain);

        let original_price = config::calculate_price(config, domain_length, no_years);
        let sale_price = internal_calculate_sale_price(original_price, coupon);

        assert!(coin::value(&payment) == sale_price, EIncorrectAmount);
        suins::app_add_balance(CouponsApp {}, suins, coin::into_balance(payment));

        // Clean up our registry by removing the coupon if no more available claims!
        if(!rules::has_available_claims(&coupon.rules)){
            // remove the coupon, since it's no longer usable.
            internal_remove_coupon(&mut self.data, coupon_code);
        };

        let registry = suins::app_registry_mut<CouponsApp, Registry>(CouponsApp {}, suins);
        registry::add_record(registry, domain, no_years, clock, ctx)
    }

    // A convenient helper to calculate the price in a PTB.
    // Important: This function doesn't check the validity of the coupon (Whether the user can indeed use it)
    // Nor does it calculate the original price. This is part of the Frontend anyways.
    public fun calculate_sale_price(self: &mut CouponHouse, price: u64, coupon_code: String): u64 {
        // Validate that specified coupon is valid.
        assert!(table::contains(&mut self.data.coupons, coupon_code), ECouponNotExists);
        // Borrow coupon from the table.
        let coupon = table::borrow_mut(&mut self.data.coupons, coupon_code);
        internal_calculate_sale_price(price, coupon)
    }

    /// A helper to calculate the final price after the discount.
    fun internal_calculate_sale_price(price: u64, coupon: &Coupon): u64{
        
        // If it's fixed price, we just deduce the amount.
        if(coupon.type == constants::fixed_price_discount_type()){
            if(coupon.amount > price) return 0; // protect underflow case.
            return price - coupon.amount
        };

        // If it's discount price, we calculate the discount 
        let discount =  (((price as u128) * (coupon.amount as u128) / 100) as u64);
        // then remove it from the sale price.
        price - discount
    }

    // Get `Data` as an authorized app.
    public fun app_data_mut<App: drop>(_: App, self: &mut CouponHouse): &mut Data {
        // verify app is authorized to get a mutable reference.
        assert_app_is_authorized<App>(self);
        &mut self.data
    }

    /// Check if an application is authorized to access protected features of the Coupon House.
    public fun is_app_authorized<App: drop>(self: &CouponHouse): bool {
        df::exists_(&self.id, AppKey<App>{})
    }

    /// Assert that an application is authorized to access protected features of Coupon House. 
    /// Aborts with `EAppNotAuthorized` if not.
    public fun assert_app_is_authorized<App: drop>(self: &CouponHouse) {
        assert!(is_app_authorized<App>(self), EAppNotAuthorized);
    }

    /// Authorize an app. This allows to a secondary module to add/remove coupons.
    public fun authorize_app<App: drop>(_: &AdminCap, self: &mut CouponHouse) {
        df::add(&mut self.id, AppKey<App>{}, true);
    }

    /// De-authorize an app. The app can no longer add or remove
    public fun deauthorize_app<App: drop>(_: &AdminCap, self: &mut CouponHouse): bool {
        df::remove(&mut self.id, AppKey<App>{})
    }

    // Add a coupon as an admin.
    public fun admin_add_coupon(
        _: &AdminCap,
        self: &mut CouponHouse,
        code: String,
        type: u8,
        amount: u64,
        rules: CouponRules,
        ctx: &mut TxContext
    ) {
        internal_save_coupon(&mut self.data, code, internal_create_coupon(type, amount, rules, ctx));
    }

    // Remove a coupon as a system's admin.
    public fun admin_remove_coupon(_: &AdminCap, self: &mut CouponHouse, code: String){
        internal_remove_coupon(&mut self.data, code)
    }

    // Add coupon as a registered app.
    public fun app_add_coupon(
        self: &mut Data,
        code: String,
        type: u8,
        amount: u64,
        rules: CouponRules,
        ctx: &mut TxContext
    ){
        internal_save_coupon(self, code, internal_create_coupon(type, amount, rules, ctx));
    }

    // Remove a coupon as a registered app.
    // A registered app can only remove a coupon that it has added.
    public fun app_remove_coupon(self: &mut Data, code: String) {
        internal_remove_coupon(self, code);
    }

    /// Private internal functions
    /// An internal function to save the coupon in the shared object's config.
    fun internal_save_coupon(
        self: &mut Data,
        code: String,
        coupon: Coupon
    ) {
        assert!(!table::contains(&mut self.coupons, code), ECouponAlreadyExists);
        table::add(&mut self.coupons, code, coupon);
    }

    /// An internal function to create a coupon object.
    /// To create a coupon, you have to call the PTB in the specific order
    /// 1. (Optional) Call rules::domain_length_rule(type, length) // generate a length specific rule (e.g. only domains of size 5)
    /// 2. Call rules::coupon_rules() to create the coupon's ruleset. 
    fun internal_create_coupon(
        type: u8,
        amount: u64,
        rules: CouponRules,
        _ctx: &mut TxContext
    ): Coupon {
        rules::assert_is_valid_amount(type, amount);
        rules::assert_is_valid_discount_type(type);
        Coupon {
            type, amount, rules
        }
    }

    // A function to remove a coupon from the system.
    fun internal_remove_coupon(self: &mut Data, code: String) {
        table::remove(&mut self.coupons, code);
    }

    // test only functions.
    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext){
        init(ctx);
    }
}
