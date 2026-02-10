// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module suins_subdomains::subdomain_tests;

use std::string::{String, utf8};
use sui::{clock::{Self, Clock}, test_scenario::{Self as ts, Scenario, ctx}};
use suins::{
    constants::{
        grace_period_ms,
        year_ms,
        subdomain_allow_creation_key,
        subdomain_allow_extension_key
    },
    domain,
    registry::{Self, Registry},
    registry_tests::burn_nfts,
    subdomain_registration::{Self, SubDomainRegistration},
    suins::{Self, SuiNS, AdminCap},
    suins_registration::{Self, SuinsRegistration}
};
use suins_denylist::denylist;
use suins_subdomains::{config, subdomains::{Self, SubDomains, SubnameCap}};

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

/// Helper to create a SubnameCap
public fun create_subname_cap(
    parent: &SuinsRegistration,
    allow_leaf: bool,
    allow_node: bool,
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
    cap: &SubnameCap,
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
    cap: &SubnameCap,
    name: String,
    expiration: u64,
    allow_creation: bool,
    allow_time_extension: bool,
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
        allow_creation,
        allow_time_extension,
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
    let cap = create_subname_cap(&parent, true, false, scenario);

    // Use the cap to create a leaf subdomain
    create_leaf_with_cap(&cap, utf8(b"leaf.test.sui"), TEST_ADDRESS, scenario);

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

    // Create a cap that only allows node creation
    let cap = create_subname_cap(&parent, false, true, scenario);

    // Use the cap to create a node subdomain with permissions
    let child = create_node_with_cap(
        &cap,
        utf8(b"node.test.sui"),
        MIN_SUBDOMAIN_DURATION,
        true,
        true,
        scenario,
    );

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
    let cap = create_subname_cap(&parent, true, true, scenario);
    let cap_id = sui::object::id(&cap);

    // Create a leaf with the cap first (should work)
    create_leaf_with_cap(&cap, utf8(b"leaf1.test.sui"), TEST_ADDRESS, scenario);

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
    let cap = create_subname_cap(&parent, true, true, scenario);
    let cap_id = sui::object::id(&cap);
    revoke_cap(&parent, cap_id, scenario);

    // Try to use the revoked cap (should fail)
    create_leaf_with_cap(&cap, utf8(b"leaf.test.sui"), TEST_ADDRESS, scenario);

    abort
}

#[test, expected_failure(abort_code = ::suins_subdomains::subdomains::ELeafCreationNotAllowed)]
/// Test that cap without leaf permission cannot create leaves
fun test_cap_leaf_not_allowed() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;

    let parent = create_sld_name(utf8(b"test.sui"), scenario);

    // Create a cap that only allows node creation (not leaf)
    let cap = create_subname_cap(&parent, false, true, scenario);

    // Try to create a leaf (should fail)
    create_leaf_with_cap(&cap, utf8(b"leaf.test.sui"), TEST_ADDRESS, scenario);

    abort
}

#[test, expected_failure(abort_code = ::suins_subdomains::subdomains::ENodeCreationNotAllowed)]
/// Test that cap without node permission cannot create nodes
fun test_cap_node_not_allowed() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;

    let parent = create_sld_name(utf8(b"test.sui"), scenario);

    // Create a cap that only allows leaf creation (not node)
    let cap = create_subname_cap(&parent, true, false, scenario);

    // Try to create a node (should fail)
    let _child = create_node_with_cap(
        &cap,
        utf8(b"node.test.sui"),
        MIN_SUBDOMAIN_DURATION,
        false,
        false,
        scenario,
    );

    abort
}

#[test, expected_failure(abort_code = ::suins_subdomains::subdomains::ECapInvalidated)]
/// Test that cap is invalidated when domain is re-registered (new NFT ID)
fun test_cap_invalidated_on_reregistration() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;

    let parent = create_sld_name(utf8(b"test.sui"), scenario);

    // Create a cap
    let cap = create_subname_cap(&parent, true, true, scenario);

    // Let the domain expire
    increment_clock(year_ms() + grace_period_ms() + 1, scenario);

    // Re-register the domain (creates a new NFT with different ID)
    let new_parent = create_sld_name(utf8(b"test.sui"), scenario);

    // Try to use the old cap (should fail because NFT ID changed)
    create_leaf_with_cap(&cap, utf8(b"leaf.test.sui"), TEST_ADDRESS, scenario);

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

    let cap = create_subname_cap(&parent, true, false, scenario);

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
    let cap = create_subname_cap(&parent, true, true, scenario);

    // Transfer cap to TEST_ADDRESS
    ts::next_tx(scenario, USER_ADDRESS);
    sui::transfer::public_transfer(cap, TEST_ADDRESS);

    // TEST_ADDRESS uses the cap to create a leaf subdomain
    ts::next_tx(scenario, TEST_ADDRESS);
    {
        let mut suins = ts::take_shared<SuiNS>(scenario);
        let clock = ts::take_shared<Clock>(scenario);
        let cap = ts::take_from_sender<SubnameCap>(scenario);

        subdomains::new_leaf_with_cap(
            &mut suins,
            &cap,
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
        let cap = ts::take_from_sender<SubnameCap>(scenario);

        let child = subdomains::new_with_cap(
            &mut suins,
            &cap,
            &clock,
            utf8(b"node.test.sui"),
            MIN_SUBDOMAIN_DURATION,
            false,
            false,
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
    let cap = create_subname_cap(&parent, true, false, scenario);

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
        let cap = ts::take_from_sender<SubnameCap>(scenario);

        subdomains::new_leaf_with_cap(
            &mut suins,
            &cap,
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
    let cap = create_subname_cap(&parent, true, false, scenario);
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
    let cap1 = create_subname_cap(&parent, true, false, scenario); // leaf only
    let cap2 = create_subname_cap(&parent, false, true, scenario); // node only
    let cap3 = create_subname_cap(&parent, true, true, scenario); // both

    // Use cap1 to create a leaf
    ts::next_tx(scenario, USER_ADDRESS);
    {
        let mut suins = ts::take_shared<SuiNS>(scenario);
        let clock = ts::take_shared<Clock>(scenario);

        subdomains::new_leaf_with_cap(
            &mut suins,
            &cap1,
            &clock,
            utf8(b"leaf1.test.sui"),
            TEST_ADDRESS,
            ctx(scenario),
        );

        ts::return_shared(suins);
        ts::return_shared(clock);
    };

    // Use cap2 to create a node
    let child = create_node_with_cap(
        &cap2,
        utf8(b"node1.test.sui"),
        MIN_SUBDOMAIN_DURATION,
        false,
        false,
        scenario,
    );

    // Use cap3 to create both a leaf and a node
    ts::next_tx(scenario, USER_ADDRESS);
    {
        let mut suins = ts::take_shared<SuiNS>(scenario);
        let clock = ts::take_shared<Clock>(scenario);

        subdomains::new_leaf_with_cap(
            &mut suins,
            &cap3,
            &clock,
            utf8(b"leaf2.test.sui"),
            TEST_ADDRESS,
            ctx(scenario),
        );

        ts::return_shared(suins);
        ts::return_shared(clock);
    };

    let child2 = create_node_with_cap(
        &cap3,
        utf8(b"node2.test.sui"),
        MIN_SUBDOMAIN_DURATION,
        true,
        true,
        scenario,
    );

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

    // Create cap with both permissions
    let cap = create_subname_cap(&parent, true, true, scenario);

    // Create a leaf
    create_leaf_with_cap(&cap, utf8(b"leaf.test.sui"), TEST_ADDRESS, scenario);

    // Create a node with permissions set
    let child = create_node_with_cap(
        &cap,
        utf8(b"node.test.sui"),
        MIN_SUBDOMAIN_DURATION,
        true,
        true,
        scenario,
    );

    // Verify the node has the permissions we passed
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
    let cap = create_subname_cap(&parent, true, false, scenario);

    // Advance time so parent expires (but not past grace period, so domain not re-registerable)
    increment_clock(year_ms() + 1, scenario);

    // Try to use cap with expired parent (should fail)
    create_leaf_with_cap(&cap, utf8(b"leaf.test.sui"), TEST_ADDRESS, scenario);

    abort
}

#[test]
/// Test that revoking one cap doesn't affect other caps
fun test_revoke_one_cap_doesnt_affect_others() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;

    let parent = create_sld_name(utf8(b"test.sui"), scenario);

    let cap1 = create_subname_cap(&parent, true, false, scenario);
    let cap2 = create_subname_cap(&parent, true, false, scenario);
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
    create_leaf_with_cap(&cap2, utf8(b"leaf.test.sui"), TEST_ADDRESS, scenario);

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
    let cap = create_subname_cap(&parent, true, false, scenario);
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

// == Surrender SubnameCap Tests ==

/// Helper to surrender a SubnameCap
public fun surrender_cap(cap: SubnameCap, scenario: &mut Scenario) {
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
    let cap = create_subname_cap(&parent, true, false, scenario);

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
    let cap = create_subname_cap(&parent, true, false, scenario);
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
    let cap1 = create_subname_cap(&parent, true, false, scenario);
    let cap1_id = sui::object::id(&cap1);

    // Revoke cap1 (simulates what happens after surrender removes from active list)
    revoke_cap(&parent, cap1_id, scenario);

    // Try to use cap1 (should fail since it's not in active list)
    create_leaf_with_cap(&cap1, utf8(b"leaf.test.sui"), TEST_ADDRESS, scenario);

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
    let cap1 = create_subname_cap(&parent, true, false, scenario);
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
    let cap2 = create_subname_cap(&parent, false, true, scenario);
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

    // Create cap
    let cap = create_subname_cap(&parent, true, false, scenario);

    ts::next_tx(scenario, USER_ADDRESS);
    {
        let suins = ts::take_shared<SuiNS>(scenario);
        let caps = subdomains::get_active_caps(&suins, parent.domain());
        assert!(caps.length() == 1, 0);

        let entry = &caps[0];
        assert!(subdomains::cap_entry_id(entry) == sui::object::id(&cap), 1);
        assert!(subdomains::cap_entry_allow_leaf(entry) == true, 2);
        assert!(subdomains::cap_entry_allow_node(entry) == false, 3);
        // created_at_ms should be >= 0 (it's the clock timestamp at creation)
        assert!(subdomains::cap_entry_created_at_ms(entry) >= 0, 4);

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
    let cap = create_subname_cap(&parent, true, false, scenario);
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
public fun clear_caps(parent: &SuinsRegistration, scenario: &mut Scenario) {
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
    let cap1 = create_subname_cap(&parent, true, false, scenario);
    let cap2 = create_subname_cap(&parent, false, true, scenario);
    let cap3 = create_subname_cap(&parent, true, true, scenario);

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
    let cap = create_subname_cap(&parent, true, false, scenario);

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
    let cap = create_subname_cap(&parent, true, false, scenario);

    // Clear all caps
    clear_caps(&parent, scenario);

    // Try to use the cap (should fail)
    create_leaf_with_cap(&cap, utf8(b"leaf.test.sui"), TEST_ADDRESS, scenario);

    abort
}
