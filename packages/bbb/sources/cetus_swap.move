module suins_bbb::bbb_cetus_swap;

use sui::{
    balance::{Self},
    clock::{Clock},
    coin::{Coin},
};
use cetusclmm::{
    config::{GlobalConfig},
    pool::{Pool, flash_swap, repay_flash_swap, swap_pay_amount},
    tick_math::{min_sqrt_price, max_sqrt_price},
};

// === errors ===

const EInvalidOwedAmount: u64 = 100;

// === public functions ===

public fun swap<CoinA, CoinB>(
    a2b: bool,
    cetus_config: &GlobalConfig,
    pool: &mut Pool<CoinA, CoinB>,
    coin_in_a: Coin<CoinA>,
    coin_in_b: Coin<CoinB>,
    clock: &Clock,
    ctx: &mut TxContext,
): (Coin<CoinA>, Coin<CoinB>) {
    if (a2b) {
        coin_in_b.destroy_zero();

        // borrow CoinB from pool
        let (balance_out_a_zero, balance_out_b, receipt) = flash_swap<CoinA, CoinB>(
            cetus_config,
            pool,
            true, // a2b=true: swap from CoinA to CoinB
            true, // by_amount_in
            coin_in_a.value(), // amount
            min_sqrt_price(), // sqrt_price_limit
            clock,
        );

        // check we owe exactly what we input
        assert!(receipt.swap_pay_amount() == coin_in_a.value(), EInvalidOwedAmount);

        // repay the flash loan with coin_in_a
        repay_flash_swap<CoinA, CoinB>(
            cetus_config,
            pool,
            coin_in_a.into_balance(),
            balance::zero<CoinB>(),
            receipt,
        );

        (balance_out_a_zero.into_coin(ctx), balance_out_b.into_coin(ctx))
    } else {
        coin_in_a.destroy_zero();

        // borrow CoinA from pool
        let (balance_out_a, balance_out_b_zero, receipt) = flash_swap<CoinA, CoinB>(
            cetus_config,
            pool,
            false, // a2b=false: swap from CoinB to CoinA
            true, // by_amount_in
            coin_in_b.value(), // amount
            max_sqrt_price(), // sqrt_price_limit
            clock,
        );

        // check we owe exactly what we input
        assert!(receipt.swap_pay_amount() == coin_in_b.value(), EInvalidOwedAmount);

        // repay the flash loan with coin_in_b
        repay_flash_swap<CoinA, CoinB>(
            cetus_config,
            pool,
            balance::zero<CoinA>(),
            coin_in_b.into_balance(),
            receipt,
        );

        (balance_out_a.into_coin(ctx), balance_out_b_zero.into_coin(ctx))
    }
}
