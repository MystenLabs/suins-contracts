module suins_voting::staking_stats;

// === imports ===

use sui::{
    package::{Self},
    table::{Self, Table},
};

// === errors ===

// === constants ===

// === structs ===

/// Staking stats. Singleton.
public struct StakingStats has key {
    id: UID,
    /// TVL = all staked NS + all locked NS
    tvl: u64,
    /// keys are user addresses
    users: Table<address, UserStats>,
}

/// User stats. One per user.
public struct UserStats has store {
    /// how much voting power the user voted with across all proposals
    total_power: u64,
    /// how much NS the user earned across all proposals
    total_reward: u64,
    /// keys are proposal addresses
    proposals: Table<address, UserProposalStats>,
}

/// User participation in a proposal. Many per user.
public struct UserProposalStats has copy, drop, store {
    /// how much voting power the user voted with in this proposal
    power: u64,
    /// how much NS the user earned in this proposal
    reward: u64,
}

/// One-Time Witness
public struct STAKING_STATS has drop {}

// === initialization ===

fun init(otw: STAKING_STATS, ctx: &mut TxContext)
{
    let publisher = package::claim(otw, ctx);
    transfer::public_transfer(publisher, ctx.sender());

    let stats = StakingStats {
        id: object::new(ctx),
        tvl: 0,
        users: table::new(ctx),
    };
    transfer::share_object(stats);
}

// === public functions ===

// === admin functions ===

// === package functions ===

public(package) fun add_tvl(
    stats: &mut StakingStats,
    balance: u64,
) {
    stats.tvl = stats.tvl + balance;
}

public(package) fun sub_tvl(
    stats: &mut StakingStats,
    balance: u64,
) {
    stats.tvl = stats.tvl - balance;
}

public(package) fun add_user_power(
    stats: &mut StakingStats,
    user: address,
    proposal: address,
    power: u64,
    ctx: &mut TxContext,
) {
    if (!stats.users.contains(user)) {
        stats.users.add(user, UserStats {
            total_power: 0,
            total_reward: 0,
            proposals: table::new(ctx),
        });
    };

    let user_stats = stats.users.borrow_mut(user);
    user_stats.total_power = user_stats.total_power + power;

    if (!user_stats.proposals.contains(proposal)) {
        user_stats.proposals.add(proposal, UserProposalStats {
            power: 0,
            reward: 0,
        });
    };

    let proposal_stats = user_stats.proposals.borrow_mut(proposal);
    proposal_stats.power = proposal_stats.power + power;
}

public(package) fun add_user_reward(
    stats: &mut StakingStats,
    user: address,
    proposal: address,
    reward: u64,
) {
    let user_stats = stats.users.borrow_mut(user);
    user_stats.total_reward = user_stats.total_reward + reward;

    let proposal_stats = user_stats.proposals.borrow_mut(proposal);
    proposal_stats.reward = proposal_stats.reward + reward;
}

// === private functions ===

// === view functions ===

public fun user_total_power(
    stats: &StakingStats,
    user: address,
): u64 {
    return if (stats.users.contains(user)) {
        stats.users.borrow(user).total_power
    } else {
        0
    }
}

public fun user_total_reward(
    stats: &StakingStats,
    user: address,
): u64 {
    return if (stats.users.contains(user)) {
        stats.users.borrow(user).total_reward
    } else {
        0
    }
}

public fun user_proposal_stats(
    stats: &StakingStats,
    user: address,
    proposal: address,
): (u64, u64) {
    if (!stats.users.contains(user)) {
        return (0, 0)
    };
    let user_stats = stats.users.borrow(user);
    if (!user_stats.proposals.contains(proposal)) {
        return (0, 0)
    };
    let proposal_stats = user_stats.proposals.borrow(proposal);
    (proposal_stats.power, proposal_stats.reward)
}

// === accessors ===

public fun tvl(stats: &StakingStats): u64 { stats.tvl }
public fun users(stats: &StakingStats): &Table<address, UserStats> { &stats.users }

// === method aliases ===

// === events ===

// === test functions ===

#[test_only]
public fun init_for_testing(
    ctx: &mut TxContext,
) {
    let otw = STAKING_STATS {};
    init(otw, ctx);
}
