module suins_bbb::bbb_cetus_swap;

fun flash_swap<CoinA, CoinB>(
    global_config: &cetus_clmm::config::GlobalConfig,
    pool: &mut cetus_clmm::pool::Pool<CoinA, CoinB>,
    amount: u64,
    a2b: bool,
    by_amount_in: bool,
    sqrt_price_limit: u128,
    clock: &sui::clock::Clock,
    ctx: &mut sui::tx_context::TxContext,
): (sui::coin::Coin<CoinA>, sui::coin::Coin<CoinB>, cetus_clmm::pool::FlashSwapReceipt<CoinA, CoinB>, u64) {
    let (balance_a, balance_b, receipt) = cetus_clmm::pool::flash_swap<CoinA, CoinB>(
        global_config, pool, a2b, by_amount_in, amount, sqrt_price_limit, clock
    );
    let pay_amount = cetus_clmm::pool::swap_pay_amount<CoinA, CoinB>(&receipt);
    (
        sui::coin::from_balance<CoinA>(balance_a, ctx),
        sui::coin::from_balance<CoinB>(balance_b, ctx),
        receipt,
        pay_amount
    )
}

fun repay_flash_swap<CoinA, CoinB>(
    global_config: &cetus_clmm::config::GlobalConfig,
    pool: &mut cetus_clmm::pool::Pool<CoinA, CoinB>,
    is_a2b: bool,
    mut coin_a: sui::coin::Coin<CoinA>,
    mut coin_b: sui::coin::Coin<CoinB>,
    receipt: cetus_clmm::pool::FlashSwapReceipt<CoinA, CoinB>,
    ctx: &mut sui::tx_context::TxContext,
): (sui::coin::Coin<CoinA>, sui::coin::Coin<CoinB>) {
    let pay_amount = cetus_clmm::pool::swap_pay_amount<CoinA, CoinB>(&receipt);
    let (balance_a_repay, balance_b_repay) = if (is_a2b) {
        (
            sui::coin::into_balance<CoinA>(sui::coin::split<CoinA>(&mut coin_a, pay_amount, ctx)),
            sui::balance::zero<CoinB>()
        )
    } else {
        (
            sui::balance::zero<CoinA>(),
            sui::coin::into_balance<CoinB>(sui::coin::split<CoinB>(&mut coin_b, pay_amount, ctx))
        )
    };
    cetus_clmm::pool::repay_flash_swap<CoinA, CoinB>(global_config, pool, balance_a_repay, balance_b_repay, receipt);
    (coin_a, coin_b)
}

public fun flash_swap_a2b<CoinA, CoinB>(
    global_config: &cetus_clmm::config::GlobalConfig,
    pool: &mut cetus_clmm::pool::Pool<CoinA, CoinB>,
    amount: u64,
    by_amount_in: bool,
    clock: &sui::clock::Clock,
    ctx: &mut sui::tx_context::TxContext,
): (sui::coin::Coin<CoinB>, cetus_clmm::pool::FlashSwapReceipt<CoinA, CoinB>, u64) {
    let (coin_a, coin_b, receipt, pay_amount) = flash_swap<CoinA, CoinB>(
        global_config,
        pool,
        amount,
        true,
        by_amount_in,
        cetus_clmm::tick_math::min_sqrt_price(),
        clock,
        ctx,
    );
    transfer_or_destroy_coin<CoinA>(coin_a, ctx);
    (coin_b, receipt, pay_amount)
}

public fun repay_flash_swap_a2b<CoinA, CoinB>(
    global_config: &cetus_clmm::config::GlobalConfig,
    pool: &mut cetus_clmm::pool::Pool<CoinA, CoinB>,
    coin_a: sui::coin::Coin<CoinA>,
    receipt: cetus_clmm::pool::FlashSwapReceipt<CoinA, CoinB>,
    ctx: &mut sui::tx_context::TxContext,
): sui::coin::Coin<CoinA> {
    let (remaining_coin_a, remaining_coin_b) = repay_flash_swap<CoinA, CoinB>(
        global_config,
        pool,
        true,
        coin_a,
        sui::coin::zero<CoinB>(ctx),
        receipt,
        ctx
    );
    transfer_or_destroy_coin<CoinB>(remaining_coin_b, ctx);
    remaining_coin_a
}

public fun swap_a2b<CoinA, CoinB>(
    global_config: &cetus_clmm::config::GlobalConfig,
    pool: &mut cetus_clmm::pool::Pool<CoinA, CoinB>,
    coin_a: sui::coin::Coin<CoinA>,
    clock: &sui::clock::Clock,
    ctx: &mut sui::tx_context::TxContext,
): sui::coin::Coin<CoinB> {
    let amount_in = sui::coin::value<CoinA>(&coin_a);
    let (unused_coin_a, coin_b_out, receipt, pay_amount) = flash_swap<CoinA, CoinB>(
        global_config,
        pool,
        amount_in,
        true,
        true,
        cetus_clmm::tick_math::min_sqrt_price(),
        clock,
        ctx,
    );
    assert!(pay_amount == amount_in, 0);
    let remaining_coin_a = repay_flash_swap_a2b<CoinA, CoinB>(global_config, pool, coin_a, receipt, ctx);
    transfer_or_destroy_coin<CoinA>(remaining_coin_a, ctx);
    sui::coin::destroy_zero<CoinA>(unused_coin_a);
    coin_b_out
}

fun transfer_or_destroy_coin<CoinType>(
    coin: sui::coin::Coin<CoinType>,
    ctx: &sui::tx_context::TxContext,
) {
    if (sui::coin::value<CoinType>(&coin) > 0) {
        sui::transfer::public_transfer<sui::coin::Coin<CoinType>>(coin, sui::tx_context::sender(ctx));
    } else {
        sui::coin::destroy_zero<CoinType>(coin);
    };
}
