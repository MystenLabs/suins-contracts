module suins_bbb::bbb_aftermath;

use std::{
    type_name::{Self,TypeName},
};
use sui::{
    clock::Clock,
};
use pyth::{
    price_info::PriceInfoObject,
};
use amm::{
    swap::swap_exact_in,
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
    bbb_pyth::calc_expected_coin_out,
    bbb_vault::BBBVault,
};

// === errors ===

const EInvalidPool: u64 = 100;
const ECoinInPriceFeedIdMismatch: u64 = 101;
const ECoinOutPriceFeedIdMismatch: u64 = 102;
const EInvalidCoinInType: u64 = 103;
const EInvalidCoinOutType: u64 = 104;

// === structs ===

/// Aftermath swap configuration.
public struct AftermathSwapConfig has copy, drop, store {
    /// Type of coin to be swapped into `coin_out_type`
    coin_in_type: TypeName,
    /// Type of coin to be received from the swap
    coin_out_type: TypeName,
    /// Number of decimals used by `coin_in_type`
    coin_in_decimals: u8,
    /// Number of decimals used by `coin_out_type`
    coin_out_decimals: u8,
    /// Pyth `PriceFeed` identifier for `coin_in_type` without the `0x` prefix
    coin_in_feed_id: vector<u8>,
    /// Pyth `PriceFeed` identifier for `coin_out_type` without the `0x` prefix
    coin_out_feed_id: vector<u8>,
    /// Aftermath `Pool` object `ID`
    pool_id: ID,
    /// Slippage tolerance as (1 - slippage) in 18-decimal fixed point.
    /// E.g., 2% slippage = 980_000_000_000_000_000 (represents 0.98)
    slippage: u64,
    /// How old the Pyth price can be, in seconds.
    max_age_secs: u64,
}

// === getters ===

public fun coin_in_type(config: &AftermathSwapConfig): &TypeName { &config.coin_in_type }
public fun coin_out_type(config: &AftermathSwapConfig): &TypeName { &config.coin_out_type }
public fun coin_in_decimals(config: &AftermathSwapConfig): u8 { config.coin_in_decimals }
public fun coin_out_decimals(config: &AftermathSwapConfig): u8 { config.coin_out_decimals }
public fun coin_in_feed_id(config: &AftermathSwapConfig): &vector<u8> { &config.coin_in_feed_id }
public fun coin_out_feed_id(config: &AftermathSwapConfig): &vector<u8> { &config.coin_out_feed_id }
public fun pool_id(config: &AftermathSwapConfig): &ID { &config.pool_id }
public fun slippage(config: &AftermathSwapConfig): u64 { config.slippage }
public fun max_age_secs(config: &AftermathSwapConfig): u64 { config.max_age_secs }

// === public functions ===

/// Swap `coin_in` for an equal-valued amount of `Coin<CoinOut>` using Aftermath's AMM.
/// Protocol fees are charged on the Coin being swapped in.
/// Resulting `Coin<CoinOut>` is deposited into the `BBBVault`.
///
/// Aborts:
/// - `EZeroValue`: `coin_in` has a value of zero.
/// - `ESlippage`: `actual_amount_out` lies outside `acceptable_slippage`.
/// - `EZeroAmountOut`: `amount_in` is worth zero amount of `Coin<CoinOut>`.
/// - `EInvalidSwapAmountOut`: the swap would result in more than `MAX_SWAP_AMOUNT_OUT`
///    worth of `Coin<CoinOut>` exiting the Pool.
public fun swap_aftermath<L, CoinIn, CoinOut>(
    // ours
    conf: &AftermathSwapConfig,
    vault: &mut BBBVault,
    // pyth
    coin_in_price_info_obj: &PriceInfoObject,
    coin_out_price_info_obj: &PriceInfoObject,
    // aftermath
    pool: &mut Pool<L>,
    pool_registry: &PoolRegistry,
    protocol_fee_vault: &ProtocolFeeVault,
    treasury: &mut Treasury,
    insurance_fund: &mut InsuranceFund,
    referral_vault: &ReferralVault,
    // sui
    clock: &Clock,
    ctx: &mut TxContext,
) {
    // check price feed ids match the config
    let coin_in_price_info = coin_in_price_info_obj.get_price_info_from_price_info_object();
    let coin_out_price_info = coin_out_price_info_obj.get_price_info_from_price_info_object();
    assert!(
        coin_in_price_info.get_price_identifier().get_bytes() == conf.coin_in_feed_id(),
        ECoinInPriceFeedIdMismatch,
    );
    assert!(
        coin_out_price_info.get_price_identifier().get_bytes() == conf.coin_out_feed_id(),
        ECoinOutPriceFeedIdMismatch,
    );

    // check pool id and coin types match the config
    assert!(object::id(pool) == conf.pool_id(), EInvalidPool);
    assert!(
        pool.type_names().contains(&type_name::get<CoinIn>().into_string()),
        EInvalidCoinInType,
    );
    assert!(
        pool.type_names().contains(&type_name::get<CoinOut>().into_string()),
        EInvalidCoinOutType,
    );

    // withdraw all CoinIn from vault
    let balance = vault.withdraw<CoinIn>();
    let coin_in = balance.into_coin(ctx);

    // return early if the vault is empty
    if (coin_in.value() == 0) {
        coin_in.destroy_zero();
        return
    };

    // calculate expected CoinOut amount
    let expected_coin_out = calc_expected_coin_out(
        coin_in_price_info_obj,
        coin_out_price_info_obj,
        conf.coin_in_decimals,
        conf.coin_out_decimals,
        coin_in.value(),
        conf.max_age_secs,
        clock,
    );

    // swap CoinIn for CoinOut
    let coin_out = swap_exact_in<L, CoinIn, CoinOut>(
        pool,
        pool_registry,
        protocol_fee_vault,
        treasury,
        insurance_fund,
        referral_vault,
        coin_in,
        expected_coin_out,
        conf.slippage,
        ctx,
    );

    // deposit CoinOut into vault
    vault.deposit<CoinOut>(coin_out.into_balance());
}

// === package functions ===

public(package) fun new_aftermath_swap_config(
    coin_in_type: TypeName,
    coin_out_type: TypeName,
    coin_in_decimals: u8,
    coin_out_decimals: u8,
    coin_in_feed_id: vector<u8>,
    coin_out_feed_id: vector<u8>,
    pool_id: ID,
    slippage: u64,
    max_age_secs: u64,
): AftermathSwapConfig {
    AftermathSwapConfig {
        coin_in_type,
        coin_out_type,
        coin_in_decimals,
        coin_out_decimals,
        coin_in_feed_id,
        coin_out_feed_id,
        pool_id,
        slippage,
        max_age_secs,
    }
}
