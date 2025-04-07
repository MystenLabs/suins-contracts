module suins_voting::early_voting_v2_tests;

// === imports ===

use sui::{
    clock::{Self},
    coin::{Self, Coin},
    test_scenario::{Self as ts},
    test_utils::{assert_eq, destroy},
};
use suins_token::{
    ns::NS,
};
use suins_voting::{
    constants::{min_voting_period_ms},
    early_voting::{Self},
    governance::{Self, NSGovernance, NSGovernanceCap},
    proposal_v2::{Self, ProposalV2},
    test_utils::{setup, admin_addr},
    voting_option::{Self},
};

// === constants ===

const USER1: address = @0x1;
const USER2: address = @0x2;
const USER3: address = @0x3;
const USER4: address = @0x4;

const DECIMALS: u64 = 1_000_000;

// === tests ===

#[test]
fun test_add_proposal_v2_ok() {
    let mut ts = ts::begin(admin_addr!());
    let mut clock = clock::create_for_testing(ts.ctx());
    governance::init_for_testing(ts.ctx());

    ts.next_tx(admin_addr!());
    let cap = ts.take_from_sender<NSGovernanceCap>();
    let mut gov = ts.take_shared<NSGovernance>();

    // create proposal1

    let start_time_1 = clock.timestamp_ms();
    let title = b"The Title".to_string();
    let description = b"The Description".to_string();
    let end_time_1 = start_time_1 + min_voting_period_ms!();
    let options = voting_option::default_options();
    let reward_value = 1_000_000;
    let reward = coin::mint_for_testing<NS>(reward_value, ts.ctx());

    let proposal1 = proposal_v2::new(
        title,
        description,
        end_time_1,
        options,
        reward,
        &clock,
        ts.ctx(),
    );

    // validate proposal1 initial state

    assert_eq(proposal1.serial_no(), 0);
    assert_eq(proposal1.threshold(), 0);
    assert_eq(*proposal1.title(), title);
    assert_eq(*proposal1.description(), description);
    assert_eq(proposal1.winning_option().is_none(), true);
    assert_eq(proposal1.vote_leaderboards().size(), voting_option::default_options().size());
    assert_eq(proposal1.start_time_ms(), start_time_1);
    assert_eq(proposal1.end_time_ms(), end_time_1);
    assert_eq(proposal1.votes().size(), voting_option::default_options().size());
    assert_eq(proposal1.voters().length(), 0);
    assert_eq(proposal1.voter_powers().length(), 0);
    assert_eq(proposal1.total_power(), 0);
    assert_eq(proposal1.reward().value(), reward_value);
    assert_eq(proposal1.total_reward(), reward_value);

    // validate proposal1 state after adding to early voting
    early_voting::add_proposal_v2(&cap, &mut gov, proposal1);
    ts.next_tx(admin_addr!());
    let proposal1 = ts.take_shared<ProposalV2>();
    assert_eq(proposal1.serial_no(), 1);
    assert_eq(proposal1.threshold(), gov.quorum_threshold());
    ts::return_shared(proposal1);

    // create proposal2

    let start_time_2 = end_time_1 + 1;
    clock.set_for_testing(start_time_2);
    let proposal2 = proposal_v2::new(
        title,
        description,
        start_time_2 + min_voting_period_ms!(),
        options,
        coin::mint_for_testing<NS>(reward_value, ts.ctx()),
        &clock,
        ts.ctx(),
    );

    // validate proposal2 state after adding to early voting
    early_voting::add_proposal_v2(&cap, &mut gov, proposal2);
    ts.next_tx(admin_addr!());
    let proposal2 = ts.take_shared<ProposalV2>();
    assert_eq(proposal2.serial_no(), 2);
    assert_eq(proposal2.threshold(), gov.quorum_threshold());
    ts::return_shared(proposal2);

    destroy(ts);
    destroy(cap);
    destroy(gov);
    destroy(clock);
}

// === original tests from v1 (adapted for proposal_v2) ===

#[test]
fun test_e2e() {
    let mut setup = setup();
    // Add a proposal. Total voting power will be (50M) + (100M + 50M) + (25M + 25M) = 250M
    {
        let cap = setup.ts().take_from_sender<NSGovernanceCap>();

        let proposal = setup.proposal__new_default();
        early_voting::add_proposal_v2(&cap, setup.gov_mut(), proposal);

        setup.ts().return_to_sender(cap);
    };
    // user 1 votes "Abstain" with 50M (20% of all votes)
    {
        setup.next_tx(USER1);
        let mut proposal = setup.ts().take_shared<ProposalV2>();

        assert_eq(proposal.serial_no(), 1);

        let mut batch = setup.batch__new(50_000_000 * DECIMALS, 0);
        setup.proposal__vote(
            &mut proposal,
            b"Abstain".to_string(),
            &mut batch,
        );
        ts::return_shared(proposal);
        destroy(batch);
    };
    // user 2 votes "Yes" with 100M and "No" with 50M (60% of all votes)
    {
        setup.next_tx(USER2);
        let mut proposal = setup.ts().take_shared<ProposalV2>();

        assert_eq(proposal.serial_no(), 1);

        let mut batch1 = setup.batch__new(100_000_000 * DECIMALS, 0);
        let mut batch2 = setup.batch__new(50_000_000 * DECIMALS, 0);
        setup.proposal__vote(
            &mut proposal,
            b"Yes".to_string(),
            &mut batch1,
        );
        setup.proposal__vote(
            &mut proposal,
            b"No".to_string(),
            &mut batch2,
        );
        ts::return_shared(proposal);
        destroy(batch1);
        destroy(batch2);
    };
    // user 3 votes "Yes" with 25M and "No" with 25M (20% of all votes)
    {
        setup.next_tx(USER3);
        let mut proposal = setup.ts().take_shared<ProposalV2>();

        assert_eq(proposal.serial_no(), 1);

        let mut batch1 = setup.batch__new(25_000_000 * DECIMALS, 0);
        let mut batch2 = setup.batch__new(25_000_000 * DECIMALS, 0);
        setup.proposal__vote(
            &mut proposal,
            b"Yes".to_string(),
            &mut batch1,
        );
        setup.proposal__vote(
            &mut proposal,
            b"No".to_string(),
            &mut batch2,
        );
        ts::return_shared(proposal);
        destroy(batch1);
        destroy(batch2);
    };

    // advance all the way to the end
    setup.add_time(min_voting_period_ms!() + 1);

    // finalize (for self) by user.
    {
        setup.next_tx(USER2);
        let mut proposal = setup.ts().take_shared<ProposalV2>();
        let reward = setup.proposal__claim_reward(&mut proposal);

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
        setup.next_tx(USER4);
        let mut proposal = setup.ts().take_shared<ProposalV2>();

        setup.proposal__distribute_rewards(&mut proposal);

        assert_eq(proposal.voter_powers().length(), 0);

        ts::return_shared(proposal);
    };

    setup.next_tx(admin_addr!());
    let coin = setup.ts().take_from_address<Coin<NS>>(USER1);
    assert_eq(coin.value(), 200_000);
    destroy(coin);

    let coin = setup.ts().take_from_address<Coin<NS>>(USER3);
    assert_eq(coin.value(), 200_000);
    destroy(coin);

    setup.destroy();
}

#[test]
fun test_e2e_no_quorum() {
    let mut setup = setup();
    // Add a proposal. Total voting power will be (300K) + (600K + 300K) = 1.2M
    {
        setup.next_tx(admin_addr!());
        let cap = setup.ts().take_from_sender<NSGovernanceCap>();

        let proposal = setup.proposal__new_default();
        early_voting::add_proposal_v2(&cap, setup.gov_mut(), proposal);

        setup.ts().return_to_sender(cap);
    };
    // User 1 votes "Abstain" with 300K (25% of all votes)
    {
        setup.next_tx(USER1);
        let mut proposal = setup.ts().take_shared<ProposalV2>();

        assert_eq(proposal.serial_no(), 1);

        let mut batch = setup.batch__new(300_000 * DECIMALS, 0);
        setup.proposal__vote(
            &mut proposal,
            b"Abstain".to_string(),
            &mut batch,
        );
        ts::return_shared(proposal);
        destroy(batch);
    };
    // User 2 votes "Yes" with 600K and "No" with 300K (75% of all votes)
    {
        setup.next_tx(USER2);
        let mut proposal = setup.ts().take_shared<ProposalV2>();

        assert_eq(proposal.serial_no(), 1);

        let mut batch1 = setup.batch__new(600_000 * DECIMALS, 0);
        let mut batch2 = setup.batch__new(300_000 * DECIMALS, 0);
        setup.proposal__vote(
            &mut proposal,
            b"Yes".to_string(),
            &mut batch1,
        );
        setup.proposal__vote(
            &mut proposal,
            b"No".to_string(),
            &mut batch2,
        );
        ts::return_shared(proposal);
        destroy(batch1);
        destroy(batch2);
    };

    // advance all the way to the end.
    setup.add_time(min_voting_period_ms!() + 1);

    // finalize (for self) by user.
    {
        setup.next_tx(USER2);
        let mut proposal = setup.ts().take_shared<ProposalV2>();
        let reward = setup.proposal__claim_reward(&mut proposal);

        assert_eq(reward.value(), 750_000);

        assert_eq(
            proposal.winning_option().borrow().value(),
            voting_option::threshold_not_reached().value(),
        );

        destroy(reward);
        ts::return_shared(proposal);
    };

    setup.destroy();
}

#[test]
fun test_e2e_tie() {
    let mut setup = setup();
    // Add a proposal. Total voting power will be (4M) + (1M + 1M) = 6M
    {
        setup.next_tx(admin_addr!());
        let cap = setup.ts().take_from_sender<NSGovernanceCap>();

        let proposal = setup.proposal__new_default();
        early_voting::add_proposal_v2(&cap, setup.gov_mut(), proposal);

        setup.ts().return_to_sender(cap);
    };
    // User 1 votes "Abstain" with 4M (66.66% of all votes)
    {
        setup.next_tx(USER1);
        let mut proposal = setup.ts().take_shared<ProposalV2>();

        assert_eq(proposal.serial_no(), 1);

        let mut batch = setup.batch__new(4_000_000 * DECIMALS, 0);
        setup.proposal__vote(
            &mut proposal,
            b"Abstain".to_string(),
            &mut batch,
        );
        ts::return_shared(proposal);
        destroy(batch);
    };
    // User 2 votes "Yes" with 1M and "No" with 1M (33.33% of all votes)
    {
        setup.next_tx(USER2);
        let mut proposal = setup.ts().take_shared<ProposalV2>();

        assert_eq(proposal.serial_no(), 1);

        let mut batch1 = setup.batch__new(1_000_000 * DECIMALS, 0);
        let mut batch2 = setup.batch__new(1_000_000 * DECIMALS, 0);
        setup.proposal__vote(
            &mut proposal,
            b"Yes".to_string(),
            &mut batch1,
        );
        setup.proposal__vote(
            &mut proposal,
            b"No".to_string(),
            &mut batch2,
        );
        ts::return_shared(proposal);
        destroy(batch1);
        destroy(batch2);
    };

    // advance all the way to the end.
    setup.add_time(min_voting_period_ms!() + 1);

    // finalize (for self) by user.
    {
        setup.next_tx(USER2);
        let mut proposal = setup.ts().take_shared<ProposalV2>();
        let reward = setup.proposal__claim_reward(&mut proposal);

        assert_eq(reward.value(), 333_333);

        assert_eq(
            proposal.winning_option().borrow().value(),
            voting_option::tie_rejected().value(),
        );

        destroy(reward);
        ts::return_shared(proposal);
    };

    setup.destroy();
}

#[test]
fun test_e2e_abstain_bypassed() {
    let mut setup = setup();
    // Add a proposal. Total voting power will be (5M) + (1M + 1M) = 7M
    {
        setup.next_tx(admin_addr!());
        let cap = setup.ts().take_from_sender<NSGovernanceCap>();

        let proposal = setup.proposal__new_default();
        early_voting::add_proposal_v2(&cap, setup.gov_mut(), proposal);

        setup.ts().return_to_sender(cap);
    };
    // User 1 votes "Abstain" with 5M
    {
        setup.next_tx(USER1);
        let mut proposal = setup.ts().take_shared<ProposalV2>();

        assert_eq(proposal.serial_no(), 1);

        let mut batch = setup.batch__new(5_000_000 * DECIMALS, 0);
        setup.proposal__vote(
            &mut proposal,
            b"Abstain".to_string(),
            &mut batch,
        );
        ts::return_shared(proposal);
        destroy(batch);
    };
    // User 2 votes "Yes" with 1M and "No" with 2M
    {
        setup.next_tx(USER2);
        let mut proposal = setup.ts().take_shared<ProposalV2>();

        assert_eq(proposal.serial_no(), 1);

        let mut batch1 = setup.batch__new(1_000_000 * DECIMALS, 0);
        let mut batch2 = setup.batch__new(2_000_000 * DECIMALS, 0);
        setup.proposal__vote(
            &mut proposal,
            b"Yes".to_string(),
            &mut batch1,
        );
        setup.proposal__vote(
            &mut proposal,
            b"No".to_string(),
            &mut batch2,
        );
        ts::return_shared(proposal);
        destroy(batch1);
        destroy(batch2);
    };

    // advance all the way to the end.
    setup.add_time(min_voting_period_ms!() + 1);

    // finalize (for self) by user.
    {
        setup.next_tx(USER2);
        let mut proposal = setup.ts().take_shared<ProposalV2>();
        let reward = setup.proposal__claim_reward(&mut proposal);

        assert_eq(reward.value(), 375_000); // 3/8 = 0.375

        assert_eq(
            proposal.winning_option().borrow().value(),
            voting_option::no_option().value(),
        );

        destroy(reward);
        ts::return_shared(proposal);
    };

    setup.destroy();
}

#[test]
fun add_second_proposal_after_first_is_completed() {
    let mut setup = setup();

    let cap = setup.ts().take_from_sender<NSGovernanceCap>();

    let proposal = setup.proposal__new_default();

    early_voting::add_proposal_v2(&cap, setup.gov_mut(), proposal);

    setup.add_time(min_voting_period_ms!() + 2);

    let second_proposal = setup.proposal__new_default();

    early_voting::add_proposal_v2(&cap, setup.gov_mut(), second_proposal);

    setup.ts().return_to_sender(cap);

    setup.destroy();
}

#[test, expected_failure(abort_code = ::suins_voting::early_voting::ECannotHaveParallelProposals)]
fun test_try_to_add_parallel_proposals() {
    let mut setup = setup();
    setup.next_tx(admin_addr!());
    let cap = setup.ts().take_from_sender<NSGovernanceCap>();

    let proposal = setup.proposal__new_default();

    let second_proposal = setup.proposal__new_default();
    early_voting::add_proposal_v2(&cap, setup.gov_mut(), proposal);
    early_voting::add_proposal_v2(&cap, setup.gov_mut(), second_proposal);

    abort 1337
}
