#[test_only]
module suins_voting::test_utils;

// === imports ===

use std::{
    string::{String},
};
use sui::{
    balance::{Balance},
    clock::{Self, Clock},
    coin::{Self, Coin},
    random::{Self},
    test_scenario::{Self as ts, Scenario},
    test_utils::{Self, assert_eq},
    vec_set::{VecSet},
};
use suins_token::{
    ns::NS,
};
use suins_voting::{
    constants::{min_voting_period_ms},
    governance::{Self, NSGovernance},
    proposal_v2::{Self, ProposalV2},
    staking_admin::{Self},
    staking_admin::{StakingAdminCap},
    staking_batch::{Self, StakingBatch},
    staking_config::{Self, Self as cnf, StakingConfig},
    staking_stats::{Self, StakingStats},
    voting_option::{Self, VotingOption},
};

// === constants ===

public macro fun admin_addr(): address { @0xaa1 }
public macro fun reward_amount(): u64 { 1_000_000 }

const INITIAL_TIME: u64 = 86_400_000; // January 2, 1970

// === setup ===

public struct TestSetup {
    ts: Scenario,
    clock: Clock,
    gov: NSGovernance,
    config: StakingConfig,
    stats: StakingStats,
}

public fun ts(setup: &TestSetup): &Scenario { &setup.ts }
public fun clock(setup: &TestSetup): &Clock { &setup.clock }
public fun gov_mut(setup: &mut TestSetup): &mut NSGovernance { &mut setup.gov }
public fun config(setup: &TestSetup): &StakingConfig { &setup.config }
public fun config_mut(setup: &mut TestSetup): &mut StakingConfig { &mut setup.config }
public fun stats(setup: &TestSetup): &StakingStats { &setup.stats }

/**
 * Setup a test with random config values
 */
public fun setup(): TestSetup {
    setup_internal(true)
}

/**
 * Setup a test with default config values
 */
public fun setup_default_config(): TestSetup {
    setup_internal(false)
}

fun setup_internal(random_config: bool): TestSetup {
    let mut ts = ts::begin(admin_addr!());

    let mut clock = clock::create_for_testing(ts.ctx());
    clock.set_for_testing(INITIAL_TIME);

    governance::init_for_testing(ts.ctx());
    staking_admin::init_for_testing(ts.ctx());
    staking_config::init_for_testing(ts.ctx());
    staking_stats::init_for_testing(ts.ctx());

    ts.next_tx(admin_addr!());
    let gov = ts.take_shared<NSGovernance>();
    let mut config = ts.take_shared<StakingConfig>();
    let stats = ts.take_shared<StakingStats>();

    if (random_config) {
        let mut gen = random::new_generator_for_testing();
        let cap = ts.take_from_sender<StakingAdminCap>();
        config.set_cooldown_ms(&cap, gen.generate_u64_in_range(
            cnf::min_cooldown_ms!(), cnf::max_cooldown_ms!())
        );
        config.set_max_lock_months(&cap, gen.generate_u64_in_range(
            cnf::min_max_lock_months!(), cnf::max_max_lock_months!())
        );
        config.set_max_boost_bps(&cap, gen.generate_u64_in_range(
            cnf::min_max_boost_bps!(), cnf::max_max_boost_bps!())
        );
        config.set_monthly_boost_bps(&cap, gen.generate_u64_in_range(
            cnf::min_monthly_boost_bps!(), cnf::max_monthly_boost_bps!())
        );
        config.set_min_balance(&cap, gen.generate_u64_in_range(
            cnf::min_min_balance!(), cnf::max_min_balance!())
        );
        ts.return_to_sender(cap);
        ts.next_tx(admin_addr!());
    };

    TestSetup { ts, clock, gov, config, stats }
}

// === staking_batch helpers ===

public fun batch__new(
    setup: &mut TestSetup,
    balance: u64,
    lock_months: u64,
): StakingBatch {
    let balance = setup.mint_ns(balance);
    staking_batch::new(
        &setup.config,
        &mut setup.stats,
        balance,
        lock_months,
        &setup.clock,
        setup.ts.ctx(),
    )
}

public fun batch__new__min_bal(
    setup: &mut TestSetup,
    lock_months: u64,
): StakingBatch {
    let balance = setup.config().min_balance();
    setup.batch__new(balance, lock_months)
}

public fun batch__unstake(
    setup: &mut TestSetup,
    batch: StakingBatch,
): Balance<NS> {
    batch.unstake(&mut setup.stats, &setup.clock, setup.ts.ctx())
}

public fun batch__keep(
    setup: &mut TestSetup,
    batch: StakingBatch,
) {
    batch.keep(setup.ts.ctx());
}

public fun assert_power(
    setup: &TestSetup,
    batch: &StakingBatch,
    expected_power: u64,
) {
    assert_eq(expected_power, batch.power(&setup.config, &setup.clock));
}

public fun batch__admin_new(
    setup: &mut TestSetup,
    balance: u64,
    start_ms: u64,
    end_ms: u64,
): StakingBatch {
    let cap = setup.ts().take_from_sender<StakingAdminCap>();
    let coin = setup.mint_ns(balance);
    let batch = staking_batch::admin_new(
        &cap,
        &mut setup.stats,
        coin,
        start_ms,
        end_ms,
        setup.ts.ctx(),
    );
    setup.ts.return_to_sender(cap);
    batch
}

public fun batch__admin_transfer(
    setup: &mut TestSetup,
    batch: StakingBatch,
    recipient: address,
) {
    let cap = setup.ts().take_from_sender<StakingAdminCap>();
    staking_batch::admin_transfer(&cap, batch, recipient);
    setup.ts.return_to_sender(cap);
}

// === proposal_v2 helpers ===

public fun proposal__new(
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

public fun proposal__new__end_time(
    setup: &mut TestSetup,
    voting_period_ms: Option<u64>,
): ProposalV2 {
    setup.proposal__new(
        voting_option::default_options(),
        reward_amount!(),
        voting_period_ms.destroy_or!(min_voting_period_ms!()),
    )
}

public fun proposal__new__default(
    setup: &mut TestSetup,
): ProposalV2 {
    setup.proposal__new(
        voting_option::default_options(),
        reward_amount!(),
        min_voting_period_ms!(),
    )
}

public fun proposal__vote(
    setup: &mut TestSetup,
    proposal: &mut ProposalV2,
    batch: &mut StakingBatch,
    opt: String,
) {
    proposal.vote(
        &setup.config,
        &mut setup.stats,
        batch,
        opt,
        &setup.clock,
        setup.ts.ctx(),
    );
}

public fun proposal__vote__new_batch_and_keep(
    setup: &mut TestSetup,
    proposal: &mut ProposalV2,
    option: vector<u8>,
    balance: u64,
) {
    let mut batch = setup.batch__new(balance, 0);
    proposal.vote(
        &setup.config,
        &mut setup.stats,
        &mut batch,
        option.to_string(),
        &setup.clock,
        setup.ts.ctx(),
    );
    batch.keep(setup.ts.ctx());
}

public fun proposal__distribute_rewards(
    setup: &mut TestSetup,
    proposal: &mut ProposalV2,
) {
    proposal.distribute_rewards(&mut setup.stats, &setup.clock, setup.ts.ctx());
}

public fun proposal__claim_reward(
    setup: &mut TestSetup,
    proposal: &mut ProposalV2,
): Balance<NS> {
    proposal.claim_reward(&mut setup.stats, &setup.clock, setup.ts.ctx())
}

// === sui helpers ===

public fun destroy(setup: TestSetup) {
    test_utils::destroy(setup);
}

public fun mint_ns(
    setup: &mut TestSetup,
    value: u64,
): Coin<NS> {
    return coin::mint_for_testing<NS>(value, setup.ts.ctx())
}

public fun assert_owns_ns(
    setup: &mut TestSetup,
    expected_amount: u64,
) {
    let last_coin = setup.ts.take_from_sender<Coin<NS>>();
    assert_eq(last_coin.value(), expected_amount);
    setup.ts.return_to_sender(last_coin);
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

public fun next_tx(
    setup: &mut TestSetup,
    sender: address,
) {
    setup.ts.next_tx(sender);
}

public fun random_addr(setup: &mut TestSetup): address {
    setup.ts.ctx().fresh_object_address()
}
