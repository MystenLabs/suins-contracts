// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module suins::controller;

use std::string::String;
use sui::{clock::Clock, event::emit, tx_context::sender};
use suins::{
    domain,
    registry::Registry,
    subdomain_registration::SubDomainRegistration,
    suins::{Self, SuiNS},
    suins_registration::SuinsRegistration
};

const AVATAR: vector<u8> = b"avatar";
const CONTENT_HASH: vector<u8> = b"content_hash";
const WALRUS_SITE_ID: vector<u8> = b"walrus_site_id";

use fun registry_mut as SuiNS.registry_mut;

const EUnsupportedKey: u64 = 0;
/// The subdomain name is not a direct child of the parent domain.
const EParentMismatch: u64 = 1;
/// The domain is not a subdomain (must have depth > 2).
const ENotSubdomain: u64 = 2;

// === Events ===

/// Emitted when an expired subdomain record is pruned from the registry.
/// The SubDomainRegistration object may still exist but is now orphaned.
public struct SubnamePrunedEvent has copy, drop {
    domain_name: String,
    parent_domain: String,
}

/// Authorization token for the controller (v2) which
/// is used to call protected functions.
public struct ControllerV2() has drop;

/// Set the target address of a domain.
public fun set_target_address(
    suins: &mut SuiNS,
    nft: &SuinsRegistration,
    new_target: Option<address>,
    clock: &Clock,
) {
    let registry = suins.registry_mut();
    registry.assert_nft_is_authorized(nft, clock);

    let domain = nft.domain();
    registry.set_target_address(domain, new_target);
}

/// Set the reverse lookup address for the domain
public fun set_reverse_lookup(suins: &mut SuiNS, domain_name: String, ctx: &TxContext) {
    suins.registry_mut().set_reverse_lookup(ctx.sender(), domain::new(domain_name));
}

/// User-facing function - unset the reverse lookup address for the domain.
public fun unset_reverse_lookup(suins: &mut SuiNS, ctx: &TxContext) {
    suins.registry_mut().unset_reverse_lookup(ctx.sender());
}

/// Allows setting the reverse lookup address for an object.
/// Expects a mutable reference of the object.
public fun set_object_reverse_lookup(suins: &mut SuiNS, obj: &mut UID, domain_name: String) {
    suins.registry_mut().set_reverse_lookup(obj.to_address(), domain::new(domain_name));
}

/// Allows unsetting the reverse lookup address for an object.
/// Expects a mutable reference of the object.
public fun unset_object_reverse_lookup(suins: &mut SuiNS, obj: &mut UID) {
    suins.registry_mut().unset_reverse_lookup(obj.to_address());
}

/// User-facing function - add a new key-value pair to the name record's data.
public fun set_user_data(
    suins: &mut SuiNS,
    nft: &SuinsRegistration,
    key: String,
    value: String,
    clock: &Clock,
) {
    let registry = suins.registry_mut();
    let mut data = *registry.get_data(nft.domain());
    let domain = nft.domain();

    registry.assert_nft_is_authorized(nft, clock);
    let key_bytes = *key.as_bytes();
    assert!(
        key_bytes == AVATAR || key_bytes == CONTENT_HASH || key_bytes == WALRUS_SITE_ID,
        EUnsupportedKey,
    );

    if (data.contains(&key)) {
        data.remove(&key);
    };

    data.insert(key, value);
    registry.set_data(domain, data);
}

/// User-facing function - remove a key from the name record's data.
public fun unset_user_data(suins: &mut SuiNS, nft: &SuinsRegistration, key: String, clock: &Clock) {
    let registry = suins.registry_mut();
    let mut data = *registry.get_data(nft.domain());
    let domain = nft.domain();

    registry.assert_nft_is_authorized(nft, clock);

    if (data.contains(&key)) {
        data.remove(&key);
    };

    registry.set_data(domain, data);
}

public fun burn_expired(suins: &mut SuiNS, nft: SuinsRegistration, clock: &Clock) {
    suins.registry_mut().burn_registration_object(nft, clock);
}

public fun burn_expired_subname(suins: &mut SuiNS, nft: SubDomainRegistration, clock: &Clock) {
    suins.registry_mut().burn_subdomain_object(nft, clock);
}

/// Prunes an expired subdomain record from the registry by name, gated by ownership of the parent.
/// This allows the parent holder to clean up expired subdomain records even when they don't
/// possess the SubDomainRegistration object. After pruning, the subdomain name becomes available
/// for re-registration. The orphaned SubDomainRegistration object (if it still exists) becomes useless.
///
/// Use this when you control the parent domain but someone else holds the expired subdomain NFT.
#[allow(lint(public_entry))]
public entry fun prune_expired_subname(
    suins: &mut SuiNS,
    parent: &SuinsRegistration,
    subdomain_name: String,
    clock: &Clock,
) {
    let registry = suins.registry_mut();

    // Parent must be valid and authorized (non-expired, matches registry record).
    registry.assert_nft_is_authorized(parent, clock);

    let parent_domain = parent.domain();
    let subdomain = domain::new(subdomain_name);

    // Verify this is actually a subdomain (depth > 2).
    assert!(domain::is_subdomain(&subdomain), ENotSubdomain);

    // Ensure the subdomain is a direct child of the parent domain.
    assert!(domain::is_parent_of(&parent_domain, &subdomain), EParentMismatch);

    // Prune the expired subdomain record from the registry.
    // This will abort if the record doesn't exist or isn't expired.
    registry.prune_expired_subdomain_record(subdomain, clock);

    emit(SubnamePrunedEvent {
        domain_name: subdomain_name,
        parent_domain: parent_domain.to_string(),
    });
}

/// Get a mutable reference to the registry, if the app is authorized.
fun registry_mut(suins: &mut SuiNS): &mut Registry {
    suins::app_registry_mut<_, Registry>(ControllerV2(), suins)
}

#[test_only]
public fun auth_for_testing(): ControllerV2 {
    ControllerV2()
}

/// Authorization token for the controller.
#[deprecated(note = b"Use ControllerV2 instead")]
public struct Controller has drop {}
