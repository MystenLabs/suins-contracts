module suins_voting::stats;

// === imports ===

use sui::{
    package::{Self},
    table::{Self, Table},
};

// === structs ===

/// Staking and governance stats. Singleton.
public struct Stats has key {
    id: UID,
    /// TVL = all staked NS + all locked NS
    tvl: u64,
    /// keys are user addresses
    users: Table<address, UserStats>,
}

/// User stats. One per user.
public struct UserStats has store {
    /// how much NS the user is staking + locking currently
    tvl: u64,
    /// how much NS the user earned across all proposals
    rewards: u64,
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
public struct STATS has drop {}

// === initialization ===

fun init(otw: STATS, ctx: &mut TxContext)
{
    let publisher = package::claim(otw, ctx);
    transfer::public_transfer(publisher, ctx.sender());

    let stats = Stats {
        id: object::new(ctx),
        tvl: 0,
        users: table::new(ctx),
    };
    transfer::share_object(stats);
}

// === package functions ===

public(package) fun add_tvl(
    stats: &mut Stats,
    balance: u64,
) {
    stats.tvl = stats.tvl + balance;
}

public(package) fun sub_tvl(
    stats: &mut Stats,
    balance: u64,
) {
    stats.tvl = stats.tvl - balance;
}

public(package) fun add_user_tvl(
    stats: &mut Stats,
    user: address,
    balance: u64,
    ctx: &mut TxContext,
) {
    if (!stats.users.contains(user)) {
        stats.users.add(user, new_user_stats(ctx));
    };

    let user_stats = stats.users.borrow_mut(user);
    user_stats.tvl = user_stats.tvl + balance;
}

public(package) fun sub_user_tvl(
    stats: &mut Stats,
    user: address,
    balance: u64,
) {
    let user_stats = stats.users.borrow_mut(user);
    user_stats.tvl = user_stats.tvl - balance;
}

public(package) fun add_user_vote(
    stats: &mut Stats,
    user: address,
    proposal: address,
    power: u64,
    ctx: &mut TxContext,
) {
    if (!stats.users.contains(user)) {
        stats.users.add(user, new_user_stats(ctx));
    };

    let user_stats = stats.users.borrow_mut(user);

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
    stats: &mut Stats,
    user: address,
    proposal: address,
    reward: u64,
) {
    let user_stats = stats.users.borrow_mut(user);
    user_stats.rewards = user_stats.rewards + reward;

    let proposal_stats = user_stats.proposals.borrow_mut(proposal);
    proposal_stats.reward = proposal_stats.reward + reward;
}

// === private functions ===

fun new_user_stats(ctx: &mut TxContext): UserStats {
    UserStats {
        tvl: 0,
        rewards: 0,
        proposals: table::new(ctx),
    }
}

// === view functions ===

public fun user_tvl(
    stats: &Stats,
    user: address,
): u64 {
    return if (stats.users.contains(user)) {
        stats.users.borrow(user).tvl
    } else {
        0
    }
}

public fun user_rewards(
    stats: &Stats,
    user: address,
): u64 {
    return if (stats.users.contains(user)) {
        stats.users.borrow(user).rewards
    } else {
        0
    }
}

public fun user_proposal_stats(
    stats: &Stats,
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

public fun tvl(stats: &Stats): u64 { stats.tvl }
public fun users(stats: &Stats): &Table<address, UserStats> { &stats.users }

// === test functions ===

#[test_only]
public fun init_for_testing(
    ctx: &mut TxContext,
) {
    let otw = STATS {};
    init(otw, ctx);
}
