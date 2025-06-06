// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module suins_voting::early_voting_tests;

use sui::{
    clock::{Self, Clock},
    coin::{Self, Coin},
    test_scenario::{Self as ts, Scenario},
    test_utils::destroy
};
use suins_token::ns::NS;
use suins_voting::{
    constants::min_voting_period_ms,
    early_voting,
    governance::{Self, NSGovernance, NSGovernanceCap},
    proposal::Proposal,
    proposal_tests,
    voting_option
};

const ADMIN: address = @0x0;
const USER: address = @0x1;
const USER2: address = @0x2;
const USER3: address = @0x3;
const USER4: address = @0x4;

const DECIMALS: u64 = 1_000_000;

public struct TestSetup {
    ts: Scenario,
    governance: NSGovernance,
    clock: Clock,
}

#[test]
fun test_e2e() {
    let mut test = prepare_early_voting();
    // Add a proposal.
    {
        test.ts.next_tx(ADMIN);
        let cap = test.ts.take_from_sender<NSGovernanceCap>();

        let proposal = test.test_proposal(option::none());
        early_voting::add_proposal(&cap, &mut test.governance, proposal);

        test.ts.return_to_sender(cap);
    };
    {
        test.ts.next_tx(USER);
        let mut proposal = test.ts.take_shared<Proposal>();

        assert!(proposal.serial_no() == 1);

        let coin = coin::mint_for_testing<NS>(
            50_000_000 * DECIMALS,
            test.ts.ctx(),
        );
        proposal.vote(b"Abstain".to_string(), coin, &test.clock, test.ts.ctx());
        ts::return_shared(proposal);
    };
    {
        test.ts.next_tx(USER2);
        let mut proposal = test.ts.take_shared<Proposal>();

        assert!(proposal.serial_no() == 1);

        let coin = coin::mint_for_testing<NS>(
            100_000_000 * DECIMALS,
            test.ts.ctx(),
        );
        let another_coin = coin::mint_for_testing<NS>(
            50_000_000 * DECIMALS,
            test.ts.ctx(),
        );

        proposal.vote(b"Yes".to_string(), coin, &test.clock, test.ts.ctx());
        proposal.vote(
            b"No".to_string(),
            another_coin,
            &test.clock,
            test.ts.ctx(),
        );
        ts::return_shared(proposal);
    };

    {
        test.ts.next_tx(USER3);
        let mut proposal = test.ts.take_shared<Proposal>();

        assert!(proposal.serial_no() == 1);

        let coin = coin::mint_for_testing<NS>(
            50_000_000 * DECIMALS,
            test.ts.ctx(),
        );
        let another_coin = coin::mint_for_testing<NS>(
            50_000_000 * DECIMALS,
            test.ts.ctx(),
        );

        proposal.vote(b"Yes".to_string(), coin, &test.clock, test.ts.ctx());
        proposal.vote(
            b"No".to_string(),
            another_coin,
            &test.clock,
            test.ts.ctx(),
        );
        ts::return_shared(proposal);
    };

    // advance all the way to the end.
    test.clock.increment_for_testing(min_voting_period_ms!() + 1);

    // finalize (for self) by user.
    {
        test.ts.next_tx(USER2);
        let mut proposal = test.ts.take_shared<Proposal>();
        let coin = proposal.return_tokens(&test.clock, test.ts.ctx());

        assert!(coin.value() == 150_000_000 * DECIMALS);

        assert!(proposal.winning_option().is_some_and!(|opt| {
            opt.value() == b"Yes".to_string()
        }));

        destroy(coin);
        ts::return_shared(proposal);
    };
    {
        // finalize for all (bulk_finalize) permisionless-ly
        test.ts.next_tx(USER4);
        let mut proposal = test.ts.take_shared<Proposal>();

        proposal.return_tokens_bulk(&test.clock, test.ts.ctx());

        assert!(proposal.voters_count() == 0);

        ts::return_shared(proposal);
    };

    test.ts.next_tx(ADMIN);
    let coin = test.ts.take_from_address<Coin<NS>>(USER);
    assert!(coin.value() == 50_000_000 * DECIMALS);
    destroy(coin);

    let coin = test.ts.take_from_address<Coin<NS>>(USER3);
    assert!(coin.value() == 100_000_000 * DECIMALS);
    destroy(coin);

    test.cleanup();
}

#[test]
fun test_e2e_no_quorum() {
    let mut test = prepare_early_voting();
    // Add a proposal.
    {
        test.ts.next_tx(ADMIN);
        let cap = test.ts.take_from_sender<NSGovernanceCap>();

        let proposal = test.test_proposal(option::none());
        early_voting::add_proposal(&cap, &mut test.governance, proposal);

        test.ts.return_to_sender(cap);
    };
    {
        test.ts.next_tx(USER);
        let mut proposal = test.ts.take_shared<Proposal>();

        assert!(proposal.serial_no() == 1);

        let coin = coin::mint_for_testing<NS>(
            400_000 * DECIMALS,
            test.ts.ctx(),
        );
        proposal.vote(b"Abstain".to_string(), coin, &test.clock, test.ts.ctx());
        ts::return_shared(proposal);
    };
    {
        test.ts.next_tx(USER2);
        let mut proposal = test.ts.take_shared<Proposal>();

        assert!(proposal.serial_no() == 1);

        let coin = coin::mint_for_testing<NS>(
            500_000 * DECIMALS,
            test.ts.ctx(),
        );
        let another_coin = coin::mint_for_testing<NS>(
            400_000 * DECIMALS,
            test.ts.ctx(),
        );

        proposal.vote(b"Yes".to_string(), coin, &test.clock, test.ts.ctx());
        proposal.vote(
            b"No".to_string(),
            another_coin,
            &test.clock,
            test.ts.ctx(),
        );
        ts::return_shared(proposal);
    };

    // advance all the way to the end.
    test.clock.increment_for_testing(min_voting_period_ms!() + 1);

    // finalize (for self) by user.
    {
        test.ts.next_tx(USER2);
        let mut proposal = test.ts.take_shared<Proposal>();
        let coin = proposal.return_tokens(&test.clock, test.ts.ctx());

        assert!(coin.value() == 900_000 * DECIMALS);

        assert!(proposal.winning_option().borrow() == voting_option::threshold_not_reached());

        destroy(coin);
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

        let proposal = test.test_proposal(option::none());
        early_voting::add_proposal(&cap, &mut test.governance, proposal);

        test.ts.return_to_sender(cap);
    };
    {
        test.ts.next_tx(USER);
        let mut proposal = test.ts.take_shared<Proposal>();

        assert!(proposal.serial_no() == 1);

        let coin = coin::mint_for_testing<NS>(
            5_000_000 * DECIMALS,
            test.ts.ctx(),
        );
        proposal.vote(b"Abstain".to_string(), coin, &test.clock, test.ts.ctx());
        ts::return_shared(proposal);
    };
    {
        test.ts.next_tx(USER2);
        let mut proposal = test.ts.take_shared<Proposal>();

        assert!(proposal.serial_no() == 1);

        let coin = coin::mint_for_testing<NS>(
            2_000_000 * DECIMALS,
            test.ts.ctx(),
        );
        let another_coin = coin::mint_for_testing<NS>(
            2_000_000 * DECIMALS,
            test.ts.ctx(),
        );

        proposal.vote(b"Yes".to_string(), coin, &test.clock, test.ts.ctx());
        proposal.vote(
            b"No".to_string(),
            another_coin,
            &test.clock,
            test.ts.ctx(),
        );
        ts::return_shared(proposal);
    };

    // advance all the way to the end.
    test.clock.increment_for_testing(min_voting_period_ms!() + 1);

    // finalize (for self) by user.
    {
        test.ts.next_tx(USER2);
        let mut proposal = test.ts.take_shared<Proposal>();
        let coin = proposal.return_tokens(&test.clock, test.ts.ctx());

        assert!(coin.value() == 4_000_000 * DECIMALS);

        assert!(proposal.winning_option().borrow() == voting_option::tie_rejected());

        destroy(coin);
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

        let proposal = test.test_proposal(option::none());
        early_voting::add_proposal(&cap, &mut test.governance, proposal);

        test.ts.return_to_sender(cap);
    };
    {
        test.ts.next_tx(USER);
        let mut proposal = test.ts.take_shared<Proposal>();

        assert!(proposal.serial_no() == 1);

        let coin = coin::mint_for_testing(
            5_000_000 * DECIMALS,
            test.ts.ctx(),
        );
        proposal.vote(b"Abstain".to_string(), coin, &test.clock, test.ts.ctx());
        ts::return_shared(proposal);
    };
    {
        test.ts.next_tx(USER2);
        let mut proposal = test.ts.take_shared<Proposal>();

        assert!(proposal.serial_no() == 1);

        let coin = coin::mint_for_testing<NS>(
            1_000_000 * DECIMALS,
            test.ts.ctx(),
        );
        let another_coin = coin::mint_for_testing<NS>(
            2_000_000 * DECIMALS,
            test.ts.ctx(),
        );

        proposal.vote(b"Yes".to_string(), coin, &test.clock, test.ts.ctx());
        proposal.vote(
            b"No".to_string(),
            another_coin,
            &test.clock,
            test.ts.ctx(),
        );
        ts::return_shared(proposal);
    };

    // advance all the way to the end.
    test.clock.increment_for_testing(min_voting_period_ms!() + 1);

    // finalize (for self) by user.
    {
        test.ts.next_tx(USER2);
        let mut proposal = test.ts.take_shared<Proposal>();
        let coin = proposal.return_tokens(&test.clock, test.ts.ctx());

        assert!(coin.value() == 3_000_000 * DECIMALS);

        assert!(proposal.winning_option().borrow() == voting_option::no_option());

        destroy(coin);
        ts::return_shared(proposal);
    };

    test.cleanup();
}

#[test]
fun add_second_proposal_after_first_is_completed() {
    let mut test = prepare_early_voting();
    test.ts.next_tx(ADMIN);
    let cap = test.ts.take_from_sender<NSGovernanceCap>();

    let proposal = test.test_proposal(option::none());

    early_voting::add_proposal(&cap, &mut test.governance, proposal);

    test.clock.increment_for_testing(min_voting_period_ms!() + 2);

    let second_proposal = test.test_proposal(option::none());

    early_voting::add_proposal(&cap, &mut test.governance, second_proposal);

    test.ts.return_to_sender(cap);

    test.cleanup();
}

#[test, expected_failure(abort_code = ::suins_voting::early_voting::ECannotHaveParallelProposals)]
fun test_try_to_add_parallel_proposals() {
    let mut test = prepare_early_voting();
    test.ts.next_tx(ADMIN);
    let cap = test.ts.take_from_sender<NSGovernanceCap>();

    let proposal = test.test_proposal(option::none());

    let second_proposal = test.test_proposal(option::none());
    early_voting::add_proposal(&cap, &mut test.governance, proposal);
    early_voting::add_proposal(&cap, &mut test.governance, second_proposal);

    abort 1337
}

fun test_proposal(setup: &mut TestSetup, end_time_ms: Option<u64>): Proposal {
    proposal_tests::test_proposal(&setup.clock, end_time_ms, setup.ts.ctx())
}

fun cleanup(setup: TestSetup) {
    sui::test_utils::destroy(setup);
}

fun prepare_early_voting(): TestSetup {
    let mut ts = ts::begin(ADMIN);
    governance::init_for_testing(ts.ctx());
    let clock = clock::create_for_testing(ts.ctx());

    ts.next_tx(ADMIN);

    let governance = ts.take_shared<NSGovernance>();

    TestSetup {
        ts,
        governance,
        clock,
    }
}
