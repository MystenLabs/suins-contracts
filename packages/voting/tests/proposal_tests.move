// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module suins_voting::proposal_tests;

use sui::{clock::{Self, Clock}, coin, vec_set};
use suins_voting::{
    constants::{min_voting_period_ms, max_voting_period_ms},
    proposal::{Self, Proposal},
    voting_option::{Self, threshold_not_reached}
};
use suins_token::ns::NS;

#[test, expected_failure(abort_code = ::suins_voting::proposal::ETooShortVotingPeriod)]
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

#[test, expected_failure(abort_code = ::suins_voting::proposal::ETooLongVotingPeriod)]
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

#[test, expected_failure(abort_code = ::suins_voting::proposal::EEndTimeNotReached)]
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

#[test, expected_failure(abort_code = ::suins_voting::proposal::EEndTimeNotReached)]
fun try_claim_tokens_back_before_endtime() {
    let mut ctx = tx_context::dummy();
    let clock = clock::create_for_testing(&mut ctx);

    let mut proposal = test_proposal(
        &clock,
        option::none(),
        &mut ctx,
    );
    proposal.return_tokens_bulk(&clock, &mut ctx);
    abort 1337
}

#[test, expected_failure(abort_code = ::suins_voting::proposal::EEndTimeNotReached)]
fun try_self_finalize_before_end_time() {
    let mut ctx = tx_context::dummy();
    let clock = clock::create_for_testing(&mut ctx);

    let mut proposal = test_proposal(
        &clock,
        option::none(),
        &mut ctx,
    );
    let _coin = proposal.return_tokens(&clock, &mut ctx);
    abort 1337
}

#[test, expected_failure(abort_code = ::suins_voting::proposal::EProposalAlreadyFinalized)]
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
    assert!(proposal.winning_option().is_some_and!(|opt| opt == threshold_not_reached()));

    proposal.finalize(&clock, &mut ctx);

    abort 1337
}

#[test, expected_failure(abort_code = ::suins_voting::proposal::EVoterNotFound)]
fun try_to_claim_without_having_voted() {
    let mut ctx = tx_context::dummy();
    let mut clock = clock::create_for_testing(&mut ctx);

    let mut proposal = test_proposal(
        &clock,
        option::none(),
        &mut ctx,
    );
    proposal.set_threshold(1);
    clock.increment_for_testing(min_voting_period_ms!() + 2);
    let _coin = proposal.return_tokens(&clock, &mut ctx);

    abort 1337
}

#[test, expected_failure(abort_code = ::suins_voting::proposal::EVotingPeriodExpired)]
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

    let coin = coin::mint_for_testing<NS>(100, &mut ctx);
    proposal.vote(b"Yes".to_string(), coin, &clock, &mut ctx);

    abort 1337
}

#[test, expected_failure(abort_code = ::suins_voting::proposal::ENotAvailableOption)]
fun vote_non_existing_option() {
    let mut ctx = tx_context::dummy();
    let clock = clock::create_for_testing(&mut ctx);

    let mut proposal = test_proposal(
        &clock,
        option::none(),
        &mut ctx,
    );

    let coin = coin::mint_for_testing<NS>(100, &mut ctx);
    proposal.vote(b"Wut".to_string(), coin, &clock, &mut ctx);

    abort 1337
}

#[test, expected_failure(abort_code = ::suins_voting::proposal::ENotEnoughOptions)]
fun create_proposal_without_enough_options() {
    let mut ctx = tx_context::dummy();
    let clock = clock::create_for_testing(&mut ctx);

    let _proposal = proposal::new(
        b"".to_string(),
        b"".to_string(),
        clock.timestamp_ms() + min_voting_period_ms!() + 1,
        vec_set::empty(),
        &clock,
        &mut ctx,
    );

    abort 1337
}

public fun test_proposal(clock: &Clock, end_time_ms: Option<u64>, ctx: &mut TxContext): Proposal {
    let options = voting_option::default_options();
    let title = b"Test Proposal".to_string();
    let description = b"Test Proposal Description".to_string();

    proposal::new(
        title,
        description,
        end_time_ms.destroy_or!(clock.timestamp_ms() + min_voting_period_ms!() + 1),
        options,
        clock,
        ctx,
    )
}
