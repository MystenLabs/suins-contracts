// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module suins::controller_tests;

use std::{option::{extract, some, none}, string::{utf8, String}};
use sui::{
    clock::{Self, Clock},
    dynamic_field,
    sui::SUI,
    test_scenario::{Self, Scenario, ctx},
    test_utils::{assert_eq, destroy},
    vec_map::VecMap
};
use suins::{
    constants::{mist_per_sui, year_ms},
    controller::{Self, ControllerV2},
    domain::{Self, Domain},
    register::Register,
    register_utils::register_util,
    registry::{Self, Registry, lookup, reverse_lookup},
    subdomain_registration,
    suins::{Self, SuiNS, AdminCap},
    suins_registration::{Self, SuinsRegistration}
};

use fun set_target_address_util as Scenario.set_target_address_util;
use fun set_reverse_lookup_util as Scenario.set_reverse_lookup_util;
use fun unset_reverse_lookup_util as Scenario.unset_reverse_lookup_util;
use fun set_user_data_util as Scenario.set_user_data_util;
use fun unset_user_data_util as Scenario.unset_user_data_util;
use fun lookup_util as Scenario.lookup_util;
use fun get_user_data as Scenario.get_user_data;
use fun setup as Scenario.setup;
use fun deauthorize_app_util as Scenario.deauthorize_app_util;
use fun reverse_lookup_util as Scenario.reverse_lookup_util;
use fun set_object_reverse_lookup_util as Scenario.set_object_reverse_lookup_util;
use fun unset_object_reverse_lookup_util as Scenario.unset_object_reverse_lookup_util;

const SUINS_ADDRESS: address = @0xA001;
const FIRST_ADDRESS: address = @0xB001;
const SECOND_ADDRESS: address = @0xB002;
const DOMAIN_NAME: vector<u8> = b"abc.sui";
const AVATAR: vector<u8> = b"avatar";
const CONTENT_HASH: vector<u8> = b"content_hash";
const WALRUS_SITE_ID: vector<u8> = b"walrus_site_id";

fun test_init(): Scenario {
    let mut scenario_val = test_scenario::begin(SUINS_ADDRESS);
    let scenario = &mut scenario_val;
    {
        let mut suins = suins::init_for_testing(scenario.ctx());
        suins.authorize_app_for_testing<Register>();
        suins.authorize_app_for_testing<ControllerV2>();
        suins.share_for_testing();
        let clock = clock::create_for_testing(scenario.ctx());
        clock.share_for_testing();
    };
    {
        scenario.next_tx(SUINS_ADDRESS);
        let admin_cap = scenario.take_from_sender<AdminCap>();
        let mut suins = scenario.take_shared<SuiNS>();

        registry::init_for_testing(&admin_cap, &mut suins, scenario.ctx());

        test_scenario::return_shared(suins);
        scenario.return_to_sender(admin_cap);
    };
    scenario_val
}

fun setup(scenario: &mut Scenario, sender: address, clock_tick: u64) {
    let nft = register_util<SUI>(
        scenario,
        DOMAIN_NAME.to_string(),
        1,
        1200 * mist_per_sui(),
        clock_tick,
    );
    transfer::public_transfer(nft, sender);
}

public fun set_target_address_util(
    scenario: &mut Scenario,
    sender: address,
    target: Option<address>,
    clock_tick: u64,
) {
    scenario.next_tx(sender);
    let mut suins = scenario.take_shared<SuiNS>();
    let nft = scenario.take_from_sender<SuinsRegistration>();
    let mut clock = scenario.take_shared<Clock>();

    clock.increment_for_testing(clock_tick);
    controller::set_target_address(&mut suins, &nft, target, &clock);

    test_scenario::return_shared(clock);
    scenario.return_to_sender(nft);
    test_scenario::return_shared(suins);
}

public fun set_reverse_lookup_util(scenario: &mut Scenario, sender: address, domain_name: String) {
    scenario.next_tx(sender);
    let mut suins = scenario.take_shared<SuiNS>();

    controller::set_reverse_lookup(&mut suins, domain_name, ctx(scenario));

    test_scenario::return_shared(suins);
}

public fun set_object_reverse_lookup_util(
    scenario: &mut Scenario,
    id: &mut UID,
    sender: address,
    domain_name: String,
) {
    scenario.next_tx(sender);
    let mut suins = scenario.take_shared<SuiNS>();

    controller::set_object_reverse_lookup(&mut suins, id, domain_name);
    test_scenario::return_shared(suins);
}

public fun unset_object_reverse_lookup_util(
    scenario: &mut Scenario,
    id: &mut UID,
    sender: address,
) {
    scenario.next_tx(sender);
    let mut suins = scenario.take_shared<SuiNS>();

    controller::unset_object_reverse_lookup(&mut suins, id);
    test_scenario::return_shared(suins);
}

public fun unset_reverse_lookup_util(scenario: &mut Scenario, sender: address) {
    scenario.next_tx(sender);
    let mut suins = scenario.take_shared<SuiNS>();

    controller::unset_reverse_lookup(&mut suins, ctx(scenario));

    test_scenario::return_shared(suins);
}

public fun set_user_data_util(
    scenario: &mut Scenario,
    sender: address,
    key: String,
    value: String,
    clock_tick: u64,
) {
    scenario.next_tx(sender);
    let mut suins = scenario.take_shared<SuiNS>();
    let nft = scenario.take_from_sender<SuinsRegistration>();
    let mut clock = scenario.take_shared<Clock>();

    clock.increment_for_testing(clock_tick);
    controller::set_user_data(&mut suins, &nft, key, value, &clock);

    test_scenario::return_shared(clock);
    test_scenario::return_shared(suins);
    scenario.return_to_sender(nft);
}

public fun unset_user_data_util(
    scenario: &mut Scenario,
    sender: address,
    key: String,
    clock_tick: u64,
) {
    scenario.next_tx(sender);
    let mut suins = scenario.take_shared<SuiNS>();
    let nft = scenario.take_from_sender<SuinsRegistration>();
    let mut clock = scenario.take_shared<Clock>();

    clock.increment_for_testing(clock_tick);
    controller::unset_user_data(&mut suins, &nft, key, &clock);

    test_scenario::return_shared(clock);
    scenario.return_to_sender(nft);
    test_scenario::return_shared(suins);
}

fun lookup_util(
    scenario: &mut Scenario,
    domain_name: String,
    expected_target_addr: Option<address>,
) {
    scenario.next_tx(SUINS_ADDRESS);
    let suins = scenario.take_shared<SuiNS>();

    let registry = suins.registry<Registry>();
    let record = extract(&mut lookup(registry, domain::new(domain_name)));
    assert_eq(record.target_address(), expected_target_addr);

    test_scenario::return_shared(suins);
}

fun get_user_data(scenario: &mut Scenario, domain_name: String): VecMap<String, String> {
    scenario.next_tx(SUINS_ADDRESS);
    let suins = scenario.take_shared<SuiNS>();

    let registry = suins.registry<Registry>();
    let record = extract(&mut lookup(registry, domain::new(domain_name)));
    let data = *record.data();
    test_scenario::return_shared(suins);

    data
}

fun reverse_lookup_util(
    scenario: &mut Scenario,
    addr: address,
    expected_domain_name: Option<Domain>,
) {
    scenario.next_tx(SUINS_ADDRESS);
    let suins = scenario.take_shared<SuiNS>();

    let registry = suins.registry<Registry>();
    let domain_name = registry.reverse_lookup(addr);
    assert_eq(domain_name, expected_domain_name);

    test_scenario::return_shared(suins);
}

fun deauthorize_app_util(scenario: &mut Scenario) {
    scenario.next_tx(SUINS_ADDRESS);
    let admin_cap = scenario.take_from_sender<AdminCap>();
    let mut suins = scenario.take_shared<SuiNS>();

    admin_cap.deauthorize_app<ControllerV2>(&mut suins);

    test_scenario::return_shared(suins);
    scenario.return_to_sender(admin_cap);
}

#[test]
fun test_set_target_address() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;
    scenario.setup(FIRST_ADDRESS, 0);

    scenario.set_target_address_util(FIRST_ADDRESS, some(SECOND_ADDRESS), 0);
    scenario.lookup_util(DOMAIN_NAME.to_string(), some(SECOND_ADDRESS));
    scenario.set_target_address_util(FIRST_ADDRESS, some(FIRST_ADDRESS), 0);
    scenario.lookup_util(DOMAIN_NAME.to_string(), some(FIRST_ADDRESS));
    scenario.set_target_address_util(FIRST_ADDRESS, none(), 0);
    scenario.lookup_util(DOMAIN_NAME.to_string(), none());

    scenario_val.end();
}

#[test, expected_failure(abort_code = registry::ERecordExpired)]
fun test_set_target_address_aborts_if_nft_expired() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;
    scenario.setup(FIRST_ADDRESS, 0);

    scenario.set_target_address_util(
        FIRST_ADDRESS,
        some(SECOND_ADDRESS),
        2 * year_ms(),
    );

    scenario_val.end();
}

#[test, expected_failure(abort_code = registry::EIdMismatch)]
fun test_set_target_address_aborts_if_nft_expired_2() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;
    scenario.setup(FIRST_ADDRESS, 0);
    scenario.setup(SECOND_ADDRESS, 2 * year_ms());

    scenario.set_target_address_util(FIRST_ADDRESS, some(SECOND_ADDRESS), 0);

    scenario_val.end();
}

#[test]
fun test_set_target_address_works_if_domain_is_registered_again() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;
    scenario.setup(FIRST_ADDRESS, 0);
    scenario.setup(SECOND_ADDRESS, 2 * year_ms());

    scenario.set_target_address_util(SECOND_ADDRESS, some(SECOND_ADDRESS), 0);
    scenario.lookup_util(DOMAIN_NAME.to_string(), some(SECOND_ADDRESS));

    scenario_val.end();
}

#[test, expected_failure(abort_code = ::suins::suins::EAppNotAuthorized)]
fun test_set_target_address_aborts_if_controller_is_deauthorized() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;
    scenario.setup(FIRST_ADDRESS, 0);

    scenario.deauthorize_app_util();
    scenario.set_target_address_util(FIRST_ADDRESS, some(SECOND_ADDRESS), 0);

    scenario_val.end();
}

#[test]
fun test_set_reverse_lookup() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;
    scenario.setup(FIRST_ADDRESS, 0);

    scenario.set_target_address_util(FIRST_ADDRESS, some(SECOND_ADDRESS), 0);
    scenario.reverse_lookup_util(SECOND_ADDRESS, none());
    scenario.set_reverse_lookup_util(SECOND_ADDRESS, DOMAIN_NAME.to_string());
    reverse_lookup_util(
        scenario,
        SECOND_ADDRESS,
        some(domain::new(DOMAIN_NAME.to_string())),
    );

    scenario.set_target_address_util(FIRST_ADDRESS, some(FIRST_ADDRESS), 0);
    scenario.reverse_lookup_util(FIRST_ADDRESS, none());
    scenario.reverse_lookup_util(SECOND_ADDRESS, none());
    scenario.set_reverse_lookup_util(FIRST_ADDRESS, DOMAIN_NAME.to_string());
    reverse_lookup_util(
        scenario,
        FIRST_ADDRESS,
        some(domain::new(DOMAIN_NAME.to_string())),
    );
    scenario.reverse_lookup_util(SECOND_ADDRESS, none());

    scenario_val.end();
}

#[test, expected_failure(abort_code = registry::ETargetNotSet)]
fun test_set_reverse_lookup_aborts_if_target_address_not_set() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;
    scenario.setup(FIRST_ADDRESS, 0);

    scenario.reverse_lookup_util(SECOND_ADDRESS, none());
    scenario.set_reverse_lookup_util(SECOND_ADDRESS, DOMAIN_NAME.to_string());

    scenario_val.end();
}

#[test, expected_failure(abort_code = registry::ERecordMismatch)]
fun test_set_reverse_lookup_aborts_if_target_address_not_match() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;
    scenario.setup(FIRST_ADDRESS, 0);

    scenario.set_target_address_util(FIRST_ADDRESS, some(FIRST_ADDRESS), 0);
    scenario.reverse_lookup_util(SECOND_ADDRESS, none());
    scenario.set_reverse_lookup_util(SECOND_ADDRESS, DOMAIN_NAME.to_string());

    scenario_val.end();
}

#[test, expected_failure(abort_code = ::suins::suins::EAppNotAuthorized)]
fun test_set_reverse_lookup_aborts_if_controller_is_deauthorized() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;
    scenario.setup(FIRST_ADDRESS, 0);

    scenario.set_target_address_util(FIRST_ADDRESS, some(SECOND_ADDRESS), 0);
    scenario.deauthorize_app_util();
    scenario.set_reverse_lookup_util(SECOND_ADDRESS, DOMAIN_NAME.to_string());

    scenario_val.end();
}

#[test]
fun test_unset_reverse_lookup() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;
    scenario.setup(FIRST_ADDRESS, 0);

    scenario.set_target_address_util(FIRST_ADDRESS, some(SECOND_ADDRESS), 0);
    scenario.set_reverse_lookup_util(SECOND_ADDRESS, DOMAIN_NAME.to_string());
    reverse_lookup_util(
        scenario,
        SECOND_ADDRESS,
        some(domain::new(DOMAIN_NAME.to_string())),
    );
    scenario.unset_reverse_lookup_util(SECOND_ADDRESS);
    scenario.reverse_lookup_util(SECOND_ADDRESS, none());

    scenario_val.end();
}

#[test, expected_failure(abort_code = ::suins::suins::EAppNotAuthorized)]
fun test_unset_reverse_lookup_if_controller_is_deauthorized() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;
    scenario.setup(FIRST_ADDRESS, 0);

    scenario.set_target_address_util(FIRST_ADDRESS, some(SECOND_ADDRESS), 0);
    scenario.set_reverse_lookup_util(SECOND_ADDRESS, DOMAIN_NAME.to_string());
    scenario.deauthorize_app_util();
    scenario.unset_reverse_lookup_util(SECOND_ADDRESS);

    scenario_val.end();
}

#[test, expected_failure(abort_code = dynamic_field::EFieldDoesNotExist)]
fun test_unset_reverse_lookup_aborts_if_not_set() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;
    scenario.setup(FIRST_ADDRESS, 0);

    scenario.unset_reverse_lookup_util(SECOND_ADDRESS);

    scenario_val.end();
}

#[test]
fun test_set_user_data() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;
    scenario.setup(FIRST_ADDRESS, 0);

    let data = &scenario.get_user_data(DOMAIN_NAME.to_string());
    assert_eq(data.size(), 0);
    set_user_data_util(
        scenario,
        FIRST_ADDRESS,
        AVATAR.to_string(),
        b"value_avatar".to_string(),
        0,
    );
    let data = &scenario.get_user_data(DOMAIN_NAME.to_string());
    assert_eq(data.size(), 1);
    assert_eq(*data.get(&AVATAR.to_string()), b"value_avatar".to_string());

    set_user_data_util(
        scenario,
        FIRST_ADDRESS,
        utf8(CONTENT_HASH),
        b"value_content_hash".to_string(),
        0,
    );
    let data = &scenario.get_user_data(DOMAIN_NAME.to_string());
    assert_eq(data.size(), 2);
    assert_eq(*data.get(&AVATAR.to_string()), b"value_avatar".to_string());
    assert_eq(*data.get(&utf8(CONTENT_HASH)), b"value_content_hash".to_string());

    set_user_data_util(
        scenario,
        FIRST_ADDRESS,
        utf8(WALRUS_SITE_ID),
        b"value_walrus_site_id".to_string(),
        0,
    );
    let data = &scenario.get_user_data(DOMAIN_NAME.to_string());
    assert_eq(data.size(), 3);
    assert_eq(*data.get(&AVATAR.to_string()), b"value_avatar".to_string());
    assert_eq(*data.get(&utf8(CONTENT_HASH)), b"value_content_hash".to_string());
    assert_eq(*data.get(&WALRUS_SITE_ID.to_string()), b"value_walrus_site_id".to_string());

    scenario_val.end();
}

#[test, expected_failure(abort_code = controller::EUnsupportedKey)]
fun test_set_user_data_aborts_if_key_is_unsupported() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;
    scenario.setup(FIRST_ADDRESS, 0);

    set_user_data_util(
        scenario,
        FIRST_ADDRESS,
        b"key".to_string(),
        b"value".to_string(),
        0,
    );

    scenario_val.end();
}

#[test, expected_failure(abort_code = registry::ERecordExpired)]
fun test_set_user_data_aborts_if_nft_expired() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;
    scenario.setup(FIRST_ADDRESS, 0);

    set_user_data_util(
        scenario,
        FIRST_ADDRESS,
        AVATAR.to_string(),
        b"value".to_string(),
        2 * year_ms(),
    );

    scenario_val.end();
}

#[test, expected_failure(abort_code = registry::EIdMismatch)]
fun test_set_user_data_aborts_if_nft_expired_2() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;
    scenario.setup(FIRST_ADDRESS, 0);
    scenario.setup(SECOND_ADDRESS, 2 * year_ms());

    set_user_data_util(
        scenario,
        FIRST_ADDRESS,
        AVATAR.to_string(),
        b"value".to_string(),
        0,
    );

    scenario_val.end();
}

#[test]
fun test_set_user_data_works_if_domain_is_registered_again() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;
    scenario.setup(FIRST_ADDRESS, 0);
    scenario.setup(SECOND_ADDRESS, 2 * year_ms());

    set_user_data_util(
        scenario,
        SECOND_ADDRESS,
        AVATAR.to_string(),
        b"value".to_string(),
        0,
    );
    let data = &scenario.get_user_data(DOMAIN_NAME.to_string());
    assert_eq(data.size(), 1);
    assert_eq(*data.get(&AVATAR.to_string()), b"value".to_string());

    scenario_val.end();
}

#[test, expected_failure(abort_code = ::suins::suins::EAppNotAuthorized)]
fun test_set_user_data_aborts_if_controller_is_deauthorized() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;
    scenario.setup(FIRST_ADDRESS, 0);

    scenario.deauthorize_app_util();
    scenario.set_user_data_util(
        FIRST_ADDRESS,
        AVATAR.to_string(),
        b"value_avatar".to_string(),
        0,
    );

    scenario_val.end();
}

#[test]
fun test_unset_user_data() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;
    scenario.setup(FIRST_ADDRESS, 0);

    scenario.set_user_data_util(
        FIRST_ADDRESS,
        AVATAR.to_string(),
        b"value_avatar".to_string(),
        0,
    );
    scenario.unset_user_data_util(FIRST_ADDRESS, AVATAR.to_string(), 0);
    let data = &scenario.get_user_data(DOMAIN_NAME.to_string());
    assert_eq(data.size(), 0);

    scenario.set_user_data_util(
        FIRST_ADDRESS,
        utf8(CONTENT_HASH),
        b"value_content_hash".to_string(),
        0,
    );
    scenario.set_user_data_util(
        FIRST_ADDRESS,
        AVATAR.to_string(),
        b"value_avatar".to_string(),
        0,
    );
    scenario.set_user_data_util(
        FIRST_ADDRESS,
        WALRUS_SITE_ID.to_string(),
        b"value_walrus_site_id".to_string(),
        0,
    );
    scenario.unset_user_data_util(FIRST_ADDRESS, utf8(CONTENT_HASH), 0);
    let data = &scenario.get_user_data(DOMAIN_NAME.to_string());
    assert_eq(data.size(), 2);
    assert_eq(*data.get(&AVATAR.to_string()), b"value_avatar".to_string());
    assert_eq(*data.get(&WALRUS_SITE_ID.to_string()), b"value_walrus_site_id".to_string());

    scenario.unset_user_data_util(FIRST_ADDRESS, WALRUS_SITE_ID.to_string(), 0);
    let data = &scenario.get_user_data(DOMAIN_NAME.to_string());
    assert_eq(data.size(), 1);
    assert_eq(*data.get(&AVATAR.to_string()), b"value_avatar".to_string());

    scenario_val.end();
}

#[test]
fun test_unset_user_data_works_if_key_not_exists() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;
    scenario.setup(FIRST_ADDRESS, 0);

    scenario.unset_user_data_util(FIRST_ADDRESS, AVATAR.to_string(), 0);

    scenario_val.end();
}

#[test, expected_failure(abort_code = registry::ERecordExpired)]
fun test_unset_user_data_aborts_if_nft_expired() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;
    scenario.setup(FIRST_ADDRESS, 0);

    scenario.unset_user_data_util(FIRST_ADDRESS, AVATAR.to_string(), 2 * year_ms());

    scenario_val.end();
}

#[test, expected_failure(abort_code = ::suins::suins::EAppNotAuthorized)]
fun test_unset_user_data_works_if_controller_is_deauthorized() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;
    scenario.setup(FIRST_ADDRESS, 0);

    scenario.deauthorize_app_util();
    scenario.unset_user_data_util(FIRST_ADDRESS, AVATAR.to_string(), 0);

    scenario_val.end();
}

#[test]
fun test_burn_expired() {
    // Only testing the surface with burning, as most logic is enforced/tested on the registry level.
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;
    scenario.next_tx(SUINS_ADDRESS);

    let mut clock = scenario.take_shared<Clock>();
    let mut suins = scenario.take_shared<SuiNS>();

    let ns_registration = suins_registration::new_for_testing(
        domain::new(b"test.sui".to_string()),
        1,
        &clock,
        scenario.ctx(),
    );

    clock.increment_for_testing(year_ms() * 2);
    controller::burn_expired(&mut suins, ns_registration, &clock);

    test_scenario::return_shared(clock);
    test_scenario::return_shared(suins);

    scenario_val.end();
}

#[test]
fun test_burn_subname_expired() {
    // Only testing the surface with burning, as most logic is enforced/tested on the registry level.
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;
    scenario.next_tx(SUINS_ADDRESS);

    let mut clock = scenario.take_shared<Clock>();
    let mut suins = scenario.take_shared<SuiNS>();

    let ns_registration = suins_registration::new_for_testing(
        domain::new(b"inner.test.sui".to_string()),
        1,
        &clock,
        scenario.ctx(),
    );

    let subname = subdomain_registration::new(ns_registration, &clock, scenario.ctx());

    clock.increment_for_testing(year_ms() * 2);
    controller::burn_expired_subname(&mut suins, subname, &clock);

    test_scenario::return_shared(clock);
    test_scenario::return_shared(suins);

    scenario_val.end();
}

// === Prune subdomain test helpers ===

/// Creates a parent domain and returns the NFT.
fun create_parent_domain(
    registry: &mut Registry,
    parent_name: vector<u8>,
    clock: &Clock,
    ctx: &mut TxContext,
): SuinsRegistration {
    registry.add_record_ignoring_grace_period(
        domain::new(parent_name.to_string()),
        1,
        clock,
        ctx,
    )
}

/// Creates a subdomain with a short expiration (expires after 1ms).
fun create_expiring_subdomain(
    registry: &mut Registry,
    subdomain_name: vector<u8>,
    clock: &Clock,
    ctx: &mut TxContext,
): SuinsRegistration {
    let subdomain = domain::new(subdomain_name.to_string());
    let mut subdomain_nft = registry.add_record_ignoring_grace_period(
        subdomain,
        1,
        clock,
        ctx,
    );
    registry.set_expiration_timestamp_ms(
        &mut subdomain_nft,
        subdomain,
        clock::timestamp_ms(clock) + 1,
    );
    subdomain_nft
}

#[test]
fun test_prune_expired_subname_allows_reregistration() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;
    scenario.next_tx(SUINS_ADDRESS);

    let mut clock = scenario.take_shared<Clock>();
    let mut suins = scenario.take_shared<SuiNS>();

    let (parent_nft, subdomain_nft) = {
        let registry = suins::app_registry_mut<ControllerV2, Registry>(
            controller::auth_for_testing(),
            &mut suins,
        );
        let parent_nft = create_parent_domain(registry, b"test.sui", &clock, scenario.ctx());
        let subdomain_nft = create_expiring_subdomain(registry, b"child.test.sui", &clock, scenario.ctx());
        (parent_nft, subdomain_nft)
    };

    clock.increment_for_testing(2);
    controller::prune_expired_subname(
        &mut suins,
        &parent_nft,
        b"child.test.sui".to_string(),
        &clock,
    );

    // Verify subdomain can be re-registered after pruning.
    let subdomain_nft_2 = {
        let registry = suins::app_registry_mut<ControllerV2, Registry>(
            controller::auth_for_testing(),
            &mut suins,
        );
        registry.add_record_ignoring_grace_period(
            domain::new(b"child.test.sui".to_string()),
            1,
            &clock,
            scenario.ctx(),
        )
    };

    transfer::public_transfer(parent_nft, SUINS_ADDRESS);
    transfer::public_transfer(subdomain_nft, SUINS_ADDRESS);
    transfer::public_transfer(subdomain_nft_2, SUINS_ADDRESS);

    test_scenario::return_shared(clock);
    test_scenario::return_shared(suins);
    scenario_val.end();
}

#[test, expected_failure(abort_code = registry::ERecordNotExpired)]
fun test_prune_expired_subname_aborts_if_not_expired() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;
    scenario.next_tx(SUINS_ADDRESS);

    let clock = scenario.take_shared<Clock>();
    let mut suins = scenario.take_shared<SuiNS>();

    let (parent_nft, subdomain_nft) = {
        let registry = suins::app_registry_mut<ControllerV2, Registry>(
            controller::auth_for_testing(),
            &mut suins,
        );
        let parent_nft = create_parent_domain(registry, b"test.sui", &clock, scenario.ctx());
        // Create subdomain without short expiration (uses default 1 year).
        let subdomain_nft = registry.add_record_ignoring_grace_period(
            domain::new(b"child.test.sui".to_string()),
            1,
            &clock,
            scenario.ctx(),
        );
        (parent_nft, subdomain_nft)
    };

    // Attempt to prune non-expired subdomain - should fail.
    controller::prune_expired_subname(
        &mut suins,
        &parent_nft,
        b"child.test.sui".to_string(),
        &clock,
    );

    transfer::public_transfer(parent_nft, SUINS_ADDRESS);
    transfer::public_transfer(subdomain_nft, SUINS_ADDRESS);
    test_scenario::return_shared(clock);
    test_scenario::return_shared(suins);
    scenario_val.end();
}

#[test, expected_failure(abort_code = controller::EParentMismatch)]
fun test_prune_expired_subname_aborts_if_wrong_parent() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;
    scenario.next_tx(SUINS_ADDRESS);

    let mut clock = scenario.take_shared<Clock>();
    let mut suins = scenario.take_shared<SuiNS>();

    let (parent_nft, other_subdomain_nft) = {
        let registry = suins::app_registry_mut<ControllerV2, Registry>(
            controller::auth_for_testing(),
            &mut suins,
        );
        let parent_nft = create_parent_domain(registry, b"test.sui", &clock, scenario.ctx());
        // Create subdomain under a different parent (other.sui, not test.sui).
        let other_subdomain_nft = create_expiring_subdomain(registry, b"child.other.sui", &clock, scenario.ctx());
        (parent_nft, other_subdomain_nft)
    };

    clock.increment_for_testing(2);

    // Attempt to prune subdomain with wrong parent - should fail.
    controller::prune_expired_subname(
        &mut suins,
        &parent_nft,
        b"child.other.sui".to_string(),
        &clock,
    );

    transfer::public_transfer(parent_nft, SUINS_ADDRESS);
    transfer::public_transfer(other_subdomain_nft, SUINS_ADDRESS);
    test_scenario::return_shared(clock);
    test_scenario::return_shared(suins);
    scenario_val.end();
}

#[test, expected_failure(abort_code = registry::ERecordNotFound)]
fun test_prune_expired_subname_aborts_if_record_missing() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;
    scenario.next_tx(SUINS_ADDRESS);

    let clock = scenario.take_shared<Clock>();
    let mut suins = scenario.take_shared<SuiNS>();

    let parent_nft = {
        let registry = suins::app_registry_mut<ControllerV2, Registry>(
            controller::auth_for_testing(),
            &mut suins,
        );
        create_parent_domain(registry, b"test.sui", &clock, scenario.ctx())
    };

    // Attempt to prune non-existent subdomain - should fail.
    controller::prune_expired_subname(
        &mut suins,
        &parent_nft,
        b"missing.test.sui".to_string(),
        &clock,
    );

    transfer::public_transfer(parent_nft, SUINS_ADDRESS);
    test_scenario::return_shared(clock);
    test_scenario::return_shared(suins);
    scenario_val.end();
}

#[test, expected_failure(abort_code = registry::ERecordExpired)]
fun test_prune_expired_subname_aborts_if_parent_expired() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;
    scenario.next_tx(SUINS_ADDRESS);

    let mut clock = scenario.take_shared<Clock>();
    let mut suins = scenario.take_shared<SuiNS>();

    let (parent_nft, subdomain_nft) = {
        let registry = suins::app_registry_mut<ControllerV2, Registry>(
            controller::auth_for_testing(),
            &mut suins,
        );
        // Create parent with short expiration.
        let parent_domain = domain::new(b"test.sui".to_string());
        let mut parent_nft = registry.add_record_ignoring_grace_period(
            parent_domain,
            1,
            &clock,
            scenario.ctx(),
        );
        registry.set_expiration_timestamp_ms(
            &mut parent_nft,
            parent_domain,
            clock::timestamp_ms(&clock) + 1,
        );
        let subdomain_nft = create_expiring_subdomain(registry, b"child.test.sui", &clock, scenario.ctx());
        (parent_nft, subdomain_nft)
    };

    clock.increment_for_testing(2);

    // Attempt to prune with expired parent - should fail.
    controller::prune_expired_subname(
        &mut suins,
        &parent_nft,
        b"child.test.sui".to_string(),
        &clock,
    );

    transfer::public_transfer(parent_nft, SUINS_ADDRESS);
    transfer::public_transfer(subdomain_nft, SUINS_ADDRESS);
    test_scenario::return_shared(clock);
    test_scenario::return_shared(suins);
    scenario_val.end();
}

#[test, expected_failure(abort_code = controller::ENotSubdomain)]
fun test_prune_expired_subname_aborts_if_not_subdomain() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;
    scenario.next_tx(SUINS_ADDRESS);

    let clock = scenario.take_shared<Clock>();
    let mut suins = scenario.take_shared<SuiNS>();

    let parent_nft = {
        let registry = suins::app_registry_mut<ControllerV2, Registry>(
            controller::auth_for_testing(),
            &mut suins,
        );
        create_parent_domain(registry, b"sui", &clock, scenario.ctx())
    };

    // Attempt to prune a TLD (not a subdomain) - should fail.
    controller::prune_expired_subname(
        &mut suins,
        &parent_nft,
        b"test.sui".to_string(),
        &clock,
    );

    transfer::public_transfer(parent_nft, SUINS_ADDRESS);
    test_scenario::return_shared(clock);
    test_scenario::return_shared(suins);
    scenario_val.end();
}

#[test]
fun test_object_reverse_lookup() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;

    let mut uid = object::new(scenario.ctx());

    scenario.setup(FIRST_ADDRESS, 0);

    scenario.set_target_address_util(FIRST_ADDRESS, some(uid.to_address()), 0);
    scenario.set_object_reverse_lookup_util(&mut uid, FIRST_ADDRESS, DOMAIN_NAME.to_string());
    scenario.lookup_util(DOMAIN_NAME.to_string(), some(uid.to_address()));
    scenario.reverse_lookup_util(uid.to_address(), some(domain::new(DOMAIN_NAME.to_string())));

    // now let's remove this reverse lookup
    scenario.unset_object_reverse_lookup_util(&mut uid, FIRST_ADDRESS);
    scenario.reverse_lookup_util(uid.to_address(), none());

    destroy(uid);
    scenario_val.end();
}

#[test]
fun test_reverse_reset_when_target_address_changes() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;

    let mut uid = object::new(scenario.ctx());

    scenario.setup(FIRST_ADDRESS, 0);

    scenario.set_target_address_util(FIRST_ADDRESS, some(uid.to_address()), 0);
    scenario.set_object_reverse_lookup_util(&mut uid, FIRST_ADDRESS, DOMAIN_NAME.to_string());
    scenario.lookup_util(DOMAIN_NAME.to_string(), some(uid.to_address()));
    scenario.reverse_lookup_util(uid.to_address(), some(domain::new(DOMAIN_NAME.to_string())));

    scenario.set_target_address_util(FIRST_ADDRESS, some(FIRST_ADDRESS), 0);
    scenario.reverse_lookup_util(uid.to_address(), none());

    destroy(uid);
    scenario_val.end();
}
