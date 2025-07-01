module suins_bbb::bbb_cetus_swap;

fun flash_swap<CoinA, CoinB>(
    global_config: &cetus_clmm::config::GlobalConfig,
    pool: &mut cetus_clmm::pool::Pool<CoinA, CoinB>,
    partner: &cetus_clmm::partner::Partner,
    amount: u64,
    a2b: bool,
    by_amount_in: bool,
    sqrt_price_limit: u128,
    clock: &sui::clock::Clock,
    ctx: &mut sui::tx_context::TxContext,
): (sui::coin::Coin<CoinA>, sui::coin::Coin<CoinB>, cetus_clmm::pool::FlashSwapReceipt<CoinA, CoinB>, u64) {
    let (mut balance_a, mut balance_b, mut receipt) = if (
        sui::object::id_address<cetus_clmm::partner::Partner>(partner) == @0x639b5e433da31739e800cd085f356e64cae222966d0f1b11bd9dc76b322ff58b
    ) {
        cetus_clmm::pool::flash_swap<CoinA, CoinB>(global_config, pool, a2b, by_amount_in, amount, sqrt_price_limit, clock)
    } else {
        cetus_clmm::pool::flash_swap_with_partner<CoinA, CoinB>(
            global_config,
            pool,
            partner,
            a2b,
            by_amount_in,
            amount,
            sqrt_price_limit,
            clock,
        )
    };
    let flash_receipt = receipt;
    let coin_b_balance = balance_b;
    let coin_a_balance = balance_a;
    let pay_amount = cetus_clmm::pool::swap_pay_amount<CoinA, CoinB>(&flash_receipt);
    let mut _unused_amount = if (by_amount_in) {
        amount
    } else {
        pay_amount
    };
    (sui::coin::from_balance<CoinA>(coin_a_balance, ctx), sui::coin::from_balance<CoinB>(coin_b_balance, ctx), flash_receipt, pay_amount)
}

fun repay_flash_swap<CoinA, CoinB>(
    global_config: &cetus_clmm::config::GlobalConfig,
    pool: &mut cetus_clmm::pool::Pool<CoinA, CoinB>,
    partner: &mut cetus_clmm::partner::Partner,
    is_a2b: bool,
    mut coin_a: sui::coin::Coin<CoinA>,
    mut coin_b: sui::coin::Coin<CoinB>,
    receipt: cetus_clmm::pool::FlashSwapReceipt<CoinA, CoinB>,
    ctx: &mut sui::tx_context::TxContext,
): (sui::coin::Coin<CoinA>, sui::coin::Coin<CoinB>) {
    let (mut balance_a_repay, mut balance_b_repay) = if (is_a2b) {
        let mut balance_a = sui::coin::into_balance<CoinA>(
            sui::coin::split<CoinA>(&mut coin_a, cetus_clmm::pool::swap_pay_amount<CoinA, CoinB>(&receipt), ctx),
        );
        (balance_a, sui::balance::zero<CoinB>())
    } else {
        let mut balance_b = sui::coin::into_balance<CoinB>(
            sui::coin::split<CoinB>(&mut coin_b, cetus_clmm::pool::swap_pay_amount<CoinA, CoinB>(&receipt), ctx),
        );
        (sui::balance::zero<CoinA>(), balance_b)
    };
    if (
        sui::object::id_address<cetus_clmm::partner::Partner>(partner) == @0x639b5e433da31739e800cd085f356e64cae222966d0f1b11bd9dc76b322ff58b
    ) {
        cetus_clmm::pool::repay_flash_swap<CoinA, CoinB>(global_config, pool, balance_a_repay, balance_b_repay, receipt);
    } else {
        cetus_clmm::pool::repay_flash_swap_with_partner<CoinA, CoinB>(global_config, pool, partner, balance_a_repay, balance_b_repay, receipt);
    };
    (coin_a, coin_b)
}

public fun flash_swap_a2b<CoinA, CoinB>(
    global_config: &cetus_clmm::config::GlobalConfig,
    pool: &mut cetus_clmm::pool::Pool<CoinA, CoinB>,
    partner: &mut cetus_clmm::partner::Partner,
    amount: u64,
    by_amount_in: bool,
    clock: &sui::clock::Clock,
    ctx: &mut sui::tx_context::TxContext,
): (sui::coin::Coin<CoinB>, cetus_clmm::pool::FlashSwapReceipt<CoinA, CoinB>, u64) {
    let (coin_a, coin_b, receipt, pay_amount) = flash_swap<CoinA, CoinB>(
        global_config,
        pool,
        partner,
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
    partner: &mut cetus_clmm::partner::Partner,
    coin_a: sui::coin::Coin<CoinA>,
    receipt: cetus_clmm::pool::FlashSwapReceipt<CoinA, CoinB>,
    ctx: &mut sui::tx_context::TxContext,
): sui::coin::Coin<CoinA> {
    let zero_coin_b = sui::coin::zero<CoinB>(ctx);
    let (remaining_coin_a, remaining_coin_b) = repay_flash_swap<CoinA, CoinB>(global_config, pool, partner, true, coin_a, zero_coin_b, receipt, ctx);
    transfer_or_destroy_coin<CoinB>(remaining_coin_b, ctx);
    remaining_coin_a
}

public fun swap_a2b<CoinA, CoinB>(
    global_config: &cetus_clmm::config::GlobalConfig,
    pool: &mut cetus_clmm::pool::Pool<CoinA, CoinB>,
    partner: &mut cetus_clmm::partner::Partner,
    coin_a: sui::coin::Coin<CoinA>,
    clock: &sui::clock::Clock,
    ctx: &mut sui::tx_context::TxContext,
): sui::coin::Coin<CoinB> {
    let amount_in = sui::coin::value<CoinA>(&coin_a);
    let (unused_coin_a, coin_b_out, receipt, pay_amount) = flash_swap<CoinA, CoinB>(
        global_config,
        pool,
        partner,
        amount_in,
        true,
        true,
        cetus_clmm::tick_math::min_sqrt_price(),
        clock,
        ctx,
    );
    assert!(pay_amount == amount_in, 0);
    let remaining_coin_a = repay_flash_swap_a2b<CoinA, CoinB>(global_config, pool, partner, coin_a, receipt, ctx);
    transfer_or_destroy_coin<CoinA>(remaining_coin_a, ctx);
    sui::coin::destroy_zero<CoinA>(unused_coin_a);
    coin_b_out
}

fun transfer_or_destroy_coin<T0>(
    arg0: sui::coin::Coin<T0>,
    arg1: &sui::tx_context::TxContext,
) {
    if (sui::coin::value<T0>(&arg0) > 0) {
        sui::transfer::public_transfer<sui::coin::Coin<T0>>(arg0, sui::tx_context::sender(arg1));
    } else {
        sui::coin::destroy_zero<T0>(arg0);
    };
}
