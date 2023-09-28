// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// A base module that holds a shared object for the configuration of the package
/// and exports some package utilities for the 2 systems to use.
module discounts::house {

    use sui::object::{Self, UID};
    use sui::tx_context::{TxContext};
    use sui::transfer;
    use sui::clock::{Clock};

    use suins::domain::{Domain};
    use suins::registry::{Self, Registry};
    use suins::suins::{Self, AdminCap, SuiNS};
    use suins::config;
    use suins::suins_registration::SuinsRegistration;

    // The `free_claims` module can use the shared object to attach configuration & claim names.
    friend discounts::free_claims;
    // The `discounts` module can use the shared object to attach configuration & claim names.
    friend discounts::discounts;

    /// Tries to register with invalid version of the app
    const ENotValidVersion: u64 = 1;

    /// A version handler that allows us to upgrade the app in the future.
    const VERSION: u8 = 1;

    /// All promotions in this package are valid only for 1 year
    const REGISTRATION_YEARS: u8 = 1;

    /// A key to authorize DiscountHouse to register names on SuiNS.
    struct DiscountHouseApp has drop {}

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

    /// A function to save a new SuiNS name in the registry.
    /// Helps re-use the same code for all discounts based on type T of the package.
    public(friend) fun friend_add_registry_entry(
        suins: &mut SuiNS,
        domain: Domain,
        clock: &Clock,
        ctx: &mut TxContext
    ): SuinsRegistration {
        // Verify that app is authorized to register names.
        suins::assert_app_is_authorized<DiscountHouseApp>(suins);

        // Validate that the name can be registered.
        config::assert_valid_user_registerable_domain(&domain);

        let registry = suins::app_registry_mut<DiscountHouseApp, Registry>(DiscountHouseApp {}, suins);
        registry::add_record(registry, domain, REGISTRATION_YEARS, clock, ctx)
    }

    /// An admin helper to set the version of the shared object.
    /// Registrations are only possible if the latest version is being used.
    public fun set_version(_: &AdminCap, self: &mut DiscountHouse, version: u8) {
        self.version = version;
    }

    /// Returns the UID of the shared object so we can add custom configuration.
    /// from different modules we have. but keep using the same shared object.
    public(friend) fun uid_mut(self: &mut DiscountHouse): &mut UID {
        &mut self.id
    }

    /// Allows the friend modules to call functions to the SuiNS registry.
    public(friend) fun suins_app_auth(): DiscountHouseApp {
        DiscountHouseApp {}
    }

    /// Validate that the version of the app is the latest.
    public fun assert_version_is_valid(self: &DiscountHouse) {
        assert!(self.version == VERSION, ENotValidVersion);
    }


    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx);
    }

}
