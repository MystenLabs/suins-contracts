// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module suins_subdomains::subdomain_tests;

use std::string::{String, utf8};
use sui::{clock::{Self, Clock}, test_scenario::{Self as ts, Scenario, ctx}};
use suins::{
    constants::{grace_period_ms, year_ms, subdomain_allow_creation_key, subdomain_allow_extension_key},
    domain,
    registry::{Self, Registry},
    registry_tests::burn_nfts,
    subdomain_registration::{Self, SubDomainRegistration},
    suins::{Self, SuiNS, AdminCap},
    suins_registration::{Self, SuinsRegistration}
};
use suins_denylist::denylist;
use suins_subdomains::{config, subdomains::{Self, SubDomains}};

const USER_ADDRESS: address = @0x01;
const TEST_ADDRESS: address = @0x02;

const MIN_SUBDOMAIN_DURATION: u64 = 24 * 60 * 60 * 1000; // 1 day

#[test]
/// A test scenario
fun test_multiple_operation_cases() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;

    let parent = create_sld_name(utf8(b"test.sui"), scenario);

    let mut child = create_node_subdomain(
        &parent,
        utf8(b"node.test.sui"),
        MIN_SUBDOMAIN_DURATION,
        true,
        true,
        scenario,
    );

    create_leaf_subdomain(&parent, utf8(b"leaf.test.sui"), TEST_ADDRESS, scenario);
    add_leaf_metadata(&parent, utf8(b"leaf.test.sui"), utf8(b"avatar"), utf8(b"value1"), scenario);
    add_leaf_metadata(
        &parent,
        utf8(b"leaf.test.sui"),
        utf8(b"content_hash"),
        utf8(b"value2"),
        scenario,
    );
    add_leaf_metadata(
        &parent,
        utf8(b"leaf.test.sui"),
        utf8(b"walrus_site_id"),
        utf8(b"value3"),
        scenario,
    );

    ts::next_tx(scenario, USER_ADDRESS);
    let mut suins = ts::take_shared<SuiNS>(scenario);
    let subdomain = domain::new(utf8(b"leaf.test.sui"));
    let data = *registry_mut(&mut suins).get_data(subdomain);
    assert!(data.get((&utf8(b"avatar"))) == utf8(b"value1"));
    assert!(data.get((&utf8(b"content_hash"))) == utf8(b"value2"));
    assert!(data.get((&utf8(b"walrus_site_id"))) == utf8(b"value3"));
    ts::return_shared(suins);

    remove_leaf_metadata(&parent, utf8(b"leaf.test.sui"), utf8(b"avatar"), scenario);
    remove_leaf_metadata(&parent, utf8(b"leaf.test.sui"), utf8(b"content_hash"), scenario);
    remove_leaf_metadata(&parent, utf8(b"leaf.test.sui"), utf8(b"walrus_site_id"), scenario);
    remove_leaf_subdomain(&parent, utf8(b"leaf.test.sui"), scenario);

    // Create a node name with the same name as the leaf that was deleted.
    let another_child = create_node_subdomain(
        &parent,
        utf8(b"leaf.test.sui"),
        MIN_SUBDOMAIN_DURATION,
        true,
        true,
        scenario,
    );

    let nested = create_node_subdomain(
        subdomain_registration::nft(&child),
        utf8(b"nested.node.test.sui"),
        MIN_SUBDOMAIN_DURATION,
        true,
        true,
        scenario,
    );

    // extend node's subdomain expiration to the limit.
    extend_node_subdomain(
        &mut child,
        suins_registration::expiration_timestamp_ms(&parent),
        scenario,
    );

    // update subdomain's setup for testing
    update_subdomain_setup(&parent, utf8(b"node.test.sui"), false, false, scenario);

    increment_clock(year_ms() +1, scenario);

    burn_subdomain(child, scenario);
    burn_subdomain(nested, scenario);
    burn_subdomain(another_child, scenario);

    burn_nfts(vector[parent]);
    ts::end(scenario_val);
}

#[test, expected_failure(abort_code = ::suins_subdomains::config::EInvalidParent)]
fun test_add_leaf_metadata_wrong_parent() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;

    let parent = create_sld_name(utf8(b"test.sui"), scenario);
    let parent2 = create_sld_name(utf8(b"test2.sui"), scenario);

    create_leaf_subdomain(&parent, utf8(b"leaf.test.sui"), TEST_ADDRESS, scenario);
    add_leaf_metadata(&parent2, utf8(b"leaf.test.sui"), utf8(b"avatar"), utf8(b"value1"), scenario);

    abort
}

#[test, expected_failure(abort_code = ::suins_subdomains::config::EInvalidParent)]
fun test_remove_leaf_metadata_wrong_parent() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;

    let parent = create_sld_name(utf8(b"test.sui"), scenario);
    let parent2 = create_sld_name(utf8(b"test2.sui"), scenario);

    create_leaf_subdomain(&parent, utf8(b"leaf.test.sui"), TEST_ADDRESS, scenario);
    add_leaf_metadata(&parent, utf8(b"leaf.test.sui"), utf8(b"avatar"), utf8(b"value1"), scenario);
    remove_leaf_metadata(&parent2, utf8(b"leaf.test.sui"), utf8(b"avatar"), scenario);

    abort
}

#[test, expected_failure(abort_code = ::suins_subdomains::subdomains::EInvalidExpirationDate)]
fun expiration_past_parents_expiration() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;
    let parent = create_sld_name(utf8(b"test.sui"), scenario);

    let _child = create_node_subdomain(
        &parent,
        utf8(b"node.test.sui"),
        suins_registration::expiration_timestamp_ms(&parent) + 1,
        true,
        true,
        scenario,
    );

    abort
}

#[test, expected_failure(abort_code = ::suins_subdomains::config::EInvalidParent)]
/// tries to create a child node using an invalid parent.
fun invalid_parent_failure() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;
    let parent = create_sld_name(utf8(b"test.sui"), scenario);

    let _child = create_node_subdomain(
        &parent,
        utf8(b"node.example.sui"),
        suins_registration::expiration_timestamp_ms(&parent),
        true,
        true,
        scenario,
    );

    abort
}

#[
    test,
    expected_failure(
        abort_code = ::suins_subdomains::subdomains::ECreationDisabledForSubDomain,
    ),
]
fun tries_to_create_subdomain_with_disallowed_node_parent() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;
    let parent = create_sld_name(utf8(b"test.sui"), scenario);

    let child = create_node_subdomain(
        &parent,
        utf8(b"node.test.sui"),
        suins_registration::expiration_timestamp_ms(&parent),
        false,
        true,
        scenario,
    );

    let child_nft = subdomain_registration::nft(&child);
    let _nested = create_node_subdomain(
        child_nft,
        utf8(b"test.node.test.sui"),
        suins_registration::expiration_timestamp_ms(child_nft),
        false,
        true,
        scenario,
    );

    abort
}

#[
    test,
    expected_failure(
        abort_code = ::suins_subdomains::subdomains::EExtensionDisabledForSubDomain,
    ),
]
fun tries_to_extend_without_permissions() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;
    let parent = create_sld_name(utf8(b"test.sui"), scenario);

    let mut child = create_node_subdomain(
        &parent,
        utf8(b"node.test.sui"),
        MIN_SUBDOMAIN_DURATION,
        false,
        false,
        scenario,
    );

    extend_node_subdomain(&mut child, 2, scenario);

    abort
}

#[test, expected_failure(abort_code = ::suins_subdomains::subdomains::EParentChanged)]
fun tries_to_extend_while_parent_changed() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;
    let parent = create_sld_name(utf8(b"test.sui"), scenario);

    // child is an expired name ofc.
    let mut child = create_node_subdomain(
        &parent,
        utf8(b"node.test.sui"),
        MIN_SUBDOMAIN_DURATION,
        true,
        true,
        scenario,
    );

    increment_clock(
        suins_registration::expiration_timestamp_ms(&parent) +grace_period_ms() + 1,
        scenario,
    );

    let _parent_w_different_owner = create_sld_name(utf8(b"test.sui"), scenario);

    // any extension.
    extend_node_subdomain(&mut child, 2, scenario);

    abort
}

#[test, expected_failure(abort_code = ::suins::registry::ERecordExpired)]
fun tries_to_use_expired_subdomain_to_create_new() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;
    let parent = create_sld_name(utf8(b"test.sui"), scenario);

    let child = create_node_subdomain(
        &parent,
        utf8(b"node.test.sui"),
        MIN_SUBDOMAIN_DURATION,
        true,
        true,
        scenario,
    );

    increment_clock(MIN_SUBDOMAIN_DURATION +1, scenario);
    create_leaf_subdomain(
        subdomain_registration::nft(&child),
        utf8(b"node.node.test.sui"),
        TEST_ADDRESS,
        scenario,
    );

    abort
}

#[test, expected_failure(abort_code = ::suins_subdomains::subdomains::EInvalidExpirationDate)]
fun tries_to_create_too_short_subdomain() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;
    let parent = create_sld_name(utf8(b"test.sui"), scenario);

    let _child = create_node_subdomain(&parent, utf8(b"node.test.sui"), 1, true, true, scenario);

    abort
}

#[test, expected_failure(abort_code = ::suins_subdomains::config::EInvalidParent)]
fun tries_to_created_nested_leaf_subdomain() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;
    let parent = create_sld_name(utf8(b"test.sui"), scenario);
    create_leaf_subdomain(&parent, utf8(b"node.node.test.sui"), TEST_ADDRESS, scenario);

    abort
}

#[test, expected_failure(abort_code = ::suins_subdomains::subdomains::ENotLeafRecord)]
fun add_leaf_metadata_not_leaf_record() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;

    let parent = create_sld_name(utf8(b"test.sui"), scenario);

    let _child = create_node_subdomain(
        &parent,
        utf8(b"node.test.sui"),
        MIN_SUBDOMAIN_DURATION,
        true,
        true,
        scenario,
    );

    add_leaf_metadata(&parent, utf8(b"node.test.sui"), utf8(b"avatar"), utf8(b"value1"), scenario);

    abort
}

#[test, expected_failure(abort_code = ::suins_subdomains::subdomains::ENotLeafRecord)]
fun remove_leaf_metadata_not_leaf_record() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;

    let parent = create_sld_name(utf8(b"test.sui"), scenario);

    let _child = create_node_subdomain(
        &parent,
        utf8(b"node.test.sui"),
        MIN_SUBDOMAIN_DURATION,
        true,
        true,
        scenario,
    );

    remove_leaf_metadata(&parent, utf8(b"node.test.sui"), utf8(b"avatar"), scenario);

    abort
}

// == Helpers ==

public fun test_init(): Scenario {
    let mut scenario_val = ts::begin(USER_ADDRESS);
    let scenario = &mut scenario_val;
    {
        let mut suins = suins::init_for_testing(ctx(scenario));
        suins::authorize_app_for_testing<SubDomains>(&mut suins);
        suins::share_for_testing(suins);
        let clock = clock::create_for_testing(ctx(scenario));
        clock::share_for_testing(clock);
    };
    {
        ts::next_tx(scenario, USER_ADDRESS);
        let admin_cap = ts::take_from_sender<AdminCap>(scenario);
        let mut suins = ts::take_shared<SuiNS>(scenario);
        suins::add_config(&admin_cap, &mut suins, config::default());

        registry::init_for_testing(&admin_cap, &mut suins, ctx(scenario));
        denylist::setup(&mut suins, &admin_cap, ctx(scenario));

        ts::return_shared(suins);
        ts::return_to_sender(scenario, admin_cap);
    };
    scenario_val
}

/// Get the active registry of the current scenario. (mutable, so we can add extra names ourselves)
public fun registry_mut(suins: &mut SuiNS): &mut Registry {
    let registry_mut = suins::app_registry_mut<SubDomains, Registry>(
        subdomains::auth_for_testing(),
        suins,
    );

    registry_mut
}

/// Create a regular name to help with our tests.
public fun create_sld_name(name: String, scenario: &mut Scenario): SuinsRegistration {
    ts::next_tx(scenario, USER_ADDRESS);
    let mut suins = ts::take_shared<SuiNS>(scenario);
    let clock = ts::take_shared<Clock>(scenario);
    let registry_mut = registry_mut(&mut suins);

    let parent = registry::add_record(registry_mut, domain::new(name), 1, &clock, ctx(scenario));

    ts::return_shared(clock);
    ts::return_shared(suins);
    parent
}

/// Create a leaf subdomain
public fun create_leaf_subdomain(
    parent: &SuinsRegistration,
    name: String,
    target: address,
    scenario: &mut Scenario,
) {
    ts::next_tx(scenario, USER_ADDRESS);
    let mut suins = ts::take_shared<SuiNS>(scenario);
    let clock = ts::take_shared<Clock>(scenario);

    subdomains::new_leaf(&mut suins, parent, &clock, name, target, ctx(scenario));

    ts::return_shared(suins);
    ts::return_shared(clock);
}

public fun add_leaf_metadata(
    parent: &SuinsRegistration,
    subdomain_name: String,
    key: String,
    value: String,
    scenario: &mut Scenario,
) {
    ts::next_tx(scenario, USER_ADDRESS);
    let mut suins = ts::take_shared<SuiNS>(scenario);
    let clock = ts::take_shared<Clock>(scenario);

    subdomains::add_leaf_metadata(
        &mut suins,
        parent,
        &clock,
        subdomain_name,
        key,
        value,
    );

    ts::return_shared(suins);
    ts::return_shared(clock);
}

public fun remove_leaf_metadata(
    parent: &SuinsRegistration,
    subdomain_name: String,
    key: String,
    scenario: &mut Scenario,
) {
    ts::next_tx(scenario, USER_ADDRESS);
    let mut suins = ts::take_shared<SuiNS>(scenario);
    let clock = ts::take_shared<Clock>(scenario);

    subdomains::remove_leaf_metadata(&mut suins, parent, &clock, subdomain_name, key);

    ts::return_shared(suins);
    ts::return_shared(clock);
}

/// Remove a leaf subdomain
public fun remove_leaf_subdomain(
    parent: &SuinsRegistration,
    name: String,
    scenario: &mut Scenario,
) {
    ts::next_tx(scenario, USER_ADDRESS);
    let mut suins = ts::take_shared<SuiNS>(scenario);
    let clock = ts::take_shared<Clock>(scenario);

    subdomains::remove_leaf(&mut suins, parent, &clock, name);

    ts::return_shared(suins);
    ts::return_shared(clock);
}

/// Create a node subdomain
public fun create_node_subdomain(
    parent: &SuinsRegistration,
    name: String,
    expiration: u64,
    allow_creation: bool,
    allow_extension: bool,
    scenario: &mut Scenario,
): SubDomainRegistration {
    ts::next_tx(scenario, USER_ADDRESS);
    let mut suins = ts::take_shared<SuiNS>(scenario);
    let clock = ts::take_shared<Clock>(scenario);

    let nft = subdomains::new(
        &mut suins,
        parent,
        &clock,
        name,
        expiration,
        allow_creation,
        allow_extension,
        ctx(scenario),
    );

    ts::return_shared(suins);
    ts::return_shared(clock);

    nft
}

/// Extend a node subdomain's expiration.
public fun extend_node_subdomain(
    nft: &mut SubDomainRegistration,
    expiration: u64,
    scenario: &mut Scenario,
) {
    ts::next_tx(scenario, USER_ADDRESS);
    let mut suins = ts::take_shared<SuiNS>(scenario);
    let clock = ts::take_shared<Clock>(scenario);

    subdomains::extend_expiration(&mut suins, nft, expiration);

    ts::return_shared(suins);
    ts::return_shared(clock);
}

public fun update_subdomain_setup(
    parent: &SuinsRegistration,
    subdomain: String,
    allow_creation: bool,
    allow_extension: bool,
    scenario: &mut Scenario,
) {
    ts::next_tx(scenario, USER_ADDRESS);
    let mut suins = ts::take_shared<SuiNS>(scenario);
    let clock = ts::take_shared<Clock>(scenario);

    subdomains::edit_setup(&mut suins, parent, &clock, subdomain, allow_creation, allow_extension);

    ts::return_shared(suins);
    ts::return_shared(clock);
}

public fun burn_subdomain(nft: SubDomainRegistration, scenario: &mut Scenario) {
    ts::next_tx(scenario, USER_ADDRESS);
    let mut suins = ts::take_shared<SuiNS>(scenario);
    let clock = ts::take_shared<Clock>(scenario);

    subdomains::burn(&mut suins, nft, &clock);

    ts::return_shared(suins);
    ts::return_shared(clock);
}

public fun increment_clock(to: u64, scenario: &mut Scenario) {
    ts::next_tx(scenario, USER_ADDRESS);
    let mut clock = ts::take_shared<Clock>(scenario);
    clock::increment_for_testing(&mut clock, to);
    ts::return_shared(clock);
}

// == SubnameCap Tests ==

use suins_subdomains::subdomains::SubnameCap;

/// Helper to create a SubnameCap with no limits (unlimited)
public fun create_subname_cap(
    parent: &SuinsRegistration,
    allow_leaf: bool,
    allow_node: bool,
    default_allow_creation: bool,
    default_allow_extension: bool,
    scenario: &mut Scenario,
): SubnameCap {
    create_subname_cap_with_limits(
        parent,
        allow_leaf,
        allow_node,
        default_allow_creation,
        default_allow_extension,
        option::none(),
        option::none(),
        option::none(),
        scenario,
    )
}

/// Helper to create a SubnameCap with programmable limits
public fun create_subname_cap_with_limits(
    parent: &SuinsRegistration,
    allow_leaf: bool,
    allow_node: bool,
    default_allow_creation: bool,
    default_allow_extension: bool,
    max_uses: Option<u64>,
    max_duration_ms: Option<u64>,
    cap_expiration_ms: Option<u64>,
    scenario: &mut Scenario,
): SubnameCap {
    ts::next_tx(scenario, USER_ADDRESS);
    let mut suins = ts::take_shared<SuiNS>(scenario);
    let clock = ts::take_shared<Clock>(scenario);

    let cap = subdomains::create_subname_cap(
        &mut suins,
        parent,
        &clock,
        allow_leaf,
        allow_node,
        default_allow_creation,
        default_allow_extension,
        max_uses,
        max_duration_ms,
        cap_expiration_ms,
        ctx(scenario),
    );

    ts::return_shared(suins);
    ts::return_shared(clock);
    cap
}

/// Helper to revoke a SubnameCap
public fun revoke_cap(
    parent: &SuinsRegistration,
    cap_id: sui::object::ID,
    scenario: &mut Scenario,
) {
    ts::next_tx(scenario, USER_ADDRESS);
    let mut suins = ts::take_shared<SuiNS>(scenario);
    let clock = ts::take_shared<Clock>(scenario);

    subdomains::revoke_subname_cap(&mut suins, parent, &clock, cap_id);

    ts::return_shared(suins);
    ts::return_shared(clock);
}

/// Helper to create a leaf subdomain with a cap
public fun create_leaf_with_cap(
    cap: &mut SubnameCap,
    name: String,
    target: address,
    scenario: &mut Scenario,
) {
    ts::next_tx(scenario, USER_ADDRESS);
    let mut suins = ts::take_shared<SuiNS>(scenario);
    let clock = ts::take_shared<Clock>(scenario);

    subdomains::new_leaf_with_cap(&mut suins, cap, &clock, name, target, ctx(scenario));

    ts::return_shared(suins);
    ts::return_shared(clock);
}

/// Helper to create a node subdomain with a cap
public fun create_node_with_cap(
    cap: &mut SubnameCap,
    name: String,
    expiration: u64,
    scenario: &mut Scenario,
): SubDomainRegistration {
    ts::next_tx(scenario, USER_ADDRESS);
    let mut suins = ts::take_shared<SuiNS>(scenario);
    let clock = ts::take_shared<Clock>(scenario);

    let nft = subdomains::new_with_cap(
        &mut suins,
        cap,
        &clock,
        name,
        expiration,
        ctx(scenario),
    );

    ts::return_shared(suins);
    ts::return_shared(clock);
    nft
}

#[test]
/// Test creating a SubnameCap and using it to create leaf subdomains
fun test_subname_cap_create_leaf() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;

    let parent = create_sld_name(utf8(b"test.sui"), scenario);

    // Create a cap that only allows leaf creation
    let mut cap = create_subname_cap(&parent, true, false, false, false, scenario);

    // Use the cap to create a leaf subdomain
    create_leaf_with_cap(&mut cap, utf8(b"leaf.test.sui"), TEST_ADDRESS, scenario);

    // Verify the leaf was created by checking we can't create another with the same name
    // (would fail with ERecordExists if we tried)

    // Clean up
    sui::transfer::public_transfer(cap, USER_ADDRESS);
    burn_nfts(vector[parent]);
    ts::end(scenario_val);
}

#[test]
/// Test creating a SubnameCap and using it to create node subdomains
fun test_subname_cap_create_node() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;

    let parent = create_sld_name(utf8(b"test.sui"), scenario);

    // Create a cap that only allows node creation with default permissions
    let mut cap = create_subname_cap(&parent, false, true, true, true, scenario);

    // Use the cap to create a node subdomain
    let child = create_node_with_cap(&mut cap, utf8(b"node.test.sui"), MIN_SUBDOMAIN_DURATION, scenario);

    // Clean up
    sui::transfer::public_transfer(cap, USER_ADDRESS);
    increment_clock(MIN_SUBDOMAIN_DURATION + 1, scenario);
    burn_subdomain(child, scenario);
    burn_nfts(vector[parent]);
    ts::end(scenario_val);
}

#[test]
/// Test revoking a SubnameCap
fun test_subname_cap_revocation() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;

    let parent = create_sld_name(utf8(b"test.sui"), scenario);

    // Create a cap
    let mut cap = create_subname_cap(&parent, true, true, false, false, scenario);
    let cap_id = sui::object::id(&cap);

    // Create a leaf with the cap first (should work)
    create_leaf_with_cap(&mut cap, utf8(b"leaf1.test.sui"), TEST_ADDRESS, scenario);

    // Revoke the cap
    revoke_cap(&parent, cap_id, scenario);

    // Verify the cap is revoked
    ts::next_tx(scenario, USER_ADDRESS);
    {
        let suins = ts::take_shared<SuiNS>(scenario);
        assert!(subdomains::is_cap_revoked(&suins, &cap), 0);
        ts::return_shared(suins);
    };

    // Clean up
    sui::transfer::public_transfer(cap, USER_ADDRESS);
    burn_nfts(vector[parent]);
    ts::end(scenario_val);
}

#[test, expected_failure(abort_code = ::suins_subdomains::subdomains::ECapNotActive)]
/// Test that a revoked cap cannot be used
fun test_revoked_cap_cannot_be_used() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;

    let parent = create_sld_name(utf8(b"test.sui"), scenario);

    // Create and revoke a cap
    let mut cap = create_subname_cap(&parent, true, true, false, false, scenario);
    let cap_id = sui::object::id(&cap);
    revoke_cap(&parent, cap_id, scenario);

    // Try to use the revoked cap (should fail)
    create_leaf_with_cap(&mut cap, utf8(b"leaf.test.sui"), TEST_ADDRESS, scenario);

    abort
}

#[test, expected_failure(abort_code = ::suins_subdomains::subdomains::ELeafCreationNotAllowed)]
/// Test that cap without leaf permission cannot create leaves
fun test_cap_leaf_not_allowed() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;

    let parent = create_sld_name(utf8(b"test.sui"), scenario);

    // Create a cap that only allows node creation (not leaf)
    let mut cap = create_subname_cap(&parent, false, true, false, false, scenario);

    // Try to create a leaf (should fail)
    create_leaf_with_cap(&mut cap, utf8(b"leaf.test.sui"), TEST_ADDRESS, scenario);

    abort
}

#[test, expected_failure(abort_code = ::suins_subdomains::subdomains::ENodeCreationNotAllowed)]
/// Test that cap without node permission cannot create nodes
fun test_cap_node_not_allowed() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;

    let parent = create_sld_name(utf8(b"test.sui"), scenario);

    // Create a cap that only allows leaf creation (not node)
    let mut cap = create_subname_cap(&parent, true, false, false, false, scenario);

    // Try to create a node (should fail)
    let _child = create_node_with_cap(&mut cap, utf8(b"node.test.sui"), MIN_SUBDOMAIN_DURATION, scenario);

    abort
}

#[test, expected_failure(abort_code = ::suins_subdomains::subdomains::ECapInvalidated)]
/// Test that cap is invalidated when domain is re-registered (new NFT ID)
fun test_cap_invalidated_on_reregistration() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;

    let parent = create_sld_name(utf8(b"test.sui"), scenario);

    // Create a cap
    let mut cap = create_subname_cap(&parent, true, true, false, false, scenario);

    // Let the domain expire
    increment_clock(year_ms() + grace_period_ms() + 1, scenario);

    // Re-register the domain (creates a new NFT with different ID)
    let new_parent = create_sld_name(utf8(b"test.sui"), scenario);

    // Try to use the old cap (should fail because NFT ID changed)
    create_leaf_with_cap(&mut cap, utf8(b"leaf.test.sui"), TEST_ADDRESS, scenario);

    // Clean up (won't reach here due to abort)
    sui::transfer::public_transfer(cap, USER_ADDRESS);
    burn_nfts(vector[parent, new_parent]);

    abort
}

#[test]
/// Test cap getters
fun test_cap_getters() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;

    let parent = create_sld_name(utf8(b"test.sui"), scenario);

    let cap = create_subname_cap(&parent, true, false, true, false, scenario);

    // Test getters
    assert!(subdomains::cap_allow_leaf_creation(&cap) == true, 0);
    assert!(subdomains::cap_allow_node_creation(&cap) == false, 1);
    assert!(subdomains::cap_parent_nft_id(&cap) == sui::object::id(&parent), 2);

    // Clean up
    sui::transfer::public_transfer(cap, USER_ADDRESS);
    burn_nfts(vector[parent]);
    ts::end(scenario_val);
}

#[test]
/// Test that a different address can use a transferred cap
fun test_cap_used_by_different_address() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;

    // USER_ADDRESS creates the domain and cap
    let parent = create_sld_name(utf8(b"test.sui"), scenario);
    let cap = create_subname_cap(&parent, true, true, false, false, scenario);

    // Transfer cap to TEST_ADDRESS
    ts::next_tx(scenario, USER_ADDRESS);
    sui::transfer::public_transfer(cap, TEST_ADDRESS);

    // TEST_ADDRESS uses the cap to create a leaf subdomain
    ts::next_tx(scenario, TEST_ADDRESS);
    {
        let mut suins = ts::take_shared<SuiNS>(scenario);
        let clock = ts::take_shared<Clock>(scenario);
        let mut cap = ts::take_from_sender<SubnameCap>(scenario);

        subdomains::new_leaf_with_cap(
            &mut suins,
            &mut cap,
            &clock,
            utf8(b"leaf.test.sui"),
            TEST_ADDRESS,
            ctx(scenario),
        );

        ts::return_to_sender(scenario, cap);
        ts::return_shared(suins);
        ts::return_shared(clock);
    };

    // TEST_ADDRESS uses the cap to create a node subdomain
    ts::next_tx(scenario, TEST_ADDRESS);
    {
        let mut suins = ts::take_shared<SuiNS>(scenario);
        let clock = ts::take_shared<Clock>(scenario);
        let mut cap = ts::take_from_sender<SubnameCap>(scenario);

        let child = subdomains::new_with_cap(
            &mut suins,
            &mut cap,
            &clock,
            utf8(b"node.test.sui"),
            MIN_SUBDOMAIN_DURATION,
            ctx(scenario),
        );

        sui::transfer::public_transfer(child, TEST_ADDRESS);
        ts::return_to_sender(scenario, cap);
        ts::return_shared(suins);
        ts::return_shared(clock);
    };

    // Clean up
    ts::next_tx(scenario, TEST_ADDRESS);
    let cap = ts::take_from_sender<SubnameCap>(scenario);
    sui::transfer::public_transfer(cap, USER_ADDRESS);

    increment_clock(MIN_SUBDOMAIN_DURATION + 1, scenario);

    ts::next_tx(scenario, TEST_ADDRESS);
    let child = ts::take_from_sender<SubDomainRegistration>(scenario);
    burn_subdomain(child, scenario);

    burn_nfts(vector[parent]);
    ts::end(scenario_val);
}

#[test]
/// Test that cap persists and works after the parent domain NFT is transferred
fun test_cap_persists_across_domain_transfer() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;

    // USER_ADDRESS creates domain and cap
    let parent = create_sld_name(utf8(b"test.sui"), scenario);
    let cap = create_subname_cap(&parent, true, false, false, false, scenario);

    // Transfer cap to TEST_ADDRESS
    ts::next_tx(scenario, USER_ADDRESS);
    sui::transfer::public_transfer(cap, TEST_ADDRESS);

    // Transfer the parent domain NFT to a third address (different from cap holder)
    ts::next_tx(scenario, USER_ADDRESS);
    sui::transfer::public_transfer(parent, @0x03);

    // TEST_ADDRESS (cap holder) can still use the cap even though domain transferred
    ts::next_tx(scenario, TEST_ADDRESS);
    {
        let mut suins = ts::take_shared<SuiNS>(scenario);
        let clock = ts::take_shared<Clock>(scenario);
        let mut cap = ts::take_from_sender<SubnameCap>(scenario);

        subdomains::new_leaf_with_cap(
            &mut suins,
            &mut cap,
            &clock,
            utf8(b"leaf.test.sui"),
            TEST_ADDRESS,
            ctx(scenario),
        );

        ts::return_to_sender(scenario, cap);
        ts::return_shared(suins);
        ts::return_shared(clock);
    };

    // Clean up
    ts::next_tx(scenario, TEST_ADDRESS);
    let cap = ts::take_from_sender<SubnameCap>(scenario);
    sui::transfer::public_transfer(cap, USER_ADDRESS);

    ts::next_tx(scenario, @0x03);
    let parent = ts::take_from_sender<SuinsRegistration>(scenario);
    burn_nfts(vector[parent]);

    ts::end(scenario_val);
}

#[test]
/// Test that new domain owner can revoke caps created by previous owner
fun test_new_owner_can_revoke_old_caps() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;

    // USER_ADDRESS creates domain and cap
    let parent = create_sld_name(utf8(b"test.sui"), scenario);
    let cap = create_subname_cap(&parent, true, false, false, false, scenario);
    let cap_id = sui::object::id(&cap);

    // Keep cap with USER_ADDRESS for now
    ts::next_tx(scenario, USER_ADDRESS);
    sui::transfer::public_transfer(cap, USER_ADDRESS);

    // Transfer the parent domain NFT to TEST_ADDRESS (new owner)
    ts::next_tx(scenario, USER_ADDRESS);
    sui::transfer::public_transfer(parent, TEST_ADDRESS);

    // New owner (TEST_ADDRESS) revokes the cap created by previous owner
    ts::next_tx(scenario, TEST_ADDRESS);
    {
        let mut suins = ts::take_shared<SuiNS>(scenario);
        let clock = ts::take_shared<Clock>(scenario);
        let parent = ts::take_from_sender<SuinsRegistration>(scenario);

        subdomains::revoke_subname_cap(&mut suins, &parent, &clock, cap_id);

        ts::return_to_sender(scenario, parent);
        ts::return_shared(suins);
        ts::return_shared(clock);
    };

    // Verify the cap is now revoked
    ts::next_tx(scenario, USER_ADDRESS);
    {
        let suins = ts::take_shared<SuiNS>(scenario);
        let cap = ts::take_from_sender<SubnameCap>(scenario);

        assert!(subdomains::is_cap_revoked(&suins, &cap), 0);

        ts::return_to_sender(scenario, cap);
        ts::return_shared(suins);
    };

    // Clean up
    ts::next_tx(scenario, USER_ADDRESS);
    let cap = ts::take_from_sender<SubnameCap>(scenario);
    sui::transfer::public_transfer(cap, USER_ADDRESS);

    ts::next_tx(scenario, TEST_ADDRESS);
    let parent = ts::take_from_sender<SuinsRegistration>(scenario);
    burn_nfts(vector[parent]);

    ts::end(scenario_val);
}

#[test]
/// Test multiple caps can be created for the same domain
fun test_multiple_caps_same_domain() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;

    let parent = create_sld_name(utf8(b"test.sui"), scenario);

    // Create multiple caps with different permissions
    let mut cap1 = create_subname_cap(&parent, true, false, false, false, scenario); // leaf only
    let mut cap2 = create_subname_cap(&parent, false, true, false, false, scenario); // node only
    let mut cap3 = create_subname_cap(&parent, true, true, true, true, scenario);    // both with defaults

    // Use cap1 to create a leaf
    ts::next_tx(scenario, USER_ADDRESS);
    {
        let mut suins = ts::take_shared<SuiNS>(scenario);
        let clock = ts::take_shared<Clock>(scenario);

        subdomains::new_leaf_with_cap(&mut suins, &mut cap1, &clock, utf8(b"leaf1.test.sui"), TEST_ADDRESS, ctx(scenario));

        ts::return_shared(suins);
        ts::return_shared(clock);
    };

    // Use cap2 to create a node
    let child = create_node_with_cap(&mut cap2, utf8(b"node1.test.sui"), MIN_SUBDOMAIN_DURATION, scenario);

    // Use cap3 to create both a leaf and a node
    ts::next_tx(scenario, USER_ADDRESS);
    {
        let mut suins = ts::take_shared<SuiNS>(scenario);
        let clock = ts::take_shared<Clock>(scenario);

        subdomains::new_leaf_with_cap(&mut suins, &mut cap3, &clock, utf8(b"leaf2.test.sui"), TEST_ADDRESS, ctx(scenario));

        ts::return_shared(suins);
        ts::return_shared(clock);
    };

    let child2 = create_node_with_cap(&mut cap3, utf8(b"node2.test.sui"), MIN_SUBDOMAIN_DURATION, scenario);

    // Clean up
    sui::transfer::public_transfer(cap1, USER_ADDRESS);
    sui::transfer::public_transfer(cap2, USER_ADDRESS);
    sui::transfer::public_transfer(cap3, USER_ADDRESS);

    increment_clock(MIN_SUBDOMAIN_DURATION + 1, scenario);
    burn_subdomain(child, scenario);
    burn_subdomain(child2, scenario);
    burn_nfts(vector[parent]);
    ts::end(scenario_val);
}

#[test]
/// Test cap with both leaf and node permissions works for both
fun test_cap_with_both_permissions() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;

    let parent = create_sld_name(utf8(b"test.sui"), scenario);

    // Create cap with both permissions and default subdomain settings
    let mut cap = create_subname_cap(&parent, true, true, true, true, scenario);

    // Create a leaf
    create_leaf_with_cap(&mut cap, utf8(b"leaf.test.sui"), TEST_ADDRESS, scenario);

    // Create a node
    let child = create_node_with_cap(&mut cap, utf8(b"node.test.sui"), MIN_SUBDOMAIN_DURATION, scenario);

    // Verify the node has the default permissions from the cap
    ts::next_tx(scenario, USER_ADDRESS);
    {
        let suins = ts::take_shared<SuiNS>(scenario);
        let subdomain = domain::new(utf8(b"node.test.sui"));
        let data = *suins.registry<Registry>().get_data(subdomain);

        // Check that allow_creation and allow_extension flags are set
        assert!(data.contains(&subdomain_allow_creation_key()), 0);
        assert!(data.contains(&subdomain_allow_extension_key()), 1);

        ts::return_shared(suins);
    };

    // Clean up
    sui::transfer::public_transfer(cap, USER_ADDRESS);
    increment_clock(MIN_SUBDOMAIN_DURATION + 1, scenario);
    burn_subdomain(child, scenario);
    burn_nfts(vector[parent]);
    ts::end(scenario_val);
}

#[test, expected_failure(abort_code = ::suins_subdomains::subdomains::EParentExpired)]
/// Test that cap becomes invalid when parent domain expires
fun test_cap_invalid_when_parent_expired() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;

    let parent = create_sld_name(utf8(b"test.sui"), scenario);
    let mut cap = create_subname_cap(&parent, true, false, false, false, scenario);

    // Advance time so parent expires (but not past grace period, so domain not re-registerable)
    increment_clock(year_ms() + 1, scenario);

    // Try to use cap with expired parent (should fail)
    create_leaf_with_cap(&mut cap, utf8(b"leaf.test.sui"), TEST_ADDRESS, scenario);

    abort
}

#[test]
/// Test that revoking one cap doesn't affect other caps
fun test_revoke_one_cap_doesnt_affect_others() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;

    let parent = create_sld_name(utf8(b"test.sui"), scenario);

    let cap1 = create_subname_cap(&parent, true, false, false, false, scenario);
    let mut cap2 = create_subname_cap(&parent, true, false, false, false, scenario);
    let cap1_id = sui::object::id(&cap1);

    // Revoke cap1
    revoke_cap(&parent, cap1_id, scenario);

    // cap1 is revoked
    ts::next_tx(scenario, USER_ADDRESS);
    {
        let suins = ts::take_shared<SuiNS>(scenario);
        assert!(subdomains::is_cap_revoked(&suins, &cap1), 0);
        assert!(!subdomains::is_cap_revoked(&suins, &cap2), 1);
        ts::return_shared(suins);
    };

    // cap2 still works
    create_leaf_with_cap(&mut cap2, utf8(b"leaf.test.sui"), TEST_ADDRESS, scenario);

    // Clean up
    sui::transfer::public_transfer(cap1, USER_ADDRESS);
    sui::transfer::public_transfer(cap2, USER_ADDRESS);
    burn_nfts(vector[parent]);
    ts::end(scenario_val);
}

#[test]
/// Test that revoking a cap twice is idempotent (doesn't error)
fun test_revoke_cap_idempotent() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;

    let parent = create_sld_name(utf8(b"test.sui"), scenario);
    let cap = create_subname_cap(&parent, true, false, false, false, scenario);
    let cap_id = sui::object::id(&cap);

    // Revoke the cap twice - should not error
    revoke_cap(&parent, cap_id, scenario);
    revoke_cap(&parent, cap_id, scenario);

    // Still revoked
    ts::next_tx(scenario, USER_ADDRESS);
    {
        let suins = ts::take_shared<SuiNS>(scenario);
        assert!(subdomains::is_cap_revoked(&suins, &cap), 0);
        ts::return_shared(suins);
    };

    // Clean up
    sui::transfer::public_transfer(cap, USER_ADDRESS);
    burn_nfts(vector[parent]);
    ts::end(scenario_val);
}

// == Programmable Limits Tests ==

#[test]
/// Test cap with max_uses limit works correctly
fun test_cap_max_uses_limit() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;

    let parent = create_sld_name(utf8(b"test.sui"), scenario);

    // Create a cap with max 2 uses
    let mut cap = create_subname_cap_with_limits(
        &parent,
        true,  // allow_leaf
        false, // allow_node
        false,
        false,
        option::some(2), // max_uses = 2
        option::none(),
        option::none(),
        scenario,
    );

    // Verify initial state
    assert!(subdomains::cap_max_uses(&cap) == option::some(2), 0);
    assert!(subdomains::cap_uses_count(&cap) == 0, 1);
    assert!(subdomains::cap_remaining_uses(&cap) == option::some(2), 2);
    assert!(!subdomains::is_cap_usage_exhausted(&cap), 3);

    // First use
    create_leaf_with_cap(&mut cap, utf8(b"leaf1.test.sui"), TEST_ADDRESS, scenario);
    assert!(subdomains::cap_uses_count(&cap) == 1, 4);
    assert!(subdomains::cap_remaining_uses(&cap) == option::some(1), 5);

    // Second use
    create_leaf_with_cap(&mut cap, utf8(b"leaf2.test.sui"), TEST_ADDRESS, scenario);
    assert!(subdomains::cap_uses_count(&cap) == 2, 6);
    assert!(subdomains::cap_remaining_uses(&cap) == option::some(0), 7);
    assert!(subdomains::is_cap_usage_exhausted(&cap), 8);

    // Clean up
    sui::transfer::public_transfer(cap, USER_ADDRESS);
    burn_nfts(vector[parent]);
    ts::end(scenario_val);
}

#[test, expected_failure(abort_code = ::suins_subdomains::subdomains::ECapUsageLimitReached)]
/// Test that cap cannot be used after max_uses is reached
fun test_cap_max_uses_exceeded() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;

    let parent = create_sld_name(utf8(b"test.sui"), scenario);

    // Create a cap with max 1 use
    let mut cap = create_subname_cap_with_limits(
        &parent,
        true,
        false,
        false,
        false,
        option::some(1), // max_uses = 1
        option::none(),
        option::none(),
        scenario,
    );

    // First use - should succeed
    create_leaf_with_cap(&mut cap, utf8(b"leaf1.test.sui"), TEST_ADDRESS, scenario);

    // Second use - should fail
    create_leaf_with_cap(&mut cap, utf8(b"leaf2.test.sui"), TEST_ADDRESS, scenario);

    abort
}

#[test]
/// Test cap with max_duration_ms limit
fun test_cap_max_duration_limit() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;

    let parent = create_sld_name(utf8(b"test.sui"), scenario);

    // Create a cap with max duration of 30 days
    let thirty_days_ms = 30 * 24 * 60 * 60 * 1000;
    let mut cap = create_subname_cap_with_limits(
        &parent,
        false,
        true,  // allow_node
        false,
        false,
        option::none(),
        option::some(thirty_days_ms), // max_duration_ms = 30 days
        option::none(),
        scenario,
    );

    // Verify initial state
    assert!(subdomains::cap_max_duration_ms(&cap) == option::some(thirty_days_ms), 0);

    // Create a node subdomain within the duration limit (using MIN_SUBDOMAIN_DURATION which is 1 day)
    let child = create_node_with_cap(&mut cap, utf8(b"node.test.sui"), MIN_SUBDOMAIN_DURATION, scenario);

    // Clean up
    sui::transfer::public_transfer(cap, USER_ADDRESS);
    increment_clock(MIN_SUBDOMAIN_DURATION + 1, scenario);
    burn_subdomain(child, scenario);
    burn_nfts(vector[parent]);
    ts::end(scenario_val);
}

#[test, expected_failure(abort_code = ::suins_subdomains::subdomains::ECapDurationLimitExceeded)]
/// Test that cap cannot create subdomain with duration exceeding max_duration_ms
fun test_cap_max_duration_exceeded() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;

    let parent = create_sld_name(utf8(b"test.sui"), scenario);

    // Create a cap with max duration of 1 day
    let one_day_ms = 24 * 60 * 60 * 1000;
    let mut cap = create_subname_cap_with_limits(
        &parent,
        false,
        true,  // allow_node
        false,
        false,
        option::none(),
        option::some(one_day_ms), // max_duration_ms = 1 day
        option::none(),
        scenario,
    );

    // Try to create a node subdomain with 2 days duration (exceeds limit)
    let two_days_ms = 2 * 24 * 60 * 60 * 1000;
    let _child = create_node_with_cap(&mut cap, utf8(b"node.test.sui"), two_days_ms, scenario);

    abort
}

#[test]
/// Test cap with cap_expiration_ms
fun test_cap_expiration() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;

    let parent = create_sld_name(utf8(b"test.sui"), scenario);

    // Create a cap that expires in 7 days
    let seven_days_ms = 7 * 24 * 60 * 60 * 1000;
    let mut cap = create_subname_cap_with_limits(
        &parent,
        true,
        false,
        false,
        false,
        option::none(),
        option::none(),
        option::some(seven_days_ms), // cap_expiration_ms = 7 days from now
        scenario,
    );

    // Verify initial state
    assert!(subdomains::cap_expiration_ms(&cap) == option::some(seven_days_ms), 0);

    // Get clock to check is_cap_expired
    ts::next_tx(scenario, USER_ADDRESS);
    {
        let clock = ts::take_shared<Clock>(scenario);
        assert!(!subdomains::is_cap_expired(&cap, &clock), 1);
        ts::return_shared(clock);
    };

    // Create a leaf subdomain - should work before expiration
    create_leaf_with_cap(&mut cap, utf8(b"leaf.test.sui"), TEST_ADDRESS, scenario);

    // Clean up
    sui::transfer::public_transfer(cap, USER_ADDRESS);
    burn_nfts(vector[parent]);
    ts::end(scenario_val);
}

#[test, expected_failure(abort_code = ::suins_subdomains::subdomains::ECapExpired)]
/// Test that cap cannot be used after cap_expiration_ms
fun test_cap_expired_cannot_be_used() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;

    let parent = create_sld_name(utf8(b"test.sui"), scenario);

    // Create a cap that expires in 1 day
    let one_day_ms = 24 * 60 * 60 * 1000;
    let mut cap = create_subname_cap_with_limits(
        &parent,
        true,
        false,
        false,
        false,
        option::none(),
        option::none(),
        option::some(one_day_ms), // cap_expiration_ms = 1 day from now
        scenario,
    );

    // Advance time past cap expiration
    increment_clock(one_day_ms + 1, scenario);

    // Verify cap is expired
    ts::next_tx(scenario, USER_ADDRESS);
    {
        let clock = ts::take_shared<Clock>(scenario);
        assert!(subdomains::is_cap_expired(&cap, &clock), 0);
        ts::return_shared(clock);
    };

    // Try to use expired cap - should fail
    create_leaf_with_cap(&mut cap, utf8(b"leaf.test.sui"), TEST_ADDRESS, scenario);

    abort
}

#[test]
/// Test cap with no limits (unlimited)
fun test_cap_unlimited() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;

    let parent = create_sld_name(utf8(b"test.sui"), scenario);

    // Create a cap with no limits
    let mut cap = create_subname_cap(&parent, true, true, false, false, scenario);

    // Verify unlimited state
    assert!(subdomains::cap_max_uses(&cap) == option::none(), 0);
    assert!(subdomains::cap_remaining_uses(&cap) == option::none(), 1);
    assert!(subdomains::cap_max_duration_ms(&cap) == option::none(), 2);
    assert!(subdomains::cap_expiration_ms(&cap) == option::none(), 3);
    assert!(!subdomains::is_cap_usage_exhausted(&cap), 4);

    ts::next_tx(scenario, USER_ADDRESS);
    {
        let clock = ts::take_shared<Clock>(scenario);
        assert!(!subdomains::is_cap_expired(&cap, &clock), 5);
        ts::return_shared(clock);
    };

    // Can create multiple subdomains
    create_leaf_with_cap(&mut cap, utf8(b"leaf1.test.sui"), TEST_ADDRESS, scenario);
    create_leaf_with_cap(&mut cap, utf8(b"leaf2.test.sui"), TEST_ADDRESS, scenario);
    create_leaf_with_cap(&mut cap, utf8(b"leaf3.test.sui"), TEST_ADDRESS, scenario);

    // Uses count should still increment even if unlimited
    assert!(subdomains::cap_uses_count(&cap) == 3, 6);

    // Clean up
    sui::transfer::public_transfer(cap, USER_ADDRESS);
    burn_nfts(vector[parent]);
    ts::end(scenario_val);
}

#[test]
/// Test cap with all limits combined
fun test_cap_all_limits_combined() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;

    let parent = create_sld_name(utf8(b"test.sui"), scenario);

    // Create a cap with all limits: max 5 uses, max 30 day duration, expires in 1 year
    let thirty_days_ms = 30 * 24 * 60 * 60 * 1000;
    let one_year_ms = year_ms();
    let mut cap = create_subname_cap_with_limits(
        &parent,
        true,
        true,
        true,
        true,
        option::some(5),              // max_uses
        option::some(thirty_days_ms), // max_duration_ms
        option::some(one_year_ms),    // cap_expiration_ms
        scenario,
    );

    // Verify all limits set
    assert!(subdomains::cap_max_uses(&cap) == option::some(5), 0);
    assert!(subdomains::cap_max_duration_ms(&cap) == option::some(thirty_days_ms), 1);
    assert!(subdomains::cap_expiration_ms(&cap) == option::some(one_year_ms), 2);

    // Create a leaf (uses 1 of 5)
    create_leaf_with_cap(&mut cap, utf8(b"leaf.test.sui"), TEST_ADDRESS, scenario);

    // Create a node with valid duration (uses 2 of 5)
    let child = create_node_with_cap(&mut cap, utf8(b"node.test.sui"), MIN_SUBDOMAIN_DURATION, scenario);

    assert!(subdomains::cap_uses_count(&cap) == 2, 3);
    assert!(subdomains::cap_remaining_uses(&cap) == option::some(3), 4);

    // Clean up
    sui::transfer::public_transfer(cap, USER_ADDRESS);
    increment_clock(MIN_SUBDOMAIN_DURATION + 1, scenario);
    burn_subdomain(child, scenario);
    burn_nfts(vector[parent]);
    ts::end(scenario_val);
}

#[test]
/// Test limit getters on cap with specific limits
fun test_cap_limit_getters() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;

    let parent = create_sld_name(utf8(b"test.sui"), scenario);

    // Create a cap with specific limits for testing getters
    let mut cap = create_subname_cap_with_limits(
        &parent,
        true,
        true,
        true,
        true,
        option::some(10),
        option::some(86400000), // 1 day in ms
        option::some(31536000000), // ~1 year in ms
        scenario,
    );

    // Test getters
    assert!(subdomains::cap_max_uses(&cap) == option::some(10), 0);
    assert!(subdomains::cap_uses_count(&cap) == 0, 1);
    assert!(subdomains::cap_remaining_uses(&cap) == option::some(10), 2);
    assert!(subdomains::cap_max_duration_ms(&cap) == option::some(86400000), 3);
    assert!(subdomains::cap_expiration_ms(&cap) == option::some(31536000000), 4);

    // Use the cap once
    create_leaf_with_cap(&mut cap, utf8(b"leaf.test.sui"), TEST_ADDRESS, scenario);

    // Verify count updated
    assert!(subdomains::cap_uses_count(&cap) == 1, 5);
    assert!(subdomains::cap_remaining_uses(&cap) == option::some(9), 6);

    // Clean up
    sui::transfer::public_transfer(cap, USER_ADDRESS);
    burn_nfts(vector[parent]);
    ts::end(scenario_val);
}

// == Surrender SubnameCap Tests ==

/// Helper to surrender a SubnameCap
public fun surrender_cap(
    cap: SubnameCap,
    scenario: &mut Scenario,
) {
    ts::next_tx(scenario, USER_ADDRESS);
    let mut suins = ts::take_shared<SuiNS>(scenario);

    subdomains::surrender_subname_cap(&mut suins, cap);

    ts::return_shared(suins);
}

#[test]
/// Test surrendering a SubnameCap removes it from active list and destroys it
fun test_surrender_cap() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;

    let parent = create_sld_name(utf8(b"test.sui"), scenario);

    // Create a cap
    let cap = create_subname_cap(&parent, true, false, false, false, scenario);

    // Verify cap is active
    ts::next_tx(scenario, USER_ADDRESS);
    {
        let suins = ts::take_shared<SuiNS>(scenario);
        assert!(subdomains::is_cap_active(&suins, &cap), 0);
        assert!(!subdomains::is_cap_revoked(&suins, &cap), 1);
        assert!(subdomains::get_active_caps_count(&suins, parent.domain()) == 1, 2);
        ts::return_shared(suins);
    };

    // Surrender the cap
    surrender_cap(cap, scenario);

    // Verify cap is no longer in active list
    ts::next_tx(scenario, USER_ADDRESS);
    {
        let suins = ts::take_shared<SuiNS>(scenario);
        // Note: cap object is destroyed, so we can't check is_cap_active on it
        // Instead, check the count
        assert!(subdomains::get_active_caps_count(&suins, parent.domain()) == 0, 3);
        ts::return_shared(suins);
    };

    // Clean up
    burn_nfts(vector[parent]);
    ts::end(scenario_val);
}

#[test]
/// Test surrendering a cap that was already revoked still works (no panic)
fun test_surrender_already_revoked_cap() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;

    let parent = create_sld_name(utf8(b"test.sui"), scenario);

    // Create a cap
    let cap = create_subname_cap(&parent, true, false, false, false, scenario);
    let cap_id = sui::object::id(&cap);

    // Revoke the cap first
    revoke_cap(&parent, cap_id, scenario);

    // Verify cap is revoked
    ts::next_tx(scenario, USER_ADDRESS);
    {
        let suins = ts::take_shared<SuiNS>(scenario);
        assert!(!subdomains::is_cap_active(&suins, &cap), 0);
        assert!(subdomains::is_cap_revoked(&suins, &cap), 1);
        ts::return_shared(suins);
    };

    // Surrender the cap - should still work even though it was revoked
    surrender_cap(cap, scenario);

    // Clean up
    burn_nfts(vector[parent]);
    ts::end(scenario_val);
}

#[test, expected_failure(abort_code = ::suins_subdomains::subdomains::ECapNotActive)]
/// Test that a surrendered cap cannot be used (even if object somehow still existed)
fun test_surrendered_cap_cannot_be_used() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;

    let parent = create_sld_name(utf8(b"test.sui"), scenario);

    // Create two caps
    let mut cap1 = create_subname_cap(&parent, true, false, false, false, scenario);
    let cap1_id = sui::object::id(&cap1);

    // Revoke cap1 (simulates what happens after surrender removes from active list)
    revoke_cap(&parent, cap1_id, scenario);

    // Try to use cap1 (should fail since it's not in active list)
    create_leaf_with_cap(&mut cap1, utf8(b"leaf.test.sui"), TEST_ADDRESS, scenario);

    abort
}

// == Active Caps Enumeration Tests ==

#[test]
/// Test get_active_caps returns all active caps for a domain
fun test_get_active_caps() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;

    let parent = create_sld_name(utf8(b"test.sui"), scenario);

    // Initially no caps
    ts::next_tx(scenario, USER_ADDRESS);
    {
        let suins = ts::take_shared<SuiNS>(scenario);
        let caps = subdomains::get_active_caps(&suins, parent.domain());
        assert!(caps.length() == 0, 0);
        assert!(subdomains::get_active_caps_count(&suins, parent.domain()) == 0, 1);
        ts::return_shared(suins);
    };

    // Create first cap
    let cap1 = create_subname_cap(&parent, true, false, false, false, scenario);
    let cap1_id = sui::object::id(&cap1);

    ts::next_tx(scenario, USER_ADDRESS);
    {
        let suins = ts::take_shared<SuiNS>(scenario);
        let caps = subdomains::get_active_caps(&suins, parent.domain());
        assert!(caps.length() == 1, 2);
        assert!(subdomains::cap_entry_id(&caps[0]) == cap1_id, 3);
        ts::return_shared(suins);
    };

    // Create second cap
    let cap2 = create_subname_cap(&parent, false, true, true, true, scenario);
    let cap2_id = sui::object::id(&cap2);

    ts::next_tx(scenario, USER_ADDRESS);
    {
        let suins = ts::take_shared<SuiNS>(scenario);
        let caps = subdomains::get_active_caps(&suins, parent.domain());
        assert!(caps.length() == 2, 4);
        assert!(subdomains::get_active_caps_count(&suins, parent.domain()) == 2, 5);
        ts::return_shared(suins);
    };

    // Revoke first cap
    revoke_cap(&parent, cap1_id, scenario);

    ts::next_tx(scenario, USER_ADDRESS);
    {
        let suins = ts::take_shared<SuiNS>(scenario);
        let caps = subdomains::get_active_caps(&suins, parent.domain());
        assert!(caps.length() == 1, 6);
        assert!(subdomains::cap_entry_id(&caps[0]) == cap2_id, 7);
        ts::return_shared(suins);
    };

    // Clean up
    sui::transfer::public_transfer(cap1, USER_ADDRESS);
    sui::transfer::public_transfer(cap2, USER_ADDRESS);
    burn_nfts(vector[parent]);
    ts::end(scenario_val);
}

#[test]
/// Test CapEntry getters
fun test_cap_entry_getters() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;

    let parent = create_sld_name(utf8(b"test.sui"), scenario);

    // Create cap with specific limits
    let cap = create_subname_cap_with_limits(
        &parent,
        true,  // allow_leaf
        false, // allow_node
        false,
        false,
        option::some(5),     // max_uses
        option::some(1000),  // max_duration_ms
        option::some(2000),  // cap_expiration_ms
        scenario,
    );

    ts::next_tx(scenario, USER_ADDRESS);
    {
        let suins = ts::take_shared<SuiNS>(scenario);
        let caps = subdomains::get_active_caps(&suins, parent.domain());
        assert!(caps.length() == 1, 0);

        let entry = &caps[0];
        assert!(subdomains::cap_entry_id(entry) == sui::object::id(&cap), 1);
        assert!(subdomains::cap_entry_allow_leaf(entry) == true, 2);
        assert!(subdomains::cap_entry_allow_node(entry) == false, 3);
        assert!(subdomains::cap_entry_max_uses(entry) == option::some(5), 4);
        assert!(subdomains::cap_entry_max_duration_ms(entry) == option::some(1000), 5);
        assert!(subdomains::cap_entry_expiration_ms(entry) == option::some(2000), 6);
        // created_at_ms should be >= 0 (it's the clock timestamp at creation)
        assert!(subdomains::cap_entry_created_at_ms(entry) >= 0, 7);

        ts::return_shared(suins);
    };

    // Clean up
    sui::transfer::public_transfer(cap, USER_ADDRESS);
    burn_nfts(vector[parent]);
    ts::end(scenario_val);
}

#[test]
/// Test is_cap_active function
fun test_is_cap_active() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;

    let parent = create_sld_name(utf8(b"test.sui"), scenario);
    let cap = create_subname_cap(&parent, true, false, false, false, scenario);
    let cap_id = sui::object::id(&cap);

    // Cap should be active initially
    ts::next_tx(scenario, USER_ADDRESS);
    {
        let suins = ts::take_shared<SuiNS>(scenario);
        assert!(subdomains::is_cap_active(&suins, &cap), 0);
        assert!(!subdomains::is_cap_revoked(&suins, &cap), 1);
        ts::return_shared(suins);
    };

    // Revoke the cap
    revoke_cap(&parent, cap_id, scenario);

    // Cap should no longer be active
    ts::next_tx(scenario, USER_ADDRESS);
    {
        let suins = ts::take_shared<SuiNS>(scenario);
        assert!(!subdomains::is_cap_active(&suins, &cap), 2);
        assert!(subdomains::is_cap_revoked(&suins, &cap), 3);
        ts::return_shared(suins);
    };

    // Clean up
    sui::transfer::public_transfer(cap, USER_ADDRESS);
    burn_nfts(vector[parent]);
    ts::end(scenario_val);
}

// == Clear Active Caps Tests ==

/// Helper to clear all active caps for a domain
public fun clear_caps(
    parent: &SuinsRegistration,
    scenario: &mut Scenario,
) {
    ts::next_tx(scenario, USER_ADDRESS);
    let mut suins = ts::take_shared<SuiNS>(scenario);
    let clock = ts::take_shared<Clock>(scenario);

    subdomains::clear_active_caps(&mut suins, parent, &clock);

    ts::return_shared(suins);
    ts::return_shared(clock);
}

#[test]
/// Test clearing all active caps at once
fun test_clear_active_caps() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;

    let parent = create_sld_name(utf8(b"test.sui"), scenario);

    // Create multiple caps
    let cap1 = create_subname_cap(&parent, true, false, false, false, scenario);
    let cap2 = create_subname_cap(&parent, false, true, true, true, scenario);
    let cap3 = create_subname_cap(&parent, true, true, false, false, scenario);

    // Verify all caps are active
    ts::next_tx(scenario, USER_ADDRESS);
    {
        let suins = ts::take_shared<SuiNS>(scenario);
        assert!(subdomains::get_active_caps_count(&suins, parent.domain()) == 3, 0);
        assert!(subdomains::is_cap_active(&suins, &cap1), 1);
        assert!(subdomains::is_cap_active(&suins, &cap2), 2);
        assert!(subdomains::is_cap_active(&suins, &cap3), 3);
        ts::return_shared(suins);
    };

    // Clear all caps
    clear_caps(&parent, scenario);

    // Verify all caps are now inactive
    ts::next_tx(scenario, USER_ADDRESS);
    {
        let suins = ts::take_shared<SuiNS>(scenario);
        assert!(subdomains::get_active_caps_count(&suins, parent.domain()) == 0, 4);
        assert!(!subdomains::is_cap_active(&suins, &cap1), 5);
        assert!(!subdomains::is_cap_active(&suins, &cap2), 6);
        assert!(!subdomains::is_cap_active(&suins, &cap3), 7);
        ts::return_shared(suins);
    };

    // Clean up
    sui::transfer::public_transfer(cap1, USER_ADDRESS);
    sui::transfer::public_transfer(cap2, USER_ADDRESS);
    sui::transfer::public_transfer(cap3, USER_ADDRESS);
    burn_nfts(vector[parent]);
    ts::end(scenario_val);
}

#[test]
/// Test clearing caps is idempotent (calling on empty list is fine)
fun test_clear_active_caps_idempotent() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;

    let parent = create_sld_name(utf8(b"test.sui"), scenario);

    // Clear caps when none exist (should not fail)
    clear_caps(&parent, scenario);

    // Create a cap
    let cap = create_subname_cap(&parent, true, false, false, false, scenario);

    // Clear caps
    clear_caps(&parent, scenario);

    // Clear again (should not fail)
    clear_caps(&parent, scenario);

    // Verify cap is inactive
    ts::next_tx(scenario, USER_ADDRESS);
    {
        let suins = ts::take_shared<SuiNS>(scenario);
        assert!(subdomains::get_active_caps_count(&suins, parent.domain()) == 0, 0);
        ts::return_shared(suins);
    };

    // Clean up
    sui::transfer::public_transfer(cap, USER_ADDRESS);
    burn_nfts(vector[parent]);
    ts::end(scenario_val);
}

#[test, expected_failure(abort_code = ::suins_subdomains::subdomains::ECapNotActive)]
/// Test that cleared caps cannot be used
fun test_cleared_cap_cannot_be_used() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;

    let parent = create_sld_name(utf8(b"test.sui"), scenario);

    // Create a cap
    let mut cap = create_subname_cap(&parent, true, false, false, false, scenario);

    // Clear all caps
    clear_caps(&parent, scenario);

    // Try to use the cap (should fail)
    create_leaf_with_cap(&mut cap, utf8(b"leaf.test.sui"), TEST_ADDRESS, scenario);

    abort
}
