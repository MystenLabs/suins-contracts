#[test_only]
module suins_voting::staking_batch_tests;

// === imports ===

use sui::{
    test_utils::{assert_eq, destroy},
};
use suins_voting::{
    staking_admin::{StakingAdminCap},
    staking_batch::{Self, StakingBatch},
    staking_constants::{month_ms},
    test_utils::{setup, setup_with_default_config, admin_addr},
};

// === constants ===

const USER_1: address = @0xee1;

// === tests ===

#[test]
fun test_end_to_end_ok() {
    let mut setup = setup_with_default_config();
    let balance = setup.config().min_balance() * 1000;
    let boost = setup.config().monthly_boost_bps() as u128;
    let initial_time = setup.clock().timestamp_ms();

    // create a new batch with a 3-month lock
    setup.next_tx(USER_1);
    let batch = setup.batch__new(balance, 3);
    setup.batch__keep(batch);

    // verify initial state
    setup.next_tx(USER_1);
    let mut batch = setup.ts().take_from_sender<StakingBatch>();
    assert_eq(batch.balance(), balance);
    assert_eq(batch.start_ms(), initial_time);
    assert_eq(batch.unlock_ms(), initial_time + 3 * month_ms!());
    assert_eq(batch.cooldown_end_ms(), 0);
    assert_eq(batch.voting_until_ms(), 0);
    assert_eq(batch.is_locked(setup.clock()), true);
    assert_eq(batch.is_unlocked(setup.clock()), false);
    assert_eq(batch.is_cooldown_requested(), false);
    assert_eq(batch.is_cooldown_over(setup.clock()), false);
    assert_eq(batch.is_voting(setup.clock()), false);
    let expected_power = (balance as u128 * boost * boost * boost / 10000 / 10000 / 10000) as u64;
    assert_eq(batch.power(setup.config(), setup.clock()), expected_power);

    // extend lock to 6 months
    batch.lock(setup.config(), 6, setup.clock());
    assert_eq(batch.is_locked(setup.clock()), true);
    assert_eq(batch.unlock_ms(), initial_time + 6 * month_ms!());
    let expected_power = (balance as u128 * boost * boost * boost * boost * boost * boost / 10000 / 10000 / 10000 / 10000 / 10000 / 10000) as u64;
    assert_eq(batch.power(setup.config(), setup.clock()), expected_power);

    // wait until lock period ends
    setup.add_time(6 * month_ms!());
    assert_eq(batch.is_locked(setup.clock()), false);
    assert_eq(batch.is_unlocked(setup.clock()), true);

    // request unstake
    batch.request_unstake(setup.config(), setup.clock());
    assert_eq(batch.is_cooldown_requested(), true);
    assert_eq(batch.is_cooldown_over(setup.clock()), false);
    assert_eq(batch.cooldown_end_ms() > 0, true);

    // wait for cooldown to end
    setup.add_time(batch.cooldown_end_ms());
    assert_eq(batch.is_cooldown_requested(), true);
    assert_eq(batch.is_cooldown_over(setup.clock()), true);

    // unstake the batch
    let unstaked_balance = setup.batch__unstake(batch);
    assert_eq(unstaked_balance.value(), balance);

    destroy(unstaked_balance);
    setup.destroy();
}

#[test]
// Voting power grows according to this formula: `power_N = TRUNC(power_N-1 * 1.1)`
//
// month 0:  1_000_000
// month 1:  1_100_000
// month 2:  1_210_000
// month 3:  1_331_000
// month 4:  1_464_100
// month 5:  1_610_510
// month 6:  1_771_561
// month 7:  1_948_717
// month 8:  2_143_588
// month 9:  2_357_946
// month 10: 2_593_740
// month 11: 2_853_114
fun test_power_ok() {
    let mut setup = setup_with_default_config();
    let balance = 1_000_000; // 1 NS

    // == regular staking ==

    // test month-by-month progression
    let batch = setup.batch__new(balance, 0);
    setup.assert_power(&batch, balance); // 1.0x at start

    let mut expected_power = balance;
    let boost_bps = setup.config().monthly_boost_bps();
    let mut i = 0;
    while (i < 11) {
        setup.add_time(month_ms!()); // (i+1) months after start
        expected_power = expected_power * boost_bps / 10000;
        setup.assert_power(&batch, expected_power);
        i = i + 1;
    };
    destroy(batch);

    // test around month 12
    let batch = setup.batch__new(balance, 0);
    setup.add_time(10 * month_ms!()); // 10 months after start
    setup.assert_power(&batch, 2_593_740); // 2.59x
    setup.add_time(1 * month_ms!()); // 11 months after start (12th month)
    setup.assert_power(&batch, 2_853_114); // 2.85x (max reached)
    setup.add_time(1 * month_ms!()); // 12 months after start
    setup.assert_power(&batch, 2_853_114); // 2.85x (capped)
    setup.add_time(12 * month_ms!()); // 1 year later
    setup.assert_power(&batch, 2_853_114); // 2.85x (still capped)
    destroy(batch);

    // test month boundary
    let batch = setup.batch__new(balance, 0);
    setup.add_time(month_ms!() - 1); // just before 1 month
    setup.assert_power(&batch, balance); // 1.0x (no change)
    setup.add_time(1); // exactly 1 month
    setup.assert_power(&batch, 1_100_000); // 1.1x (first month boost)
    destroy(batch);

    // == locking ===

    // test 1-month lock
    let batch = setup.batch__new(balance, 1);
    setup.assert_power(&batch, 1_100_000); // 1.1x from lock
    destroy(batch);

    // test 11-month lock (maximum regular multiplier)
    let batch = setup.batch__new(balance, 11);
    setup.assert_power(&batch, 2_853_114);
    destroy(batch);

    // test 12-month lock (special bonus case)
    let batch = setup.batch__new(balance, 12);
    setup.assert_power(&batch, 3_000_000); // 3.0x (special bonus)
    destroy(batch);

    // == transition from locked to staked ===

    // test 3-month lock transitioning to staked
    let batch = setup.batch__new(balance, 3);
    setup.assert_power(&batch, 1_331_000);

    // test boundary at unlock time
    setup.add_time(3 * month_ms!() - 1); // just before 3-month lock ends
    setup.assert_power(&batch, 1_331_000); // (no change)
    setup.add_time(1); // exactly when 3-month lock ends
    setup.assert_power(&batch, 1_331_000); // (no change)

    // test additional staking time after unlock
    setup.add_time(1 * month_ms!()); // 1 month later
    setup.assert_power(&batch, 1_464_100);
    setup.add_time(2 * month_ms!()); // 2 months later
    setup.assert_power(&batch, 1_771_561);

    // test cap after many months of staking
    setup.add_time(12 * month_ms!()); // 1 year later
    setup.assert_power(&batch, 2_853_114); // 2.85x (capped)
    destroy(batch);

    // test partial months after lock period
    let batch = setup.batch__new(balance, 2);
    setup.assert_power(&batch, 1_210_000);
    setup.add_time(2 * month_ms!()); // exactly when lock ends
    setup.add_time(month_ms!() / 2); // half a month after unlock
    setup.assert_power(&batch, 1_210_000); // (no change)
    setup.add_time(month_ms!() / 2); // 1 month after unlock
    setup.assert_power(&batch, 1_331_000); // 1.331x
    destroy(batch);

    // == edge cases ===

    // test 6-month lock + 5 months staking (reaching cap)
    let batch = setup.batch__new(balance, 6);
    setup.assert_power(&batch, 1_771_561);
    setup.add_time(6 * month_ms!()); // exactly when lock ends
    setup.assert_power(&batch, 1_771_561); // (no change)
    setup.add_time(1 * month_ms!()); // 1 months after unlock
    setup.assert_power(&batch, 1_948_717);
    setup.add_time(4 * month_ms!()); // 5 months after unlock
    setup.assert_power(&batch, 2_853_114); // max reached
    setup.add_time(12 * month_ms!()); // 1 year later
    setup.assert_power(&batch, 2_853_114); // still capped
    destroy(batch);

    // test 12-month lock with additional staking time
    let batch = setup.batch__new(balance, 12);
    setup.assert_power(&batch, 3_000_000); // 3.0x (special bonus)
    setup.add_time(12 * month_ms!()); // exactly when lock ends
    setup.assert_power(&batch, 2_853_114); // 2.85x (no longer locked, gets max staking boost)
    setup.add_time(12 * month_ms!()); // 12 months after unlock
    setup.assert_power(&batch, 2_853_114); // 2.85x (no longer locked, gets max staking boost)
    destroy(batch);

    setup.destroy();
}

#[test]
fun test_power_max_balance() {
    let mut setup = setup_with_default_config();

    // test with total NS supply
    let total_supply = 500_000_000 * 1_000_000; // 500 million NS

    // lock for 1 month
    let mut batch = setup.batch__new(total_supply, 1);
    let boost = setup.config().monthly_boost_bps() as u128;
    let expected_power = (total_supply as u128 * boost / 10000) as u64;
    assert_eq(batch.power(setup.config(), setup.clock()), expected_power);

    // lock for max months
    let max_months = setup.config().max_lock_months();
    batch.lock(setup.config(), max_months, setup.clock());
    let max_boost = setup.config().max_boost_bps() as u128;
    let expected_power = (total_supply as u128 * max_boost / 10000) as u64;
    assert_eq(batch.power(setup.config(), setup.clock()), expected_power);

    destroy(batch);
    setup.destroy();
}

#[test]
fun test_admin_functions() {
    let mut setup = setup();

    // test admin_new
    let now = setup.clock().timestamp_ms();
    let past_time_ms = now - 1000 * 60 * 60; // 1 hour ago
    let batch = setup.batch__admin_new(
        1_000_000,
        past_time_ms,
        past_time_ms, // never locked
    );

    // test admin_transfer
    setup.next_tx(admin_addr!());
    setup.batch__admin_transfer(batch, USER_1);

    // verify USER_1 received the batch
    setup.next_tx(USER_1);
    let taken_batch = setup.ts().take_from_sender<StakingBatch>();
    assert_eq(taken_batch.balance(), 1_000_000);
    assert_eq(taken_batch.is_locked(setup.clock()), false);

    destroy(taken_batch);
    setup.destroy();
}

// === tests: admin ===

#[test]
fun test_config_changes() {
    let mut setup = setup_with_default_config();
    let min_bal = setup.config().min_balance();
    let cap = setup.ts().take_from_sender<StakingAdminCap>();

    // change monthly_boost_bps
    let batch = setup.batch__new(min_bal, 1);
    let boost_1 = setup.config().monthly_boost_bps();
    let boost_2 = boost_1 + 1000; // increase by 10%
    setup.config_mut().set_monthly_boost_bps(&cap, boost_2);
    let power_2 = batch.power(setup.config(), setup.clock());
    assert_eq(power_2, min_bal * boost_2 / 10000);
    destroy(batch);

    // increase max_boost_bps
    let max_boost_2 = 1000_00; // 10x
    setup.config_mut().set_max_boost_bps(&cap, max_boost_2);
    let max_lock_months = setup.config().max_lock_months();
    let batch = setup.batch__new(min_bal, max_lock_months);
    let expected_power = min_bal * max_boost_2 / 10000;
    assert_eq(batch.power(setup.config(), setup.clock()), expected_power);
    destroy(batch);

    // change cooldown period
    let mut batch = setup.batch__new(min_bal, 0);
    let cooldown_1 = setup.config().cooldown_ms();
    let cooldown_2 = cooldown_1 / 2;
    setup.config_mut().set_cooldown_ms(&cap, cooldown_2);
    batch.request_unstake(setup.config(), setup.clock());
    setup.add_time(cooldown_2);
    let unstaked_balance = setup.batch__unstake(batch);

    destroy(unstaked_balance);
    destroy(cap);
    setup.destroy();
}

#[test]
fun test_zero_cooldown() {
    let mut setup = setup();
    let cap = setup.ts().take_from_sender<StakingAdminCap>();
    let balance = setup.config().min_balance();

    // set cooldown to zero
    setup.config_mut().set_cooldown_ms(&cap, 0);

    // create and request unstake for a batch
    let mut batch = setup.batch__new(balance, 0);
    batch.request_unstake(setup.config(), setup.clock());

    // should be able to unstake immediately
    let unstaked_balance = setup.batch__unstake(batch);
    assert_eq(unstaked_balance.value(), balance);

    destroy(unstaked_balance);
    destroy(cap);
    setup.destroy();
}

#[test]
fun test_stats_ok() {
    let mut setup = setup();
    let min_bal = setup.config().min_balance();

    // stake 1x min bal and lock 2x min bal
    setup.next_tx(USER_1);
    let mut batch1 = setup.batch__new(min_bal, 0);
    let batch2 = setup.batch__new(min_bal * 2, 3);

    // check TVL
    assert_eq(setup.stats().total_balance(), min_bal * 3);

    // unstake batch1
    batch1.request_unstake(setup.config(), setup.clock()); // request unstake
    setup.set_time(batch1.cooldown_end_ms() + month_ms!()); // cooldown ended a while ago
    assert_eq(setup.stats().total_balance(), min_bal * 3); // but user didn't unstake yet
    let unstaked_balance = setup.batch__unstake(batch1); // actually unstake
    assert_eq(setup.stats().total_balance(), min_bal * 2); // TVL reduced

    destroy(batch2);
    destroy(unstaked_balance);
    setup.destroy();
}

// === tests: errors ===

#[test, expected_failure(abort_code = staking_batch::EBalanceTooLow)]
fun test_new_e_balance_too_low() {
    let mut setup = setup();
    // try to create a batch with balance below minimum
    let min_balance = setup.config().min_balance();
    let balance = min_balance - 1;
    let _batch = setup.batch__new(balance, 0);

    abort 123
}

#[test, expected_failure(abort_code = staking_batch::EInvalidLockPeriod)]
fun test_new_e_invalid_lock_period_above_max() {
    let mut setup = setup();
    let max_lock_months = setup.config().max_lock_months();
    let balance = setup.config().min_balance();

    // try to create a batch with lock period exceeding maximum
    let _batch = setup.batch__new(balance, max_lock_months + 1);

    abort 123
}

#[test, expected_failure(abort_code = staking_batch::EBatchIsVoting)]
fun test_lock_e_is_voting() {
    let mut setup = setup();
    let mut batch = setup.batch__new__with_min_bal(0);
    batch.set_voting_until_ms(setup.clock().timestamp_ms() + 1000, setup.clock());
    batch.lock(setup.config(), 3, setup.clock());
    abort 123
}

#[test, expected_failure(abort_code = staking_batch::ECooldownAlreadyRequested)]
fun test_lock_e_cooldown_already_requested() {
    let mut setup = setup();
    let mut batch = setup.batch__new__with_min_bal(0);
    batch.request_unstake(setup.config(), setup.clock());
    // try to lock after cooldown started
    batch.lock(setup.config(), 3, setup.clock());
    abort 123
}

#[test, expected_failure(abort_code = staking_batch::EInvalidLockPeriod)]
fun test_lock_e_invalid_lock_period_shorter_than_current() {
    let mut setup = setup();
    let mut batch = setup.batch__new__with_min_bal(6);
    // try to extend lock with a shorter period
    batch.lock(setup.config(), 3, setup.clock());
    abort 123
}

#[test, expected_failure(abort_code = staking_batch::EInvalidLockPeriod)]
fun test_lock_e_invalid_lock_period_too_long() {
    let mut setup = setup();
    // try to extend lock beyond maximum
    let max_lock_months = setup.config().max_lock_months();
    let mut batch = setup.batch__new__with_min_bal(6);
    batch.lock(setup.config(), max_lock_months + 1, setup.clock());
    abort 123
}

#[test, expected_failure(abort_code = staking_batch::EBatchIsVoting)]
fun test_request_unstake_e_is_voting() {
    let mut setup = setup();
    let mut batch = setup.batch__new__with_min_bal(0);
    batch.set_voting_until_ms(setup.clock().timestamp_ms() + 1000, setup.clock());
    batch.request_unstake(setup.config(), setup.clock());
    abort 123
}

#[test, expected_failure(abort_code = staking_batch::EBatchLocked)]
fun test_request_unstake_e_batch_locked() {
    let mut setup = setup();
    let mut batch = setup.batch__new__with_min_bal(3);
    // try to request unstake while batch is locked
    batch.request_unstake(setup.config(), setup.clock());
    abort 123
}

#[test, expected_failure(abort_code = staking_batch::ECooldownAlreadyRequested)]
fun test_request_unstake_e_already_requested() {
    let mut setup = setup();
    let mut batch = setup.batch__new__with_min_bal(0);
    batch.request_unstake(setup.config(), setup.clock());
    // try to request unstake twice
    batch.request_unstake(setup.config(), setup.clock());
    abort 123
}

#[test, expected_failure(abort_code = staking_batch::ECooldownNotRequested)]
fun test_unstake_e_not_requested() {
    let mut setup = setup();
    let batch = setup.batch__new__with_min_bal(0);
    // try to unstake without requesting first
    let _balance = setup.batch__unstake(batch);
    abort 123
}

#[test, expected_failure(abort_code = staking_batch::EBatchLocked)]
fun test_unstake_e_batch_locked() {
    let mut setup = setup();
    let batch = setup.batch__new__with_min_bal(3);
    // try to unstake a locked batch
    let _balance = setup.batch__unstake(batch);
    abort 123
}

#[test, expected_failure(abort_code = staking_batch::ECooldownNotOver)]
fun test_unstake_e_cooldown_not_over() {
    let mut setup = setup();
    let mut batch = setup.batch__new__with_min_bal(0);

    batch.request_unstake(setup.config(), setup.clock());

    // add some time but less than cooldown period
    let cooldown_ms = setup.config().cooldown_ms();
    setup.add_time(cooldown_ms - 1);

    // try to unstake before cooldown period ends
    let _balance = setup.batch__unstake(batch);

    abort 123
}

#[test, expected_failure(abort_code = staking_batch::EBatchIsVoting)]
fun test_unstake_e_batch_is_voting() {
    let mut setup = setup();
    let mut batch = setup.batch__new__with_min_bal(0);

    batch.request_unstake(setup.config(), setup.clock());

    // set voting until later than cooldown period
    let voting_end_time = batch.cooldown_end_ms() * 2;
    batch.set_voting_until_ms(voting_end_time, setup.clock());

    // wait for cooldown to end
    setup.add_time(batch.cooldown_end_ms());

    // try to unstake while batch is being used for voting
    let _balance = setup.batch__unstake(batch);

    abort 123

}

#[test, expected_failure(abort_code = staking_batch::EVotingUntilMsInPast)]
fun test_set_voting_until_ms_e_ms_in_past() {
    let mut setup = setup();
    let mut batch = setup.batch__new__with_min_bal(0);

    // try to set voting_until_ms to a time in the past
    let past_time = setup.clock().timestamp_ms() - 1000;
    batch.set_voting_until_ms(past_time, setup.clock());

    abort 123
}

#[test, expected_failure(abort_code = staking_batch::EVotingUntilMsNotExtended)]
fun test_set_voting_until_ms_e_not_extended() {
    let mut setup = setup();
    let mut batch = setup.batch__new__with_min_bal(0);

    let voting_until_ms = setup.clock().timestamp_ms() + 1000;
    batch.set_voting_until_ms(voting_until_ms, setup.clock());

    // try to set voting_until_ms to the same time
    batch.set_voting_until_ms(voting_until_ms, setup.clock());

    abort 123
}

#[test, expected_failure(abort_code = staking_batch::EInvalidLockPeriod)]
fun test_admin_new_e_invalid_lock_period() {
    let mut setup = setup();

    // try to set unlock_ms before start_ms
    let now = setup.clock().timestamp_ms();
    let _batch = setup.batch__admin_new(1_000_000, now, now - 1);

    abort 123
}
