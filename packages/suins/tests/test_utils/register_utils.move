// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module suins::register_utils;

use std::string::String;
use sui::clock::Clock;
use sui::coin;
use sui::test_scenario::{Self, Scenario, ctx};
use suins::register::register;
use suins::suins::SuiNS;
use suins::suins_registration::SuinsRegistration;

const SUINS_ADDRESS: address = @0xA001;

public fun register_util<T>(
    scenario: &mut Scenario,
    domain_name: String,
    no_years: u8,
    amount: u64,
    clock_tick: u64,
): SuinsRegistration {
    scenario.next_tx(SUINS_ADDRESS);
    let mut suins = scenario.take_shared<SuiNS>();
    let payment = coin::mint_for_testing<T>(amount, scenario.ctx());
    let mut clock = scenario.take_shared<Clock>();

    clock.increment_for_testing(clock_tick);
    let nft = register<T>(
        &mut suins,
        domain_name,
        no_years,
        payment,
        &clock,
        scenario.ctx(),
    );

    test_scenario::return_shared(clock);
    test_scenario::return_shared(suins);

    nft
}
