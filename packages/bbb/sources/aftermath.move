module suins_bbb::bbb_aftermath;

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
    bbb_config::{BBBConfig, get_aftermath_swap_config},
    bbb_pyth::calc_expected_coin_out,
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
    // ours
    config: &BBBConfig,
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
    // check swap config exists for CoinIn
    let swap_opt = get_aftermath_swap_config<CoinIn>(config);
    assert!(swap_opt.is_some(), ENoAftermathSwap);

    // check pool id matches the one in the swap config
    let swap_conf = swap_opt.destroy_some();
    assert!(object::id(pool) == swap_conf.pool_id(), EInvalidPool);

    // check price feed ids match the swap config
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
        swap_conf.coin_in_decimals(),
        swap_conf.coin_out_decimals(),
        coin_in.value(),
        config.max_age_secs(),
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
        config.slippage(),
        ctx,
    );

    // deposit CoinOut into vault
    vault.deposit<CoinOut>(coin_out.into_balance());
}
