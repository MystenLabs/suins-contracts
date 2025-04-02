module suins_voting::early_voting_v2_tests;

// === imports ===

use sui::{
    clock::{Self, Clock},
    test_scenario::{Self as ts, Scenario},
    test_utils::{assert_eq, destroy},
};
use suins_voting::{
    constants::{min_voting_period_ms},
    early_voting::{Self},
    governance::{Self, NSGovernance, NSGovernanceCap},
    proposal_v2_tests::{Self},
    proposal_v2::{ProposalV2},
    staking_batch::{Self, StakingBatch},
    staking_config::{Self, StakingConfig},
    voting_option::{Self},
};

// === constants ===

const ADMIN: address = @0x0;
const USER1: address = @0x1;
const USER2: address = @0x2;
const USER3: address = @0x3;
const USER4: address = @0x4;

const DECIMALS: u64 = 1_000_000;

// === setup ===

public struct TestSetup {
    ts: Scenario,
    clock: Clock,
    governance: NSGovernance,
    staking_config: StakingConfig,
}

fun new_proposal(setup: &mut TestSetup, end_time_ms: Option<u64>): ProposalV2 {
    proposal_v2_tests::test_proposal(&setup.clock, end_time_ms, setup.ts.ctx())
}

fun new_batch(setup: &mut TestSetup, balance: u64): StakingBatch {
    let now = setup.clock.timestamp_ms();
    staking_batch::new_for_testing(
        balance,
        now, // start_ms
        now, // unlock_ms
        0, // cooldown_end_ms
        0, // voting_until_ms
        setup.ts.ctx(),
    )
}

fun cleanup(setup: TestSetup) {
    sui::test_utils::destroy(setup);
}

fun prepare_early_voting(): TestSetup {
    let mut ts = ts::begin(ADMIN);
    let clock = clock::create_for_testing(ts.ctx());
    governance::init_for_testing(ts.ctx());
    staking_config::init_for_testing(ts.ctx());

    ts.next_tx(ADMIN);

    let governance = ts.take_shared<NSGovernance>();
    let staking_config = ts.take_shared<StakingConfig>();
    TestSetup {
        ts,
        clock,
        governance,
        staking_config,
    }
}

// === tests ===

#[test]
fun test_e2e() {
    let mut test = prepare_early_voting();
    // Add a proposal.
    {
        test.ts.next_tx(ADMIN);
        let cap = test.ts.take_from_sender<NSGovernanceCap>();

        let proposal = test.new_proposal(option::none());
        early_voting::add_proposal_v2(&cap, &mut test.governance, proposal);

        test.ts.return_to_sender(cap);
    };
    {
        test.ts.next_tx(USER1);
        let mut proposal = test.ts.take_shared<ProposalV2>();

        assert_eq(proposal.serial_no(), 1);

        let mut batch = new_batch(&mut test, 50_000_000 * DECIMALS);
        proposal.vote(
            b"Abstain".to_string(),
            &mut batch,
            &test.staking_config,
            &test.clock,
            test.ts.ctx(),
        );
        ts::return_shared(proposal);
        destroy(batch);
    };
    {
        test.ts.next_tx(USER2);
        let mut proposal = test.ts.take_shared<ProposalV2>();

        assert_eq(proposal.serial_no(), 1);

        let mut batch1 = new_batch(&mut test, 100_000_000 * DECIMALS);
        let mut batch2 = new_batch(&mut test, 50_000_000 * DECIMALS);
        proposal.vote(
            b"Yes".to_string(),
            &mut batch1,
            &test.staking_config,
            &test.clock,
            test.ts.ctx(),
        );
        proposal.vote(
            b"No".to_string(),
            &mut batch2,
            &test.staking_config,
            &test.clock,
            test.ts.ctx(),
        );
        ts::return_shared(proposal);
        destroy(batch1);
        destroy(batch2);
    };
    {
        test.ts.next_tx(USER3);
        let mut proposal = test.ts.take_shared<ProposalV2>();

        assert_eq(proposal.serial_no(), 1);

        let mut batch1 = new_batch(&mut test, 50_000_000 * DECIMALS);
        let mut batch2 = new_batch(&mut test, 50_000_000 * DECIMALS);
        proposal.vote(
            b"Yes".to_string(),
            &mut batch1,
            &test.staking_config,
            &test.clock,
            test.ts.ctx(),
        );
        proposal.vote(
            b"No".to_string(),
            &mut batch2,
            &test.staking_config,
            &test.clock,
            test.ts.ctx(),
        );
        ts::return_shared(proposal);
        destroy(batch1);
        destroy(batch2);
    };

    // advance all the way to the end.
    test.clock.increment_for_testing(min_voting_period_ms!() + 1);

    // finalize (for self) by user.
    {
        test.ts.next_tx(USER2);
        let mut proposal = test.ts.take_shared<ProposalV2>();
        let reward_batch = proposal.claim_reward(
            &test.clock,
            test.ts.ctx(),
        );

        // assert_eq(reward_batch.balance().value(), 150_000_000 * DECIMALS); // TODO

        assert_eq(
            proposal.winning_option().borrow().value(),
            b"Yes".to_string(),
        );

        destroy(reward_batch);
        ts::return_shared(proposal);
    };
    {
        // finalize for all
        test.ts.next_tx(USER4);
        let mut proposal = test.ts.take_shared<ProposalV2>();

        proposal.distribute_rewards(&test.clock, test.ts.ctx());

        assert_eq(proposal.voter_powers().length(), 0);

        ts::return_shared(proposal);
    };

    // test.ts.next_tx(ADMIN);
    // let coin = test.ts.take_from_address<Coin<NS>>(USER1);
    // assert_eq(coin.value(), 50_000_000 * DECIMALS);
    // destroy(coin);

    // let coin = test.ts.take_from_address<Coin<NS>>(USER3);
    // assert_eq(coin.value(), 100_000_000 * DECIMALS);
    // destroy(coin);

    test.cleanup();
}

#[test]
fun test_e2e_no_quorum() {
    let mut test = prepare_early_voting();
    // Add a proposal.
    {
        test.ts.next_tx(ADMIN);
        let cap = test.ts.take_from_sender<NSGovernanceCap>();

        let proposal = test.new_proposal(option::none());
        early_voting::add_proposal_v2(&cap, &mut test.governance, proposal);

        test.ts.return_to_sender(cap);
    };
    {
        test.ts.next_tx(USER1);
        let mut proposal = test.ts.take_shared<ProposalV2>();

        assert_eq(proposal.serial_no(), 1);

        let mut batch = new_batch(&mut test, 400_000 * DECIMALS);
        proposal.vote(
            b"Abstain".to_string(),
            &mut batch,
            &test.staking_config,
            &test.clock,
            test.ts.ctx(),
        );
        ts::return_shared(proposal);
        destroy(batch);
    };
    {
        test.ts.next_tx(USER2);
        let mut proposal = test.ts.take_shared<ProposalV2>();

        assert_eq(proposal.serial_no(), 1);

        let mut batch1 = new_batch(&mut test, 500_000 * DECIMALS);
        let mut batch2 = new_batch(&mut test, 400_000 * DECIMALS);
        proposal.vote(
            b"Yes".to_string(),
            &mut batch1,
            &test.staking_config,
            &test.clock,
            test.ts.ctx(),
        );
        proposal.vote(
            b"No".to_string(),
            &mut batch2,
            &test.staking_config,
            &test.clock,
            test.ts.ctx(),
        );
        ts::return_shared(proposal);
        destroy(batch1);
        destroy(batch2);
    };

    // advance all the way to the end.
    test.clock.increment_for_testing(min_voting_period_ms!() + 1);

    // finalize (for self) by user.
    {
        test.ts.next_tx(USER2);
        let mut proposal = test.ts.take_shared<ProposalV2>();
        let reward_batch = proposal.claim_reward(
            &test.clock,
            test.ts.ctx(),
        );

        // assert_eq(reward_batch.balance().value(), 900_000 * DECIMALS); // TODO

        assert_eq(
            proposal.winning_option().borrow().value(),
            voting_option::threshold_not_reached().value(),
        );

        destroy(reward_batch);
        ts::return_shared(proposal);
    };

    test.cleanup();
}

#[test]
fun test_e2e_tie() {
    let mut test = prepare_early_voting();
    // Add a proposal.
    {
        test.ts.next_tx(ADMIN);
        let cap = test.ts.take_from_sender<NSGovernanceCap>();

        let proposal = test.new_proposal(option::none());
        early_voting::add_proposal_v2(&cap, &mut test.governance, proposal);

        test.ts.return_to_sender(cap);
    };
    {
        test.ts.next_tx(USER1);
        let mut proposal = test.ts.take_shared<ProposalV2>();

        assert_eq(proposal.serial_no(), 1);

        let mut batch = new_batch(&mut test, 5_000_000 * DECIMALS);
        proposal.vote(
            b"Abstain".to_string(),
            &mut batch,
            &test.staking_config,
            &test.clock,
            test.ts.ctx(),
        );
        ts::return_shared(proposal);
        destroy(batch);
    };
    {
        test.ts.next_tx(USER2);
        let mut proposal = test.ts.take_shared<ProposalV2>();

        assert_eq(proposal.serial_no(), 1);

        let mut batch1 = new_batch(&mut test, 2_000_000 * DECIMALS);
        let mut batch2 = new_batch(&mut test, 2_000_000 * DECIMALS);
        proposal.vote(
            b"Yes".to_string(),
            &mut batch1,
            &test.staking_config,
            &test.clock,
            test.ts.ctx(),
        );
        proposal.vote(
            b"No".to_string(),
            &mut batch2,
            &test.staking_config,
            &test.clock,
            test.ts.ctx(),
        );
        ts::return_shared(proposal);
        destroy(batch1);
        destroy(batch2);
    };

    // advance all the way to the end.
    test.clock.increment_for_testing(min_voting_period_ms!() + 1);

    // finalize (for self) by user.
    {
        test.ts.next_tx(USER2);
        let mut proposal = test.ts.take_shared<ProposalV2>();
        let reward_batch = proposal.claim_reward(
            &test.clock,
            test.ts.ctx(),
        );

        // assert_eq(reward_batch.balance().value(), 4_000_000 * DECIMALS); // TODO

        assert_eq(
            proposal.winning_option().borrow().value(),
            voting_option::tie_rejected().value(),
        );

        destroy(reward_batch);
        ts::return_shared(proposal);
    };

    test.cleanup();
}

#[test]
fun test_e2e_abstain_bypassed() {
    let mut test = prepare_early_voting();
    // Add a proposal.
    {
        test.ts.next_tx(ADMIN);
        let cap = test.ts.take_from_sender<NSGovernanceCap>();

        let proposal = test.new_proposal(option::none());
        early_voting::add_proposal_v2(&cap, &mut test.governance, proposal);

        test.ts.return_to_sender(cap);
    };
    {
        test.ts.next_tx(USER1);
        let mut proposal = test.ts.take_shared<ProposalV2>();

        assert_eq(proposal.serial_no(), 1);

        let mut batch = new_batch(&mut test, 5_000_000 * DECIMALS);
        proposal.vote(
            b"Abstain".to_string(),
            &mut batch,
            &test.staking_config,
            &test.clock,
            test.ts.ctx(),
        );
        ts::return_shared(proposal);
        destroy(batch);
    };
    {
        test.ts.next_tx(USER2);
        let mut proposal = test.ts.take_shared<ProposalV2>();

        assert_eq(proposal.serial_no(), 1);

        let mut batch1 = new_batch(&mut test, 1_000_000 * DECIMALS);
        let mut batch2 = new_batch(&mut test, 2_000_000 * DECIMALS);
        proposal.vote(
            b"Yes".to_string(),
            &mut batch1,
            &test.staking_config,
            &test.clock,
            test.ts.ctx(),
        );
        proposal.vote(
            b"No".to_string(),
            &mut batch2,
            &test.staking_config,
            &test.clock,
            test.ts.ctx(),
        );
        ts::return_shared(proposal);
        destroy(batch1);
        destroy(batch2);
    };

    // advance all the way to the end.
    test.clock.increment_for_testing(min_voting_period_ms!() + 1);

    // finalize (for self) by user.
    {
        test.ts.next_tx(USER2);
        let mut proposal = test.ts.take_shared<ProposalV2>();
        let reward_batch = proposal.claim_reward(
            &test.clock,
            test.ts.ctx(),
        );

        // assert_eq(reward_batch.balance().value(), 3_000_000 * DECIMALS); // TODO

        assert_eq(
            proposal.winning_option().borrow().value(),
            voting_option::no_option().value(),
        );

        destroy(reward_batch);
        ts::return_shared(proposal);
    };

    test.cleanup();
}

#[test]
fun add_second_proposal_after_first_is_completed() {
    let mut test = prepare_early_voting();
    test.ts.next_tx(ADMIN);
    let cap = test.ts.take_from_sender<NSGovernanceCap>();

    let proposal = test.new_proposal(option::none());

    early_voting::add_proposal_v2(&cap, &mut test.governance, proposal);

    test.clock.increment_for_testing(min_voting_period_ms!() + 2);

    let second_proposal = test.new_proposal(option::none());

    early_voting::add_proposal_v2(&cap, &mut test.governance, second_proposal);

    test.ts.return_to_sender(cap);

    test.cleanup();
}

#[test, expected_failure(abort_code = ::suins_voting::early_voting::ECannotHaveParallelProposals)]
fun test_try_to_add_parallel_proposals() {
    let mut test = prepare_early_voting();
    test.ts.next_tx(ADMIN);
    let cap = test.ts.take_from_sender<NSGovernanceCap>();

    let proposal = test.new_proposal(option::none());

    let second_proposal = test.new_proposal(option::none());
    early_voting::add_proposal_v2(&cap, &mut test.governance, proposal);
    early_voting::add_proposal_v2(&cap, &mut test.governance, second_proposal);

    abort 1337
}
