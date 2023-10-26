// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// The core of D3 functionality.
/// 
module d3::d3 {
    use std::string::{String, utf8};
    use std::vector;

    use sui::object::{Self};
    use sui::tx_context::{TxContext};
    use sui::clock::{Self, Clock};
    use sui::dynamic_field::{Self as df};
    use sui::vec_map::{Self, VecMap};
    use sui::event;

    use suins::domain::{Self, Domain};
    use suins::registry::{Self, Registry};
    use suins::suins::SuiNS;
    use suins::config;
    use suins::suins_registration::{Self, SuinsRegistration};

    use d3::constants::{d3_compatibility_metadata_key, icann_lock_metadata_key};
    use d3::auth::{Self, registry_mut, DThreeCap};
    
    /// Number of years passed is not within [1-5] interval.
    const EInvalidYearsArgument: u64 = 0;
    /// The cap is not authorized to mint names.
    const ECapNotAuthorized: u64 = 1;
    /// Tries to edit a domain that's not registered in the registry.
    const EDomainNotRegistered: u64 = 2;
    /// Tries to edit a non-d3 compatible name.
    const ENotD3CompatibleRecord: u64 = 3;

    /// A DF key to show that a `SuinsRegistration` object is D3 compliant.
    /// Helpful for clients to query this without looking up the registry 
    /// ++ future display support (showing a D3 label or something similar)
    struct DThreeCompatibleName has copy, store, drop {}

    /// An event emitted when a name is minted by D3.
    struct DThreeMintEvent has copy, drop {
        domain: Domain,
        timestamp_ms: u64
    }

    // Allows registering from D3's side with D3 Cap
    //
    // Makes sure that:
    // - the domain is not already registered (or, if active, expired)
    // - the domain TLD is .sui
    // - the domain is not a subdomain
    // - number of years is within [1-5] interval
    // We attach the D3 eligibility to the SuinsRegistration
    public fun create_name(
        suins: &mut SuiNS,
        domain_name: String,
        no_years: u8,
        clock: &Clock,
        cap: &DThreeCap,
        ctx: &mut TxContext
    ): SuinsRegistration {
        auth::assert_app_authorized(suins);

        assert!(is_cap_authorized(suins, cap), ECapNotAuthorized);

        let domain = domain::new(domain_name);
        config::assert_valid_user_registerable_domain(&domain);

        assert!(0 < no_years && no_years <= 5, EInvalidYearsArgument);

        let registry = registry_mut(suins);

        let registration = registry::add_record(registry, domain, no_years, clock, ctx);

        // We attach the D3 eligibility flag to the SuinsRegistration object.
        df::add(suins_registration::uid_mut(&mut registration), DThreeCompatibleName {}, true);

        // We also attach the D3 eligibility to the NameRecord.
        let metadata: VecMap<String, String> = vec_map::empty();
        vec_map::insert(&mut metadata, d3_compatibility_metadata_key(), utf8(b"true"));

        registry::set_data(registry, domain, metadata);

        // Emit an event so we can track the minting of D3 names easily.
        event::emit(DThreeMintEvent {
            domain: domain,
            timestamp_ms: clock::timestamp_ms(clock)
        });

        registration
    }

    /// === ICANN functionality ===
    /// Locks a D3 name (ICANN)
    public fun icann_lock(suins: &mut SuiNS, _: &DThreeCap, domain_name: String) {
        auth::assert_app_authorized(suins);

        let registry_mut = registry_mut(suins);

        let data = internal_get_record_data(registry_mut, domain_name);
        vec_map::insert(&mut data, icann_lock_metadata_key(), utf8(b"true"));

        registry::set_data(registry_mut, domain::new(domain_name), data);
    }

    /// Unlocks a D3 name (ICANN)
    public fun icann_unlock(suins: &mut SuiNS, _: &DThreeCap, domain_name: String) {
        auth::assert_app_authorized(suins);

        let registry_mut = registry_mut(suins);

        let data = internal_get_record_data(registry_mut, domain_name);
        vec_map::remove(&mut data, &icann_lock_metadata_key());

        registry::set_data(registry_mut, domain::new(domain_name), data);
    }

    /// Validate whether a D3Cap is authorized for use in the app.
    public fun is_cap_authorized(suins: &SuiNS, cap: &DThreeCap): bool {
        vector::contains(auth::d3_allowed_keys(suins), &object::id(cap))
    }

    /// A helper to validate whether a name is D3 compatible by looking up the registry.
    public fun registry_is_compatible_d3_name(suins: &SuiNS, domain_name: String): bool {
        let data = registry::get_data(auth::registry(suins), domain::new(domain_name));

        is_d3_compatible_name(data)
    }

    public fun registry_is_icann_locked_name(suins: &SuiNS, domain_name: String): bool {
        let data = registry::get_data(auth::registry(suins), domain::new(domain_name));
        is_icann_locked_name(data)
    }

    public fun is_icann_locked_name(data: &VecMap<String, String>): bool {
        vec_map::contains(data, &icann_lock_metadata_key())
    }

    /// Validates that a name is D3 compatible. Accepts name record's data as the parameter. 
    public fun is_d3_compatible_name(data: &VecMap<String, String>): bool {
        vec_map::contains(data, &d3_compatibility_metadata_key())
    }
    
    /// An internal helper to get record data (editable)
    /// 
    /// Validates:
    /// 1. Name is a valid name for registrations (won't work for subdomains or non-supported TLDs).
    /// 2. Name is registered.
    /// 3. Name is D3 compatible (D3 contract can't alter non-D3 names).
    /// 
    /// Returns:
    /// A VecMap that the function can edit (add/remove keys).
    fun internal_get_record_data(registry: &Registry, domain_name: String): VecMap<String, String> {
        let domain = domain::new(domain_name);

        config::assert_valid_user_registerable_domain(&domain);

        assert!(registry::has_record(registry, domain::new(domain_name)), EDomainNotRegistered);
        let data = *registry::get_data(registry, domain);

        assert!(is_d3_compatible_name(&data), ENotD3CompatibleRecord);

        data
    }

    #[test_only]
    public fun add_non_d3_domain_for_testing(
        suins: &mut SuiNS,
        domain_name: String,
        clock: &Clock,
        ctx: &mut TxContext
    ): SuinsRegistration {
        let registry = registry_mut(suins);

        registry::add_record(registry, domain::new(domain_name), 1, clock, ctx)
    }
}
