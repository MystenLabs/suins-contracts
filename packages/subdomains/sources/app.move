// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

// the base setup of subdomains.
module subdomains::app {
    use std::option;
    use std::string::{String};

    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::table::{Self, Table};
    use sui::transfer;
    use sui::clock::Clock;
    use sui::dynamic_field::{Self as df};

    use suins::domain::{Self, Domain};
    use suins::registry::{Self, Registry};
    use suins::suins::{Self, SuiNS, AdminCap};
    use suins::suins_registration::{Self, SuinsRegistration};
    use suins::name_record;

    use subdomains::utils::{validate_subdomain, is_subdomain};

    /// Tries to create a subdomain that already exists.
    const ESubdomainAlreadyExists: u64 = 1;
    /// Tries to create a subdomain that expires later than the parent.
    const EInvalidExpirationDate: u64 = 2;
    /// Tries to create a subdomain with a parent that is not allowed to do so.
    const ECreationDisabledForSubDomain: u64 = 3;

    // The authentication scheme for SuiNS.
    struct SubDomains has drop {}

    struct ParentKey has copy, store, drop {}

    // The shared object. Holds the configuration for all subdomains registered in the system.
    struct SubDomainApp has key, store {
        id: UID,
        setup: Table<Domain, SubDomainSetup>
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
    fun init(ctx: &mut TxContext){
        transfer::public_share_object(SubDomainApp {
            id: object::new(ctx),
            setup: table::new(ctx)
        })
    }

    // creates a new subdomain.
    public fun new(
        suins: &mut SuiNS,
        subdomain_app: &mut SubDomainApp,
        subdomain: String,
        parent: &SuinsRegistration,
        clock: &Clock,
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

        let subdomain = domain::new(subdomain);
        // validate that the subdomain is valid for the supplied parent.
        validate_subdomain(&suins_registration::domain(parent), &subdomain);

        assert!(expiration_timestamp_ms <= suins_registration::expiration_timestamp_ms(parent), EInvalidExpirationDate);

        // if `parent` is a subdomain. We check the subdomain config to see if we are allowed to mint subdomains.
        // For regular names (e.g. example.sui), we can always mint subdomains.
        if(is_subdomain(&suins_registration::domain(parent))) {
            let config = table::borrow(&mut subdomain_app.setup, suins_registration::domain(parent));
            assert!(config.allow_creation, ECreationDisabledForSubDomain);
        };

        // Check whether a NameRecord exists for that subdomain.
        // if it exists: check whether it is expired. If it has expired, we can overwrite the old one.
        // if it doesn't exist: we can just register.
        // *********** NOTE TO MYSELF **********
        // We need to tweak `registry` to check at period instead of grace_period. Otherwise, 
        // we will be unable to remove an expired subdomain. We don't have grace periods for subdomains.
        // We treat their expiration date as the normal one.
        let existing_name_record = registry::lookup(registry, subdomain);

        if(option::is_some(&existing_name_record)) {
            assert!(name_record::has_expired(option::borrow(&existing_name_record), clock), ESubdomainAlreadyExists);
        };

        // We create the `setup` for the particular SubDomain.
        // We save a setting like: `subdomain.example.sui` -> { allow_creation: true/false, allow_time_extension: true/false }
        internal_create_or_replace_setup(subdomain_app, subdomain, SubDomainSetup {
            allow_creation,
            allow_time_extension
        });

        // we register the subdomain (e.g. `subdomain.example.sui`) and return the SuinsRegistration object.
        internal_create_subdomain(registry, subdomain, expiration_timestamp_ms, object::id(parent), clock, ctx)
    }



    // extends the time of the subdomain
    public fun extend(
        _suins: &mut SuiNS,
        _subdomain_app: &mut SubDomainApp,
        _subdomain: &mut SuinsRegistration,
    ) {
        
    }


    /// Creates the setup for a `Domain`, and updates it if it already exists.
    fun internal_create_or_replace_setup(
        subdomain_app: &mut SubDomainApp,
        domain: Domain,
        setup: SubDomainSetup
    ) {

        if(table::contains(&subdomain_app.setup, domain)){
            let _ = table::remove(&mut subdomain_app.setup, domain);
        };

        table::add(&mut subdomain_app.setup, domain, setup);  
    }




    // a function to add a subdomain to the registry with the correct expiration timestamp. 
    // It doesn't check whether the expiration is valid. This needs to be checked on the calling function.
    fun internal_create_subdomain(
        registry: &mut Registry,
        subdomain: Domain,
        expiration_timestamp_ms: u64,
        parent_nft_id: ID,
        clock: &Clock,
        ctx: &mut TxContext,
    ): SuinsRegistration {
        let nft = registry::add_record(registry, subdomain, 1, clock, ctx);
        // set the timestamp to the correct one. `add_record` only works with years :/
        registry::set_expiration_timestamp_ms(registry, &mut nft, subdomain, expiration_timestamp_ms);

        // attach the `ParentID` to the SuinsRegistration, so we validate that the parent who created this subdomain
        // is the same as the one currently holding the parent domain.
        df::add(suins_registration::uid_mut(&mut nft), ParentKey {}, parent_nft_id);
        
        nft
    }
}
