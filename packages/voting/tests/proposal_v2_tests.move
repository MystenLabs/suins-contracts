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
    staking_batch::{Self, StakingBatch},
    staking_config::{Self, StakingConfig},
    staking_constants::{day_ms},
};

// === constants ===

const INITIAL_TIME: u64 = 86_400_000; // January 2, 1970
const VOTING_PERIOD_MS: u64 = 1000 * 60 * 60 * 24 * 7; // 7 days

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

fun create_default_proposal(
    setup: &mut TestSetup,
): ProposalV2 {
    create_proposal(setup, voting_option::default_options(), 0, VOTING_PERIOD_MS)
}

fun vote_with_new_batch_and_keep(
    setup: &mut TestSetup,
    proposal: &mut ProposalV2,
    option: vector<u8>,
    balance: u64,
) {
    let mut batch = setup.create_batch(balance, 0);
    proposal.vote(
        option.to_string(),
        &mut batch,
        &setup.config,
        &setup.clock,
        setup.ts.ctx(),
    );
    batch.keep(setup.ts.ctx());
}

// === helpers for sui modules ===

fun mint_ns(
    setup: &mut TestSetup,
    value: u64,
): Coin<NS> {
    return coin::mint_for_testing<NS>(value, setup.ts.ctx())
}

fun assert_owns_ns(
    setup: &TestSetup,
    expected_amount: u64,
) {
    let last_coin = setup.ts.take_from_sender<Coin<NS>>();
    assert_eq(last_coin.value(), expected_amount);
    setup.ts.return_to_sender(last_coin);
}

fun add_time(
    setup: &mut TestSetup,
    ms: u64,
) {
    setup.clock.increment_for_testing(ms);
}

fun set_time(
    setup: &mut TestSetup,
    ms: u64,
) {
    setup.clock.set_for_testing(ms);
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
    let mut batch1 = setup.create_batch(250_000_000, 3); // 250 NS, locked for 3 months
    let mut batch2 = setup.create_batch(500_000_000, 3); // 500 NS, locked for 3 months
    let batch1_power = batch1.power(&setup.config, &setup.clock);
    let batch2_power = batch2.power(&setup.config, &setup.clock);
    proposal.vote(
        b"Yes".to_string(),
        &mut batch1,
        &setup.config,
        &setup.clock,
        setup.ts.ctx()
    );
    proposal.vote(
        b"Yes".to_string(),
        &mut batch2,
        &setup.config,
        &setup.clock,
        setup.ts.ctx()
    );
    batch1.keep(setup.ts.ctx());
    batch2.keep(setup.ts.ctx());

    // user_2 votes with one batch
    ts::next_tx(&mut setup.ts, USER_2);
    let mut batch3 = setup.create_batch(250_000_000, 3); // 250 NS, locked for 3 months
    let batch3_power = batch3.power(&setup.config, &setup.clock);
    proposal.vote(
        b"Option A".to_string(),
        &mut batch3,
        &setup.config,
        &setup.clock,
        setup.ts.ctx()
    );
    batch3.keep(setup.ts.ctx());
    // verify voting results
    let expected_total_power = batch1_power + batch2_power + batch3_power;
    assert_eq(proposal.total_power(), expected_total_power);
    assert_eq(*proposal.votes().get(&voting_option::new(b"Yes".to_string())), batch1_power + batch2_power);
    assert_eq(*proposal.votes().get(&voting_option::new(b"Option A".to_string())), batch3_power);
    assert_eq(*proposal.votes().get(&voting_option::new(b"No".to_string())), 0);
    assert_eq(*proposal.votes().get(&voting_option::new(b"Abstain".to_string())), 0);

    // finalize proposal and distribute rewards
    ts::next_tx(&mut setup.ts, USER_3); // anyone can do this
    setup.add_time(voting_period_ms);
    proposal.finalize(&setup.clock);
    proposal.distribute_rewards(&setup.clock, setup.ts.ctx());
    assert_eq(*proposal.winning_option().borrow(), voting_option::new(b"Yes".to_string()));

    // user_1 received rewards
    ts::next_tx(&mut setup.ts, USER_1);
    setup.assert_owns_ns(750_000);

    // user_2 received rewards
    ts::next_tx(&mut setup.ts, USER_2);
    setup.assert_owns_ns(250_000);

    destroy(proposal);
    destroy(setup);
}

#[test]
fun test_threshold_not_reached_ok() {
    let mut setup = setup();

    // Create proposal with threshold
    let mut proposal = create_default_proposal(&mut setup);
    let threshold = 1_000_000_000; // 1000 NS
    proposal.set_threshold(threshold);

    // Add some votes, but not enough to meet threshold
    ts::next_tx(&mut setup.ts, USER_1);
    setup.vote_with_new_batch_and_keep(&mut proposal, b"Yes", threshold - 1);

    // Finalize proposal
    setup.add_time(proposal.end_time_ms());
    proposal.finalize(&setup.clock);

    assert_eq(*proposal.winning_option().borrow(), threshold_not_reached());

    destroy(proposal);
    destroy(setup);
}

#[test]
fun test_tied_vote_ok() {
    let mut setup = setup();
    let mut proposal = create_default_proposal(&mut setup);

    // Two users vote with equal power for different options
    ts::next_tx(&mut setup.ts, USER_1);
    setup.vote_with_new_batch_and_keep(&mut proposal, b"Yes", 1_000_000);

    ts::next_tx(&mut setup.ts, USER_2);
    setup.vote_with_new_batch_and_keep(&mut proposal, b"No", 1_000_000);

    // Time passes, finalize proposal
    setup.set_time(proposal.end_time_ms());
    proposal.finalize(&setup.clock);

    assert_eq(*proposal.winning_option().borrow(), tie_rejected());

    destroy(proposal);
    destroy(setup);
}

#[test]
fun test_abstain_ok() {
    let mut setup = setup();
    let mut proposal = create_default_proposal(&mut setup);

    // Two users vote: one for Yes, one for Abstain with more power
    ts::next_tx(&mut setup.ts, USER_1);
    setup.vote_with_new_batch_and_keep(&mut proposal, b"Yes", 1_000_000);

    ts::next_tx(&mut setup.ts, USER_2);
    setup.vote_with_new_batch_and_keep(&mut proposal, b"Abstain", 2_000_000);

    // Verify total power counts
    assert_eq(proposal.total_power(), 1_000_000 + 2_000_000);

    // Time passes, finalize proposal
    setup.set_time(proposal.end_time_ms());
    proposal.finalize(&setup.clock);

    // Yes should win despite having fewer votes, since Abstain is ignored for winner selection
    assert_eq(*proposal.winning_option().borrow(), voting_option::new(b"Yes".to_string()));

    destroy(proposal);
    destroy(setup);
}

#[test]
fun test_user_can_vote_multiple_times_ok() {
    let mut setup = setup();
    let mut proposal = create_default_proposal(&mut setup);

    // User votes in two separate transactions
    ts::next_tx(&mut setup.ts, USER_1);
    setup.vote_with_new_batch_and_keep(&mut proposal, b"Yes", 1_000_000);

    ts::next_tx(&mut setup.ts, USER_1);
    setup.vote_with_new_batch_and_keep(&mut proposal, b"Yes", 2_000_000);

    // Check that user's voting power is accumulated correctly in user_powers
    let expected_power = 1_000_000 + 2_000_000;
    let user_powers = proposal.voters();
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
    proposal.finalize(&clock);
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
    proposal.finalize(&clock);
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
    proposal.finalize(&clock);

    assert_eq(proposal.is_threshold_reached(), false);

    // our chance to test the non-reached threshold result too.
    assert_eq(
        proposal
            .winning_option()
            .is_some_and!(|opt| opt == threshold_not_reached()),
        true
    );

    proposal.finalize(&clock);

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
    let mut batch = staking_batch::new_for_testing(
        1000, // balance
        0, // start_ms
        0, // unlock_ms
        0, // cooldown_end_ms
        0, // voting_until_ms
        &mut ctx,
    );
    proposal.vote(
        b"Yes".to_string(),
        &mut batch,
        &staking_config,
        &clock,
        &ctx,
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
    let mut batch = staking_batch::new_for_testing(
        1000, // balance
        0, // start_ms
        0, // unlock_ms
        0, // cooldown_end_ms
        0, // voting_until_ms
        &mut ctx,
    );
    proposal.vote(
        b"Wut".to_string(),
        &mut batch,
        &staking_config,
        &clock,
        &ctx,
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
    let reward = coin::mint_for_testing<NS>(1_000_000, ctx); // 1 NS

    proposal_v2::new(
        title,
        description,
        end_time_ms.destroy_or!(
            clock.timestamp_ms() + min_voting_period_ms!() + 1,
        ),
        options,
        reward,
        clock,
        ctx,
    )
}
