module cetus_demo::cetus_swap;

use sui::{
    balance::{Self},
    clock::{Clock},
    coin::{Coin},
};
use cetusclmm::{
    config::{GlobalConfig},
    pool::{Pool, flash_swap, repay_flash_swap, swap_pay_amount},
    tick_math::{min_sqrt_price},
};

const EInvalidOwedAmount: u64 = 100;

public fun swap_a2b<CoinA, CoinB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinA, CoinB>,
    coin_a: Coin<CoinA>,
    clock: &Clock,
    ctx: &mut TxContext,
): Coin<CoinB> {
    // borrow CoinB from pool
    let (balance_a_zero, balance_b, receipt) = flash_swap<CoinA, CoinB>(
        config,
        pool,
        true, // a2b=true: swap from CoinA to CoinB
        true, // by_amount_in
        coin_a.value(), // amount
        min_sqrt_price(), // sqrt_price_limit
        clock,
    );
    balance_a_zero.destroy_zero();

    // check we owe exactly what we input
    assert!(receipt.swap_pay_amount() == coin_a.value(), EInvalidOwedAmount);

    // repay the flash loan with coin_a
    repay_flash_swap<CoinA, CoinB>(
        config,
        pool,
        coin_a.into_balance(),
        balance::zero<CoinB>(),
        receipt,
    );

    balance_b.into_coin(ctx)
}

public fun swap_b2a<CoinA, CoinB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinA, CoinB>,
    coin_b: Coin<CoinB>,
    clock: &Clock,
    ctx: &mut TxContext,
): Coin<CoinA> {
    // borrow CoinA from pool
    let (balance_a, balance_b_zero, receipt) = flash_swap<CoinA, CoinB>(
        config,
        pool,
        false, // a2b=false: swap from CoinB to CoinA
        true, // by_amount_in
        coin_b.value(), // amount
        min_sqrt_price(), // sqrt_price_limit
        clock,
    );
    balance_b_zero.destroy_zero();

    // check we owe exactly what we input
    assert!(receipt.swap_pay_amount() == coin_b.value(), EInvalidOwedAmount);

    // repay the flash loan with coin_b
    repay_flash_swap<CoinA, CoinB>(
        config,
        pool,
        balance::zero<CoinA>(),
        coin_b.into_balance(),
        receipt,
    );

    balance_a.into_coin(ctx)
}
