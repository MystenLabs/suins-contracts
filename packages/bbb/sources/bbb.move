module suins_bbb::bbb;

use sui::{coin::{Coin}};

// === aftermath dependencies ===

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

//**************************************************************************************************
// Swap | One-to-one | Exact in
//**************************************************************************************************

// Swap `coin_in` for an equal-valued amount of `Coin<CO>`. Protocol fees are charged on the Coin
//  being swapped in.
//
// Aborts:
//    i. `EZeroValue`: `coin_in` has a value of zero.
//   ii. `ESlippage`: `actual_amount_out` lies outside of the Slippage bound set by `acceptable_slippage`.
//  iii. `EZeroAmountOut`: `amount_in` is worth zero amount of `Coin<CO>`.
//   iv. `EInvalidSwapAmountOut`: the swap would result in more than `MAX_SWAP_AMOUNT_OUT` worth of
//    `Coin<CO>` exiting the Pool.
public fun swap<L, CI, CO>(
    pool: &mut Pool<L>,
    pool_registry: &PoolRegistry,
    protocol_fee_vault: &ProtocolFeeVault,
    treasury: &mut Treasury,
    insurance_fund: &mut InsuranceFund,
    referral_vault: &ReferralVault,
    coin_in: Coin<CI>,
    expected_coin_out: u64,
    allowable_slippage: u64,
    ctx: &mut TxContext,
): Coin<CO> {
    swap_exact_in<L, CI, CO>(
        pool,
        pool_registry,
        protocol_fee_vault,
        treasury,
        insurance_fund,
        referral_vault,
        coin_in,
        expected_coin_out,
        allowable_slippage,
        ctx
    )
}
