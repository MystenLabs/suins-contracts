module suins_voting::proposal_v2_tests;

// === imports ===

use sui::{
    clock::{Self, Clock},
    coin::{Self, Coin},
    test_scenario::{Self as ts, Scenario},
    test_utils::{assert_eq, destroy},
    vec_set::{Self, VecSet},
};
use token::{
    ns::NS,
};
use suins_voting::{
    constants::{min_voting_period_ms, max_voting_period_ms},
    proposal_v2::{Self, ProposalV2},
    voting_option::{Self, VotingOption, threshold_not_reached, tie_rejected},
    staking_batch::{Self, StakingBatch, Reward},
    staking_config::{Self, StakingConfig},
    staking_constants::{day_ms},
};

// === constants ===

const INITIAL_TIME: u64 = 86_400_000; // January 2, 1970

const ADMIN: address = @0xaa1;
const USER_1: address = @0xee1;
const USER_2: address = @0xee2;
const USER_3: address = @0xee3;

// === setup ===

public struct TestSetup {
    ts: Scenario,
    clock: Clock,
    config: StakingConfig,
}

fun setup(): TestSetup {
    let mut ts = ts::begin(ADMIN);
    let mut clock = clock::create_for_testing(ts.ctx());
    clock.set_for_testing(INITIAL_TIME);
    staking_config::init_for_testing(ts.ctx());

    ts.next_tx(ADMIN);
    let config = ts.take_shared<StakingConfig>();
    TestSetup { ts, clock, config }
}

// === helpers for our modules ===

fun create_batch(
    setup: &mut TestSetup,
    balance: u64,
    lock_months: u64,
): StakingBatch {
    let coin = setup.mint_ns(balance);
    staking_batch::new(&setup.config, coin, lock_months, &setup.clock, setup.ts.ctx())
}

fun create_proposal(
    setup: &mut TestSetup,
    options: VecSet<VotingOption>,
    reward_amount: u64,
    voting_period_ms: u64,
): ProposalV2 {
    let reward_coin = setup.mint_ns(reward_amount);
    let end_time_ms = setup.clock.timestamp_ms() + voting_period_ms;

    proposal_v2::new(
        b"Test Title".to_string(),
        b"Test Description".to_string(),
        end_time_ms,
        options,
        reward_coin,
        &setup.clock,
        setup.ts.ctx()
    )
}

fun keep_batches(
    setup: &mut TestSetup,
    batches: vector<StakingBatch>,
) {
    batches.destroy!(|batch| {
        batch.keep(setup.ts.ctx());
    });
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
fun test_end_to_end_ok() {
    let mut setup = setup();

    // admin creates and configures proposal
    let mut options = voting_option::default_options();
    options.insert(voting_option::new(b"Option A".to_string()));
    options.insert(voting_option::new(b"Option B".to_string()));
    let voting_period_ms = 7 * day_ms!();
    let mut proposal = setup.create_proposal(
        options,
        1_000_000, // 1 NS
        voting_period_ms,
    );

    // user_1 votes with two batches
    ts::next_tx(&mut setup.ts, USER_1);
    let batch1 = setup.create_batch(250_000_000, 3); // 250 NS, locked for 3 months
    let batch2 = setup.create_batch(500_000_000, 3); // 500 NS, locked for 3 months
    let batch1_id = batch1.id();
    let batch2_id = batch2.id();
    let batch1_power = batch1.power(&setup.config, &setup.clock);
    let batch2_power = batch2.power(&setup.config, &setup.clock);
    let mut voting_batches_u1 = vector[batch1, batch2];
    proposal.vote(
        b"Yes".to_string(),
        &mut voting_batches_u1,
        &setup.config,
        &setup.clock,
        setup.ts.ctx()
    );
    setup.keep_batches(voting_batches_u1);

    // user_2 votes with one batch
    ts::next_tx(&mut setup.ts, USER_2);
    let batch3 = setup.create_batch(250_000_000, 3); // 250 NS, locked for 3 months
    let batch3_id = batch3.id();
    let batch3_power = batch3.power(&setup.config, &setup.clock);
    let mut voting_batches_u2 = vector[batch3];
    proposal.vote(
        b"Option A".to_string(),
        &mut voting_batches_u2,
        &setup.config,
        &setup.clock,
        setup.ts.ctx()
    );
    setup.keep_batches(voting_batches_u2);

    // verify voting results
    let expected_total_power = batch1_power + batch2_power + batch3_power;
    assert_eq(proposal.total_power(), expected_total_power);
    assert_eq(*proposal.option_powers().get(&voting_option::new(b"Yes".to_string())), batch1_power + batch2_power);
    assert_eq(*proposal.option_powers().get(&voting_option::new(b"Option A".to_string())), batch3_power);
    assert_eq(*proposal.option_powers().get(&voting_option::new(b"No".to_string())), 0);
    assert_eq(*proposal.option_powers().get(&voting_option::new(b"Abstain".to_string())), 0);

    // finalize proposal and distribute rewards
    ts::next_tx(&mut setup.ts, USER_3); // anyone can do this
    setup.add_time(voting_period_ms);
    proposal.finalize(&setup.clock, setup.ts.ctx());
    proposal.distribute_rewards(&setup.clock, setup.ts.ctx());
    assert_eq(*proposal.winning_option().borrow(), voting_option::new(b"Yes".to_string()));

    // user_1 collects rewards
    ts::next_tx(&mut setup.ts, USER_1);

    let mut batch1 = setup.ts.take_from_sender_by_id<StakingBatch>(batch1_id);
    let ticket = ts::most_recent_receiving_ticket<Reward>(&batch1_id);
    batch1.receive_reward(ticket);
    assert_eq(batch1.rewards(), 250_000);
    assert_eq(batch1.balance(), 250_000_000 + 250_000);
    setup.ts.return_to_sender(batch1);

    let mut batch2 = setup.ts.take_from_sender_by_id<StakingBatch>(batch2_id);
    let ticket = ts::most_recent_receiving_ticket<Reward>(&batch2_id);
    batch2.receive_reward(ticket);
    assert_eq(batch2.rewards(), 500_000);
    assert_eq(batch2.balance(), 500_000_000 + 500_000);
    setup.ts.return_to_sender(batch2);

    // user_2 collects rewards
    ts::next_tx(&mut setup.ts, USER_2);
    let mut batch3 = setup.ts.take_from_sender_by_id<StakingBatch>(batch3_id);
    let ticket = ts::most_recent_receiving_ticket<Reward>(&batch3_id);
    batch3.receive_reward(ticket);
    assert_eq(batch3.rewards(), 250_000);
    assert_eq(batch3.balance(), 250_000_000 + 250_000);
    setup.ts.return_to_sender(batch3);

    destroy(proposal);
    destroy(setup);
}

#[test]
fun test_threshold_not_reached_ok() {
    let mut setup = setup();

    // Create proposal with threshold
    let threshold = 1_000_000; // 1 NS
    let voting_period_ms = day_ms!() * 7;
    let mut proposal = setup.create_proposal(
        voting_option::default_options(),
        0, // no rewards
        voting_period_ms,
    );
    proposal.set_threshold(threshold);

    // Add some votes, but not enough to meet threshold
    ts::next_tx(&mut setup.ts, USER_1);
    let batch = setup.create_batch(threshold - 1, 0);
    let mut batches = vector[batch];
    proposal.vote(b"Yes".to_string(), &mut batches, &setup.config, &setup.clock, setup.ts.ctx());
    setup.keep_batches(batches);

    // Finalize proposal
    setup.add_time(voting_period_ms);
    proposal.finalize(&setup.clock, setup.ts.ctx());

    assert_eq(*proposal.winning_option().borrow(), threshold_not_reached());

    destroy(proposal);
    destroy(setup);
}

#[test]
fun test_tied_vote_ok() {
    let mut setup = setup();

    // Create proposal
    let voting_period_ms = day_ms!() * 7;
    let mut proposal = setup.create_proposal(
        voting_option::default_options(),
        0, // no rewards
        voting_period_ms,
    );

    // Two users vote with equal power for different options
    ts::next_tx(&mut setup.ts, USER_1);
    let batch1 = setup.create_batch(1_000_000, 0);
    let mut batches1 = vector[batch1];
    proposal.vote(b"Yes".to_string(), &mut batches1, &setup.config, &setup.clock, setup.ts.ctx());
    setup.keep_batches(batches1);

    ts::next_tx(&mut setup.ts, USER_2);
    let batch2 = setup.create_batch(1_000_000, 0);
    let mut batches2 = vector[batch2];
    proposal.vote(b"No".to_string(), &mut batches2, &setup.config, &setup.clock, setup.ts.ctx());
    setup.keep_batches(batches2);

    // Time passes, finalize proposal
    setup.add_time(voting_period_ms);
    proposal.finalize(&setup.clock, setup.ts.ctx());

    assert_eq(*proposal.winning_option().borrow(), tie_rejected());

    destroy(proposal);
    destroy(setup);
}

#[test]
fun test_abstain_ok() {
    let mut setup = setup();

    // Create proposal
    let voting_period_ms = day_ms!() * 7;
    let mut proposal = setup.create_proposal(
        voting_option::default_options(),
        0, // no rewards
        voting_period_ms,
    );

    // Two users vote: one for Yes, one for Abstain with more power
    ts::next_tx(&mut setup.ts, USER_1);
    let batch1_balance = 1_000_000;
    let batch1 = setup.create_batch(batch1_balance, 0);
    let mut batches1 = vector[batch1];
    proposal.vote(b"Yes".to_string(), &mut batches1, &setup.config, &setup.clock, setup.ts.ctx());
    setup.keep_batches(batches1);

    ts::next_tx(&mut setup.ts, USER_2);
    let batch2_balance = 2_000_000;
    let batch2 = setup.create_batch(batch2_balance, 0);
    let mut batches2 = vector[batch2];
    proposal.vote(b"Abstain".to_string(), &mut batches2, &setup.config, &setup.clock, setup.ts.ctx());
    setup.keep_batches(batches2);

    // Verify total power counts
    assert_eq(proposal.total_power(), batch1_balance + batch2_balance);

    // Time passes, finalize proposal
    setup.add_time(voting_period_ms);
    proposal.finalize(&setup.clock, setup.ts.ctx());

    // Yes should win despite having fewer votes, since Abstain is ignored for winner selection
    assert_eq(*proposal.winning_option().borrow(), voting_option::new(b"Yes".to_string()));

    destroy(proposal);
    destroy(setup);
}

#[test]
fun test_user_can_vote_multiple_times_ok() {
    let mut setup = setup();

    // Create proposal
    let mut options = voting_option::default_options();
    options.insert(voting_option::new(b"Option A".to_string()));
    let mut proposal = setup.create_proposal(options, 1_000_000, day_ms!() * 7);

    // User votes in two separate transactions
    ts::next_tx(&mut setup.ts, USER_1);
    let batch1 = setup.create_batch(1_000_000, 0);
    let batch1_power = batch1.power(&setup.config, &setup.clock);
    let mut batches1 = vector[batch1];
    proposal.vote(b"Yes".to_string(), &mut batches1, &setup.config, &setup.clock, setup.ts.ctx());
    setup.keep_batches(batches1);

    ts::next_tx(&mut setup.ts, USER_1);
    let batch2 = setup.create_batch(2_000_000, 0);
    let batch2_power = batch2.power(&setup.config, &setup.clock);
    let mut batches2 = vector[batch2];
    proposal.vote(b"Yes".to_string(), &mut batches2, &setup.config, &setup.clock, setup.ts.ctx());
    setup.keep_batches(batches2);

    // Check that user's voting power is accumulated correctly in user_powers
    let expected_power = batch1_power + batch2_power;
    let user_powers = proposal.user_powers();
    assert_eq(
        *user_powers.borrow(USER_1).get(&voting_option::new(b"Yes".to_string())),
        expected_power
    );

    destroy(proposal);
    destroy(setup);
}

// === original tests from v1 ===

#[test, expected_failure(abort_code = proposal_v2::ETooShortVotingPeriod)]
fun try_create_outside_min_range() {
    let mut ctx = tx_context::dummy();
    let clock = clock::create_for_testing(&mut ctx);

    let mut _proposal = test_proposal(
        &clock,
        option::some(min_voting_period_ms!() - 1),
        &mut ctx,
    );

    abort 1337
}

#[test, expected_failure(abort_code = proposal_v2::ETooLongVotingPeriod)]
fun try_create_outside_max_range() {
    let mut ctx = tx_context::dummy();
    let clock = clock::create_for_testing(&mut ctx);

    let mut _proposal = test_proposal(
        &clock,
        option::some(max_voting_period_ms!() + 1),
        &mut ctx,
    );

    abort 1337
}

#[test, expected_failure(abort_code = proposal_v2::EEndTimeNotReached)]
fun try_finalize_before_endtime() {
    let mut ctx = tx_context::dummy();
    let clock = clock::create_for_testing(&mut ctx);

    let mut proposal = test_proposal(
        &clock,
        option::none(),
        &mut ctx,
    );
    proposal.finalize(&clock, &mut ctx);
    abort 1337
}

#[test, expected_failure(abort_code = proposal_v2::EEndTimeNotReached)]
fun try_claim_tokens_back_before_endtime() {
    let mut ctx = tx_context::dummy();
    let clock = clock::create_for_testing(&mut ctx);

    let mut proposal = test_proposal(
        &clock,
        option::none(),
        &mut ctx,
    );
    proposal.distribute_rewards(
        &clock,
        &mut ctx,
    );
    abort 1337
}

#[test, expected_failure(abort_code = proposal_v2::EEndTimeNotReached)]
fun try_self_finalize_before_end_time() {
    let mut ctx = tx_context::dummy();
    let clock = clock::create_for_testing(&mut ctx);

    let mut proposal = test_proposal(
        &clock,
        option::none(),
        &mut ctx,
    );
    proposal.finalize(&clock, &mut ctx);
    abort 1337
}

#[test, expected_failure(abort_code = proposal_v2::EProposalAlreadyFinalized)]
fun try_finalize_twice() {
    let mut ctx = tx_context::dummy();
    let mut clock = clock::create_for_testing(&mut ctx);

    let mut proposal = test_proposal(
        &clock,
        option::none(),
        &mut ctx,
    );
    proposal.set_threshold(1);
    clock.increment_for_testing(min_voting_period_ms!() + 2);
    proposal.finalize(&clock, &mut ctx);

    assert_eq(proposal.is_threshold_reached(), false);

    // our chance to test the non-reached threshold result too.
    assert_eq(
        proposal
            .winning_option()
            .is_some_and!(|opt| opt == threshold_not_reached()),
        true
    );

    proposal.finalize(&clock, &mut ctx);

    abort 1337
}

#[test, expected_failure(abort_code = proposal_v2::EVotingPeriodExpired)]
fun try_to_vote_on_expired_proposal() {
    let mut ctx = tx_context::dummy();
    let mut clock = clock::create_for_testing(&mut ctx);

    let mut proposal = test_proposal(
        &clock,
        option::none(),
        &mut ctx,
    );
    proposal.set_threshold(1);
    clock.increment_for_testing(min_voting_period_ms!() + 2);

    let staking_config = staking_config::new_for_testing_default(&mut ctx);
    let batch = staking_batch::new_for_testing(
        1000, // balance
        0, // rewards
        0, // start_ms
        0, // unlock_ms
        0, // cooldown_end_ms
        0, // voting_until_ms
        &mut ctx,
    );
    proposal.vote(
        b"Yes".to_string(),
        &mut vector[batch],
        &staking_config,
        &clock,
        &mut ctx,
    );

    abort 1337
}

#[test, expected_failure(abort_code = proposal_v2::ENotAvailableOption)]
fun vote_non_existing_option() {
    let mut ctx = tx_context::dummy();
    let clock = clock::create_for_testing(&mut ctx);

    let mut proposal = test_proposal(
        &clock,
        option::none(),
        &mut ctx,
    );

    let staking_config = staking_config::new_for_testing_default(&mut ctx);
    let batch = staking_batch::new_for_testing(
        1000, // balance
        0, // rewards
        0, // start_ms
        0, // unlock_ms
        0, // cooldown_end_ms
        0, // voting_until_ms
        &mut ctx,
    );
    proposal.vote(
        b"Wut".to_string(),
        &mut vector[batch],
        &staking_config,
        &clock,
        &mut ctx,
    );

    abort 1337
}

#[test, expected_failure(abort_code = proposal_v2::ENotEnoughOptions)]
fun create_proposal_without_enough_options() {
    let mut ctx = tx_context::dummy();
    let clock = clock::create_for_testing(&mut ctx);

    let _proposal = proposal_v2::new(
        b"".to_string(),
        b"".to_string(),
        clock.timestamp_ms() + min_voting_period_ms!() + 1,
        vec_set::empty(),
        coin::mint_for_testing<NS>(0, &mut ctx),
        &clock,
        &mut ctx,
    );

    abort 1337
}

public fun test_proposal(
    clock: &Clock,
    end_time_ms: Option<u64>,
    ctx: &mut TxContext,
): ProposalV2 {
    let options = voting_option::default_options();
    let title = b"Test Proposal".to_string();
    let description = b"Test Proposal Description".to_string();

    proposal_v2::new(
        title,
        description,
        end_time_ms.destroy_or!(
            clock.timestamp_ms() + min_voting_period_ms!() + 1,
        ),
        options,
        coin::mint_for_testing<NS>(0, ctx),
        clock,
        ctx,
    )
}
