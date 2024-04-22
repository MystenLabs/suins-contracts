// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// A simple package to allows us set a target address &  default name in a single PTB in frontend.
/// Unblocks better UX in the registration flow.
module utils::direct_setup {
    use std::string::String;

    use sui::clock::Clock;

    use suins::{
        domain, 
        registry::Registry, 
        suins::{Self, SuiNS}, 
        suins_registration::SuinsRegistration,
        subdomain_registration::SubDomainRegistration
    };

    /// Tries to add not supported user data in the vecmap of the name record.
    const EUnsupportedKey: u64 = 1;

    const AVATAR: vector<u8> = b"avatar";
    const CONTENT_HASH: vector<u8> = b"content_hash";

    /// Authorization token for the controller.
    public struct DirectSetup has drop {}

    /// Set the target address of a domain.
    public fun set_target_address(
        suins: &mut SuiNS,
        nft: &SuinsRegistration,
        new_target: Option<address>,
        clock: &Clock,
    ) {
        let registry = registry_mut(suins);
        registry.assert_nft_is_authorized(nft, clock);

        let domain = nft.domain();
        registry.set_target_address(domain, new_target);
    }

    /// Set the reverse lookup address for the domain
    public fun set_reverse_lookup(suins: &mut SuiNS, domain_name: String, ctx: &TxContext) {
        registry_mut(suins).set_reverse_lookup(ctx.sender(), domain::new(domain_name));
    }

    /// User-facing function - unset the reverse lookup address for the domain.
    public fun unset_reverse_lookup(suins: &mut SuiNS, ctx: &TxContext) {
        registry_mut(suins).unset_reverse_lookup(ctx.sender());
    }

    /// User-facing function - add a new key-value pair to the name record's data.
    public fun set_user_data(
        suins: &mut SuiNS, nft: &SuinsRegistration, key: String, value: String, clock: &Clock
    ) {
        let registry = registry_mut(suins);
        let mut data = *registry.get_data(nft.domain());
        let domain = nft.domain();

        registry.assert_nft_is_authorized(nft, clock);
        let key_bytes = *key.bytes();
        assert!(key_bytes == AVATAR || key_bytes == CONTENT_HASH, EUnsupportedKey);

        if (data.contains(&key)) {
            data.remove(&key);
        };

        data.insert(key, value);
        registry.set_data(domain, data);
    }

    /// User-facing function - remove a key from the name record's data.
    public fun unset_user_data(
        suins: &mut SuiNS, nft: &SuinsRegistration, key: String, clock: &Clock
    ) {
        let registry = registry_mut(suins);
        let mut data = *registry.get_data(nft.domain());
        let domain = nft.domain();

        registry.assert_nft_is_authorized(nft, clock);

        if (data.contains(&key)) {
            data.remove(&key);
        };

        registry.set_data(domain, data);
    }

    public fun burn_expired(suins: &mut SuiNS, nft: SuinsRegistration, clock: &Clock) {
        registry_mut(suins).burn_registration_object(nft, clock);
    }

    public fun burn_expired_subname(suins: &mut SuiNS, nft: SubDomainRegistration, clock: &Clock) {
        registry_mut(suins).burn_subdomain_object(nft, clock);
    }

    fun registry_mut(suins: &mut SuiNS): &mut Registry {
        suins::app_registry_mut<DirectSetup, Registry>(DirectSetup {}, suins)
    }
}
