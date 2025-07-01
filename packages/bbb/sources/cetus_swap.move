module suins_bbb::bbb_cetus_swap;

use sui::{
    balance::{Self},
    clock::{Clock},
    coin::{Coin},
};
use cetus_clmm::{
    config::{GlobalConfig},
    pool::{Pool, flash_swap, repay_flash_swap, swap_pay_amount},
    tick_math::{min_sqrt_price},
};

const EInvalidOwedAmount: u64 = 100;

public fun swap<CoinIn, CoinOut>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinIn, CoinOut>,
    coin_in: Coin<CoinIn>,
    clock: &Clock,
    ctx: &mut TxContext,
): Coin<CoinOut> {
    // borrow CoinOut from pool
    let (balance_in_zero, balance_out, receipt) = flash_swap<CoinIn, CoinOut>(
        config,
        pool,
        true, // a2b
        true, // by_amount_in
        coin_in.value(), // amount_in
        min_sqrt_price(), // sqrt_price_limit
        clock,
    );
    balance_in_zero.destroy_zero();

    // check we owe exactly what we input
    assert!(receipt.swap_pay_amount() == coin_in.value(), EInvalidOwedAmount);

    // repay the flash loan with coin_in
    repay_flash_swap<CoinIn, CoinOut>(
        config,
        pool,
        coin_in.into_balance(),
        balance::zero<CoinOut>(),
        receipt,
    );

    balance_out.into_coin(ctx)
}
