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
    total_balance: u64,
    user_rewards: Table<address, u64>,
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
        total_balance: 0,
        user_rewards: table::new(ctx),
    };
    transfer::share_object(stats);
}

// === public functions ===

// === admin functions ===

// === package functions ===

public(package) fun add_balance(
    stats: &mut StakingStats,
    balance: u64,
) {
    stats.total_balance = stats.total_balance + balance;
}

public(package) fun sub_balance(
    stats: &mut StakingStats,
    balance: u64,
) {
    stats.total_balance = stats.total_balance - balance;
}

public(package) fun add_user_reward(
    stats: &mut StakingStats,
    user: address,
    reward: u64,
) {
    if (!stats.user_rewards.contains(user)) {
        stats.user_rewards.add(user, reward);
    } else {
        let old_reward = stats.user_rewards.borrow_mut(user);
        *old_reward = *old_reward + reward;
    }
}

// === private functions ===

// === view functions ===

// === accessors ===

public fun id(stats: &StakingStats): ID { stats.id.to_inner() }
public fun total_balance(stats: &StakingStats): u64 { stats.total_balance }

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
