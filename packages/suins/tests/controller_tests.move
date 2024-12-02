// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module suins::controller_tests;

use std::option::{extract, some, none};
use std::string::{utf8, String};
use sui::clock::{Self, Clock};
use sui::dynamic_field;
use sui::sui::SUI;
use sui::test_scenario::{Self, Scenario, ctx};
use sui::test_utils::assert_eq;
use sui::vec_map::VecMap;
use suins::constants::{mist_per_sui, year_ms};
use suins::controller::{Self, ControllerV2};
use suins::domain::{Self, Domain};
use suins::register::Register;
use suins::register_utils::register_util;
use suins::registry::{Self, Registry, lookup, reverse_lookup};
use suins::suins::{Self, SuiNS, AdminCap};
use suins::suins_registration::{Self, SuinsRegistration};
use suins::subdomain_registration::{Self, SubDomainRegistration};

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

const SUINS_ADDRESS: address = @0xA001;
const FIRST_ADDRESS: address = @0xB001;
const SECOND_ADDRESS: address = @0xB002;
const DOMAIN_NAME: vector<u8> = b"abc.sui";
const AVATAR: vector<u8> = b"avatar";
const CONTENT_HASH: vector<u8> = b"content_hash";

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
        utf8(DOMAIN_NAME),
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
    scenario.lookup_util(utf8(DOMAIN_NAME), some(SECOND_ADDRESS));
    scenario.set_target_address_util(FIRST_ADDRESS, some(FIRST_ADDRESS), 0);
    scenario.lookup_util(utf8(DOMAIN_NAME), some(FIRST_ADDRESS));
    scenario.set_target_address_util(FIRST_ADDRESS, none(), 0);
    scenario.lookup_util(utf8(DOMAIN_NAME), none());

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
    scenario.lookup_util(utf8(DOMAIN_NAME), some(SECOND_ADDRESS));

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
    scenario.set_reverse_lookup_util(SECOND_ADDRESS, utf8(DOMAIN_NAME));
    reverse_lookup_util(
        scenario,
        SECOND_ADDRESS,
        some(domain::new(utf8(DOMAIN_NAME))),
    );

    scenario.set_target_address_util(FIRST_ADDRESS, some(FIRST_ADDRESS), 0);
    scenario.reverse_lookup_util(FIRST_ADDRESS, none());
    scenario.reverse_lookup_util(SECOND_ADDRESS, none());
    scenario.set_reverse_lookup_util(FIRST_ADDRESS, utf8(DOMAIN_NAME));
    reverse_lookup_util(
        scenario,
        FIRST_ADDRESS,
        some(domain::new(utf8(DOMAIN_NAME))),
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
    scenario.set_reverse_lookup_util(SECOND_ADDRESS, utf8(DOMAIN_NAME));

    scenario_val.end();
}

#[test, expected_failure(abort_code = registry::ERecordMismatch)]
fun test_set_reverse_lookup_aborts_if_target_address_not_match() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;
    scenario.setup(FIRST_ADDRESS, 0);

    scenario.set_target_address_util(FIRST_ADDRESS, some(FIRST_ADDRESS), 0);
    scenario.reverse_lookup_util(SECOND_ADDRESS, none());
    scenario.set_reverse_lookup_util(SECOND_ADDRESS, utf8(DOMAIN_NAME));

    scenario_val.end();
}

#[test, expected_failure(abort_code = ::suins::suins::EAppNotAuthorized)]
fun test_set_reverse_lookup_aborts_if_controller_is_deauthorized() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;
    scenario.setup(FIRST_ADDRESS, 0);

    scenario.set_target_address_util(FIRST_ADDRESS, some(SECOND_ADDRESS), 0);
    scenario.deauthorize_app_util();
    scenario.set_reverse_lookup_util(SECOND_ADDRESS, utf8(DOMAIN_NAME));

    scenario_val.end();
}

#[test]
fun test_unset_reverse_lookup() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;
    scenario.setup(FIRST_ADDRESS, 0);

    scenario.set_target_address_util(FIRST_ADDRESS, some(SECOND_ADDRESS), 0);
    scenario.set_reverse_lookup_util(SECOND_ADDRESS, utf8(DOMAIN_NAME));
    reverse_lookup_util(
        scenario,
        SECOND_ADDRESS,
        some(domain::new(utf8(DOMAIN_NAME))),
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
    scenario.set_reverse_lookup_util(SECOND_ADDRESS, utf8(DOMAIN_NAME));
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

    let data = &scenario.get_user_data(utf8(DOMAIN_NAME));
    assert_eq(data.size(), 0);
    set_user_data_util(
        scenario,
        FIRST_ADDRESS,
        utf8(AVATAR),
        utf8(b"value_avatar"),
        0,
    );
    let data = &scenario.get_user_data(utf8(DOMAIN_NAME));
    assert_eq(data.size(), 1);
    assert_eq(*data.get(&utf8(AVATAR)), utf8(b"value_avatar"));

    set_user_data_util(
        scenario,
        FIRST_ADDRESS,
        utf8(CONTENT_HASH),
        utf8(b"value_content_hash"),
        0,
    );
    let data = &scenario.get_user_data(utf8(DOMAIN_NAME));
    assert_eq(data.size(), 2);
    assert_eq(*data.get(&utf8(AVATAR)), utf8(b"value_avatar"));
    assert_eq(*data.get(&utf8(CONTENT_HASH)), utf8(b"value_content_hash"));

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
        utf8(b"key"),
        utf8(b"value"),
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
        utf8(AVATAR),
        utf8(b"value"),
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
        utf8(AVATAR),
        utf8(b"value"),
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
        utf8(AVATAR),
        utf8(b"value"),
        0,
    );
    let data = &scenario.get_user_data(utf8(DOMAIN_NAME));
    assert_eq(data.size(), 1);
    assert_eq(*data.get(&utf8(AVATAR)), utf8(b"value"));

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
        utf8(AVATAR),
        utf8(b"value_avatar"),
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
        utf8(AVATAR),
        utf8(b"value_avatar"),
        0,
    );
    scenario.unset_user_data_util(FIRST_ADDRESS, utf8(AVATAR), 0);
    let data = &scenario.get_user_data(utf8(DOMAIN_NAME));
    assert_eq(data.size(), 0);

    scenario.set_user_data_util(
        FIRST_ADDRESS,
        utf8(CONTENT_HASH),
        utf8(b"value_content_hash"),
        0,
    );
    scenario.set_user_data_util(
        FIRST_ADDRESS,
        utf8(AVATAR),
        utf8(b"value_avatar"),
        0,
    );
    scenario.unset_user_data_util(FIRST_ADDRESS, utf8(CONTENT_HASH), 0);
    let data = &scenario.get_user_data(utf8(DOMAIN_NAME));
    assert_eq(data.size(), 1);
    assert_eq(*data.get(&utf8(AVATAR)), utf8(b"value_avatar"));

    scenario_val.end();
}

#[test]
fun test_unset_user_data_works_if_key_not_exists() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;
    scenario.setup(FIRST_ADDRESS, 0);

    scenario.unset_user_data_util(FIRST_ADDRESS, utf8(AVATAR), 0);

    scenario_val.end();
}

#[test, expected_failure(abort_code = registry::ERecordExpired)]
fun test_unset_user_data_aborts_if_nft_expired() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;
    scenario.setup(FIRST_ADDRESS, 0);

    scenario.unset_user_data_util(FIRST_ADDRESS, utf8(AVATAR), 2 * year_ms());

    scenario_val.end();
}

#[test, expected_failure(abort_code = ::suins::suins::EAppNotAuthorized)]
fun test_unset_user_data_works_if_controller_is_deauthorized() {
    let mut scenario_val = test_init();
    let scenario = &mut scenario_val;
    scenario.setup(FIRST_ADDRESS, 0);

    scenario.deauthorize_app_util();
    scenario.unset_user_data_util(FIRST_ADDRESS, utf8(AVATAR), 0);

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
