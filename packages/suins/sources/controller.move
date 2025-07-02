// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module suins::controller;

use std::string::String;
use sui::{clock::Clock, tx_context::sender};
use suins::{
    domain::{Self, is_parent_of},
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
const EInvalidParent: u64 = 1;

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

/// User-facing function - add a new key-value pair to the name record's data.
/// This is used for leaf subdomains.
public fun set_user_data_leaf_subname(
    suins: &mut SuiNS,
    nft: &SuinsRegistration,
    key: String,
    value: String,
    subdomain_name: String,
    clock: &Clock,
) {
    let registry = suins.registry_mut();
    let parent_domain = nft.domain();
    let subdomain = domain::new(subdomain_name);
    let mut data = *registry.get_data(subdomain);
    assert!(is_parent_of(&parent_domain, &subdomain), EInvalidParent);

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
    registry.set_data(subdomain, data);
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

/// User-facing function - remove a key from the name record's data.
/// This is used for leaf subdomains.
public fun unset_user_data_leaf_subname(
    suins: &mut SuiNS,
    nft: &SuinsRegistration,
    key: String,
    subdomain_name: String,
    clock: &Clock,
) {
    let registry = suins.registry_mut();
    let parent_domain = nft.domain();
    let subdomain = domain::new(subdomain_name);
    let mut data = *registry.get_data(subdomain);

    assert!(is_parent_of(&parent_domain, &subdomain), EInvalidParent);

    registry.assert_nft_is_authorized(nft, clock);

    if (data.contains(&key)) {
        data.remove(&key);
    };

    registry.set_data(subdomain, data);
}

public fun burn_expired(suins: &mut SuiNS, nft: SuinsRegistration, clock: &Clock) {
    suins.registry_mut().burn_registration_object(nft, clock);
}

public fun burn_expired_subname(suins: &mut SuiNS, nft: SubDomainRegistration, clock: &Clock) {
    suins.registry_mut().burn_subdomain_object(nft, clock);
}

/// Get a mutable reference to the registry, if the app is authorized.
fun registry_mut(suins: &mut SuiNS): &mut Registry {
    suins::app_registry_mut<_, Registry>(ControllerV2(), suins)
}

/// Authorization token for the controller.
#[deprecated(note = b"Use ControllerV2 instead")]
public struct Controller has drop {}
