#[test_only]
module suins_voting::test_utils;

// === imports ===

use sui::{
    clock::{Self, Clock},
    coin::{Self, Coin},
    test_scenario::{Self as ts, Scenario},
    test_utils::{Self, assert_eq},
};
use suins_token::{
    ns::NS,
};
use suins_voting::{
    staking_admin::{Self, StakingAdminCap},
    staking_batch::{Self, StakingBatch},
    staking_config::{Self, StakingConfig},
};

// === constants ===

const INITIAL_TIME: u64 = 86_400_000; // January 2, 1970

// === addresses ===

const ADMIN: address = @0xaa1;

// === setup ===

public struct TestSetup {
    clock: Clock,
    config: StakingConfig,
    admin_cap: StakingAdminCap,
}

public fun clock(setup: &TestSetup): &Clock { &setup.clock }
public fun config(setup: &TestSetup): &StakingConfig { &setup.config }
public fun admin_cap(setup: &TestSetup): &StakingAdminCap { &setup.admin_cap }

public fun config_mut(setup: &mut TestSetup): &mut StakingConfig { &mut setup.config }

public fun setup(): (Scenario, TestSetup) {
    let mut ts = ts::begin(ADMIN);
    let mut clock = clock::create_for_testing(ts.ctx());
    clock.set_for_testing(INITIAL_TIME);
    staking_config::init_for_testing(ts.ctx());
    staking_admin::init_for_testing(ts.ctx());

    ts.next_tx(ADMIN);
    let config = ts.take_shared<StakingConfig>();
    let admin_cap = ts::take_from_address<StakingAdminCap>(&ts, ADMIN);
    (
        ts,
        TestSetup { clock, config, admin_cap }
    )
}

// === helpers for our modules ===

public fun new_batch(
    setup: &mut TestSetup,
    ts: &mut Scenario,
    sender: address,
    balance: u64,
    lock_months: u64,
): StakingBatch {
    ts.next_tx(sender);
    let balance = mint_ns(ts, balance);
    staking_batch::new(&setup.config, balance, lock_months, &setup.clock, ts.ctx())
}

public fun assert_power(
    setup: &TestSetup,
    batch: &StakingBatch,
    expected_power: u64,
) {
    assert_eq(expected_power, batch.power(&setup.config, &setup.clock));
}

// === helpers for sui modules ===

public fun mint_ns(
    ts: &mut Scenario,
    value: u64,
): Coin<NS> {
    return coin::mint_for_testing<NS>(value, ts.ctx())
}

public fun add_time(
    setup: &mut TestSetup,
    ms: u64,
) {
    setup.clock.increment_for_testing(ms);
}

public fun set_time(
    setup: &mut TestSetup,
    ms: u64,
) {
    setup.clock.set_for_testing(ms);
}

public fun destroy(setup: TestSetup, ts: Scenario) {
    test_utils::destroy(ts);
    test_utils::destroy(setup);
}
