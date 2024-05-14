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
/// 3. Registering `leaf` names (whose parent acts as the Capability holder)
/// 4. Removing `leaf` names
/// 5. Extending a subdomain expiration's time
/// 6. Burning expired subdomain NFTs.
/// 
/// Comments:
/// 
/// 1. By attaching the creation/extension attributes as metadata to the subdomain's NameRecord, we can easily
/// turn off this package completely, and retain the state on a different package's deployment. This is useful
/// both for effort-less upgradeability and gas savings.
/// 2. For any `registry_mut` call, we know that if this module is not authorized, we'll get an abort
/// from the core suins package.
/// 
module subdomains::subdomains {
    use std::string::{String, utf8};

    use sui::{clock::Clock, dynamic_field as df, vec_map::VecMap};

    use suins::{
        domain::{Self, Domain, is_subdomain}, 
        registry::Registry, 
        suins::{Self, SuiNS}, 
        suins_registration::SuinsRegistration, 
        subdomain_registration::SubDomainRegistration, 
        constants::{subdomain_allow_extension_key, subdomain_allow_creation_key}
    };

    use subdomains::config::{Self, SubDomainConfig};

    use denylist::denylist;

    /// Tries to create a subdomain that expires later than the parent or below the minimum.
    const EInvalidExpirationDate: u64 = 1;
    /// Tries to create a subdomain with a parent that is not allowed to do so.
    const ECreationDisabledForSubDomain: u64 = 2;
    /// Tries to extend the expiration of a subdomain which doesn't have the permission to do so.
    const EExtensionDisabledForSubDomain: u64 = 3;
    /// The subdomain has been replaced by a newer NFT, so it can't be renewed.
    const ESubdomainReplaced: u64 = 4;
    /// Parent for a given subdomain has changed, hence time extension cannot be done.
    const EParentChanged: u64 = 5;
    /// Checks whether a name is allowed or not (against blocked names list)
    const ENotAllowedName: u64 = 6;

    /// Enabled metadata value.
    const ACTIVE_METADATA_VALUE: vector<u8> = b"1";

    /// The authentication scheme for SuiNS.
    public struct SubDomains has drop {}

    /// The key to store the parent's ID in the subdomain object.
    public struct ParentKey has copy, store, drop {}

    /// Creates a `leaf` subdomain
    /// A `leaf` subdomain, is a subdomain that is managed by the parent's NFT.
    public fun new_leaf(
        suins: &mut SuiNS,
        parent: &SuinsRegistration,
        clock: &Clock,
        subdomain_name: String,
        target: address,
        ctx: &mut TxContext
    ) {
        assert!(!denylist::is_blocked_name(suins, subdomain_name), ENotAllowedName);

        let subdomain = domain::new(subdomain_name);
        // all validation logic for subdomain creation / management.
        internal_validate_nft_can_manage_subdomain(suins, parent, clock, subdomain, true);

        // Aborts with `suins::registry::ERecordExists` if the subdomain already exists.
        registry_mut(suins).add_leaf_record(subdomain, clock, target, ctx)
    }

    /// Removes a `leaf` subdomain from the registry.
    /// Management of the `leaf` subdomain can only be achieved through the parent's valid NFT.
    public fun remove_leaf(
        suins: &mut SuiNS,
        parent: &SuinsRegistration,
        clock: &Clock,
        subdomain_name: String,
    ) {
        let subdomain = domain::new(subdomain_name);
        
        // All validation logic for subdomain creation / management.
        // We pass `false` as last argument because even if we don't have create capabilities (anymore),
        // we can still remove a leaf name (we just can't add a new one).
        internal_validate_nft_can_manage_subdomain(suins, parent, clock, subdomain, false);

        registry_mut(suins).remove_leaf_record(subdomain)
    }

    /// Creates a new `node` subdomain
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
    public fun new(
        suins: &mut SuiNS,
        parent: &SuinsRegistration,
        clock: &Clock,
        subdomain_name: String,
        expiration_timestamp_ms: u64,
        allow_creation: bool,
        allow_time_extension: bool,
        ctx: &mut TxContext
    ): SubDomainRegistration {
        assert!(!denylist::is_blocked_name(suins, subdomain_name), ENotAllowedName);

        let subdomain = domain::new(subdomain_name);
        // all validation logic for subdomain creation / management.
        internal_validate_nft_can_manage_subdomain(suins, parent, clock, subdomain, true);

        // Validate that the duration is at least the minimum duration.
        assert!(expiration_timestamp_ms >= clock.timestamp_ms() + app_config(suins).minimum_duration(), EInvalidExpirationDate);
        // validate that the requested expiration timestamp is not greater than the parent's one.
        assert!(expiration_timestamp_ms <= parent.expiration_timestamp_ms(), EInvalidExpirationDate);

        // We register the subdomain (e.g. `subdomain.example.sui`) and return the SuinsRegistration object.
        // Aborts with `suins::registry::ERecordExists` if the subdomain already exists.
        let nft = internal_create_subdomain(registry_mut(suins), subdomain, expiration_timestamp_ms, object::id(parent), clock, ctx);

        // We create the `setup` for the particular SubDomainRegistration.
        // We save a setting like: `subdomain.example.sui` -> { allow_creation: true/false, allow_time_extension: true/false }
        if (allow_creation) {
            internal_set_flag(suins, subdomain, subdomain_allow_creation_key(), allow_creation);
        };

        if (allow_time_extension){
            internal_set_flag(suins, subdomain, subdomain_allow_extension_key(), allow_time_extension);
        };

        nft
    }

    /// Extends the expiration of a `node` subdomain.
    public fun extend_expiration(
        suins: &mut SuiNS,
        sub_nft: &mut SubDomainRegistration,
        expiration_timestamp_ms: u64,
    ) {
        let registry = registry(suins);

        let nft = sub_nft.nft_mut();
        let subdomain = nft.domain();
        let parent_domain = subdomain.parent();

        // Check if time extension is allowed for this subdomain.
        assert!(is_extension_allowed(&record_metadata(suins, subdomain)), EExtensionDisabledForSubDomain);

        let existing_name_record = registry.lookup(subdomain);
        let parent_name_record = registry.lookup(parent_domain);

        // we need to make sure this name record exists (both child + parent), otherwise we don't have a valid object.
        assert!(option::is_some(&existing_name_record) && option::is_some(&parent_name_record), ESubdomainReplaced);

        // Validate that the parent of the name is the same as the actual parent
        // (to prevent cases where owner of the parent changed. When that happens, subdomains lose all abilities to renew / create subdomains)
        assert!(parent(nft) == option::borrow(&parent_name_record).nft_id(), EParentChanged);

        // validate that expiration date is > than the current.
        assert!(expiration_timestamp_ms > nft.expiration_timestamp_ms(), EInvalidExpirationDate);
        // validate that the requested expiration timestamp is not greater than the parent's one.
        assert!(expiration_timestamp_ms <= option::borrow(&parent_name_record).expiration_timestamp_ms(), EInvalidExpirationDate);

        registry_mut(suins).set_expiration_timestamp_ms(nft, subdomain, expiration_timestamp_ms);
    }

    /// Called by the parent domain to edit a subdomain's settings.
    /// - Allows the parent domain to toggle time extension.
    /// - Allows the parent to toggle subdomain (grand-children) creation
    /// --> For creations: A parent can't retract already created children, nor can limit the depth if creation capability is on.
    public fun edit_setup(
        suins: &mut SuiNS,
        parent: &SuinsRegistration,
        clock: &Clock,
        subdomain_name: String,
        allow_creation: bool,
        allow_time_extension: bool
    ) {
        // validate that parent is a valid, non expired object.
        registry(suins).assert_nft_is_authorized(parent, clock);

        let parent_domain = parent.domain();
        let subdomain = domain::new(subdomain_name);

        // validate that the subdomain is valid for the supplied parent
        // (as well as it is valid in label length, total length, depth, etc).
        config::assert_is_valid_subdomain(&parent_domain, &subdomain, app_config(suins));

        // We create the `setup` for the particular SubDomainRegistration.
        // We save a setting like: `subdomain.example.sui` -> { allow_creation: true/false, allow_time_extension: true/false }
        internal_set_flag(suins, subdomain, subdomain_allow_creation_key(), allow_creation);
        internal_set_flag(suins, subdomain, subdomain_allow_extension_key(), allow_time_extension);
    }

    /// Burns a `SubDomainRegistration` object if it is expired.
    public fun burn(
        suins: &mut SuiNS,
        nft: SubDomainRegistration,
        clock: &Clock,
    ) {
        registry_mut(suins).burn_subdomain_object(nft, clock);
    }

    /// Parent ID of a subdomain
    public fun parent(subdomain: &SuinsRegistration): ID {
        *df::borrow(subdomain.uid(), ParentKey {})
    }

    // Sets/removes a (key,value) on the domain's NameRecord metadata (depending on cases).
    // Validation needs to happen on the calling function.
    fun internal_set_flag(
        self: &mut SuiNS,
        subdomain: Domain,
        key: String,
        enable: bool
    ) {
        let mut config = record_metadata(self, subdomain);
        let is_enabled = config.contains(&key);

        if (enable && !is_enabled) {
            config.insert(key,  utf8(ACTIVE_METADATA_VALUE));
        };

        if(!enable && is_enabled) {
            config.remove(&key);
        };

        registry_mut(self).set_data(subdomain, config);
    }

    /// Check if subdomain creation is allowed.
    fun is_creation_allowed(metadata: &VecMap<String, String>): bool {
        metadata.contains(&subdomain_allow_creation_key())
    }

    /// Check if time extension is allowed.
    fun is_extension_allowed(metadata: &VecMap<String, String>): bool {
        metadata.contains(&subdomain_allow_extension_key())
    }

    /// Get the name record's metadata for a subdomain.
    fun record_metadata(
        self: &SuiNS,
        subdomain: Domain
    ): VecMap<String, String> {
        *registry(self).get_data(subdomain)
    }

    /// Does all the regular checks for validating that a parent `SuinsRegistration` object
    /// can operate on a given subdomain.
    /// 
    /// 1. Checks that NFT is authorized.
    /// 2. Checks that the parent can create subdomains (applies to subdomain `node` names).
    /// 3. Validates that the subdomain is valid (accepted TLD, depth, length, is child of given parent, etc).
    fun internal_validate_nft_can_manage_subdomain(
        suins: &SuiNS,
        parent: &SuinsRegistration,
        clock: &Clock,
        subdomain: Domain,
        // Set to `true` for `validate_creation` if you want to validate that the parent can create subdomains.
        // Set to false when editing the setup of a subdomain or removing leaf names.
        check_creation_auth: bool
    ) {
        // validate that parent is a valid, non expired object.
        registry(suins).assert_nft_is_authorized(parent, clock);

        if (check_creation_auth) {
            // validate that the parent can create subdomains.
            internal_assert_parent_can_create_subdomains(suins, parent.domain());
        };

        // validate that the subdomain is valid for the supplied parent.
        config::assert_is_valid_subdomain(&parent.domain(), &subdomain, app_config(suins));
    }

    /// Validate whether a `SuinsRegistration` object is eligible for creating a subdomain.
    /// 1. If the NFT is authorized (not expired, active)
    /// 2. If the parent is a subdomain, check whether it is allowed to create subdomains.
    fun internal_assert_parent_can_create_subdomains(
        self: &SuiNS,
        parent: Domain,
    ) {
        // if the parent is not a subdomain, we can always create subdomains.
        if (!is_subdomain(&parent)) {
            return
        };

        // if `parent` is a subdomain. We check the subdomain config to see if we are allowed to mint subdomains.
        // For regular names (e.g. example.sui), we can always mint subdomains.
        // if there's no config for this parent, and the parent is a subdomain, we can't create deeper names.
        assert!(is_creation_allowed(&record_metadata(self, parent)), ECreationDisabledForSubDomain);
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
    ): SubDomainRegistration {
        let mut nft = registry.add_record_ignoring_grace_period(subdomain, 1, clock, ctx);
        // set the timestamp to the correct one. `add_record` only works with years but we can correct it easily here.
        registry.set_expiration_timestamp_ms(&mut nft, subdomain, expiration_timestamp_ms);

        // attach the `ParentID` to the SuinsRegistration, so we validate that the parent who created this subdomain
        // is the same as the one currently holding the parent domain.
        df::add(nft.uid_mut(), ParentKey {}, parent_nft_id);

        registry.wrap_subdomain(nft, clock, ctx)
    }

    // == Internal helper to access registry & app setup ==

    fun registry(suins: &SuiNS): &Registry {
        suins.registry<Registry>()
    }

    fun registry_mut(suins: &mut SuiNS): &mut Registry {
        suins::app_registry_mut<SubDomains, Registry>(SubDomains {}, suins)
    }

    fun app_config(suins: &SuiNS): &SubDomainConfig {
        suins.get_config<SubDomainConfig>()
    }

    #[test_only]
    public fun auth_for_testing(): SubDomains {
        SubDomains {}
    }
}
