module suins_voting::staking_config;

// === imports ===

use sui::{
    package::{Self},
};
use suins_voting::{
    staking_admin::{StakingAdminCap},
};

// === errors ===

const EInvalidCooldownMs: u64 = 100;
const EInvalidMaxLockMonths: u64 = 101;
const EInvalidMaxBoostBps: u64 = 102;
const EInvalidMonthlyBoostBps: u64 = 103;
const EInvalidMinBalance: u64 = 104;

// === constants (initial values, and min/max values the admin can set) ===

public(package) macro fun init_cooldown_ms(): u64 { 1000 * 60 * 60 * 24 * 3 } // 3 days
public(package) macro fun min_cooldown_ms(): u64 { 0 } // instant
public(package) macro fun max_cooldown_ms(): u64 { 1000 * 60 * 60 * 24 * 30 } // 30 days

public(package) macro fun init_max_lock_months(): u64 { 12 }
public(package) macro fun min_max_lock_months(): u64 { 3 } // 3 months
public(package) macro fun max_max_lock_months(): u64 { 36 } // 3 years

public(package) macro fun init_max_boost_bps(): u64 { 300_00 } // 3x
public(package) macro fun min_max_boost_bps(): u64 { 100_00 } // 1x
public(package) macro fun max_max_boost_bps(): u64 { 1000_00 } // 10x

public(package) macro fun init_monthly_boost_bps(): u64 { 110_00 } // 1.1x
public(package) macro fun min_monthly_boost_bps(): u64 { 101_00 } // 1.01x
public(package) macro fun max_monthly_boost_bps(): u64 { 300_00 } // 3x

public(package) macro fun init_min_balance(): u64 { 1_000_000 } // 1 NS
public(package) macro fun min_min_balance(): u64 { 1_000 } // 0.001 NS
public(package) macro fun max_min_balance(): u64 { 1_000_000_000 } // 1000 NS

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
        cooldown_ms: init_cooldown_ms!(),
        max_lock_months: init_max_lock_months!(),
        max_boost_bps: init_max_boost_bps!(),
        monthly_boost_bps: init_monthly_boost_bps!(),
        min_balance: init_min_balance!(),
    };
    transfer::share_object(config);
}

// === public functions ===

// === admin functions ===

public fun set_cooldown_ms(config: &mut StakingConfig, _: &StakingAdminCap, cooldown_ms: u64 ) {
    assert!(cooldown_ms >= min_cooldown_ms!(), EInvalidCooldownMs);
    assert!(cooldown_ms <= max_cooldown_ms!(), EInvalidCooldownMs);
    config.cooldown_ms = cooldown_ms;
}
public fun set_max_lock_months(config: &mut StakingConfig, _: &StakingAdminCap, max_lock_months: u64 ) {
    assert!(max_lock_months >= min_max_lock_months!(), EInvalidMaxLockMonths);
    assert!(max_lock_months <= max_max_lock_months!(), EInvalidMaxLockMonths);
    config.max_lock_months = max_lock_months;
}
public fun set_max_boost_bps(config: &mut StakingConfig, _: &StakingAdminCap, max_boost_bps: u64) {
    assert!(max_boost_bps >= min_max_boost_bps!(), EInvalidMaxBoostBps);
    assert!(max_boost_bps <= max_max_boost_bps!(), EInvalidMaxBoostBps);
    config.max_boost_bps = max_boost_bps;
}
public fun set_monthly_boost_bps(config: &mut StakingConfig, _: &StakingAdminCap, monthly_boost_bps: u64) {
    assert!(monthly_boost_bps >= min_monthly_boost_bps!(), EInvalidMonthlyBoostBps);
    assert!(monthly_boost_bps <= max_monthly_boost_bps!(), EInvalidMonthlyBoostBps);
    config.monthly_boost_bps = monthly_boost_bps;
}
public fun set_min_balance(config: &mut StakingConfig, _: &StakingAdminCap, min_balance: u64 ) {
    assert!(min_balance >= min_min_balance!(), EInvalidMinBalance);
    assert!(min_balance <= max_min_balance!(), EInvalidMinBalance);
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

// === package functions ===

// === private functions ===

// === view functions ===

// === accessors ===

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
