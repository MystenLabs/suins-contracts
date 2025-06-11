module suins_bbb::bbb_config;

// === imports ===

use std::{
    string::{String},
    type_name::{Self, TypeName},
};
use sui::{
    coin::{Coin},
    event::{emit},
};
use amm::{
    swap::{swap_exact_in},
    pool::Pool,
    pool_registry::PoolRegistry,
};
use protocol_fee_vault::{
    vault::ProtocolFeeVault,
};
use treasury::{
    treasury::Treasury,
};
use insurance_fund::{
    insurance_fund::InsuranceFund,
};
use referral_vault::{
    referral_vault::ReferralVault,
};
use suins_bbb::{
    bbb_admin::{BBBAdminCap},
    bbb_vault::{BBBVault},
};

// === errors ===

const EInvalidBurnBps: u64 = 100;
const ENotBurnable: u64 = 101;
const ENoAftermathSwap: u64 = 102;
const EInvalidPool: u64 = 103;

// === constants ===

macro fun burn_address(): address { @0x0 }

// === constants: initial config values ===

macro fun init_burn_bps(): u64 { 80_00 } // 80%

// === structs ===

/// Buy Back & Burn configuration. Singleton.
public struct BBBConfig has key {
    id: UID,
    /// Percentage of revenue that will be burned, in basis points
    burn_bps: u64,
    /// Coin types that can be burned
    burn_types: vector<TypeName>,
    /// Aftermath swap configurations
    af_swaps: vector<AftermathSwapConfig>,
}

public struct AftermathSwapConfig has copy, drop, store {
    coin_type: TypeName,
    pool_id: ID,
}

/// One-Time Witness
public struct BBB_CONFIG has drop {}

// === initialization ===

fun init(
    _otw: BBB_CONFIG,
    ctx: &mut TxContext,
) {
    let config = BBBConfig {
        id: object::new(ctx),
        burn_bps: init_burn_bps!(),
        burn_types: vector::empty(),
        af_swaps: vector::empty(),
    };
    transfer::share_object(config);
}

// === public functions ===

public fun burn<C>(
    config: &BBBConfig,
    vault: &mut BBBVault,
    ctx: &mut TxContext,
) {
    assert!(config.is_burnable<C>(), ENotBurnable);

    let balance = vault.withdraw<C>();
    if (balance.value() == 0) {
        balance.destroy_zero();
        return
    };

    transfer::public_transfer(
        balance.into_coin(ctx), burn_address!()
    )
}

public fun swap_aftermath<L, CoinIn, CoinOut>(
    config: &BBBConfig,
    vault: &mut BBBVault,
    // Aftermath `swap_exact_in` parameters
    pool: &mut Pool<L>,
    pool_registry: &PoolRegistry,
    protocol_fee_vault: &ProtocolFeeVault,
    treasury: &mut Treasury,
    insurance_fund: &mut InsuranceFund,
    referral_vault: &ReferralVault,
    expected_coin_out: u64, // MAYBE remove since can't be trusted anyway
    allowable_slippage: u64, // TODO move to BBBConfig
    ctx: &mut TxContext,
) {
    let swap_opt = get_aftermath_swap_config<CoinIn>(config);
    assert!(swap_opt.is_some(), ENoAftermathSwap);

    let swap = swap_opt.destroy_some();
    assert!(swap.pool_id == object::id(pool), EInvalidPool);

    let balance = vault.withdraw<CoinIn>();
    if (balance.value() == 0) {
        balance.destroy_zero();
        return
    };

    let coin_in = balance.into_coin(ctx);
    let coin_out = swap_exact_in<L, CoinIn, CoinOut>(
        pool,
        pool_registry,
        protocol_fee_vault,
        treasury,
        insurance_fund,
        referral_vault,
        coin_in,
        expected_coin_out,
        allowable_slippage,
        ctx,
    );

    vault.deposit<CoinOut>(coin_out.into_balance());
}

/// === public helpers ===

public fun is_burnable<C>(
    config: &BBBConfig,
): bool {
    config.burn_types.any!(|coin_type| {
        coin_type == type_name::get<C>()
    })
}

public fun get_aftermath_swap_config<C>(
    config: &BBBConfig,
): Option<AftermathSwapConfig> {
    let target_type = type_name::get<C>();

    let idx = config.af_swaps.find_index!(|swap| {
        swap.coin_type == target_type
    });

    if (idx.is_none()) {
        option::none()
    } else {
        option::some(config.af_swaps[idx.destroy_some()])
    }
}

// === public admin functions ===

public fun add_burn_action<C>(
    config: &mut BBBConfig,
    _cap: &BBBAdminCap,
) {
    // TODO: check if already exists
    config.burn_types.push_back(type_name::get<C>());
}

public fun add_aftermath_swap<C, L>(
    config: &mut BBBConfig,
    _cap: &BBBAdminCap,
    pool: &Pool<L>,
) {
    // TODO: check if already exists
    config.af_swaps.push_back(AftermathSwapConfig {
        coin_type: type_name::get<C>(),
        pool_id: object::id(pool),
    });
}

// === setters (admin only) ===

public fun set_burn_bps(config: &mut BBBConfig, _: &BBBAdminCap, burn_bps: u64) {
    assert!(burn_bps <= 100_00, EInvalidBurnBps);
    emit_event(b"burn_bps", config.burn_bps, burn_bps);
    config.burn_bps = burn_bps;
}

// === getters TODO ===

// === private functions ===

fun emit_event(
    property: vector<u8>,
    old_value: u64,
    new_value: u64,
) {
    emit(EventConfigChange {
        property: property.to_string(),
        old_value,
        new_value,
    });
}

// === accessors ===

public fun id(config: &BBBConfig): ID { config.id.to_inner() }
public fun burn_bps(config: &BBBConfig): u64 { config.burn_bps }

// === events ===

public struct EventConfigChange has copy, drop {
    property: String,
    old_value: u64,
    new_value: u64,
}

// === test functions ===

#[test_only]
public fun init_for_testing(
    ctx: &mut TxContext,
) {
    let otw = BBB_CONFIG {};
    init(otw, ctx);
}
