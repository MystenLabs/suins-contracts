module suins_voting::proposal_v2_tests;

// === imports ===

use sui::{
    clock::{Self, Clock},
    coin::{Self},
    test_scenario::{Self as ts},
    test_utils::{assert_eq, destroy},
    vec_set::{Self},
};
use suins_token::{
    ns::NS,
};
use suins_voting::{
    constants::{min_voting_period_ms, max_voting_period_ms},
    proposal_v2::{Self, ProposalV2},
    voting_option::{Self, threshold_not_reached, tie_rejected},
    staking_constants::{day_ms},
    test_utils::{setup, assert_owns_ns},
};

// === constants ===

const USER_1: address = @0xee1;
const USER_2: address = @0xee2;
const USER_3: address = @0xee3;

// === tests ===

#[test]
fun test_end_to_end_ok() {
    let (mut ts, mut setup) = setup();

    // admin creates and configures proposal
    let mut options = voting_option::default_options();
    options.insert(voting_option::new(b"Option A".to_string()));
    options.insert(voting_option::new(b"Option B".to_string()));
    let voting_period_ms = 7 * day_ms!();
    let mut proposal = setup.new_proposal(
        &mut ts,
        options,
        1_000_000, // 1 NS
        voting_period_ms,
    );

    // user_1 votes with two batches
    ts::next_tx(&mut ts, USER_1);
    let mut batch1 = setup.new_batch(&mut ts, 250_000_000, 3); // 250 NS, locked for 3 months
    let mut batch2 = setup.new_batch(&mut ts, 500_000_000, 3); // 500 NS, locked for 3 months
    let batch1_power = batch1.power(setup.config(), setup.clock());
    let batch2_power = batch2.power(setup.config(), setup.clock());
    proposal.vote(
        b"Yes".to_string(),
        &mut batch1,
        setup.config(),
        setup.clock(),
        ts.ctx(),
    );
    proposal.vote(
        b"Yes".to_string(),
        &mut batch2,
        setup.config(),
        setup.clock(),
        ts.ctx(),
    );
    batch1.keep(ts.ctx(),);
    batch2.keep(ts.ctx(),);

    // user_2 votes with one batch
    ts::next_tx(&mut ts, USER_2);
    let mut batch3 = setup.new_batch(&mut ts, 250_000_000, 3); // 250 NS, locked for 3 months
    let batch3_power = batch3.power(setup.config(), setup.clock());
    proposal.vote(
        b"Option A".to_string(),
        &mut batch3,
        setup.config(),
        setup.clock(),
        ts.ctx(),
    );
    batch3.keep(ts.ctx(),);
    // verify voting results
    let expected_total_power = batch1_power + batch2_power + batch3_power;
    assert_eq(proposal.total_power(), expected_total_power);
    assert_eq(*proposal.votes().get(&voting_option::new(b"Yes".to_string())), batch1_power + batch2_power);
    assert_eq(*proposal.votes().get(&voting_option::new(b"Option A".to_string())), batch3_power);
    assert_eq(*proposal.votes().get(&voting_option::new(b"No".to_string())), 0);
    assert_eq(*proposal.votes().get(&voting_option::new(b"Abstain".to_string())), 0);

    // finalize proposal and distribute rewards
    ts::next_tx(&mut ts, USER_3); // anyone can do this
    setup.add_time(voting_period_ms);
    proposal.finalize(setup.clock());
    proposal.distribute_rewards(setup.clock(), ts.ctx(),);
    assert_eq(*proposal.winning_option().borrow(), voting_option::new(b"Yes".to_string()));

    // user_1 received rewards
    ts::next_tx(&mut ts, USER_1);
    assert_owns_ns(&ts, 750_000);

    // user_2 received rewards
    ts::next_tx(&mut ts, USER_2);
    assert_owns_ns(&ts, 250_000);

    destroy(proposal);
    setup.destroy(ts);
}

#[test]
fun test_threshold_not_reached_ok() {
    let (mut ts, mut setup) = setup();

    // Create proposal with threshold
    let mut proposal = setup.new_default_proposal(&mut ts);
    let threshold = 1_000_000_000; // 1000 NS
    proposal.set_threshold(threshold);

    // Add some votes, but not enough to meet threshold
    setup.vote_with_new_batch_and_keep(&mut ts, &mut proposal, b"Yes", threshold - 1);

    // Finalize proposal
    setup.add_time(proposal.end_time_ms());
    proposal.finalize(setup.clock());

    assert_eq(*proposal.winning_option().borrow(), threshold_not_reached());

    destroy(proposal);
    setup.destroy(ts);
}

#[test]
fun test_tied_vote_ok() {
    let (mut ts, mut setup) = setup();
    let mut proposal = setup.new_default_proposal(&mut ts);

    // Two votes with equal power for different options
    setup.vote_with_new_batch_and_keep(&mut ts, &mut proposal, b"Yes", 1_000_000);
    setup.vote_with_new_batch_and_keep(&mut ts, &mut proposal, b"No", 1_000_000);

    // Time passes, finalize proposal
    setup.set_time(proposal.end_time_ms());
    proposal.finalize(setup.clock());

    assert_eq(*proposal.winning_option().borrow(), tie_rejected());

    destroy(proposal);
    setup.destroy(ts);
}

#[test]
fun test_abstain_ok() {
    let (mut ts, mut setup) = setup();
    let mut proposal = setup.new_default_proposal(&mut ts);

    // Two votes: one for Yes, one for Abstain with more power
    setup.vote_with_new_batch_and_keep(&mut ts, &mut proposal, b"Yes", 1_000_000);
    setup.vote_with_new_batch_and_keep(&mut ts, &mut proposal, b"Abstain", 2_000_000);

    // Verify total power counts
    assert_eq(proposal.total_power(), 1_000_000 + 2_000_000);

    // Time passes, finalize proposal
    setup.set_time(proposal.end_time_ms());
    proposal.finalize(setup.clock());

    // Yes should win despite having fewer votes, since Abstain is ignored for winner selection
    assert_eq(*proposal.winning_option().borrow(), voting_option::new(b"Yes".to_string()));

    destroy(proposal);
    setup.destroy(ts);
}

#[test]
fun test_user_can_vote_same_option_multiple_times_ok() {
    let (mut ts, mut setup) = setup();
    let mut proposal = setup.new_default_proposal(&mut ts);

    ts.next_tx(USER_1);
    setup.vote_with_new_batch_and_keep(&mut ts, &mut proposal, b"Yes", 1_000_000);
    setup.vote_with_new_batch_and_keep(&mut ts, &mut proposal, b"Yes", 2_000_000);

    // Check that user's voting power is accumulated correctly in user_powers
    let expected_power = 1_000_000 + 2_000_000;
    let user_powers = proposal.voters();
    assert_eq(
        *user_powers.borrow(USER_1).get(&voting_option::new(b"Yes".to_string())),
        expected_power
    );

    destroy(proposal);
    setup.destroy(ts);
}

// === original tests from v1 (adapted for proposal_v2) ===

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
    let (mut ts, mut setup) = setup();

    let mut proposal = test_proposal(
        setup.clock(),
        option::none(),
        ts.ctx(),
    );
    proposal.set_threshold(1);
    setup.add_time(min_voting_period_ms!() + 2);

    let mut batch = setup.new_batch(&mut ts, 1_000_000, 0);

    proposal.vote(
        b"Yes".to_string(),
        &mut batch,
        setup.config(),
        setup.clock(),
        ts.ctx(),
    );

    abort 1337
}

#[test, expected_failure(abort_code = proposal_v2::ENotAvailableOption)]
fun vote_non_existing_option() {
    let (mut ts, mut setup) = setup();

    let mut proposal = test_proposal(
        setup.clock(),
        option::none(),
        ts.ctx(),
    );

    let mut batch = setup.new_batch(&mut ts, 1_000_000, 0);

    proposal.vote(
        b"Wut".to_string(),
        &mut batch,
        setup.config(),
        setup.clock(),
        ts.ctx(),
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
