// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module suins_subdomains::subdomain_tests;

use std::string::{String, utf8};
use sui::{clock::{Self, Clock}, test_scenario::{Self as ts, Scenario, ctx}};
use suins::{
    constants::{grace_period_ms, year_ms},
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
