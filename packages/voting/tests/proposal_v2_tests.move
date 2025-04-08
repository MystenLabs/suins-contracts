module suins_voting::proposal_v2_tests;

// === imports ===

use sui::{
    clock::{Self},
    coin::{Self, Coin},
    test_utils::{assert_eq, destroy},
    vec_set::{Self},
};
use suins_token::{
    ns::NS,
};
use suins_voting::{
    constants::{min_voting_period_ms, max_voting_period_ms},
    proposal_v2::{Self, max_returns_per_tx},
    voting_option::{Self, threshold_not_reached, tie_rejected},
    staking_constants::{day_ms},
    test_utils::{setup, random_addr, assert_owns_ns, proposal__new_with_end_time, reward_amount},
};

// === constants ===

const USER_1: address = @0xee1;
const USER_2: address = @0xee2;
const USER_3: address = @0xee3;

// === tests ===

#[test]
fun test_end_to_end_ok() {
    let mut setup = setup();

    // admin creates and configures proposal
    let mut options = voting_option::default_options();
    options.insert(voting_option::new(b"Option A".to_string()));
    options.insert(voting_option::new(b"Option B".to_string()));
    let voting_period_ms = 7 * day_ms!();
    let mut proposal = setup.proposal__new(
        options,
        1_000_000, // 1 NS
        voting_period_ms,
    );

    // user_1 votes with two batches
    setup.next_tx(USER_1);
    let mut batch1 = setup.batch__new(250_000_000, 3); // 250 NS, locked for 3 months
    let mut batch2 = setup.batch__new(500_000_000, 3); // 500 NS, locked for 3 months
    let batch1_power = batch1.power(setup.config(), setup.clock());
    let batch2_power = batch2.power(setup.config(), setup.clock());
    setup.proposal__vote(
        &mut proposal,
        &mut batch1,
        b"Yes".to_string(),
    );
    setup.proposal__vote(
        &mut proposal,
        &mut batch2,
        b"Yes".to_string(),
    );
    setup.batch__keep(batch1);
    setup.batch__keep(batch2);

    // user_2 votes with one batch
    setup.next_tx(USER_2);
    let mut batch3 = setup.batch__new(250_000_000, 3); // 250 NS, locked for 3 months
    let batch3_power = batch3.power(setup.config(), setup.clock());
    setup.proposal__vote(
        &mut proposal,
        &mut batch3,
        b"Option A".to_string(),
    );
    setup.batch__keep(batch3);
    // verify voting results
    let expected_total_power = batch1_power + batch2_power + batch3_power;
    assert_eq(proposal.total_power(), expected_total_power);
    assert_eq(*proposal.votes().get(&voting_option::new(b"Yes".to_string())), batch1_power + batch2_power);
    assert_eq(*proposal.votes().get(&voting_option::new(b"Option A".to_string())), batch3_power);
    assert_eq(*proposal.votes().get(&voting_option::new(b"No".to_string())), 0);
    assert_eq(*proposal.votes().get(&voting_option::new(b"Abstain".to_string())), 0);

    // finalize proposal and distribute rewards
    setup.next_tx(USER_3); // anyone can do this
    setup.add_time(voting_period_ms);
    proposal.finalize(setup.clock());
    setup.proposal__distribute_rewards(&mut proposal);
    assert_eq(*proposal.winning_option().borrow(), voting_option::new(b"Yes".to_string()));

    // user_1 received rewards
    setup.next_tx(USER_1);
    setup.assert_owns_ns(750_000);

    // user_2 received rewards
    setup.next_tx(USER_2);
    setup.assert_owns_ns(250_000);

    destroy(proposal);
    setup.destroy();
}

#[test]
fun test_threshold_not_reached_ok() {
    let mut setup = setup();

    // Create proposal with threshold
    let mut proposal = setup.proposal__new_default();
    let threshold = 1_000_000_000; // 1000 NS
    proposal.set_threshold(threshold);

    // Add some votes, but not enough to meet threshold
    setup.proposal__vote_with_new_batch_and_keep(&mut proposal, b"Yes", threshold - 1);

    // Finalize proposal
    setup.add_time(proposal.end_time_ms());
    proposal.finalize(setup.clock());

    assert_eq(*proposal.winning_option().borrow(), threshold_not_reached());

    destroy(proposal);
    setup.destroy();
}

#[test]
fun test_tied_vote_ok() {
    let mut setup = setup();
    let mut proposal = setup.proposal__new_default();

    // Two votes with equal power for different options
    setup.proposal__vote_with_new_batch_and_keep(&mut proposal, b"Yes", 1_000_000);
    setup.proposal__vote_with_new_batch_and_keep(&mut proposal, b"No", 1_000_000);

    // Time passes, finalize proposal
    setup.set_time(proposal.end_time_ms());
    proposal.finalize(setup.clock());

    assert_eq(*proposal.winning_option().borrow(), tie_rejected());

    destroy(proposal);
    setup.destroy();
}

#[test]
fun test_abstain_ok() {
    let mut setup = setup();
    let mut proposal = setup.proposal__new_default();

    // Two votes: one for Yes, one for Abstain with more power
    setup.proposal__vote_with_new_batch_and_keep(&mut proposal, b"Yes", 1_000_000);
    setup.proposal__vote_with_new_batch_and_keep(&mut proposal, b"Abstain", 2_000_000);

    // Verify total power counts
    assert_eq(proposal.total_power(), 1_000_000 + 2_000_000);

    // Time passes, finalize proposal
    setup.set_time(proposal.end_time_ms());
    proposal.finalize(setup.clock());

    // Yes should win despite having fewer votes, since Abstain is ignored for winner selection
    assert_eq(*proposal.winning_option().borrow(), voting_option::new(b"Yes".to_string()));

    destroy(proposal);
    setup.destroy();
}

#[test]
fun test_user_can_vote_same_option_multiple_times_ok() {
    let mut setup = setup();
    let mut proposal = setup.proposal__new_default();

    setup.next_tx(USER_1);
    setup.proposal__vote_with_new_batch_and_keep(&mut proposal, b"Yes", 1_000_000);
    setup.proposal__vote_with_new_batch_and_keep(&mut proposal, b"Yes", 2_000_000);

    // Check that user's voting power is accumulated correctly in user_powers
    let expected_power = 1_000_000 + 2_000_000;
    let user_powers = proposal.voters();
    assert_eq(
        *user_powers.borrow(USER_1).get(&voting_option::new(b"Yes".to_string())),
        expected_power
    );

    destroy(proposal);
    setup.destroy();
}

#[test]
fun test_proposal_with_no_rewards_ok() {
    let mut setup = setup();

    let mut proposal = setup.proposal__new(
        voting_option::default_options(),
        0, // no rewards
        min_voting_period_ms!(),
    );

    // user_1 votes
    setup.next_tx(USER_1);
    setup.proposal__vote_with_new_batch_and_keep(&mut proposal, b"Yes", 1_000_000);

    // user_2 votes
    setup.next_tx(USER_2);
    setup.proposal__vote_with_new_batch_and_keep(&mut proposal, b"Yes", 1_000_000);

    // finalize proposal
    setup.add_time(proposal.end_time_ms());
    proposal.finalize(setup.clock());

    // user_1 claims reward coin with 0 value
    setup.next_tx(USER_1);
    let reward_coin = setup.proposal__claim_reward(&mut proposal);
    assert_eq(reward_coin.value(), 0);
    reward_coin.destroy_zero();

    // distribute all remaining rewards
    setup.proposal__distribute_rewards(&mut proposal);

    // user_2 does not receive any Coin<NS>
    setup.next_tx(USER_2);
    assert_eq(setup.ts().has_most_recent_for_sender<Coin<NS>>(), false);

    destroy(proposal);
    setup.destroy();
}

#[test]
fun test_distribute_rewards_ok_and_recover_dust() {
    let mut setup = setup();
    let mut proposal = setup.proposal__new(
        voting_option::default_options(),
        1_000_000, // 1 NS reward
        min_voting_period_ms!(),
    );
    // user_1 votes with 33.33% of total power
    setup.next_tx(USER_1);
    setup.proposal__vote_with_new_batch_and_keep(&mut proposal, b"Yes", 1_000_000);
    // user_2 votes with 66.66% of total power
    setup.next_tx(USER_2);
    setup.proposal__vote_with_new_batch_and_keep(&mut proposal, b"Yes", 2_000_000);
    // user_3 finalizes proposal and distributes rewards
    setup.next_tx(USER_3);
    setup.add_time(proposal.end_time_ms());
    setup.proposal__distribute_rewards(&mut proposal);
    // user_1 receives 0.333333 NS
    setup.next_tx(USER_1);
    setup.assert_owns_ns(333_333);
    // user_2 receives 0.666666 NS
    setup.next_tx(USER_2);
    setup.assert_owns_ns(666_666);
    // user_3 receives 0.000001 NS
    setup.next_tx(USER_3);
    setup.assert_owns_ns(1);

    destroy(proposal);
    setup.destroy();
}

#[test]
fun test_distribute_rewards_ok_many_voters() {
    let mut setup = setup();
    let mut proposal = setup.proposal__new_default();

    let total_voters = max_returns_per_tx!() + 7; // 125 + 7 = 132
    let total_power = 5_000_000 * total_voters;

    total_voters.do!(|_| {
        let voter_addr = setup.random_addr();
        setup.next_tx(voter_addr);
        setup.proposal__vote_with_new_batch_and_keep(&mut proposal, b"Yes", 5_000_000);
    });
    setup.add_time(proposal.end_time_ms());

    // check state before distributing rewards
    assert_eq(proposal.total_power(), total_power);
    assert_eq(proposal.total_reward(), reward_amount!());
    assert_eq(proposal.voters().length(), total_voters);
    assert_eq(proposal.voter_powers().length(), total_voters);
    assert_eq(proposal.reward().value(), reward_amount!()); // full reward

    // first round of distributing rewards
    setup.proposal__distribute_rewards(&mut proposal);
    assert_eq(proposal.total_power(), total_power); // unchanged
    assert_eq(proposal.total_reward(), reward_amount!()); // unchanged
    assert_eq(proposal.voters().length(), total_voters); // unchanged
    assert_eq(proposal.voter_powers().length(), 7); // 132 - 125 = 7 voter have yet to receive rewards
    assert!(proposal.reward().value() > 0 && proposal.reward().value() < reward_amount!()); // partially distributed

    // second and final round of distributing rewards
    setup.proposal__distribute_rewards(&mut proposal);
    assert_eq(proposal.total_power(), total_power); // unchanged
    assert_eq(proposal.total_reward(), reward_amount!()); // unchanged
    assert_eq(proposal.voters().length(), total_voters); // unchanged
    assert_eq(proposal.voter_powers().length(), 0); // all voters received their rewards
    assert_eq(proposal.reward().value(), 0); // reward fully distributed

    // check stats
    assert_eq(setup.stats().total_balance(), total_power);
    assert_eq(setup.stats().user_rewards().length(), total_voters);

    destroy(proposal);
    setup.destroy();
}

#[test]
fun test_stats_ok() {
    let mut setup = setup();

    let mut prop1 = setup.proposal__new_default();

    // user_1 votes on prop1 with 9 NS
    setup.next_tx(USER_1);
    setup.proposal__vote_with_new_batch_and_keep(&mut prop1, b"Yes", 1_000_000);
    setup.proposal__vote_with_new_batch_and_keep(&mut prop1, b"No", 8_000_000); // bro changed his mind
    let user_1_reward_prop1 = reward_amount!() * 9 / 10;

    // user_2 votes on prop1 with 1 NS
    setup.next_tx(USER_2);
    setup.proposal__vote_with_new_batch_and_keep(&mut prop1, b"Yes", 1_000_000);
    let user_2_reward_prop1 = reward_amount!() / 10;

    // check stats before finalizing prop1
    assert_eq(setup.stats().total_balance(), 10_000_000);
    assert_eq(setup.stats().user_rewards().length(), 0);
    assert_eq(setup.stats().user_reward(USER_1), 0);
    assert_eq(setup.stats().user_reward(USER_2), 0);

    // finalize prop1 and check stats
    setup.set_time(prop1.end_time_ms());
    setup.proposal__distribute_rewards(&mut prop1);
    assert_eq(setup.stats().total_balance(), 10_000_000); // no change
    assert_eq(setup.stats().user_rewards().length(), 2);
    assert_eq(setup.stats().user_reward(USER_1), user_1_reward_prop1);
    assert_eq(setup.stats().user_reward(USER_2), user_2_reward_prop1);

    // user_1 stakes another 5 NS and votes on a second proposal with it
    let mut prop2 = setup.proposal__new_default();
    setup.next_tx(USER_1);
    setup.proposal__vote_with_new_batch_and_keep(&mut prop2, b"Yes", 5_000_000);

    // finalize prop2 and check stats
    setup.add_time(prop2.end_time_ms());
    let reward_coin = setup.proposal__claim_reward(&mut prop2);
    assert_eq(reward_coin.value(), reward_amount!()); // user_1 is the only voter, so gets all rewards
    assert_eq(setup.stats().total_balance(), 15_000_000); // increased by 5 NS
    assert_eq(setup.stats().user_rewards().length(), 2); // no change
    assert_eq(setup.stats().user_reward(USER_1), user_1_reward_prop1 + reward_amount!());

    destroy(prop1);
    destroy(prop2);
    destroy(reward_coin);
    setup.destroy();
}

// === tests: errors ===

#[test, expected_failure(abort_code = proposal_v2::EBatchIsVoting)]
fun test_vote_e_batch_is_voting() {
    let mut setup = setup();
    let mut proposal = setup.proposal__new_default();
    // user_1 votes
    setup.next_tx(USER_1);
    let mut batch = setup.batch__new(5_000_000, 0);
    setup.proposal__vote(&mut proposal, &mut batch, b"Yes".to_string());
    // user_1 tries to vote again with the same batch
    setup.proposal__vote(&mut proposal, &mut batch, b"Yes".to_string());
    abort 123
}

#[test, expected_failure(abort_code = proposal_v2::EBatchInCooldown)]
fun test_vote_e_batch_in_cooldown_requested() {
    let mut setup = setup();
    let mut proposal = setup.proposal__new_default();
    let mut batch = setup.batch__new(5_000_000, 0);
    // try to vote with a batch that's requested cooldown
    batch.request_unstake(setup.config(), setup.clock());
    setup.proposal__vote(&mut proposal, &mut batch, b"Yes".to_string());
    abort 123
}

#[test, expected_failure(abort_code = proposal_v2::EBatchInCooldown)]
fun test_vote_e_batch_in_cooldown_completed() {
    let mut setup = setup();
    let mut proposal = setup.proposal__new(
        voting_option::default_options(),
        1_000_000, // 1 NS
        max_voting_period_ms!(),
    );
    let mut batch = setup.batch__new(5_000_000, 0);
    // request batch cooldown
    batch.request_unstake(setup.config(), setup.clock());
    assert_eq(batch.is_cooldown_over(setup.clock()), false);
    // wait for cooldown to end
    setup.set_time(batch.cooldown_end_ms());
    assert_eq(batch.is_cooldown_over(setup.clock()), true);
    // try to vote with a batch that's completed cooldown
    setup.proposal__vote(&mut proposal, &mut batch, b"Yes".to_string());
    abort 123
}

#[test, expected_failure(abort_code = proposal_v2::EVoterNotFound)]
fun test_claim_reward_e_voter_not_found() {
    let mut setup = setup();
    let mut proposal = setup.proposal__new_default();
    // user_1 tries to claim reward, but is not a voter
    setup.set_time(proposal.end_time_ms());
    setup.next_tx(USER_1);
    let _reward_coin = setup.proposal__claim_reward(&mut proposal);
    abort 123
}

#[test, expected_failure(abort_code = proposal_v2::EVoterNotFound)]
fun test_claim_reward_e_voter_not_found_double_claim() {
    let mut setup = setup();
    let mut proposal = setup.proposal__new_default();
    // user_1 votes
    setup.next_tx(USER_1);
    setup.proposal__vote_with_new_batch_and_keep(&mut proposal, b"Yes", 5_000_000);
    // user_1 successfully claims reward
    setup.set_time(proposal.end_time_ms());
    setup.next_tx(USER_1);
    let reward_coin1 = setup.proposal__claim_reward(&mut proposal);
    assert_eq(reward_coin1.value(), reward_amount!());
    // user_1 tries to claim reward again
    setup.next_tx(USER_1);
    let _reward_coin2 = setup.proposal__claim_reward(&mut proposal);
    abort 123
}

// === original tests from v1 (adapted for proposal_v2) ===

#[test, expected_failure(abort_code = proposal_v2::ETooShortVotingPeriod)]
fun try_create_outside_min_range() {
    let mut setup = setup();
    let _proposal = setup.proposal__new_with_end_time(
        option::some(min_voting_period_ms!() - 1),
    );
    abort 123
}

#[test, expected_failure(abort_code = proposal_v2::ETooLongVotingPeriod)]
fun try_create_outside_max_range() {
    let mut setup = setup();
    let _proposal = setup.proposal__new_with_end_time(
        option::some(max_voting_period_ms!() + 1),
    );
    abort 123
}

#[test, expected_failure(abort_code = proposal_v2::EEndTimeNotReached)]
fun try_finalize_before_endtime() {
    let mut setup = setup();
    let mut proposal = setup.proposal__new_with_end_time(
        option::some(max_voting_period_ms!()),
    );
    setup.add_time(max_voting_period_ms!() - 1);
    proposal.finalize(setup.clock());
    abort 123
}

#[test, expected_failure(abort_code = proposal_v2::EEndTimeNotReached)]
fun try_claim_tokens_back_before_endtime() {
    let mut setup = setup();
    let mut proposal = setup.proposal__new_with_end_time(
        option::some(max_voting_period_ms!()),
    );
    setup.add_time(max_voting_period_ms!() - 1);
    setup.proposal__distribute_rewards(&mut proposal);
    abort 123
}

#[test, expected_failure(abort_code = proposal_v2::EEndTimeNotReached)]
fun try_self_finalize_before_end_time() {
    let mut setup = setup();
    let mut proposal = setup.proposal__new_with_end_time(
        option::some(max_voting_period_ms!()),
    );
    setup.add_time(max_voting_period_ms!() - 1);
    proposal.finalize(setup.clock());
    abort 123
}

#[test, expected_failure(abort_code = proposal_v2::EProposalAlreadyFinalized)]
fun try_finalize_twice() {
    let mut setup = setup();

    let mut proposal = setup.proposal__new_default();

    proposal.set_threshold(1);
    setup.add_time(min_voting_period_ms!() + 2);
    proposal.finalize(setup.clock());

    assert_eq(proposal.is_threshold_reached(), false);

    // our chance to test the non-reached threshold result too.
    assert_eq(
        proposal
            .winning_option()
            .is_some_and!(|opt| opt == threshold_not_reached()),
        true
    );

    proposal.finalize(setup.clock());

    abort 123
}

#[test, expected_failure(abort_code = proposal_v2::EVotingPeriodExpired)]
fun try_to_vote_on_expired_proposal() {
    let mut setup = setup();

    let mut proposal = setup.proposal__new_with_end_time(
        option::some(min_voting_period_ms!()),
    );
    proposal.set_threshold(1);
    setup.add_time(min_voting_period_ms!());

    let mut batch = setup.batch__new(1_000_000, 0);

    setup.proposal__vote(
        &mut proposal,
        &mut batch,
        b"Yes".to_string(),
    );

    abort 123
}

#[test, expected_failure(abort_code = proposal_v2::ENotAvailableOption)]
fun vote_non_existing_option() {
    let mut setup = setup();

    let mut proposal = setup.proposal__new_default();

    let mut batch = setup.batch__new(1_000_000, 0);

    setup.proposal__vote(
        &mut proposal,
        &mut batch,
        b"Wut".to_string(),
    );

    abort 123
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

    abort 123
}
