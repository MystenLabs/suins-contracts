module suins_bbb::bbb_swap;

use sui::{
    coin::{Coin},
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
    bbb_config::{BBBConfig, get_aftermath_swap_config},
    bbb_vault::{BBBVault},
};

// === errors ===

const ENoAftermathSwap: u64 = 100;
const EInvalidPool: u64 = 101;

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
    expected_coin_out: u64, // MAYBE remove since can't be trusted anyway
    allowable_slippage: u64, // TODO move to BBBConfig
    ctx: &mut TxContext,
) {
    let swap_opt = get_aftermath_swap_config<CoinIn>(config);
    assert!(swap_opt.is_some(), ENoAftermathSwap);

    let swap = swap_opt.destroy_some();
    assert!(swap.pool_id() == object::id(pool), EInvalidPool);

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
