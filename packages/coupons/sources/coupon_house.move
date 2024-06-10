// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// A module to support coupons for SuiNS.
/// This module allows secondary modules (e.g. Discord) to add or remove coupons too.
/// This allows for separation of logic & ease of de-authorization in case we don't want some functionality anymore.
/// 
/// Coupons are unique string codes, that can be used (based on the business rules) to claim discounts in the app.
/// Each coupon is validated towards a list of rules. View `rules` module for explanation.
/// The app is authorized on `SuiNS` to be able to claim names and add earnings to the registry.
module coupons::coupon_house {
    use std::string::String;
    use sui::{
        dynamic_field::{Self as df}, 
        clock::Clock, 
        sui::SUI, 
        coin::Coin
    };
    use coupons::{
        rules::CouponRules, 
        data::{Self, Data}, 
        coupon::{Self, Coupon} 
    };
    use suins::{
        domain, 
        suins::{Self, AdminCap, SuiNS}, 
        suins_registration::SuinsRegistration, 
        config::{Self, Config}, 
        registry::Registry
    };

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

    /// Our versioning of the coupons package.
    const VERSION: u8 = 1;

    // Authorization for the Coupons on SuiNS, to be able to register names on the app.
    public struct CouponsApp has drop {}

    /// Authorization Key for secondary apps (e.g. Discord) connected to this module.
    public struct AppKey<phantom A: drop> has copy, store, drop {}

    /// The CouponHouse Shared Object which holds a table of coupon codes available for claim.
    public struct CouponHouse has store {
        data: Data,
        version: u8,
        storage: UID
    }

    /// Called once to setup the CouponHouse on SuiNS.
    public fun setup(suins: &mut SuiNS, cap: &AdminCap, ctx: &mut TxContext) {
        cap.add_registry(suins, CouponHouse {
            storage: object::new(ctx),
            data: data::new(ctx),
            version: VERSION
        });
    }

    /// Register a name using a coupon code.
    public fun register_with_coupon(
        suins: &mut SuiNS,
        coupon_code: String,
        domain_name: String,
        no_years: u8,
        payment: Coin<SUI>,
        clock: &Clock,
        ctx: &mut TxContext
    ): SuinsRegistration {
        // Validate registration years are in [0,5] range.
        assert!(no_years > 0 && no_years <= 5, EInvalidYearsArgument);

        let config = suins.get_config<Config>();
        let domain = domain::new(domain_name);
        let label = domain.sld();
        let domain_length = (label.length() as u8);
        let original_price = config.calculate_price(domain_length, no_years);
        // Validate name can be registered (is main domain (no subdomain) and length is valid)
        config::assert_valid_user_registerable_domain(&domain);

        // Verify coupon house is authorized to get the registry / register names.
        let coupon_house = coupon_house_mut(suins);

        // Validate that specified coupon is valid.
        assert!(coupon_house.data.coupons().contains(coupon_code), ECouponNotExists);

        // Borrow coupon from the table.
        let coupon: &mut Coupon = &mut coupon_house.data.coupons_mut()[coupon_code];

        // We need to do a total of 5 checks, based on `CouponRules`
        // Our checks work with `AND`, all of the conditions must pass for a coupon to be used.
        // 1. Validate domain size.
        coupon.rules().assert_coupon_valid_for_domain_size(domain_length);
        // 2. Decrease available claims. Will ABORT if the coupon doesn't have enough available claims.
        coupon.rules_mut().decrease_available_claims();
        // 3. Validate the coupon is valid for the specified user.
        coupon.rules().assert_coupon_valid_for_address(ctx.sender());
        // 4. Validate the coupon hasn't expired (Based on clock)
        coupon.rules().assert_coupon_is_not_expired(clock);
        // 5. Validate years are valid for the coupon.
        coupon.rules().assert_coupon_valid_for_domain_years(no_years);

        let sale_price = coupon.calculate_sale_price(original_price);
        assert!(payment.value() == sale_price, EIncorrectAmount);

        // Clean up our registry by removing the coupon if no more available claims!
        if(!coupon.rules().has_available_claims()){
            // remove the coupon, since it's no longer usable.
            coupon_house.data.remove_coupon(coupon_code);
        };

        suins::app_add_balance(CouponsApp {}, suins, payment.into_balance());
        let registry = suins::app_registry_mut<CouponsApp, Registry>(CouponsApp {}, suins);
        registry.add_record(domain, no_years, clock, ctx)
    }

    // A convenient helper to calculate the price in a PTB.
    // Important: This function doesn't check the validity of the coupon (Whether the user can indeed use it)
    // Nor does it calculate the original price. This is part of the Frontend anyways.
    public fun calculate_sale_price(suins: &SuiNS, price: u64, coupon_code: String): u64 {
        let coupon_house = coupon_house(suins);
        // Validate that specified coupon is valid.
        assert!(coupon_house.data.coupons().contains(coupon_code), ECouponNotExists);

        // Borrow coupon from the table.
        let coupon: &Coupon = &coupon_house.data.coupons()[coupon_code];

        coupon.calculate_sale_price(price)
    }

    // Get `Data` as an authorized app.
    public fun app_data_mut<A: drop>(suins: &mut SuiNS, _: A): &mut Data {
        let coupon_house_mut = coupon_house_mut(suins);
        coupon_house_mut.assert_version_is_valid();
        // verify app is authorized to get a mutable reference.
        coupon_house_mut.assert_app_is_authorized<A>();
        &mut coupon_house_mut.data
    }

    /// Authorize an app on the coupon house. This allows to a secondary module to add/remove coupons.
    public fun authorize_app<A: drop>(_: &AdminCap, suins: &mut SuiNS) {
        df::add(&mut coupon_house_mut(suins).storage, AppKey<A>{}, true);
    }

    /// De-authorize an app. The app can no longer add or remove
    public fun deauthorize_app<A: drop>(_: &AdminCap, suins: &mut SuiNS): bool {
        df::remove(&mut coupon_house_mut(suins).storage, AppKey<A>{})
    }

    /// An admin helper to set the version of the shared object.
    /// Registrations are only possible if the latest version is being used.
    public fun set_version(_: &AdminCap, suins: &mut SuiNS, version: u8) {
        coupon_house_mut(suins).version = version;
    }

    /// Validate that the version of the app is the latest.
    public fun assert_version_is_valid(self: &CouponHouse) {
        assert!(self.version == VERSION, EInvalidVersion);
    }

    // Add a coupon as an admin.
    /// To create a coupon, you have to call the PTB in the specific order
    /// 1. (Optional) Call rules::new_domain_length_rule(type, length) // generate a length specific rule (e.g. only domains of size 5)
    /// 2. Call rules::coupon_rules(...) to create the coupon's ruleset.
    public fun admin_add_coupon(
        _: &AdminCap,
        suins: &mut SuiNS,
        code: String,
        kind: u8,
        amount: u64,
        rules: CouponRules,
        ctx: &mut TxContext
    ) {
        let coupon_house = coupon_house_mut(suins);
        coupon_house.assert_version_is_valid();
        coupon_house.data.save_coupon(code, coupon::new(kind, amount, rules, ctx));
    }

    // Remove a coupon as a system's admin.
    public fun admin_remove_coupon(_: &AdminCap, suins: &mut SuiNS, code: String){
        let coupon_house = coupon_house_mut(suins);
        coupon_house.assert_version_is_valid();
        coupon_house.data.remove_coupon(code);
    }

    // Add coupon as a registered app.
    public fun app_add_coupon(
        data: &mut Data,
        code: String,
        kind: u8,
        amount: u64,
        rules: CouponRules,
        ctx: &mut TxContext
    ){
        data.save_coupon(code, coupon::new(kind, amount, rules, ctx));
    }

    // Remove a coupon as a registered app.
    public fun app_remove_coupon(data: &mut Data, code: String) {
        data.remove_coupon(code);
    }

    /// Check if an application is authorized to access protected features of the Coupon House.
    public fun is_app_authorized<A: drop>(coupon_house: &CouponHouse): bool {
        df::exists_(&coupon_house.storage, AppKey<A>{})
    }

    /// Assert that an application is authorized to access protected features of Coupon House. 
    /// Aborts with `EAppNotAuthorized` if not.
    public fun assert_app_is_authorized<A: drop>(coupon_house: &CouponHouse) {
        assert!(coupon_house.is_app_authorized<A>(), EAppNotAuthorized);
    }

    /// local helper to get the `coupon house` object from the SuiNS object.
    fun coupon_house(suins: &SuiNS): &CouponHouse {
        // Verify coupon house is authorized to get the registry / register names.
        suins.assert_app_is_authorized<CouponsApp>();
        let coupons = suins.registry<CouponHouse>();
        coupons.assert_version_is_valid();
        coupons
    }

    /// Gets a mutable reference to the coupon's house
    fun coupon_house_mut(suins: &mut SuiNS): &mut CouponHouse {
       // Verify coupon house is authorized to get the registry / register names.
        suins.assert_app_is_authorized<CouponsApp>();
        let coupons = suins::app_registry_mut<CouponsApp, CouponHouse>(CouponsApp {}, suins);
        coupons.assert_version_is_valid();
        coupons
    }
}
