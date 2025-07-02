module suins_bbb::bbb_cetus_swap;

use std::{
    ascii::{String},
    type_name::{Self, TypeName},
};
use sui::{
    balance::{Self},
    clock::{Clock},
    coin::{Self, Coin},
    event::{emit},
};
use pyth::{
    price_info::PriceInfoObject,
};
use cetusclmm::{
    config::{GlobalConfig},
    pool::{Pool, flash_swap, repay_flash_swap, swap_pay_amount},
    tick_math::{min_sqrt_price, max_sqrt_price},
};
use suins_bbb::{
    bbb_admin::{BBBAdminCap},
    bbb_pyth::{calc_amount_out},
    bbb_vault::{BBBVault},
};

// === errors ===

const EInvalidPool: u64 = 1000;
const EFeedInMismatch: u64 = 1001;
const EFeedOutMismatch: u64 = 1002;
const EInvalidCoinAType: u64 = 1003;
const EInvalidCoinBType: u64 = 1004;
const EAmountOutTooLow: u64 = 1005;
const EInvalidOwedAmount: u64 = 1006;

// === structs ===

/// Cetus swap configuration.
/// Grants the right to swap `Balance<type_a>` for `Balance<type_b>` in the vault, or vice versa.
/// Only the admin can create it.
public struct CetusSwap has copy, drop, store {
    /// Whether to swap from `type_a` to `type_b` or vice versa.
    a2b: bool,
    /// Type of coin to be swapped into `type_b`
    type_a: TypeName,
    /// Type of coin to be received from the swap
    type_b: TypeName,
    /// Number of decimals used by `type_a`
    decimals_a: u8,
    /// Number of decimals used by `type_b`
    decimals_b: u8,
    /// Pyth `PriceFeed` identifier for `type_a` without the `0x` prefix
    feed_a: vector<u8>,
    /// Pyth `PriceFeed` identifier for `type_b` without the `0x` prefix
    feed_b: vector<u8>,
    /// Cetus `Pool` object `ID`
    pool_id: ID,
    /// Swap slippage tolerance as `1 - slippage` in 18-decimal fixed point.
    /// E.g., 2% slippage = 980_000_000_000_000_000 (represents 0.98).
    slippage: u64,
    /// How stale the Pyth price can be, in seconds.
    max_age_secs: u64,
}

public fun a2b(self: &CetusSwap): bool { self.a2b }
public fun type_a(self: &CetusSwap): &TypeName { &self.type_a }
public fun type_b(self: &CetusSwap): &TypeName { &self.type_b }
public fun decimals_a(self: &CetusSwap): u8 { self.decimals_a }
public fun decimals_b(self: &CetusSwap): u8 { self.decimals_b }
public fun feed_a(self: &CetusSwap): &vector<u8> { &self.feed_a }
public fun feed_b(self: &CetusSwap): &vector<u8> { &self.feed_b }
public fun pool_id(self: &CetusSwap): &ID { &self.pool_id }
public fun slippage(self: &CetusSwap): u64 { self.slippage }
public fun max_age_secs(self: &CetusSwap): u64 { self.max_age_secs }

public fun new<CoinA, CoinB>(
    _cap: &BBBAdminCap,
    a2b: bool,
    decimals_a: u8,
    decimals_b: u8,
    feed_a: vector<u8>,
    feed_b: vector<u8>,
    pool: &Pool<CoinA, CoinB>,
    slippage: u64,
    max_age_secs: u64,
): CetusSwap {
    CetusSwap {
        a2b,
        type_a: type_name::get<CoinA>(),
        type_b: type_name::get<CoinB>(),
        decimals_a,
        decimals_b,
        feed_a,
        feed_b,
        pool_id: object::id(pool),
        slippage,
        max_age_secs,
    }
}

// === public functions ===

/// Swap the `CoinA` in the vault for an equal-valued amount of `CoinB`, or vice versa,
/// and deposit the resulting `CoinB` into the vault.
/// Uses Cetus's AMM. Protocol fees are charged on the coin being swapped.
public fun swap<CoinA, CoinB>(
    // ours
    cetus_swap: &CetusSwap,
    vault: &mut BBBVault,
    // pyth
    info_a: &PriceInfoObject,
    info_b: &PriceInfoObject,
    // cetus
    cetus_config: &GlobalConfig,
    pool: &mut Pool<CoinA, CoinB>,
    // sui
    clock: &Clock,
    ctx: &mut TxContext,
) {
    // check price feed ids match the config
    let feed_id_a = info_a.get_price_info_from_price_info_object().get_price_identifier();
    let feed_id_b = info_b.get_price_info_from_price_info_object().get_price_identifier();
    assert!(feed_id_a.get_bytes() == cetus_swap.feed_a(), EFeedInMismatch);
    assert!(feed_id_b.get_bytes() == cetus_swap.feed_b(), EFeedOutMismatch);

    // check pool id and coin types match the config
    assert!(object::id(pool) == cetus_swap.pool_id(), EInvalidPool);
    let type_a = type_name::get<CoinA>();
    let type_b = type_name::get<CoinB>();
    assert!(type_a == cetus_swap.type_a(), EInvalidCoinAType);
    assert!(type_b == cetus_swap.type_b(), EInvalidCoinBType);

    if (cetus_swap.a2b) {
        // withdraw all CoinA from vault
        let coin_in_a = vault.withdraw<CoinA>().into_coin(ctx);
        let amount_in_a = coin_in_a.value();

        // return early if zero
        if (amount_in_a == 0) {
            coin_in_a.destroy_zero();
            return
        };

        // calculate expected CoinB amount
        let expected_a = 0;
        let expected_b = calc_amount_out(
            info_a,
            info_b,
            cetus_swap.decimals_a,
            cetus_swap.decimals_b,
            amount_in_a,
            cetus_swap.max_age_secs,
            clock,
        );

        // swap CoinA for CoinB
        let coin_in_b = coin::zero<CoinB>(ctx);
        let amount_in_b = coin_in_b.value();
        let (coin_out_a, coin_out_b) = swap_internal(
            cetus_swap.a2b, cetus_config, pool, coin_in_a, coin_in_b, clock, ctx
        );
        let amount_out_a = coin_out_a.value();
        let amount_out_b = coin_out_b.value();

        coin_out_a.destroy_zero();

        // check that we received enough CoinB
        let minimum_out_b = ((expected_b as u256) * (cetus_swap.slippage as u256)) / 1_000_000_000_000_000_000;
        assert!(amount_out_b >= minimum_out_b as u64, EAmountOutTooLow);

        // deposit CoinB into vault
        vault.deposit<CoinB>(coin_out_b);

        emit(CetusSwapEvent {
            a2b: cetus_swap.a2b,
            type_a: type_a.into_string(),
            type_b: type_b.into_string(),
            amount_in_a,
            amount_in_b,
            amount_out_a,
            amount_out_b,
            expected_a,
            expected_b,
        });
    } else {

    }
}

// === private functions ===

public fun swap_internal<CoinA, CoinB>( // TODO make private
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


// === events ===

public struct CetusSwapEvent has drop, copy {
    a2b: bool,
    type_a: String,
    type_b: String,
    amount_in_a: u64,
    amount_in_b: u64,
    amount_out_a: u64,
    amount_out_b: u64,
    expected_a: u64,
    expected_b: u64,
}
