// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module coupons::coupons {
    use std::string::{String};
    use std::option::{Self, Option};

    use sui::table::{Self, Table};
    use sui::tx_context::{TxContext};
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::dynamic_field::{Self as df};
    use sui::linked_table::{Self, LinkedTable};

    use coupons::helpers::{Self, DomainSizeRule};

    // Errors
    const EInvalidAmount: u64 = 0;
    const EAlreadyExists: u64 = 1;
    const EAppNotAuthorized: u64 = 2;

    // use suins::config;
    // use suins::domain::{Self, Domain};
    use suins::suins::{AdminCap}; // re-use AdminCap for creating new coupons.
    // use suins::suins_registration::{Self as nft, SuinsRegistration};
    // use suins::registry::{Self, Registry};

    // Authorization for the Coupons on SuiNS, to be able to register names.
    struct CouponsApp has drop {}

    /// Authorization Key for secondary apps (e.g. DiscordLoyalty) connected to this module.
    struct AppKey<phantom App: drop> has copy, store, drop {}

    struct Data has store {
        // hold a list of all coupons in the system.
        coupons: Table<String, Coupon>,
        // hold historic usages of coupons ({user, coupon}) to prevent double claiming.
        // Used as a separate table to avoid spamming our object's DF space.
        used_coupons: Table<AddressCouponUsageKey, bool> 
    }

    // The CouponHouse Shared Object which holds a table of coupon codes available for claim.
    // As well as the history of used coupons as a table.
    struct CouponHouse has key, store {
        id: UID,
        data: Data
    }

    struct AddressCouponUsageKey has copy, store, drop { 
        code: String,
        address: address
    }

    // Coupon data type which defines how the coupon will work.
    struct Coupon has store {
        type: u8, // 0 -> Percentage Discount | 1 -> Fixed Discount
        amount: u64, // if type == 0, we need it to be between 0, 100. We only allow int stlye (not 0.5% discount)
        // 1st validity point: Making sure the name we're trying to register works with the domain sizing rules.
        size_rule: DomainSizeRule, // A domainSizeRule object to define the rules around the length of the name.
        // 2nd validity point: max amount of claims. (option::none() -> unlimited claims)
        available_claims: Option<u16>, // if none, it can be claimed unlimited times.
        // 3rd validity point: Coupon can be used only be an address in this table (option::none() -> any address can claim);
        addresses: Option<LinkedTable<address, bool>>,  // We save this as a linked table so we can clean this up when removing a coupon.
        // 4th validity point: If `expiration` is set and its' in the past, coupon can't be claimed.
        expiration: Option<u64>,
        // 5th eligibility point: If we can claim the coupon for N years.
        max_years: Option<u8>, // [none, 5]
    }

    // Initialization function.
    // Share the CouponHouse.
    fun init(ctx: &mut TxContext){
        transfer::share_object(CouponHouse {
            id: object::new(ctx),
            data: Data {
                coupons: table::new(ctx),
                used_coupons: table::new(ctx),
            }
        });
    }


    // Create a new coupon.
    // Can only be added to our house by authorized apps.
    public fun new_coupon(
        type: u8,
        amount: u64,
        size_rule: DomainSizeRule,
        available_claims: Option<u16>,
        addresses: Option<LinkedTable<address, bool>>,
        expiration: Option<u64>,
        max_years: Option<u8> // E.g., this coupon is enabled for registering a maximum of 2 years.
    ): Coupon {
        Coupon {
            type, amount, size_rule, addresses, available_claims, expiration, max_years
        }
    }

    // Adds a coupon. Requires an authorized app or an AdminCap to get a valid mutable reference
    // to `Data`, as it's wrapped in the CouponHouse.
    public fun add_coupon(
        self: &mut Data,
        code: String,  // The unique coupon code.
        coupon: Coupon
    ) { 
        assert!(helpers::is_valid_amount(coupon.type, coupon.amount), EInvalidAmount);
        assert!(table::contains(&mut self.coupons, code), EAlreadyExists);

        // adds the coupon.
        table::add(&mut self.coupons, code, coupon)
    }

    // A function to remove a coupon from the system.
    // It first cleans up the addresses from the linked_table, then it destroys.
    public fun remove_coupon(
        self: &mut Data,
        code: String
    ) {

        let Coupon { 
            amount: _,
           type: _, 
           size_rule: _,
           available_claims: _,
           addresses,
           expiration: _,
           max_years: _
         } = table::remove(&mut self.coupons, code);

        // clean up the coupon addresses table.
        if(option::is_some(&addresses)){
            let table = option::destroy_some(addresses);

            while(!linked_table::is_empty(&table)){
                let (address, _) = linked_table::pop_back(&mut table);

                // clean up historic data claims for this coupon, since we no longer have it here.
                // TODO: Discuss if we should do it. I believe we should.
                table::remove(&mut self.used_coupons, AddressCouponUsageKey { address, code});
            };

            linked_table::destroy_empty(table);
        }else{
            option::destroy_none(addresses);
        }

    }


    // App authorization for secondary trusted coupon apps.
    // get `Data` as an admin of the app.
    public fun app_data_mut_as_admin(_: &AdminCap, self: &mut CouponHouse) {
        &mut self.data;
    }

    // get `Data` as an authorized app.
    public fun app_data_mut<App: drop>(
        _: App,
        self: &mut CouponHouse,
    ): &mut Data {
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

    // Authorize an app.
    public fun authorize_app<App: drop>(_: &AdminCap, self: &mut CouponHouse) {
        df::add(&mut self.id, AppKey<App>{}, true);
    }

    // De-authorize an app
    public fun deauthorize_app<App: drop>(_: &AdminCap, self: &mut CouponHouse): bool {
        df::remove(&mut self.id, AppKey<App>{})
    }

    // test only functions.
    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext){
        init(ctx);
    }
}
