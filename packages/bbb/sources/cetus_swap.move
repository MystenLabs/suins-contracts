module suins_bbb::bbb_cetus_swap;

use sui::{
    balance::{Self},
    clock::{Clock},
    coin::{Coin},
    transfer::{public_transfer}
};
use cetus_clmm::{
    config::{GlobalConfig},
    pool::{Pool, flash_swap, repay_flash_swap, swap_pay_amount},
    tick_math::{min_sqrt_price},
};

public fun swap<CoinA, CoinB>(
    global_config: &GlobalConfig,
    pool: &mut Pool<CoinA, CoinB>,
    mut coin_a: Coin<CoinA>,
    clock: &Clock,
    ctx: &mut TxContext,
): Coin<CoinB> {
    let amount_in = coin_a.value();

    // flash swap
    let (balance_a, balance_b, receipt) = flash_swap<CoinA, CoinB>(
        global_config,
        pool,
        true, // a2b
        true, // by_amount_in
        amount_in,
        min_sqrt_price(),
        clock,
    );

    balance_a.destroy_zero();
    let pay_amount = swap_pay_amount<CoinA, CoinB>(&receipt);
    let coin_b_out = balance_b.into_coin(ctx);

    assert!(pay_amount == amount_in, 0);

    // repay flash swap
    let balance_a_repay = coin_a.split(pay_amount, ctx).into_balance();
    let balance_b_repay = balance::zero<CoinB>();
    repay_flash_swap<CoinA, CoinB>(global_config, pool, balance_a_repay, balance_b_repay, receipt);

    // cleanup
    transfer_or_destroy_coin<CoinA>(coin_a, ctx);

    coin_b_out
}

#[allow(lint(self_transfer))]
fun transfer_or_destroy_coin<CoinType>(
    coin: Coin<CoinType>,
    ctx: &TxContext,
) {
    if (coin.value() > 0) {
        public_transfer(coin, ctx.sender());
    } else {
        coin.destroy_zero();
    };
}
