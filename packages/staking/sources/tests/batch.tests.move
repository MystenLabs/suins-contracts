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
};

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
    let clock = clock::create_for_testing(ts.ctx());
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
    let batch = setup.stake_and_take(USER_1, 1000, 0);
    assert_eq(batch.balance().value(), 1000);
    destroy(batch);
    destroy(setup);
}
