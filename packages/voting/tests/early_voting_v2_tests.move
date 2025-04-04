module suins_voting::early_voting_v2_tests;

// === imports ===

use sui::{
    coin::{Coin},
    test_scenario::{Self as ts},
    test_utils::{assert_eq, destroy},
};
use suins_token::{
    ns::NS,
};
use suins_voting::{
    constants::{min_voting_period_ms},
    early_voting::{Self},
    governance::{NSGovernanceCap},
    proposal_v2::{ProposalV2},
    test_utils::{setup, admin_addr},
    voting_option::{Self},
};

// === constants ===

const USER1: address = @0x1;
const USER2: address = @0x2;
const USER3: address = @0x3;
const USER4: address = @0x4;

const DECIMALS: u64 = 1_000_000;

// === original tests from v1 (adapted for proposal_v2) ===

#[test]
fun test_e2e() {
    let (mut ts, mut setup) = setup();
    // Add a proposal. Total voting power will be (50M) + (100M + 50M) + (25M + 25M) = 250M
    {
        let cap = ts.take_from_sender<NSGovernanceCap>();

        let proposal = setup.new_proposal_with_end_time(&mut ts, option::none());
        early_voting::add_proposal_v2(&cap, setup.gov_mut(), proposal);

        ts.return_to_sender(cap);
    };
    // user 1 votes "Abstain" with 50M (20% of all votes)
    {
        ts.next_tx(USER1);
        let mut proposal = ts.take_shared<ProposalV2>();

        assert_eq(proposal.serial_no(), 1);

        let mut batch = setup.batch__new(&mut ts, 50_000_000 * DECIMALS, 0);
        proposal.vote(
            b"Abstain".to_string(),
            &mut batch,
            setup.system(),
            setup.clock(),
            ts.ctx(),
        );
        ts::return_shared(proposal);
        destroy(batch);
    };
    // user 2 votes "Yes" with 100M and "No" with 50M (60% of all votes)
    {
        ts.next_tx(USER2);
        let mut proposal = ts.take_shared<ProposalV2>();

        assert_eq(proposal.serial_no(), 1);

        let mut batch1 = setup.batch__new(&mut ts, 100_000_000 * DECIMALS, 0);
        let mut batch2 = setup.batch__new(&mut ts, 50_000_000 * DECIMALS, 0);
        proposal.vote(
            b"Yes".to_string(),
            &mut batch1,
            setup.system(),
            setup.clock(),
            ts.ctx(),
        );
        proposal.vote(
            b"No".to_string(),
            &mut batch2,
            setup.system(),
            setup.clock(),
            ts.ctx(),
        );
        ts::return_shared(proposal);
        destroy(batch1);
        destroy(batch2);
    };
    // user 3 votes "Yes" with 25M and "No" with 25M (20% of all votes)
    {
        ts.next_tx(USER3);
        let mut proposal = ts.take_shared<ProposalV2>();

        assert_eq(proposal.serial_no(), 1);

        let mut batch1 = setup.batch__new(&mut ts, 25_000_000 * DECIMALS, 0);
        let mut batch2 = setup.batch__new(&mut ts, 25_000_000 * DECIMALS, 0);
        proposal.vote(
            b"Yes".to_string(),
            &mut batch1,
            setup.system(),
            setup.clock(),
            ts.ctx(),
        );
        proposal.vote(
            b"No".to_string(),
            &mut batch2,
            setup.system(),
            setup.clock(),
            ts.ctx(),
        );
        ts::return_shared(proposal);
        destroy(batch1);
        destroy(batch2);
    };

    // advance all the way to the end
    setup.add_time(min_voting_period_ms!() + 1);

    // finalize (for self) by user.
    {
        ts.next_tx(USER2);
        let mut proposal = ts.take_shared<ProposalV2>();
        let reward = proposal.claim_reward(
            setup.clock(),
            ts.ctx(),
        );

        assert_eq(reward.value(), 600_000);

        assert_eq(
            proposal.winning_option().borrow().value(),
            b"Yes".to_string(),
        );

        destroy(reward);
        ts::return_shared(proposal);
    };
    {
        // finalize for all
        ts.next_tx(USER4);
        let mut proposal = ts.take_shared<ProposalV2>();

        proposal.distribute_rewards(setup.clock(), ts.ctx());

        assert_eq(proposal.voter_powers().length(), 0);

        ts::return_shared(proposal);
    };

    ts.next_tx(admin_addr!());
    let coin = ts.take_from_address<Coin<NS>>(USER1);
    assert_eq(coin.value(), 200_000);
    destroy(coin);

    let coin = ts.take_from_address<Coin<NS>>(USER3);
    assert_eq(coin.value(), 200_000);
    destroy(coin);

    setup.destroy(ts);
}

#[test]
fun test_e2e_no_quorum() {
    let (mut ts, mut setup) = setup();
    // Add a proposal. Total voting power will be (300K) + (600K + 300K) = 1.2M
    {
        ts.next_tx(admin_addr!());
        let cap = ts.take_from_sender<NSGovernanceCap>();

        let proposal = setup.new_proposal_with_end_time(&mut ts, option::none());
        early_voting::add_proposal_v2(&cap, setup.gov_mut(), proposal);

        ts.return_to_sender(cap);
    };
    // User 1 votes "Abstain" with 300K (25% of all votes)
    {
        ts.next_tx(USER1);
        let mut proposal = ts.take_shared<ProposalV2>();

        assert_eq(proposal.serial_no(), 1);

        let mut batch = setup.batch__new(&mut ts, 300_000 * DECIMALS, 0);
        proposal.vote(
            b"Abstain".to_string(),
            &mut batch,
            setup.system(),
            setup.clock(),
            ts.ctx(),
        );
        ts::return_shared(proposal);
        destroy(batch);
    };
    // User 2 votes "Yes" with 600K and "No" with 300K (75% of all votes)
    {
        ts.next_tx(USER2);
        let mut proposal = ts.take_shared<ProposalV2>();

        assert_eq(proposal.serial_no(), 1);

        let mut batch1 = setup.batch__new(&mut ts, 600_000 * DECIMALS, 0);
        let mut batch2 = setup.batch__new(&mut ts, 300_000 * DECIMALS, 0);
        proposal.vote(
            b"Yes".to_string(),
            &mut batch1,
            setup.system(),
            setup.clock(),
            ts.ctx(),
        );
        proposal.vote(
            b"No".to_string(),
            &mut batch2,
            setup.system(),
            setup.clock(),
            ts.ctx(),
        );
        ts::return_shared(proposal);
        destroy(batch1);
        destroy(batch2);
    };

    // advance all the way to the end.
    setup.add_time(min_voting_period_ms!() + 1);

    // finalize (for self) by user.
    {
        ts.next_tx(USER2);
        let mut proposal = ts.take_shared<ProposalV2>();
        let reward = proposal.claim_reward(
            setup.clock(),
            ts.ctx(),
        );

        assert_eq(reward.value(), 750_000);

        assert_eq(
            proposal.winning_option().borrow().value(),
            voting_option::threshold_not_reached().value(),
        );

        destroy(reward);
        ts::return_shared(proposal);
    };

    setup.destroy(ts);
}

#[test]
fun test_e2e_tie() {
    let (mut ts, mut setup) = setup();
    // Add a proposal. Total voting power will be (4M) + (1M + 1M) = 6M
    {
        ts.next_tx(admin_addr!());
        let cap = ts.take_from_sender<NSGovernanceCap>();

        let proposal = setup.new_proposal_with_end_time(&mut ts, option::none());
        early_voting::add_proposal_v2(&cap, setup.gov_mut(), proposal);

        ts.return_to_sender(cap);
    };
    // User 1 votes "Abstain" with 4M (66.66% of all votes)
    {
        ts.next_tx(USER1);
        let mut proposal = ts.take_shared<ProposalV2>();

        assert_eq(proposal.serial_no(), 1);

        let mut batch = setup.batch__new(&mut ts, 4_000_000 * DECIMALS, 0);
        proposal.vote(
            b"Abstain".to_string(),
            &mut batch,
            setup.system(),
            setup.clock(),
            ts.ctx(),
        );
        ts::return_shared(proposal);
        destroy(batch);
    };
    // User 2 votes "Yes" with 1M and "No" with 1M (33.33% of all votes)
    {
        ts.next_tx(USER2);
        let mut proposal = ts.take_shared<ProposalV2>();

        assert_eq(proposal.serial_no(), 1);

        let mut batch1 = setup.batch__new(&mut ts, 1_000_000 * DECIMALS, 0);
        let mut batch2 = setup.batch__new(&mut ts, 1_000_000 * DECIMALS, 0);
        proposal.vote(
            b"Yes".to_string(),
            &mut batch1,
            setup.system(),
            setup.clock(),
            ts.ctx(),
        );
        proposal.vote(
            b"No".to_string(),
            &mut batch2,
            setup.system(),
            setup.clock(),
            ts.ctx(),
        );
        ts::return_shared(proposal);
        destroy(batch1);
        destroy(batch2);
    };

    // advance all the way to the end.
    setup.add_time(min_voting_period_ms!() + 1);

    // finalize (for self) by user.
    {
        ts.next_tx(USER2);
        let mut proposal = ts.take_shared<ProposalV2>();
        let reward = proposal.claim_reward(
            setup.clock(),
            ts.ctx(),
        );

        assert_eq(reward.value(), 333_333);

        assert_eq(
            proposal.winning_option().borrow().value(),
            voting_option::tie_rejected().value(),
        );

        destroy(reward);
        ts::return_shared(proposal);
    };

    setup.destroy(ts);
}

#[test]
fun test_e2e_abstain_bypassed() {
    let (mut ts, mut setup) = setup();
    // Add a proposal. Total voting power will be (5M) + (1M + 1M) = 7M
    {
        ts.next_tx(admin_addr!());
        let cap = ts.take_from_sender<NSGovernanceCap>();

        let proposal = setup.new_proposal_with_end_time(&mut ts, option::none());
        early_voting::add_proposal_v2(&cap, setup.gov_mut(), proposal);

        ts.return_to_sender(cap);
    };
    // User 1 votes "Abstain" with 5M
    {
        ts.next_tx(USER1);
        let mut proposal = ts.take_shared<ProposalV2>();

        assert_eq(proposal.serial_no(), 1);

        let mut batch = setup.batch__new(&mut ts, 5_000_000 * DECIMALS, 0);
        proposal.vote(
            b"Abstain".to_string(),
            &mut batch,
            setup.system(),
            setup.clock(),
            ts.ctx(),
        );
        ts::return_shared(proposal);
        destroy(batch);
    };
    // User 2 votes "Yes" with 1M and "No" with 2M
    {
        ts.next_tx(USER2);
        let mut proposal = ts.take_shared<ProposalV2>();

        assert_eq(proposal.serial_no(), 1);

        let mut batch1 = setup.batch__new(&mut ts, 1_000_000 * DECIMALS, 0);
        let mut batch2 = setup.batch__new(&mut ts, 2_000_000 * DECIMALS, 0);
        proposal.vote(
            b"Yes".to_string(),
            &mut batch1,
            setup.system(),
            setup.clock(),
            ts.ctx(),
        );
        proposal.vote(
            b"No".to_string(),
            &mut batch2,
            setup.system(),
            setup.clock(),
            ts.ctx(),
        );
        ts::return_shared(proposal);
        destroy(batch1);
        destroy(batch2);
    };

    // advance all the way to the end.
    setup.add_time(min_voting_period_ms!() + 1);

    // finalize (for self) by user.
    {
        ts.next_tx(USER2);
        let mut proposal = ts.take_shared<ProposalV2>();
        let reward = proposal.claim_reward(
            setup.clock(),
            ts.ctx(),
        );

        assert_eq(reward.value(), 375_000); // 3/8 = 0.375

        assert_eq(
            proposal.winning_option().borrow().value(),
            voting_option::no_option().value(),
        );

        destroy(reward);
        ts::return_shared(proposal);
    };

    setup.destroy(ts);
}

#[test]
fun add_second_proposal_after_first_is_completed() {
    let (mut ts, mut setup) = setup();

    let cap = ts.take_from_sender<NSGovernanceCap>();

    let proposal = setup.new_proposal_with_end_time(&mut ts, option::none());

    early_voting::add_proposal_v2(&cap, setup.gov_mut(), proposal);

    setup.add_time(min_voting_period_ms!() + 2);

    let second_proposal = setup.new_proposal_with_end_time(&mut ts, option::none());

    early_voting::add_proposal_v2(&cap, setup.gov_mut(), second_proposal);

    ts.return_to_sender(cap);

    setup.destroy(ts);
}

#[test, expected_failure(abort_code = ::suins_voting::early_voting::ECannotHaveParallelProposals)]
fun test_try_to_add_parallel_proposals() {
    let (mut ts, mut setup) = setup();
    ts.next_tx(admin_addr!());
    let cap = ts.take_from_sender<NSGovernanceCap>();

    let proposal = setup.new_proposal_with_end_time(&mut ts, option::none());

    let second_proposal = setup.new_proposal_with_end_time(&mut ts, option::none());
    early_voting::add_proposal_v2(&cap, setup.gov_mut(), proposal);
    early_voting::add_proposal_v2(&cap, setup.gov_mut(), second_proposal);

    abort 1337
}
