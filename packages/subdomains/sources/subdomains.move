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
module suins_subdomains::subdomains;

use std::string::{String, utf8};
use sui::{clock::Clock, dynamic_field as df, event, vec_map::VecMap};
use suins::{
    constants::{subdomain_allow_extension_key, subdomain_allow_creation_key},
    domain::{Self, Domain, is_subdomain},
    registry::Registry,
    subdomain_registration::SubDomainRegistration,
    suins::{Self, SuiNS},
    suins_registration::SuinsRegistration
};
use suins_denylist::denylist;
use suins_subdomains::config::{Self, SubDomainConfig};

const AVATAR: vector<u8> = b"avatar";
const CONTENT_HASH: vector<u8> = b"content_hash";
const WALRUS_SITE_ID: vector<u8> = b"walrus_site_id";

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
/// Checks whether a key is supported or not (e.g. avatar, content_hash, etc).
const EUnsupportedKey: u64 = 7;
/// Checks whether the subdomain is a leaf record.
const ENotLeafRecord: u64 = 8;
/// The SubnameCap doesn't allow leaf subdomain creation.
const ELeafCreationNotAllowed: u64 = 10;
/// The SubnameCap doesn't allow node subdomain creation.
const ENodeCreationNotAllowed: u64 = 11;
/// The parent domain was not found in the registry.
const EParentNotFound: u64 = 12;
/// The parent domain has expired.
const EParentExpired: u64 = 13;
/// The SubnameCap is not in the active list (revoked or never registered).
const ECapNotActive: u64 = 14;
/// The SubnameCap's parent NFT ID doesn't match the registry (domain was re-registered).
const ECapInvalidated: u64 = 15;

/// Enabled metadata value.
const ACTIVE_METADATA_VALUE: vector<u8> = b"1";

/// The authentication scheme for SuiNS.
public struct SubDomains has drop {}

/// The key to store the parent's ID in the subdomain object.
public struct ParentKey has copy, drop, store {}

// SubnameCap: Minimal Revocable Delegation Primitive
//
// Custom constraints (limits, fees, allowlists) are intentionally omitted.
// Implement via external wrapper/policy modules that hold the SubnameCap.

/// A capability that allows the holder to create subnames under a specific parent domain.
/// This enables delegation without transferring the parent SuinsRegistration NFT.
public struct SubnameCap has key, store {
    id: UID,
    /// The parent domain this cap delegates for (e.g., "example.sui")
    parent_domain: Domain,
    /// The NFT ID of the parent SuinsRegistration at creation time.
    /// If record.nft_id() != this value, the cap is invalid (domain was re-registered).
    parent_nft_id: ID,
    /// Whether this cap can create leaf subdomains
    allow_leaf_creation: bool,
    /// Whether this cap can create node subdomains
    allow_node_creation: bool,
}

/// Key for storing active SubnameCaps as a dynamic field on the SuiNS object, keyed by domain.
public struct ActiveCapsKey has copy, drop, store {
    domain: Domain,
}

/// Stores information about an active SubnameCap for enumeration and validation.
public struct CapEntry has copy, drop, store {
    /// The ID of the SubnameCap
    cap_id: ID,
    /// Timestamp when the cap was created
    created_at_ms: u64,
    /// Whether this cap can create leaf subdomains
    allow_leaf: bool,
    /// Whether this cap can create node subdomains
    allow_node: bool,
}

/// Container for active SubnameCaps, stored as a dynamic field on the parent domain's NameRecord.
public struct ActiveSubnameCaps has store {
    caps: vector<CapEntry>,
}

// === SubnameCap Events ===

/// Emitted when a new SubnameCap is created.
public struct SubnameCapCreated has copy, drop {
    /// The ID of the created SubnameCap
    cap_id: ID,
    /// The parent domain this cap delegates for
    parent_domain: String,
    /// The NFT ID of the parent SuinsRegistration
    parent_nft_id: ID,
    /// Whether this cap allows leaf subdomain creation
    allow_leaf_creation: bool,
    /// Whether this cap allows node subdomain creation
    allow_node_creation: bool,
}

/// Emitted when a SubnameCap is revoked.
public struct SubnameCapRevoked has copy, drop {
    /// The ID of the revoked SubnameCap
    cap_id: ID,
    /// The parent domain the cap was for
    parent_domain: String,
    /// The NFT ID of the parent that revoked it
    parent_nft_id: ID,
}

/// Emitted when a SubnameCap is used to create a subdomain.
public struct SubnameCapUsed has copy, drop {
    /// The ID of the SubnameCap used
    cap_id: ID,
    /// The parent domain
    parent_domain: String,
    /// The subdomain that was created
    subdomain_name: String,
    /// Whether a leaf (true) or node (false) was created
    is_leaf: bool,
}

/// Emitted when a SubnameCap is surrendered by its holder.
public struct SubnameCapSurrendered has copy, drop {
    /// The ID of the surrendered SubnameCap
    cap_id: ID,
    /// The parent domain the cap was for
    parent_domain: String,
    /// The NFT ID of the parent at surrender time
    parent_nft_id: ID,
}

/// Emitted when all active caps are cleared for a domain.
public struct ActiveCapsCleared has copy, drop {
    /// The parent domain whose caps were cleared
    parent_domain: String,
    /// The NFT ID of the parent
    parent_nft_id: ID,
    /// Number of caps that were cleared
    caps_cleared: u64,
}

/// Creates a `leaf` subdomain
/// A `leaf` subdomain, is a subdomain that is managed by the parent's NFT.
public fun new_leaf(
    suins: &mut SuiNS,
    parent: &SuinsRegistration,
    clock: &Clock,
    subdomain_name: String,
    target: address,
    ctx: &mut TxContext,
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

public fun add_leaf_metadata(
    suins: &mut SuiNS,
    parent: &SuinsRegistration,
    clock: &Clock,
    subdomain_name: String,
    key: String,
    value: String,
) {
    let subdomain = domain::new(subdomain_name);
    assert!(is_leaf_record(registry(suins), subdomain), ENotLeafRecord);
    // all validation logic for subdomain creation / management.
    internal_validate_nft_can_manage_subdomain(suins, parent, clock, subdomain, false);

    let registry = registry_mut(suins);
    let mut data = *registry.get_data(subdomain);
    let key_bytes = *key.as_bytes();
    assert!(
        key_bytes == AVATAR || key_bytes == CONTENT_HASH || key_bytes == WALRUS_SITE_ID,
        EUnsupportedKey,
    );
    data.insert(key, value);

    registry.set_data(subdomain, data);
}

public fun remove_leaf_metadata(
    suins: &mut SuiNS,
    parent: &SuinsRegistration,
    clock: &Clock,
    subdomain_name: String,
    key: String,
) {
    let subdomain = domain::new(subdomain_name);
    assert!(is_leaf_record(registry(suins), subdomain), ENotLeafRecord);
    // all validation logic for subdomain creation / management.
    internal_validate_nft_can_manage_subdomain(suins, parent, clock, subdomain, false);

    let registry = registry_mut(suins);
    let mut data = *registry.get_data(subdomain);
    if (data.contains(&key)) {
        data.remove(&key);
    };

    registry.set_data(subdomain, data);
}

/// Creates a new `node` subdomain
///
/// The following script does the following lookups:
/// 1. Checks if app is authorized.
/// 2. Validates that the parent NFT is valid and non expired.
/// 3. Validates that the parent can create subdomains (based on the on-chain setup). [all 2nd level names with valid tld can create names]
/// 4. Validates the subdomain validity.
///     2.1 Checks that the TLD is in the list of supported tlds.
///     2.2 Checks that the length of the new label has the min length.
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
    ctx: &mut TxContext,
): SubDomainRegistration {
    assert!(!denylist::is_blocked_name(suins, subdomain_name), ENotAllowedName);

    let subdomain = domain::new(subdomain_name);
    // all validation logic for subdomain creation / management.
    internal_validate_nft_can_manage_subdomain(suins, parent, clock, subdomain, true);

    // Validate that the duration is at least the minimum duration.
    assert!(
        expiration_timestamp_ms >= clock.timestamp_ms() + app_config(suins).minimum_duration(),
        EInvalidExpirationDate,
    );
    // validate that the requested expiration timestamp is not greater than the parent's one.
    assert!(expiration_timestamp_ms <= parent.expiration_timestamp_ms(), EInvalidExpirationDate);

    // We register the subdomain (e.g. `subdomain.example.sui`) and return the SuinsRegistration object.
    // Aborts with `suins::registry::ERecordExists` if the subdomain already exists.
    let nft = internal_create_subdomain(
        registry_mut(suins),
        subdomain,
        expiration_timestamp_ms,
        object::id(parent),
        clock,
        ctx,
    );

    // We create the `setup` for the particular SubDomainRegistration.
    // We save a setting like: `subdomain.example.sui` -> { allow_creation: true/false, allow_time_extension: true/false }
    if (allow_creation) {
        internal_set_flag(suins, subdomain, subdomain_allow_creation_key(), allow_creation);
    };

    if (allow_time_extension) {
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
    assert!(
        is_extension_allowed(&record_metadata(suins, subdomain)),
        EExtensionDisabledForSubDomain,
    );

    let existing_name_record = registry.lookup(subdomain);
    let parent_name_record = registry.lookup(parent_domain);

    // we need to make sure this name record exists (both child + parent), otherwise we don't have a valid object.
    assert!(
        option::is_some(&existing_name_record) && option::is_some(&parent_name_record),
        ESubdomainReplaced,
    );

    // Validate that the parent of the name is the same as the actual parent
    // (to prevent cases where owner of the parent changed. When that happens, subdomains lose all abilities to renew / create subdomains)
    assert!(parent(nft) == option::borrow(&parent_name_record).nft_id(), EParentChanged);

    // validate that expiration date is > than the current.
    assert!(expiration_timestamp_ms > nft.expiration_timestamp_ms(), EInvalidExpirationDate);
    // validate that the requested expiration timestamp is not greater than the parent's one.
    assert!(
        expiration_timestamp_ms <= option::borrow(&parent_name_record).expiration_timestamp_ms(),
        EInvalidExpirationDate,
    );

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
    allow_time_extension: bool,
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
public fun burn(suins: &mut SuiNS, nft: SubDomainRegistration, clock: &Clock) {
    registry_mut(suins).burn_subdomain_object(nft, clock);
}

/// Parent ID of a subdomain
public fun parent(subdomain: &SuinsRegistration): ID {
    *df::borrow(subdomain.uid(), ParentKey {})
}

// Sets/removes a (key,value) on the domain's NameRecord metadata (depending on cases).
// Validation needs to happen on the calling function.
fun internal_set_flag(self: &mut SuiNS, subdomain: Domain, key: String, enable: bool) {
    let mut config = record_metadata(self, subdomain);
    let is_enabled = config.contains(&key);

    if (enable && !is_enabled) {
        config.insert(key, utf8(ACTIVE_METADATA_VALUE));
    };

    if (!enable && is_enabled) {
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
fun record_metadata(self: &SuiNS, subdomain: Domain): VecMap<String, String> {
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
    check_creation_auth: bool,
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
fun internal_assert_parent_can_create_subdomains(self: &SuiNS, parent: Domain) {
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

fun is_leaf_record(self: &Registry, domain: Domain): bool {
    if (!domain.is_subdomain()) {
        return false
    };

    let option_name_record = self.lookup(domain);

    if (option_name_record.is_none()) {
        return false
    };

    option_name_record.borrow().is_leaf_record()
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

// == SubnameCap Functions ==

/// Creates a new SubnameCap for the given parent domain.
/// The caller must own the parent SuinsRegistration NFT.
///
/// Parameters:
/// - `allow_leaf_creation`: Whether this cap can create leaf subdomains.
/// - `allow_node_creation`: Whether this cap can create node subdomains.
public fun create_subname_cap(
    suins: &mut SuiNS,
    parent: &SuinsRegistration,
    clock: &Clock,
    allow_leaf_creation: bool,
    allow_node_creation: bool,
    ctx: &mut TxContext,
): SubnameCap {
    // Validate parent NFT is authorized (not expired, matches registry)
    registry(suins).assert_nft_is_authorized(parent, clock);

    let cap = SubnameCap {
        id: object::new(ctx),
        parent_domain: parent.domain(),
        parent_nft_id: object::id(parent),
        allow_leaf_creation,
        allow_node_creation,
    };

    // Add cap to active list
    add_to_active_caps(
        suins,
        parent.domain(),
        object::id(&cap),
        clock.timestamp_ms(),
        allow_leaf_creation,
        allow_node_creation,
    );

    // Emit creation event
    event::emit(SubnameCapCreated {
        cap_id: object::id(&cap),
        parent_domain: parent.domain().to_string(),
        parent_nft_id: object::id(parent),
        allow_leaf_creation,
        allow_node_creation,
    });

    cap
}

/// Revokes a SubnameCap by removing it from the active caps list.
/// Can be called by anyone who holds the parent SuinsRegistration NFT.
/// Does NOT require the cap object itself (one-sided revocation).
/// Idempotent: calling this on an already-revoked cap is a no-op.
public fun revoke_subname_cap(
    suins: &mut SuiNS,
    parent: &SuinsRegistration,
    clock: &Clock,
    cap_id: ID,
) {
    // Validate parent NFT is authorized (not expired, matches registry)
    registry(suins).assert_nft_is_authorized(parent, clock);

    let parent_domain = parent.domain();

    // Remove from active list (idempotent - returns false if not found)
    if (remove_from_active_caps(suins, parent_domain, cap_id)) {
        // Emit revocation event only if we actually removed something
        event::emit(SubnameCapRevoked {
            cap_id,
            parent_domain: parent_domain.to_string(),
            parent_nft_id: object::id(parent),
        });
    }
}

/// Surrenders a SubnameCap, removing it from the active list and destroying the cap object.
/// Can be called by anyone who holds the cap (doesn't require parent NFT).
/// This provides a clean way for cap holders to remove their caps from the active list
/// before destroying the cap object.
public fun surrender_subname_cap(suins: &mut SuiNS, cap: SubnameCap) {
    let cap_id = object::id(&cap);
    let parent_domain = cap.parent_domain;
    let parent_nft_id = cap.parent_nft_id;

    // Remove from active list (may not exist if already revoked or parent re-registered)
    remove_from_active_caps(suins, parent_domain, cap_id);

    // Emit surrender event
    event::emit(SubnameCapSurrendered {
        cap_id,
        parent_domain: parent_domain.to_string(),
        parent_nft_id,
    });

    // Destroy the cap
    let SubnameCap {
        id,
        parent_domain: _,
        parent_nft_id: _,
        allow_leaf_creation: _,
        allow_node_creation: _,
    } = cap;
    object::delete(id);
}

/// Clears all active SubnameCaps for a domain, effectively revoking all delegated caps at once.
/// Can only be called by the current owner of the parent SuinsRegistration NFT.
/// Useful when transferring a domain or resetting all delegated permissions.
public fun clear_active_caps(suins: &mut SuiNS, parent: &SuinsRegistration, clock: &Clock) {
    // Validate parent NFT is authorized (not expired, matches registry)
    registry(suins).assert_nft_is_authorized(parent, clock);

    let parent_domain = parent.domain();
    let key = ActiveCapsKey { domain: parent_domain };
    let suins_uid = suins::app_uid_mut(SubDomains {}, suins);

    if (df::exists_(suins_uid, key)) {
        // Remove and drop the entire active caps list
        let ActiveSubnameCaps { caps } = df::remove(suins_uid, key);
        let count = caps.length();

        // Emit event with count of cleared caps
        event::emit(ActiveCapsCleared {
            parent_domain: parent_domain.to_string(),
            parent_nft_id: object::id(parent),
            caps_cleared: count,
        });
    };
}

/// Creates a leaf subdomain using a SubnameCap instead of the parent NFT.
public fun new_leaf_with_cap(
    suins: &mut SuiNS,
    cap: &SubnameCap,
    clock: &Clock,
    subdomain_name: String,
    target: address,
    ctx: &mut TxContext,
) {
    assert!(cap.allow_leaf_creation, ELeafCreationNotAllowed);

    // Validate cap is still valid (includes revocation, parent validity, NFT ID match)
    internal_validate_cap(suins, cap, clock);

    assert!(!denylist::is_blocked_name(suins, subdomain_name), ENotAllowedName);

    let subdomain = domain::new(subdomain_name);

    // Validate the subdomain is valid for this parent
    config::assert_is_valid_subdomain(&cap.parent_domain, &subdomain, app_config(suins));

    // Check parent can create subdomains (for subdomain parents)
    internal_assert_parent_can_create_subdomains(suins, cap.parent_domain);

    // Create the leaf record
    registry_mut(suins).add_leaf_record(subdomain, clock, target, ctx);

    // Emit usage event
    event::emit(SubnameCapUsed {
        cap_id: object::id(cap),
        parent_domain: cap.parent_domain.to_string(),
        subdomain_name,
        is_leaf: true,
    });
}

/// Creates a node subdomain using a SubnameCap instead of the parent NFT.
public fun new_with_cap(
    suins: &mut SuiNS,
    cap: &SubnameCap,
    clock: &Clock,
    subdomain_name: String,
    expiration_timestamp_ms: u64,
    allow_creation: bool,
    allow_time_extension: bool,
    ctx: &mut TxContext,
): SubDomainRegistration {
    assert!(cap.allow_node_creation, ENodeCreationNotAllowed);

    // Validate cap is still valid (includes revocation, parent validity, NFT ID match)
    internal_validate_cap(suins, cap, clock);

    assert!(!denylist::is_blocked_name(suins, subdomain_name), ENotAllowedName);

    let subdomain = domain::new(subdomain_name);

    // Validate the subdomain is valid for this parent
    config::assert_is_valid_subdomain(&cap.parent_domain, &subdomain, app_config(suins));

    // Check parent can create subdomains (for subdomain parents)
    internal_assert_parent_can_create_subdomains(suins, cap.parent_domain);

    // Get parent's expiration from registry to validate expiration
    let parent_record = registry(suins).lookup(cap.parent_domain);
    assert!(parent_record.is_some(), EParentNotFound);
    let parent_expiration = parent_record.borrow().expiration_timestamp_ms();

    // Validate that the duration is at least the minimum duration.
    assert!(
        expiration_timestamp_ms >= clock.timestamp_ms() + app_config(suins).minimum_duration(),
        EInvalidExpirationDate,
    );
    // Validate that the requested expiration timestamp is not greater than the parent's one.
    assert!(expiration_timestamp_ms <= parent_expiration, EInvalidExpirationDate);

    // Create the subdomain using the parent_nft_id from the cap
    let nft = internal_create_subdomain(
        registry_mut(suins),
        subdomain,
        expiration_timestamp_ms,
        cap.parent_nft_id,
        clock,
        ctx,
    );

    // Set up permissions using caller-provided values
    if (allow_creation) {
        internal_set_flag(suins, subdomain, subdomain_allow_creation_key(), true);
    };
    if (allow_time_extension) {
        internal_set_flag(suins, subdomain, subdomain_allow_extension_key(), true);
    };

    // Emit usage event
    event::emit(SubnameCapUsed {
        cap_id: object::id(cap),
        parent_domain: cap.parent_domain.to_string(),
        subdomain_name,
        is_leaf: false,
    });

    nft
}

/// Validates that a SubnameCap is still valid for use.
fun internal_validate_cap(suins: &SuiNS, cap: &SubnameCap, clock: &Clock) {
    let parent_record = registry(suins).lookup(cap.parent_domain);

    // Parent must exist in registry
    assert!(parent_record.is_some(), EParentNotFound);

    let record = parent_record.borrow();

    // Parent must not be expired
    assert!(!record.has_expired(clock), EParentExpired);

    // The NFT ID must match (parent hasn't been re-registered)
    assert!(record.nft_id() == cap.parent_nft_id, ECapInvalidated);

    // Check if cap is in the active list
    assert!(is_cap_in_active_list(suins, cap.parent_domain, object::id(cap)), ECapNotActive);
}

// == Active Caps List Management ==

/// Gets the active caps list for a domain, or creates an empty one if it doesn't exist.
fun get_or_create_active_caps(suins: &mut SuiNS, domain: Domain): &mut ActiveSubnameCaps {
    let key = ActiveCapsKey { domain };
    let suins_uid = suins::app_uid_mut(SubDomains {}, suins);

    if (!df::exists_(suins_uid, key)) {
        df::add(suins_uid, key, ActiveSubnameCaps { caps: vector[] });
    };

    df::borrow_mut(suins_uid, key)
}

/// Checks if a cap ID is in the active caps list for a domain.
fun is_cap_in_active_list(suins: &SuiNS, domain: Domain, cap_id: ID): bool {
    let key = ActiveCapsKey { domain };
    let suins_uid = suins::app_uid(SubDomains {}, suins);

    if (!df::exists_(suins_uid, key)) {
        return false
    };

    let active_caps: &ActiveSubnameCaps = df::borrow(suins_uid, key);
    let mut i = 0;
    let len = active_caps.caps.length();
    while (i < len) {
        if (active_caps.caps[i].cap_id == cap_id) {
            return true
        };
        i = i + 1;
    };
    false
}

/// Adds a cap to the active caps list.
fun add_to_active_caps(
    suins: &mut SuiNS,
    domain: Domain,
    cap_id: ID,
    created_at_ms: u64,
    allow_leaf: bool,
    allow_node: bool,
) {
    let active_caps = get_or_create_active_caps(suins, domain);
    active_caps
        .caps
        .push_back(CapEntry {
            cap_id,
            created_at_ms,
            allow_leaf,
            allow_node,
        });
}

/// Removes a cap from the active caps list. Returns true if found and removed.
fun remove_from_active_caps(suins: &mut SuiNS, domain: Domain, cap_id: ID): bool {
    let key = ActiveCapsKey { domain };
    let suins_uid = suins::app_uid_mut(SubDomains {}, suins);

    if (!df::exists_(suins_uid, key)) {
        return false
    };

    let active_caps: &mut ActiveSubnameCaps = df::borrow_mut(suins_uid, key);
    let mut i = 0;
    let len = active_caps.caps.length();
    while (i < len) {
        if (active_caps.caps[i].cap_id == cap_id) {
            active_caps.caps.swap_remove(i);
            return true
        };
        i = i + 1;
    };
    false
}

// == SubnameCap Getters ==

/// Get the parent domain for this SubnameCap.
public fun cap_parent_domain(cap: &SubnameCap): Domain {
    cap.parent_domain
}

/// Get the parent NFT ID for this SubnameCap.
public fun cap_parent_nft_id(cap: &SubnameCap): ID {
    cap.parent_nft_id
}

/// Check if this SubnameCap allows leaf subdomain creation.
public fun cap_allow_leaf_creation(cap: &SubnameCap): bool {
    cap.allow_leaf_creation
}

/// Check if this SubnameCap allows node subdomain creation.
public fun cap_allow_node_creation(cap: &SubnameCap): bool {
    cap.allow_node_creation
}

/// Check if a SubnameCap is active (in the active list for its parent domain).
public fun is_cap_active(suins: &SuiNS, cap: &SubnameCap): bool {
    is_cap_in_active_list(suins, cap.parent_domain, object::id(cap))
}

/// Check if a SubnameCap is revoked (not in the active list).
/// This is the inverse of is_cap_active - a cap is considered revoked if it's not active.
public fun is_cap_revoked(suins: &SuiNS, cap: &SubnameCap): bool {
    !is_cap_active(suins, cap)
}

// == Active Caps Enumeration ==

/// Get all active cap entries for a domain.
/// Returns an empty vector if no caps have been created for this domain.
public fun get_active_caps(suins: &SuiNS, domain: Domain): vector<CapEntry> {
    let key = ActiveCapsKey { domain };
    let suins_uid = suins::app_uid(SubDomains {}, suins);

    if (!df::exists_(suins_uid, key)) {
        return vector[]
    };

    let active_caps: &ActiveSubnameCaps = df::borrow(suins_uid, key);
    active_caps.caps
}

/// Get the number of active caps for a domain.
public fun get_active_caps_count(suins: &SuiNS, domain: Domain): u64 {
    let key = ActiveCapsKey { domain };
    let suins_uid = suins::app_uid(SubDomains {}, suins);

    if (!df::exists_(suins_uid, key)) {
        return 0
    };

    let active_caps: &ActiveSubnameCaps = df::borrow(suins_uid, key);
    active_caps.caps.length()
}

// == CapEntry Getters ==

/// Get the cap ID from a CapEntry.
public fun cap_entry_id(entry: &CapEntry): ID {
    entry.cap_id
}

/// Get the creation timestamp from a CapEntry.
public fun cap_entry_created_at_ms(entry: &CapEntry): u64 {
    entry.created_at_ms
}

/// Check if a CapEntry allows leaf creation.
public fun cap_entry_allow_leaf(entry: &CapEntry): bool {
    entry.allow_leaf
}

/// Check if a CapEntry allows node creation.
public fun cap_entry_allow_node(entry: &CapEntry): bool {
    entry.allow_node
}

#[test_only]
public fun auth_for_testing(): SubDomains {
    SubDomains {}
}
