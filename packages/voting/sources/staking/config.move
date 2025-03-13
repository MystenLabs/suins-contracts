module suins_voting::staking_config;

// === imports ===

use sui::{
    package::{Self},
};
use suins_voting::{
    staking_admin::{StakingAdminCap},
    staking_constants::{day_ms},
};

// === errors ===

const EInvalidMaxLockMonths: u64 = 0;
const EInvalidMaxBoostPct: u64 = 1;
const EInvalidMonthlyBoostPct: u64 = 2;
const EInvalidMinBalance: u64 = 3;

// === constants ===

// === structs ===

/// Staking configuration. Singleton.
public struct StakingConfig has key {
    id: UID,
    /// how long it takes to unstake a batch
    cooldown_ms: u64,
    /// max number of months a batch can be staked for
    max_lock_months: u64,
    /// total power multiplier when locking a batch for `max_lock_months`
    max_boost_pct: u64,
    /// monthly power multiplier for staked/locked batches
    monthly_boost_pct: u64,
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
        cooldown_ms: 3 * day_ms!(),
        max_lock_months: 12,
        max_boost_pct: 300, // 300% / 3.0x
        monthly_boost_pct: 110, // 110% / 1.1x
        min_balance: 1000, // 0.001 NS
    };
    transfer::share_object(config);
}

// === public functions ===

// === admin functions ===

// === package functions ===

// === private functions ===

public fun set_cooldown_ms(c: &mut StakingConfig, _: &StakingAdminCap, cooldown_ms: u64 ) {
    c.cooldown_ms = cooldown_ms;
}
public fun set_max_lock_months(c: &mut StakingConfig, _: &StakingAdminCap, max_lock_months: u64 ) {
    assert!(max_lock_months > 0, EInvalidMaxLockMonths);
    c.max_lock_months = max_lock_months;
}
public fun set_max_boost_pct(c: &mut StakingConfig, _: &StakingAdminCap, max_boost_pct: u64 ) {
    assert!(max_boost_pct > 0, EInvalidMaxBoostPct);
    c.max_boost_pct = max_boost_pct;
}
public fun set_monthly_boost_pct(c: &mut StakingConfig, _: &StakingAdminCap, monthly_boost_pct: u64 ) {
    assert!(monthly_boost_pct >= 100, EInvalidMonthlyBoostPct);
    c.monthly_boost_pct = monthly_boost_pct;
}
public fun set_min_balance(c: &mut StakingConfig, _: &StakingAdminCap, min_balance: u64 ) {
    assert!(min_balance > 0, EInvalidMinBalance);
    c.min_balance = min_balance;
}
public fun set_all(
    config: &mut StakingConfig,
    _: &StakingAdminCap,
    cooldown_ms: u64,
    max_lock_months: u64,
    max_boost_pct: u64,
    monthly_boost_pct: u64,
    min_balance: u64,
) {
    set_cooldown_ms(config, _, cooldown_ms);
    set_max_lock_months(config, _, max_lock_months);
    set_max_boost_pct(config, _, max_boost_pct);
    set_monthly_boost_pct(config, _, monthly_boost_pct);
    set_min_balance(config, _, min_balance);
}

// === view functions ===

// === accessors ===

public fun id(config: &StakingConfig): ID { config.id.to_inner() }
public fun cooldown_ms(config: &StakingConfig): u64 { config.cooldown_ms }
public fun max_lock_months(config: &StakingConfig): u64 { config.max_lock_months }
public fun max_boost_pct(config: &StakingConfig): u64 { config.max_boost_pct }
public fun monthly_boost_pct(config: &StakingConfig): u64 { config.monthly_boost_pct }
public fun min_balance(config: &StakingConfig): u64 { config.min_balance }

// === method aliases ===

// === events ===

#[test_only]
public fun init_for_testing(
    ctx: &mut TxContext,
) {
    let otw = STAKING_CONFIG {};
    init(otw, ctx);
}

// === test functions ===
