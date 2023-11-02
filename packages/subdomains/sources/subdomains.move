// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// A registration module for subdomains.
/// 
/// This module is responsible for creating subdomains and managing their settings.
/// 
/// It allows the following functionality:
/// 
/// 1. Registering a new subdomain as a holder of Parent NFT.
/// 2. Setup the subdomain with capabilities (creating nested names, extending to parent's renewal time).
module subdomains::subdomains {
    use std::option::{Self, Option};
    use std::string::{String, utf8, bytes};

    use sui::object::{Self, ID};
    use sui::tx_context::{TxContext};
    use sui::table::{Self, Table};
    use sui::clock::Clock;
    use sui::dynamic_field::{Self as df};
    use sui::vec_map::{Self, VecMap};
    use sui::event;

    use suins::domain::{Self, Domain, is_subdomain, parent_from_child};
    use suins::registry::{Self, Registry};
    use suins::suins::{Self, SuiNS, AdminCap};
    use suins::suins_registration::{Self, SuinsRegistration};
    use suins::constants::{subdomain_allow_extension_key, subdomain_allow_creation_key};
    use suins::name_record::{Self, NameRecord};

    use subdomains::utils::{Self, SubDomainConfig, validate_subdomain};

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
    /// The subdomain has been replaced by a newer NFT, so it can't be renewed.
    const ESubdomainReplaced: u64 = 6;

    /// The authentication scheme for SuiNS.
    struct SubDomains has drop {}

    /// The key to store the parent's ID in the subdomain object.
    struct ParentKey has copy, store, drop {}

    /// The subdomain's config Holds the configuration for all subdomains registered in the system.
    struct App has store {
        config: SubDomainConfig
    }

    // We initialize the `App`
    public fun setup(suins: &mut SuiNS, cap: &AdminCap, ctx: &mut TxContext){
        suins::add_registry(cap, suins, App {
            config: utils::default_config()
        })
    }

    /// Creates a new subdomain
    /// 
    /// The following script does the following lookups:
    /// 1. Checks if app is authorized.
    /// 2. Validates that the parent NFT is valid and non expired.
    /// 3. Validates that the parent can create subdomains (based on the on-chain setup). [all 2nd level names with valid tld can create names]
    /// 4. Validates the subdomain validity.
    ///     2.1 Checks that the TLD is in the list of supported tlds.
    ///     2.2 Checks that the length of the new label has the min lenth.
    ///     2.3 Validates that this subdomain can indeed be registered by that parent.
    ///     2.4 Validates that the subdomain's expiration timestamp is less or equal to the parents.
    ///     2.5 Checks if this subdomain already exists. [If it does, it aborts if it's not expired, overrides otherwise]
    /// 
    /// It then saves the configuration for that child (manage-able by the parent), and returns the SuinsRegistration object.
    /// 
    public fun create(
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
        let registry = registry(suins);

        // validate that parent is a valid, non expired object.
        registry::assert_nft_is_authorized(registry, parent, clock);

        // validate that the parent can create subdomains.
        internal_assert_parent_can_create_subdomains(suins, suins_registration::domain(parent));

        // validate that the requested expiration timestamp is not greater than the parent's one.
        assert!(expiration_timestamp_ms <= suins_registration::expiration_timestamp_ms(parent), EInvalidExpirationDate);

        let subdomain = domain::new(subdomain_name);
        // validate that the subdomain is valid for the supplied parent.
        validate_subdomain(&suins_registration::domain(parent), &subdomain, &self(suins).config);

        // Check whether a NameRecord exists for that subdomain.
        // if it exists: check whether it is expired. If it has expired, we can overwrite the old one.
        // if it doesn't exist: we can just register.
        let existing_name_record = registry::lookup(registry, subdomain);

        if(option::is_some(&existing_name_record)) {
            assert!(name_record::has_expired(option::borrow(&existing_name_record), clock), ESubdomainAlreadyExists);
        };

        // We create the `setup` for the particular SubDomain.
        // We save a setting like: `subdomain.example.sui` -> { allow_creation: true/false, allow_time_extension: true/false }
        internal_set_flag(suins, subdomain, subdomain_allow_creation_key(), option::none(), allow_creation);
        internal_set_flag(suins, subdomain, subdomain_allow_extension_key(), option::none(), allow_time_extension);

        // we register the subdomain (e.g. `subdomain.example.sui`) and return the SuinsRegistration object.
        internal_create_subdomain(registry_mut(suins), subdomain, expiration_timestamp_ms, object::id(parent), clock, ctx)
    }

    /// Extends the expiration of a `node` subdomain.
    public fun extend_expiration(
        suins: &mut SuiNS,
        nft: &mut SuinsRegistration,
        expiration_timestamp_ms: u64,
        clock: &Clock
    ) {
        let registry = registry(suins);
        let subdomain = &suins_registration::domain(nft);
        let parent_domain = parent_from_child(subdomain);

        // first, we validate that we are indeed looking at a subdomain.
        assert!(is_subdomain(subdomain), ENotSubdomain);
        assert!(is_extension_allowed(&internal_get_domain_config(suins, *subdomain)), ECreationDisabledForSubDomain);

        // doing the full domain validation at ease.
        validate_subdomain(&parent_domain, subdomain, &self(suins).config);

        let existing_name_record = registry::lookup(registry, *subdomain);
        let parent_name_record = registry::lookup(registry, parent_domain);

        // we need to make sure this name record exists (both child + parent), otherwise we don't have a valid object.
        assert!(option::is_some(&existing_name_record) && option::is_some(&parent_name_record), ESubdomainReplaced);
        assert!(parent(nft) == name_record::nft_id(option::borrow(&parent_name_record)), ESubdomainReplaced);
    
        // validate that the requested expiration timestamp is not greater than the parent's one.
        assert!(expiration_timestamp_ms <= name_record::expiration_timestamp_ms(option::borrow(&parent_name_record)), EInvalidExpirationDate);

        registry::set_expiration_timestamp_ms(registry_mut(suins), nft, *subdomain, expiration_timestamp_ms);
    }

    /// Called by the parent domain to edit a subdomain's settings.
    /// - Allows the parent domain to `disable` time extension.
    /// - Allows the parent to `disable` subdomain (grand-children) creation | --> Can't retract already created ones <--
    public fun edit_setup(
        suins: &mut SuiNS,
        parent: &SuinsRegistration,
        clock: &Clock,
        subdomain_name: String,
        allow_creation: bool,
        allow_time_extension: bool
    ) {
        assert!(!suins_registration::has_expired(parent, clock), EInvalidParent);

        let parent_domain = suins_registration::domain(parent);
        let subdomain = domain::new(subdomain_name);

        // validate that the subdomain is valid for the supplied parent
        // (as well as it is valid in label length, total length, depth, etc).
        validate_subdomain(&parent_domain, &subdomain, &self(suins).config);

        // validate that the parent can create subdomains, otherwise there's no point in allowing it to edit the setup.
        internal_assert_parent_can_create_subdomains(suins, parent_domain);

        // We create the `setup` for the particular SubDomain.
        // We save a setting like: `subdomain.example.sui` -> { allow_creation: true/false, allow_time_extension: true/false }
        internal_set_flag(suins, subdomain, subdomain_allow_creation_key(), option::none(), allow_creation);
        internal_set_flag(suins, subdomain, subdomain_allow_extension_key(), option::none(), allow_time_extension);
    }

    /// Parent ID of a subdomain
    public fun parent(subdomain: &SuinsRegistration): ID {
        *df::borrow(suins_registration::uid(subdomain), ParentKey {})
    }

    // Sets/removes a (key,value) on the domain's NameRecord metadata (depending on cases).
    // Validation needs to happen on the calling function.
    fun internal_set_flag(
        self: &mut SuiNS,
        subdomain: Domain,
        key: String,
        value: Option<String>,
        enable: bool
    ) {
        let config = internal_get_domain_config(self, subdomain);
        let is_enabled = vec_map::contains(&config, &key);

        if(enable) {
            if(!is_enabled){
                let normalized_value = if(option::is_some(&value)) {
                    option::extract(&mut value)
                } else {
                    // default to 1 (similar to bool)
                    utf8(b"1")
                };
                vec_map::insert(&mut config, key, normalized_value);
            }
        }else {
            if(is_enabled){
                vec_map::remove(&mut config, &key);
            }
        };

        registry::set_data(registry_mut(self), subdomain, config);
    }

    /// Check if subdomain creation is allowed.
    fun is_creation_allowed(config: &VecMap<String, String>): bool {
        vec_map::contains(config, &subdomain_allow_creation_key())
    }

    /// Check if time extension is allowed.
    fun is_extension_allowed(config: &VecMap<String, String>): bool {
        vec_map::contains(config, &subdomain_allow_extension_key())
    }

    /// Get the name record's metadata for a subdomain.
    fun internal_get_domain_config(
        self: &SuiNS,
        subdomain: Domain
    ): VecMap<String, String> {
        let registry = registry(self);
        *registry::get_data(registry, subdomain)
    }

    /// Validate whether a `SuinsRegistration` object is eligible for creating a subdomain.
    /// 1. If the NFT is authorized (not expired, active)
    /// 2. If the parent is a subdomain, check whether it is allowed to create subdomains.
    fun internal_assert_parent_can_create_subdomains(
        self: &SuiNS,
        parent: Domain,
    ) {
        // if the parent is not a subdomain, we can always create subdomains.
        if(!is_subdomain(&parent)) {
            return
        };

        // if `parent` is a subdomain. We check the subdomain config to see if we are allowed to mint subdomains.
        // For regular names (e.g. example.sui), we can always mint subdomains.
        // if there's no config for this parent, and the parent is a subdomain, we can't create deeper names.
         assert!(is_creation_allowed(&internal_get_domain_config(self, parent)), ECreationDisabledForSubDomain);
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
        // set the timestamp to the correct one. `add_record` only works with years but we can correct it easily.
        registry::set_expiration_timestamp_ms(registry, &mut nft, subdomain, expiration_timestamp_ms);

        // attach the `ParentID` to the SuinsRegistration, so we validate that the parent who created this subdomain
        // is the same as the one currently holding the parent domain.
        df::add(suins_registration::uid_mut(&mut nft), ParentKey {}, parent_nft_id);
    
        // Emits an event for our indexing purposes.
        event::emit(SubDomainTweakEvent {
            domain: subdomain,
            expiration_timestamp_ms: expiration_timestamp_ms,
            is_leaf: false,
            target: option::none()
        });

        nft
    }

    fun registry(suins: &SuiNS): &Registry {
        suins::registry<Registry>(suins)
    }

    fun registry_mut(suins: &mut SuiNS): &mut Registry {
        suins::app_registry_mut<SubDomains, Registry>(SubDomains {}, suins)
    }

    fun self(suins: &SuiNS): &App {
        suins::registry<App>(suins)
    }

    fun self_mut(suins: &mut SuiNS): &mut App {
        suins::app_registry_mut<SubDomains, App>(SubDomains {}, suins)
    }

    // === Events ===

    /// Event that's indexed on our Indexer.
    /// We save the created subdomain (out of which we can also extract the parent) and the expiration timestamp.
    /// We reuse the same event both for creation and renewal of subdomain's expiration.
    struct SubDomainTweakEvent has copy, drop {
        domain: Domain,
        expiration_timestamp_ms: u64,
        is_leaf: bool,
        target: Option<address>
    }
}
