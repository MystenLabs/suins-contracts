module suins_bbb::bbb_aftermath_swap;

use std::{
    ascii::{String},
    type_name::{Self, TypeName},
};
use sui::{
    clock::{Clock},
    event::{emit},
};
use pyth::{
    price_info::PriceInfoObject,
};
use amm::{
    swap::{swap_exact_in},
    pool::{Pool},
    pool_registry::PoolRegistry,
};
use protocol_fee_vault::{
    vault::{ProtocolFeeVault},
};
use treasury::{
    treasury::{Treasury},
};
use insurance_fund::{
    insurance_fund::{InsuranceFund},
};
use referral_vault::{
    referral_vault::{ReferralVault},
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
const EInvalidCoinInType: u64 = 1003;
const EInvalidCoinOutType: u64 = 1004;
const EAmountOutTooLow: u64 = 1005;

// === structs ===

/// Aftermath swap configuration.
/// Grants the right to swap `Balance<type_in>` for `Balance<type_out>` in the vault.
/// Only the admin can create it.
public struct AftermathSwap has copy, drop, store {
    /// Type of coin to be swapped into `type_out`
    type_in: TypeName,
    /// Type of coin to be received from the swap
    type_out: TypeName,
    /// Number of decimals used by `type_in`
    decimals_in: u8,
    /// Number of decimals used by `type_out`
    decimals_out: u8,
    /// Pyth `PriceFeed` identifier for `type_in` without the `0x` prefix
    feed_in: vector<u8>,
    /// Pyth `PriceFeed` identifier for `type_out` without the `0x` prefix
    feed_out: vector<u8>,
    /// Aftermath `Pool` object `ID`
    pool_id: ID,
    /// Swap slippage tolerance as `1 - slippage` in 18-decimal fixed point.
    /// E.g., 2% slippage = 980_000_000_000_000_000 (represents 0.98).
    slippage: u64,
    /// How stale the Pyth price can be, in seconds.
    max_age_secs: u64,
}

public fun type_in(self: &AftermathSwap): &TypeName { &self.type_in }
public fun type_out(self: &AftermathSwap): &TypeName { &self.type_out }
public fun decimals_in(self: &AftermathSwap): u8 { self.decimals_in }
public fun decimals_out(self: &AftermathSwap): u8 { self.decimals_out }
public fun feed_in(self: &AftermathSwap): &vector<u8> { &self.feed_in }
public fun feed_out(self: &AftermathSwap): &vector<u8> { &self.feed_out }
public fun pool_id(self: &AftermathSwap): &ID { &self.pool_id }
public fun slippage(self: &AftermathSwap): u64 { self.slippage }
public fun max_age_secs(self: &AftermathSwap): u64 { self.max_age_secs }

public fun new<L, CoinIn, CoinOut>(
    _cap: &BBBAdminCap,
    decimals_in: u8,
    decimals_out: u8,
    feed_in: vector<u8>,
    feed_out: vector<u8>,
    pool: &Pool<L>,
    slippage: u64,
    max_age_secs: u64,
): AftermathSwap {
    let type_in = type_name::get<CoinIn>();
    let type_out = type_name::get<CoinOut>();
    assert!(pool.type_names().contains(&type_in.into_string()), EInvalidCoinInType);
    assert!(pool.type_names().contains(&type_out.into_string()), EInvalidCoinOutType);
    AftermathSwap {
        type_in,
        type_out,
        decimals_in,
        decimals_out,
        feed_in,
        feed_out,
        pool_id: object::id(pool),
        slippage,
        max_age_secs,
    }
}

// === public functions ===

/// Swap the `CoinIn` in the vault for an equal-valued amount of `CoinOut`,
/// and deposit the resulting `CoinOut` into the vault.
/// Uses Aftermath's AMM. Protocol fees are charged on the `CoinIn` being swapped.
public fun swap<L, CoinIn, CoinOut>(
    // ours
    self: &AftermathSwap,
    vault: &mut BBBVault,
    // pyth
    info_in: &PriceInfoObject,
    info_out: &PriceInfoObject,
    // aftermath
    pool: &mut Pool<L>,
    pool_registry: &PoolRegistry,
    protocol_fee_vault: &ProtocolFeeVault,
    treasury: &mut Treasury,
    insurance_fund: &mut InsuranceFund,
    referral_vault: &ReferralVault,
    // sui
    clock: &Clock,
    ctx: &mut TxContext,
) {
    // check price feed ids match the config
    let feed_id_in = info_in.get_price_info_from_price_info_object().get_price_identifier();
    let feed_id_out = info_out.get_price_info_from_price_info_object().get_price_identifier();
    assert!(feed_id_in.get_bytes() == self.feed_in(), EFeedInMismatch);
    assert!(feed_id_out.get_bytes() == self.feed_out(), EFeedOutMismatch);

    // check pool id and coin types match the config
    assert!(object::id(pool) == self.pool_id(), EInvalidPool);
    let type_in = type_name::get<CoinIn>();
    let type_out = type_name::get<CoinOut>();
    assert!(type_in == self.type_in(), EInvalidCoinInType);
    assert!(type_out == self.type_out(), EInvalidCoinOutType);

    // withdraw all CoinIn from vault
    let coin_in = vault.withdraw<CoinIn>().into_coin(ctx);
    let amount_in = coin_in.value();

    // return early if zero
    if (amount_in == 0) {
        coin_in.destroy_zero();
        return
    };

    // calculate expected CoinOut amount
    let expected_out = calc_amount_out(
        info_in,
        info_out,
        self.decimals_in,
        self.decimals_out,
        amount_in,
        self.max_age_secs,
        clock,
    );

    // swap CoinIn for CoinOut
    let coin_out = swap_exact_in<L, CoinIn, CoinOut>(
        pool,
        pool_registry,
        protocol_fee_vault,
        treasury,
        insurance_fund,
        referral_vault,
        coin_in,
        expected_out,
        self.slippage,
        ctx,
    );
    let amount_out = coin_out.value();

    // check that we received enough CoinOut
    let minimum_out = ((expected_out as u256) * (self.slippage as u256)) / slippage_scale!();
    assert!(amount_out >= minimum_out as u64, EAmountOutTooLow);

    // deposit CoinOut into vault
    vault.deposit<CoinOut>(coin_out);

    emit(AftermathSwapEvent {
        type_in: type_in.into_string(),
        type_out: type_out.into_string(),
        amount_in,
        amount_out,
        expected_out,
    });
}

// === events ===

public struct AftermathSwapEvent has copy, drop {
    type_in: String,
    type_out: String,
    amount_in: u64,
    amount_out: u64,
    expected_out: u64,
}
