module suins_voting::staking_config;

// === imports ===

use sui::{
    package::{Self},
};
use suins_voting::{
    staking_admin::{StakingAdminCap},
};

// === errors ===

const EInvalidMaxLockMonths: u64 = 0;
const EInvalidMaxBoostBps: u64 = 1;
const EInvalidMonthlyBoostBps: u64 = 2;
const EInvalidMinBalance: u64 = 3;

// === constants (initial values) ===

const COOLDOWN_MS: u64 = 1000 * 60 * 60 * 24 * 3; // 3 days
const MAX_LOCK_MONTHS: u64 = 12;
const MAX_BOOST_BPS: u64 = 300_00; // 3x
const MONTHLY_BOOST_BPS: u64 = 110_00; // 1.1x
const MIN_BALANCE: u64 = 1_000_000; // 1 NS

// === structs ===

/// Staking configuration. Singleton.
public struct StakingConfig has key {
    id: UID,
    /// how long it takes to unstake a batch
    cooldown_ms: u64,
    /// max number of months a batch can be staked for
    max_lock_months: u64,
    /// total power multiplier when locking a batch for `max_lock_months`
    max_boost_bps: u64,
    /// monthly power multiplier for staked/locked batches
    monthly_boost_bps: u64,
    /// minimum NS balance allowed in a batch
    min_balance: u64,
}

/// One-Time Witness
public struct STAKING_CONFIG has drop {}

// === initialization ===

fun init(otw: STAKING_CONFIG, ctx: &mut TxContext)
{
    let publisher = package::claim(otw, ctx);
    transfer::public_transfer(publisher, ctx.sender());

    let config = StakingConfig {
        id: object::new(ctx),
        cooldown_ms: COOLDOWN_MS,
        max_lock_months: MAX_LOCK_MONTHS,
        max_boost_bps: MAX_BOOST_BPS,
        monthly_boost_bps: MONTHLY_BOOST_BPS,
        min_balance: MIN_BALANCE,
    };
    transfer::share_object(config);
}

// === public functions ===

// === admin functions ===

// === package functions ===

// === private functions ===

public fun set_cooldown_ms(config: &mut StakingConfig, _: &StakingAdminCap, cooldown_ms: u64 ) {
    config.cooldown_ms = cooldown_ms;
}
public fun set_max_lock_months(config: &mut StakingConfig, _: &StakingAdminCap, max_lock_months: u64 ) {
    assert!(max_lock_months > 0, EInvalidMaxLockMonths);
    config.max_lock_months = max_lock_months;
}
public fun set_max_boost_bps(config: &mut StakingConfig, _: &StakingAdminCap, max_boost_bps: u64) {
    assert!(max_boost_bps > 0, EInvalidMaxBoostBps);
    config.max_boost_bps = max_boost_bps;
}
public fun set_monthly_boost_bps(config: &mut StakingConfig, _: &StakingAdminCap, monthly_boost_bps: u64) {
    assert!(monthly_boost_bps >= 10000, EInvalidMonthlyBoostBps); // at least 1x
    config.monthly_boost_bps = monthly_boost_bps;
}
public fun set_min_balance(config: &mut StakingConfig, _: &StakingAdminCap, min_balance: u64 ) {
    assert!(min_balance > 0, EInvalidMinBalance);
    config.min_balance = min_balance;
}
public fun set_all(
    config: &mut StakingConfig,
    _: &StakingAdminCap,
    cooldown_ms: u64,
    max_lock_months: u64,
    max_boost_bps: u64,
    monthly_boost_bps: u64,
    min_balance: u64,
) {
    set_cooldown_ms(config, _, cooldown_ms);
    set_max_lock_months(config, _, max_lock_months);
    set_max_boost_bps(config, _, max_boost_bps);
    set_monthly_boost_bps(config, _, monthly_boost_bps);
    set_min_balance(config, _, min_balance);
}

// === view functions ===

// === accessors ===

public fun id(config: &StakingConfig): ID { config.id.to_inner() }
public fun cooldown_ms(config: &StakingConfig): u64 { config.cooldown_ms }
public fun max_lock_months(config: &StakingConfig): u64 { config.max_lock_months }
public fun max_boost_bps(config: &StakingConfig): u64 { config.max_boost_bps }
public fun monthly_boost_bps(config: &StakingConfig): u64 { config.monthly_boost_bps }
public fun min_balance(config: &StakingConfig): u64 { config.min_balance }

// === method aliases ===

// === events ===

// === test functions ===

#[test_only]
public fun init_for_testing(
    ctx: &mut TxContext,
) {
    let otw = STAKING_CONFIG {};
    init(otw, ctx);
}

#[test_only]
public fun new_for_testing(
    cooldown_ms: u64,
    max_lock_months: u64,
    max_boost_bps: u64,
    monthly_boost_bps: u64,
    min_balance: u64,
    ctx: &mut TxContext,
): StakingConfig {
    StakingConfig {
        id: object::new(ctx),
        cooldown_ms,
        max_lock_months,
        max_boost_bps,
        monthly_boost_bps,
        min_balance,
    }
}

#[test_only]
public fun new_for_testing_default(
    ctx: &mut TxContext,
): StakingConfig {
    StakingConfig {
        id: object::new(ctx),
        cooldown_ms: COOLDOWN_MS,
        max_lock_months: MAX_LOCK_MONTHS,
        max_boost_bps: MAX_BOOST_BPS,
        monthly_boost_bps: MONTHLY_BOOST_BPS,
        min_balance: MIN_BALANCE,
    }
}


// === test functions ===
