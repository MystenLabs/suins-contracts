// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

// the base setup of subdomains.
module subdomains::app {
    use std::option;
    use std::string::{String};

    use sui::object::{Self, UID, ID};
    use sui::tx_context::{TxContext};
    use sui::table::{Self, Table};
    use sui::transfer;
    use sui::clock::Clock;
    use sui::dynamic_field::{Self as df};

    use suins::domain::{Self, Domain};
    use suins::registry::{Self, Registry};
    use suins::suins::{Self, SuiNS};
    use suins::suins_registration::{Self, SuinsRegistration};
    use suins::name_record;

    use subdomains::utils::{validate_subdomain, is_subdomain};

    /// Tries to create a subdomain that already exists.
    const ESubdomainAlreadyExists: u64 = 1;
    /// Tries to create a subdomain that expires later than the parent.
    const EInvalidExpirationDate: u64 = 2;
    /// Tries to create a subdomain with a parent that is not allowed to do so.
    const ECreationDisabledForSubDomain: u64 = 3;
    /// Tries to tweak options with a parent that has expired.
    const EInvalidParent: u64 = 4;
    /// Tries to extend the time using a domain that is not a subdomain.
    const ENotSubdomain: u64 = 5;

    // The authentication scheme for SuiNS.
    struct SubDomains has drop {}

    // The key to store the parent's ID in the subdomain object.
    struct ParentKey has copy, store, drop {}

    // The shared object. Holds the configuration for all subdomains registered in the system.
    struct SubDomainApp has key, store {
        id: UID,
        setup: Table<Domain, SubDomainSetup>,
    }

    // For each subdomain, we save this configuration.
    // By checking up this config, we can check if a subdomain can do different actions
    //
    //  `allow_creation`: If this is true, we can create new subdomains under this subdomain
    //  `allow_time_extension`: If this is true, we can extend the time of the subdomain (max is parent's expiration)
    struct SubDomainSetup has store, drop {
        allow_creation: bool,
        allow_time_extension: bool
    }
    
    // shares the object
    fun init(ctx: &mut TxContext) {
        transfer::public_share_object(SubDomainApp {
            id: object::new(ctx),
            setup: table::new(ctx)
        })
    }

    /// Creates a new subdomain.
    public fun create(
        self: &mut SubDomainApp,
        suins: &mut SuiNS,
        parent: &SuinsRegistration,
        clock: &Clock,
        subdomain_name: String,
        expiration_timestamp_ms: u64,
        allow_creation: bool,
        allow_time_extension: bool,
        ctx: &mut TxContext
    ): SuinsRegistration {
        // Gets the registry mut reference, so we can add the name and validate. 
        // Aborts if the app is not authorized.
        let registry = suins::app_registry_mut<SubDomains, Registry>(SubDomains {}, suins);
        // validate that parent is a valid, non expired object.
        registry::assert_nft_is_authorized(registry, parent, clock);

        // validate that the parent can create subdomains.
        internal_assert_parent_can_create_subdomains(self, parent);

        // validate that the requested expiration timestamp is not greater than the parent's one.
        assert!(expiration_timestamp_ms <= suins_registration::expiration_timestamp_ms(parent), EInvalidExpirationDate);

        let subdomain = domain::new(subdomain_name);
        // validate that the subdomain is valid for the supplied parent.
        validate_subdomain(&suins_registration::domain(parent), &subdomain);

        // Check whether a NameRecord exists for that subdomain.
        // if it exists: check whether it is expired. If it has expired, we can overwrite the old one.
        // if it doesn't exist: we can just register.
        let existing_name_record = registry::lookup(registry, subdomain);

        if(option::is_some(&existing_name_record)) {
            assert!(name_record::has_expired(option::borrow(&existing_name_record), clock), ESubdomainAlreadyExists);
        };

        // We create the `setup` for the particular SubDomain.
        // We save a setting like: `subdomain.example.sui` -> { allow_creation: true/false, allow_time_extension: true/false }
        internal_create_or_replace_setup(self, subdomain, SubDomainSetup {
            allow_creation,
            allow_time_extension
        });

        // we register the subdomain (e.g. `subdomain.example.sui`) and return the SuinsRegistration object.
        internal_create_subdomain(registry, subdomain, expiration_timestamp_ms, object::id(parent), clock, ctx)
    }

    /// extends the time of the subdomain.
    // public fun extend_expiration(
    //     self: &mut SubDomainApp,
    //     suins: &mut SuiNS,
    //     subdomain: &mut SuinsRegistration,
    //     expiration_timestamp_ms: u64,
    //     clock: &Clock
    // ) {

    // }

    /// Called by the parent domain to edit a subdomain's settings.
    /// - Allows the parent domain to `disable` time extension.
    /// - Allows the parent to `disable` subdomain (grand-children) creation.
    public fun edit_setup(
        self: &mut SubDomainApp,
        parent: &SuinsRegistration,
        clock: &Clock,
        subdomain_name: String,
        allow_creation: bool,
        allow_time_extension: bool
    ) {
        let subdomain = domain::new(subdomain_name);
        // validate that the subdomain is valid for the supplied parent.
        validate_subdomain(&suins_registration::domain(parent), &subdomain);

        // validate that the parent can create subdomains, otherwise there's no point in allowing it to edit the setup.
        internal_assert_parent_can_create_subdomains(self, parent);

        assert!(suins_registration::has_expired(parent, clock), EInvalidParent);

        // We create the `setup` for the particular SubDomain.
        // We save a setting like: `subdomain.example.sui` -> { allow_creation: true/false, allow_time_extension: true/false }
        internal_create_or_replace_setup(self, subdomain, SubDomainSetup {
            allow_creation,
            allow_time_extension
        });
    }

    /// Creates the setup for a `Domain`, or updates it if it already exists.
    fun internal_create_or_replace_setup(
        self: &mut SubDomainApp,
        subdomain: Domain,
        setup: SubDomainSetup
    ) {
        if(table::contains(&self.setup, subdomain)){
            let _ = table::remove(&mut self.setup, subdomain);
        };

        table::add(&mut self.setup, subdomain, setup);  
    }

    /// Validate whether a `SuinsRegistration` object is eligible for creating a subdomain.
    /// 1. If the NFT is authorized (not expired, active)
    /// 2. If the parent is a subdomain, check whether it is allowed to create subdomains.
    fun internal_assert_parent_can_create_subdomains(
        self: &mut SubDomainApp,
        parent: &SuinsRegistration,
    ) {
        // if the parent is not a subdomain, we can always create subdomains.
        if(!is_subdomain(&suins_registration::domain(parent))) {
            return
        };
    
        // if `parent` is a subdomain. We check the subdomain config to see if we are allowed to mint subdomains.
        // For regular names (e.g. example.sui), we can always mint subdomains.
        // if there's no config for this parent, and the parent is a subdomain, we can't create deeper names.
        assert!(table::contains(&self.setup, suins_registration::domain(parent)), ECreationDisabledForSubDomain);
        let config = table::borrow(&mut self.setup, suins_registration::domain(parent));
        assert!(config.allow_creation, ECreationDisabledForSubDomain);
    }

    /// An internal function to add a subdomain to the registry with the correct expiration timestamp. 
    /// It doesn't check whether the expiration is valid. This needs to be checked on the calling function.
    fun internal_create_subdomain(
        registry: &mut Registry,
        subdomain: Domain,
        expiration_timestamp_ms: u64,
        parent_nft_id: ID,
        clock: &Clock,
        ctx: &mut TxContext,
    ): SuinsRegistration {
        let nft = registry::add_record_ignoring_grace_period(registry, subdomain, 1, clock, ctx);
        // set the timestamp to the correct one. `add_record` only works with years :/
        registry::set_expiration_timestamp_ms(registry, &mut nft, subdomain, expiration_timestamp_ms);

        // attach the `ParentID` to the SuinsRegistration, so we validate that the parent who created this subdomain
        // is the same as the one currently holding the parent domain.
        df::add(suins_registration::uid_mut(&mut nft), ParentKey {}, parent_nft_id);
        
        nft
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx);
    }
}
