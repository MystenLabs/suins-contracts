module suins_bbb::bbb_swap_aftermath;

use std::{
    type_name,
};
use sui::{
    clock::Clock,
};
use pyth::{
    price_info::PriceInfoObject,
    pyth::Self,
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
    bbb_config::{AftermathSwapConfig, BBBConfig, get_aftermath_swap_config},
    bbb_vault::BBBVault,
};

// === errors ===

const ENoAftermathSwap: u64 = 100;
const EInvalidPool: u64 = 101;
const ECoinInPriceFeedIdMismatch: u64 = 102;
const ECoinOutPriceFeedIdMismatch: u64 = 103;

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
    config: &BBBConfig,
    vault: &mut BBBVault,
    pool: &mut Pool<L>,
    pool_registry: &PoolRegistry,
    protocol_fee_vault: &ProtocolFeeVault,
    treasury: &mut Treasury,
    insurance_fund: &mut InsuranceFund,
    referral_vault: &ReferralVault,
    ctx: &mut TxContext,
) {
    let swap_opt = get_aftermath_swap_config<CoinIn>(config);
    assert!(swap_opt.is_some(), ENoAftermathSwap);

    let swap_conf = swap_opt.destroy_some();
    assert!(swap_conf.pool_id() == object::id(pool), EInvalidPool);

    let expected_coin_out = 123; // TODO: call oracle

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
        config.slippage(),
        ctx,
    );

    vault.deposit<CoinOut>(coin_out.into_balance());
}

fun calc_expected_coin_out(
    bbb_conf: &BBBConfig,
    swap_conf: &AftermathSwapConfig,
    coin_in_price_info_obj: &PriceInfoObject,
    coin_out_price_info_obj: &PriceInfoObject,
    coin_in_amount: u64,
    clock: &Clock,
): u64 {
    // check that the price feed ids match the swap configuration
    let coin_in_price_info = coin_in_price_info_obj.get_price_info_from_price_info_object();
    let coin_out_price_info = coin_out_price_info_obj.get_price_info_from_price_info_object();
    assert!(
        coin_in_price_info.get_price_identifier().get_bytes() == swap_conf.coin_in_feed_id(),
        ECoinInPriceFeedIdMismatch,
    );
    assert!(
        coin_out_price_info.get_price_identifier().get_bytes() == swap_conf.coin_out_feed_id(),
        ECoinOutPriceFeedIdMismatch,
    );

    // get the price of both coins in USD
    let coin_in_price_usd = pyth::get_price_no_older_than(
        coin_in_price_info_obj,
        clock,
        bbb_conf.max_age_secs(),
    );
    let coin_out_price_usd = pyth::get_price_no_older_than(
        coin_out_price_info_obj,
        clock,
        bbb_conf.max_age_secs(),
    );

    // extract price magnitudes and decimal exponents from the `Price` structs
    let coin_in_price_mag = coin_in_price_usd.get_price().get_magnitude_if_positive();
    let coin_out_price_mag = coin_out_price_usd.get_price().get_magnitude_if_positive();
    let coin_in_price_dec = coin_in_price_usd.get_expo().get_magnitude_if_negative() as u8;
    let coin_out_price_dec = coin_out_price_usd.get_expo().get_magnitude_if_negative() as u8;

    // buffer to avoid precision loss when the computed exponent would be negative.
    let buffer: u8 = 10;

    // calculate the numerator and denominator
    let coin_in_decimals = suins_bbb::bbb_config::coin_in_decimals(swap_conf);
    let coin_out_decimals = suins_bbb::bbb_config::coin_out_decimals(swap_conf);
    let numerator = (coin_in_amount as u128)
        * (coin_in_price_mag as u128)
        * 10u128.pow((buffer + coin_out_price_dec + coin_out_decimals) as u8);
    let denominator = (coin_out_price_mag as u128)
        * 10u128.pow((buffer + coin_in_price_dec + coin_in_decimals) as u8);

    // divide and round up to avoid precision loss
    let expected_coin_out = numerator
        .divide_and_round_up(denominator)
        .divide_and_round_up(10u128.pow(buffer)) as u64;

    expected_coin_out
}
