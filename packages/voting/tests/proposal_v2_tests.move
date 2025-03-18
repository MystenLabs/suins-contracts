module suins_voting::proposal_v2_tests;

use sui::{
    clock::{Self, Clock},
    coin::{Self},
    test_scenario::{Self as ts},
    test_utils::{assert_eq, destroy},
    vec_set::{Self},
};
use token::{
    ns::NS,
};
use suins_voting::{
    constants::{min_voting_period_ms, max_voting_period_ms},
    proposal_v2::{Self, ProposalV2},
    voting_option::{Self, threshold_not_reached},
    staking_batch::{Self, StakingBatch, Reward},
    staking_config::{Self},
};

#[test]
fun test_reward() {
    let admin: address = @0xAAA;
    let user1: address = @0xBBB;

    // user creates batch
    let mut ts = ts::begin(user1);
    let clock = clock::create_for_testing(ts.ctx());
    let batch = staking_batch::new_for_testing(
        1000, // balance
        0, // start_ms
        0, // unlock_ms
        0, // cooldown_end_ms
        0, // voting_until_ms
        0, // origin
        ts.ctx()
    );
    let batch_address = batch.id().to_address();

    assert_eq(batch.balance(), 1000);
    batch.keep(ts.ctx());

    // admin creates proposal and sends reward to batch
    ts.next_tx(admin);
    let mut proposal = proposal_v2::new(
        b"The title".to_string(),
        b"The description".to_string(),
        clock.timestamp_ms() + min_voting_period_ms!() + 1,
        voting_option::default_options(),
        coin::mint_for_testing<NS>(5000, ts.ctx()),
        &clock,
        ts.ctx(),
    );
    proposal.demo_send_reward(batch_address, 100, ts.ctx());

    // user collects reward
    ts.next_tx(user1);
    let mut batch = ts.take_from_sender<StakingBatch>();
    let receiving_ticket = ts::most_recent_receiving_ticket<Reward>(&batch.id());
    batch.receive_reward(receiving_ticket);
    assert_eq(batch.balance(), 1100);

    destroy(ts);
    destroy(clock);
    destroy(proposal);
    destroy(batch);
}

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

    assert!(!proposal.is_threshold_reached());

    // our chance to test the non-reached threshold result too.
    assert!(
        proposal
            .winning_option()
            .is_some_and!(|opt| opt == threshold_not_reached()),
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
