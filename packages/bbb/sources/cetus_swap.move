module suins_bbb::bbb_cetus_swap;

use std::{
    ascii::{String},
    type_name::{Self, TypeName},
};
use sui::{
    balance::{Self},
    clock::{Clock},
    coin::{Coin},
    event::{emit},
};
use pyth::{
    price_info::{PriceInfoObject},
};
use cetusclmm::{
    config::{GlobalConfig},
    pool::{Pool, flash_swap, repay_flash_swap, swap_pay_amount},
    tick_math::{min_sqrt_price, max_sqrt_price},
};
use suins_bbb::{
    bbb_admin::{BBBAdminCap},
    bbb_constants::{slippage_scale},
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
const ESlippageTooHigh: u64 = 1007;
const ESlippageTooLow: u64 = 1008;
const EMaxAgeTooHigh: u64 = 1009;

// === events ===

public struct CetusSwapEvent has copy, drop {
    type_in: String,
    type_out: String,
    amount_in: u64,
    amount_out: u64,
    expected_out: u64,
}

// === structs ===

/// Cetus swap configuration.
/// Grants the right to swap `Balance<type_a>` for `Balance<type_b>` in the vault, or vice versa.
/// Only the admin can create it.
public struct CetusSwap has copy, drop, store {
    /// Whether to swap from `type_a` to `type_b` or vice versa.
    a2b: bool,
    /// First coin type in the pool
    type_a: TypeName,
    /// Second coin type in the pool
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
    /// Freshness requirement for the Pyth price, in seconds.
    max_age_secs: u64,
}

/// Hot potato to ensure the CetusSwap is used within the same tx
public struct CetusSwapPromise {
    swap: CetusSwap,
}

// === accessors ===

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

public fun inner(promise: &CetusSwapPromise): &CetusSwap { &promise.swap }

// === constructors ===

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
    assert!(slippage as u256 <= slippage_scale!(), ESlippageTooHigh);
    assert!(slippage as u256 >= slippage_scale!() / 2, ESlippageTooLow);
    assert!(max_age_secs < 3600, EMaxAgeTooHigh);
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

public(package) fun new_promise(
    swap: CetusSwap,
): CetusSwapPromise {
    CetusSwapPromise { swap }
}

// === public functions ===

/// Swap `CoinA` in the vault for `CoinB` or vice versa, depending on `a2b`,
/// and deposit the resulting coin into the vault.
/// Uses Cetus's AMM. Protocol fees are charged on the coin being swapped.
public fun swap<CoinA, CoinB>(
    // ours
    promise: CetusSwapPromise,
    vault: &mut BBBVault,
    // pyth
    info_a: &PriceInfoObject,
    info_b: &PriceInfoObject,
    // cetus
    cetus_registry: &GlobalConfig,
    pool: &mut Pool<CoinA, CoinB>,
    // sui
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let CetusSwapPromise { swap: self } = promise;

    // check that Pyth price feeds match the config
    let feed_id_a = info_a.get_price_info_from_price_info_object().get_price_identifier();
    let feed_id_b = info_b.get_price_info_from_price_info_object().get_price_identifier();
    assert!(feed_id_a.get_bytes() == self.feed_a(), EFeedInMismatch);
    assert!(feed_id_b.get_bytes() == self.feed_b(), EFeedOutMismatch);

    // check that Cetus pool matches the config
    assert!(object::id(pool) == self.pool_id(), EInvalidPool);

    // check that coin types match the config
    let type_a = type_name::get<CoinA>();
    let type_b = type_name::get<CoinB>();
    assert!(type_a == self.type_a(), EInvalidCoinAType);
    assert!(type_b == self.type_b(), EInvalidCoinBType);

    if (self.a2b) {
        // withdraw all CoinA from vault
        let coin_in_a = vault.withdraw<CoinA>().into_coin(ctx);
        let amount_in_a = coin_in_a.value();

        // return early if zero
        if (amount_in_a == 0) {
            coin_in_a.destroy_zero();
            return
        };

        // calculate expected CoinB amount
        let expected_b = calc_amount_out(
            info_a,
            info_b,
            self.decimals_a,
            self.decimals_b,
            amount_in_a,
            self.max_age_secs,
            clock,
        );

        // swap CoinA for CoinB
        let coin_out_b = swap_a2b(cetus_registry, pool, coin_in_a, clock, ctx);
        let amount_out_b = coin_out_b.value();

        // check that we received enough CoinB
        let minimum_out_b = ((expected_b as u256) * (self.slippage as u256)) / slippage_scale!();
        assert!(amount_out_b >= minimum_out_b as u64, EAmountOutTooLow);

        // deposit CoinB into vault
        vault.deposit<CoinB>(coin_out_b);

        emit(CetusSwapEvent {
            type_in: type_a.into_string(),
            type_out: type_b.into_string(),
            amount_in: amount_in_a,
            amount_out: amount_out_b,
            expected_out: expected_b,
        });
    } else {
        // withdraw all CoinB from vault
        let coin_in_b = vault.withdraw<CoinB>().into_coin(ctx);
        let amount_in_b = coin_in_b.value();

        // return early if zero
        if (amount_in_b == 0) {
            coin_in_b.destroy_zero();
            return
        };

        // calculate expected CoinA amount
        let expected_a = calc_amount_out(
            info_b,
            info_a,
            self.decimals_b,
            self.decimals_a,
            amount_in_b,
            self.max_age_secs,
            clock,
        );

        // swap CoinB for CoinA
        let coin_out_a = swap_b2a(cetus_registry, pool, coin_in_b, clock, ctx);
        let amount_out_a = coin_out_a.value();

        // check that we received enough CoinA
        let minimum_out_a = ((expected_a as u256) * (self.slippage as u256)) / slippage_scale!();
        assert!(amount_out_a >= minimum_out_a as u64, EAmountOutTooLow);

        // deposit CoinA into vault
        vault.deposit<CoinA>(coin_out_a);

        emit(CetusSwapEvent {
            type_in: type_b.into_string(),
            type_out: type_a.into_string(),
            amount_in: amount_in_b,
            amount_out: amount_out_a,
            expected_out: expected_a,
        });
    }
}

/// Get the input and output coin types based on the `a2b` flag.
public fun input_output_types(
    swap: &CetusSwap,
): (&TypeName, &TypeName) {
    if (swap.a2b()) {
        (swap.type_a(), swap.type_b())
    } else {
        (swap.type_b(), swap.type_a())
    }
}

// === private functions ===

fun swap_a2b<CoinA, CoinB>(
    cetus_registry: &GlobalConfig,
    pool: &mut Pool<CoinA, CoinB>,
    coin_a: Coin<CoinA>,
    clock: &Clock,
    ctx: &mut TxContext,
): Coin<CoinB> {
    // borrow CoinB from pool
    let (balance_a_zero, balance_b, receipt) = flash_swap<CoinA, CoinB>(
        cetus_registry,
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
        cetus_registry,
        pool,
        coin_a.into_balance(),
        balance::zero<CoinB>(),
        receipt,
    );

    balance_b.into_coin(ctx)
}

fun swap_b2a<CoinA, CoinB>(
    cetus_registry: &GlobalConfig,
    pool: &mut Pool<CoinA, CoinB>,
    coin_b: Coin<CoinB>,
    clock: &Clock,
    ctx: &mut TxContext,
): Coin<CoinA> {
    // borrow CoinA from pool
    let (balance_a, balance_b_zero, receipt) = flash_swap<CoinA, CoinB>(
        cetus_registry,
        pool,
        false, // a2b=false: swap from CoinB to CoinA
        true, // by_amount_in
        coin_b.value(), // amount
        max_sqrt_price(), // sqrt_price_limit
        clock,
    );
    balance_b_zero.destroy_zero();

    // check we owe exactly what we input
    assert!(receipt.swap_pay_amount() == coin_b.value(), EInvalidOwedAmount);

    // repay the flash loan with coin_b
    repay_flash_swap<CoinA, CoinB>(
        cetus_registry,
        pool,
        balance::zero<CoinA>(),
        coin_b.into_balance(),
        receipt,
    );

    balance_a.into_coin(ctx)
}
