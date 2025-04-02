#[test_only]
module suins_voting::test_utils;

// === imports ===

use sui::{
    clock::{Self, Clock},
    coin::{Self, Coin},
    test_scenario::{Self as ts, Scenario},
    test_utils::{Self, assert_eq},
    vec_set::{VecSet},
};
use suins_token::{
    ns::NS,
};
use suins_voting::{
    proposal_v2::{Self, ProposalV2},
    staking_admin::{Self, StakingAdminCap},
    staking_batch::{Self, StakingBatch},
    staking_config::{Self, StakingConfig},
    voting_option::{Self, VotingOption},
};

// === constants ===

const ADMIN: address = @0xaa1;
const INITIAL_TIME: u64 = 86_400_000; // January 2, 1970
const VOTING_PERIOD_MS: u64 = 1000 * 60 * 60 * 24 * 7; // 7 days

// === setup ===

public struct TestSetup {
    clock: Clock,
    config: StakingConfig,
    admin_cap: StakingAdminCap,
}

public fun clock(setup: &TestSetup): &Clock { &setup.clock }
public fun config(setup: &TestSetup): &StakingConfig { &setup.config }
public fun config_mut(setup: &mut TestSetup): &mut StakingConfig { &mut setup.config }
public fun admin_cap(setup: &TestSetup): &StakingAdminCap { &setup.admin_cap }

public fun setup(): (Scenario, TestSetup) {
    let mut ts = ts::begin(ADMIN);
    let mut clock = clock::create_for_testing(ts.ctx());

    clock.set_for_testing(INITIAL_TIME);
    staking_config::init_for_testing(ts.ctx());
    staking_admin::init_for_testing(ts.ctx());

    ts.next_tx(ADMIN);
    let config = ts.take_shared<StakingConfig>();
    let admin_cap = ts::take_from_address<StakingAdminCap>(&ts, ADMIN);

    (
        ts,
        TestSetup { clock, config, admin_cap }
    )
}

// === staking_batch helpers ===

public fun new_batch(
    setup: &mut TestSetup,
    ts: &mut Scenario,
    balance: u64,
    lock_months: u64,
): StakingBatch {
    let balance = mint_ns(ts, balance);
    staking_batch::new(&setup.config, balance, lock_months, &setup.clock, ts.ctx())
}

public fun assert_power(
    setup: &TestSetup,
    batch: &StakingBatch,
    expected_power: u64,
) {
    assert_eq(expected_power, batch.power(&setup.config, &setup.clock));
}

// === proposal_v2 helpers ===

public fun new_proposal(
    setup: &mut TestSetup,
    ts: &mut Scenario,
    options: VecSet<VotingOption>,
    reward_amount: u64,
    voting_period_ms: u64,
): ProposalV2 {
    let reward_coin = mint_ns(ts, reward_amount);
    let end_time_ms = setup.clock.timestamp_ms() + voting_period_ms;

    proposal_v2::new(
        b"Test Title".to_string(),
        b"Test Description".to_string(),
        end_time_ms,
        options,
        reward_coin,
        &setup.clock,
        ts.ctx()
    )
}

public fun new_default_proposal(
    setup: &mut TestSetup,
    ts: &mut Scenario,
): ProposalV2 {
    new_proposal(setup, ts, voting_option::default_options(), 0, VOTING_PERIOD_MS)
}

public fun vote_with_new_batch_and_keep(
    setup: &mut TestSetup,
    ts: &mut Scenario,
    proposal: &mut ProposalV2,
    option: vector<u8>,
    balance: u64,
) {
    let mut batch = new_batch(setup, ts, balance, 0);
    proposal.vote(
        option.to_string(),
        &mut batch,
        &setup.config,
        &setup.clock,
        ts.ctx(),
    );
    batch.keep(ts.ctx());
}

// === sui helpers ===

public fun destroy(setup: TestSetup, ts: Scenario) {
    test_utils::destroy(ts);
    test_utils::destroy(setup);
}

public fun mint_ns(
    ts: &mut Scenario,
    value: u64,
): Coin<NS> {
    return coin::mint_for_testing<NS>(value, ts.ctx())
}

public fun assert_owns_ns(
    ts: &Scenario,
    expected_amount: u64,
) {
    let last_coin = ts.take_from_sender<Coin<NS>>();
    assert_eq(last_coin.value(), expected_amount);
    ts.return_to_sender(last_coin);
}

public fun add_time(
    setup: &mut TestSetup,
    ms: u64,
) {
    setup.clock.increment_for_testing(ms);
}

public fun set_time(
    setup: &mut TestSetup,
    ms: u64,
) {
    setup.clock.set_for_testing(ms);
}
