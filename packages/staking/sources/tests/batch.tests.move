#[test_only]
module staking::batch_tests;

// === imports ===

use sui::{
    clock::{Self, Clock},
    coin::{Self, Coin},
    test_scenario::{Self as ts, Scenario},
    test_utils::{assert_eq, destroy},
};
use token::{
    ns::NS,
};
use staking::{
    batch::{Self, Batch},
    constants::{month_ms},
};

// === constants ===

const INITIAL_TIME: u64 = 86_400_000; // January 2, 1970

// === addresses ===

const ADMIN: address = @0xaa1;
const USER_1: address = @0xee1;

// === test setup ===

public struct TestSetup {
    ts: Scenario,
    clock: Clock,
}

fun setup(): TestSetup {
    let mut ts = ts::begin(ADMIN);
    let mut clock = clock::create_for_testing(ts.ctx());
    clock.set_for_testing(INITIAL_TIME);
    TestSetup { ts, clock }
}

// === helpers for our modules ===

fun stake_and_take(
    setup: &mut TestSetup,
    sender: address,
    balance: u64,
    lock_months: u64,
): Batch {
    setup.ts.next_tx(sender);
    let balance = mint_ns(setup, balance);
    batch::stake(balance, lock_months, &setup.clock, setup.ts.ctx());
    setup.ts.next_tx(sender);
    return setup.ts.take_from_sender<Batch>()
}

fun assert_power(
    setup: &TestSetup,
    batch: &Batch,
    expected_power: u64,
) {
    assert_eq(expected_power, batch.power(&setup.clock));
}

// === helpers for sui modules ===

public fun mint_ns(
    setup: &mut TestSetup,
    value: u64,
): Coin<NS> {
    return coin::mint_for_testing<NS>(value, setup.ts.ctx())
}

// === tests ===

#[test]
fun test_power_ok() {
    let mut setup = setup();

    let balance = 1000;

    // locking

    // 0 months
    let batch = setup.stake_and_take(USER_1, balance, 0);
    setup.assert_power(&batch, balance); // no increase in power
    destroy(batch);

    // 1 month
    let batch = setup.stake_and_take(USER_1, balance, 1);
    setup.assert_power(&batch, 1100);
    setup.clock.increment_for_testing(2 * month_ms!());
    setup.assert_power(&batch, 1210);
    setup.clock.increment_for_testing(1 * month_ms!());
    setup.assert_power(&batch, 1331);
    setup.clock.increment_for_testing(24 * month_ms!());
    setup.assert_power(&batch, 2850); // same as 11 months
    destroy(batch);

    // 11 months
    let batch = setup.stake_and_take(USER_1, balance, 11);
    setup.assert_power(&batch, 2850);
    destroy(batch);

    // 12 months
    let batch = setup.stake_and_take(USER_1, balance, 12);
    setup.assert_power(&batch, 3000); // 3.0x (0.15x bonus)
    destroy(batch);

    // staking

    // 0 months
    let batch = setup.stake_and_take(USER_1, balance, 0);
    setup.assert_power(&batch, balance); // no increase in power
    setup.clock.increment_for_testing(1 * month_ms!() - 1); // just under 1 month
    setup.assert_power(&batch, balance); // no increase in power
    setup.clock.increment_for_testing(1); // exactly 1 month
    setup.assert_power(&batch, 1100); // 1.1x
    setup.clock.increment_for_testing(24 * month_ms!());
    setup.assert_power(&batch, 2850); // same as 11 months
    destroy(batch);

    destroy(setup);
}
