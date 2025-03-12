#[test_only]
module suins_voting::staking_batch_tests;

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
use suins_voting::{
    staking_batch::{Self, StakingBatch},
    staking_constants::{month_ms},
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

fun new_batch(
    setup: &mut TestSetup,
    sender: address,
    balance: u64,
    lock_months: u64,
): StakingBatch {
    setup.ts.next_tx(sender);
    let balance = mint_ns(setup, balance);
    staking_batch::new(balance, lock_months, &setup.clock, setup.ts.ctx())
}

fun assert_power(
    setup: &TestSetup,
    batch: &StakingBatch,
    expected_power: u64,
) {
    assert_eq(expected_power, batch.power(&setup.clock));
}

// === helpers for sui modules ===

fun mint_ns(
    setup: &mut TestSetup,
    value: u64,
): Coin<NS> {
    return coin::mint_for_testing<NS>(value, setup.ts.ctx())
}

fun add_time(
    setup: &mut TestSetup,
    ms: u64,
) {
    setup.clock.increment_for_testing(ms);
}

// === tests ===

#[test]
fun test_power_ok() {
    let mut setup = setup();
    let balance = 1000;

    // == regular staking ==

    // Basic staking with no lock
    let batch = setup.new_batch(USER_1, balance, 0);
    setup.assert_power(&batch, balance); // 1.0x at start

    // Test month-by-month progression
    let mut expected_power = balance;
    let mut i = 0;
    while (i < 11) {
        setup.add_time(month_ms!()); // (i+1) months after start
        expected_power = expected_power * 110 / 100;
        setup.assert_power(&batch, expected_power); // increases by 10% each month
        i = i + 1;
    };

    // Test cap at month 12 and beyond
    setup.add_time(month_ms!()); // 12 months after start
    setup.assert_power(&batch, 2850); // 2.85x (capped)
    setup.add_time(3 * month_ms!()); // 15 months after start
    setup.assert_power(&batch, 2850); // 2.85x (still capped)
    destroy(batch);

    // Test partial month handling
    let batch = setup.new_batch(USER_1, balance, 0);
    setup.add_time(month_ms!() - 1); // just before 1 month
    setup.assert_power(&batch, balance); // 1.0x (no change)
    setup.add_time(1); // exactly 1 month
    setup.assert_power(&batch, 1100); // 1.1x (first month boost)
    destroy(batch);

    // == locking ===

    // Test 1-month lock
    let batch = setup.new_batch(USER_1, balance, 1);
    setup.assert_power(&batch, 1100); // 1.1x from lock
    destroy(batch);

    // Test 11-month lock (maximum regular multiplier)
    let batch = setup.new_batch(USER_1, balance, 11);
    setup.assert_power(&batch, 2850); // 2.85x (1.1^11)
    destroy(batch);

    // Test 12-month lock (special bonus case)
    let batch = setup.new_batch(USER_1, balance, 12);
    setup.assert_power(&batch, 3000); // 3.0x (special bonus)
    destroy(batch);

    // == transition from locked to staked ===

    // Test 3-month lock transitioning to staked
    let batch = setup.new_batch(USER_1, balance, 3);
    setup.assert_power(&batch, 1331); // 1.331x (1.1^3 from lock)

    // Test boundary at unlock time
    setup.add_time(3 * month_ms!() - 1); // just before 3-month lock ends
    setup.assert_power(&batch, 1331); // 1.331x (no change)
    setup.add_time(1); // exactly when 3-month lock ends
    setup.assert_power(&batch, 1331); // 1.331x (no change at unlock)

    // Test additional staking time after unlock
    setup.add_time(1 * month_ms!()); // 1 month after unlock
    setup.assert_power(&batch, 1464); // 1.464x (1.331x * 1.1)
    setup.add_time(2 * month_ms!()); // 3 months after unlock
    setup.assert_power(&batch, 1771); // 1.771x (1.464x * 1.1^2)

    // Test cap after many months of staking
    setup.add_time(20 * month_ms!()); // 23 months after unlock
    setup.assert_power(&batch, 2850); // 2.85x (capped)
    destroy(batch);

    // Test partial months after lock period
    let batch = setup.new_batch(USER_1, balance, 2);
    setup.assert_power(&batch, 1210); // 1.21x (1.1^2 from lock)
    setup.add_time(2 * month_ms!()); // exactly when lock ends
    setup.add_time(month_ms!() / 2); // half a month after unlock
    setup.assert_power(&batch, 1210); // 1.21x (no change)
    setup.add_time(month_ms!() / 2); // 1 month after unlock
    setup.assert_power(&batch, 1331); // 1.331x (1.21x * 1.1)
    destroy(batch);

    // == edge cases ===

    // Test 6-month lock + 6 months staking (reaching cap)
    let batch = setup.new_batch(USER_1, balance, 6);
    setup.assert_power(&batch, 1771); // 1.771x (1.1^6 from lock)
    setup.add_time(6 * month_ms!()); // exactly when lock ends
    setup.add_time(5 * month_ms!()); // 5 months after unlock
    setup.assert_power(&batch, 2850); // 2.85x (1.771x * 1.1^5, capped)
    destroy(batch);

    // Test 12-month lock with additional staking time
    let batch = setup.new_batch(USER_1, balance, 12);
    setup.assert_power(&batch, 3000); // 3.0x (special bonus)
    setup.add_time(12 * month_ms!()); // exactly when lock ends
    setup.assert_power(&batch, 3000); // 3.0x (no change)
    setup.add_time(12 * month_ms!()); // 12 months after unlock
    setup.assert_power(&batch, 3000); // 3.0x (no change)
    destroy(batch);

    destroy(setup);
}
