module payments::payments;

use pyth::price_info::PriceInfoObject;
use pyth::pyth;
use std::type_name::{Self, TypeName};
use sui::clock::Clock;
use sui::coin::{Coin, CoinMetadata};
use sui::vec_map::{Self, VecMap};
use suins::payment::{Receipt, PaymentIntent, calculate_total_after_discount};
use suins::suins::SuiNS;

use fun get_config_for_type as SuiNS.get_config_for_type;

public struct PaymentsApp() has drop;

#[error]
const EBaseCurrencySetupMissing: vector<u8> =
    b"Setup for the base currency is missing.";
#[error]
const EInsufficientPayment: vector<u8> = b"Insufficient coin balance.";
#[error]
const EInvalidPaymentType: vector<u8> =
    b"The supplied payment coin type is not supported.";
#[error]
const ECannotUseOracleForBaseCurrency: vector<u8> =
    b"Cannot use this function for base currency. Use `handle_base_payment` instead.";
#[error]
const EPriceFeedIdMismatch: vector<u8> =
    b"The supplied `PriceInfoObject` is invalid for the given coin type.";
#[error]
const EInvalidPythPrice: vector<u8> = b"Invalid Pyth price.";
#[error]
const ESafeguardViolation: vector<u8> =
    b"User price guard violation. The payment amount is higher than the user's expected amount.";

/// A buffer added to the exponent when calculating the target currency amount.
const BUFFER: u8 = 10;
/// The key for the payment discount in the payment intent.
const PAYMENT_DISCOUNT_KEY: vector<u8> = b"payment_discount";

/// Configuration for the payments module.
/// Holds a VecMap that determines the configuration for each currency.
public struct PaymentsConfig has store, drop {
    // the configuration for each currency.
    currencies: VecMap<TypeName, CoinTypeData>,
    // the type of our base currency (which determines the base price unit).
    base_currency: TypeName,
    // max age tolerance for pyth prices in seconds.
    max_age: u64,
}

public struct CoinTypeData has copy, store, drop {
    /// The coin's decimals.
    decimals: u8,
    // A discount can be applied if the user pays with this currency.
    discount_percentage: u8,
    // Pyth's price feed id for the given currency. Make sure you omit the `0x`
    // prefix.
    price_feed_id: vector<u8>,
    // type
    type_name: TypeName,
}

/// This has to be called with our base payment currency.
/// The payment has to be equal to the base price of the domain.
/// We do not need to check the price feed for the base currency.
public fun handle_base_payment<T>(
    suins: &mut SuiNS,
    mut intent: PaymentIntent,
    payment: Coin<T>,
): Receipt {
    let payment_type = type_name::get<T>();
    let config = suins.get_config<PaymentsConfig>();

    assert!(payment_type == config.base_currency, EInvalidPaymentType);

    suins
        .get_config_for_type<T>()
        .apply_discount_if_eligible(suins, &mut intent);

    let price = intent.request_data().base_amount();
    assert!(payment.value() == price, EInsufficientPayment);

    intent.finalize_payment(suins, PaymentsApp(), payment)
}

/// Handles a payment done for a non-base currency payment.
/// E.g. SUI, NS.
///
/// The payment amount is derived from the base currency price and the Pyth
/// price feed.
///
/// The `user_price_guard` is a value that the user expects to pay. If the
/// payment
/// amount is higher than this value, the payment will be rejected. This is to
/// protect
/// the user from paying more than they expected on their FEs. Ideally this
/// number should be
/// calcualated on the FE based on the price that is being displayed to the user
/// (with a buffer determined by the FE).
public fun handle_payment<T>(
    suins: &mut SuiNS,
    mut intent: PaymentIntent,
    payment: Coin<T>,
    clock: &Clock,
    price_info_object: &PriceInfoObject,
    user_price_guard: u64,
): Receipt {
    let type_config = suins.get_config_for_type<T>();
    type_config.apply_discount_if_eligible(suins, &mut intent);

    let target_currency_amount = calculate_price<T>(
        suins,
        intent.request_data().base_amount(),
        clock,
        price_info_object,
    );
    assert!(payment.value() == target_currency_amount, EInsufficientPayment);
    assert!(user_price_guard >= target_currency_amount, ESafeguardViolation); // price guard should be larger than the payment amount

    intent.finalize_payment(suins, PaymentsApp(), payment)
}

/// Calculates the amount that has to be paid in the target currency.
///
/// Can be used to split the payment amount in a single PTB.
/// 1. const intent = function_to_get_intent();
/// 2. const price = calculate_price<SUI>(suins, intent, ...);
/// 3. const coin = txb.splitCoins(baseCoin, [price])
/// 4. handle_payment<SUI>(suins, intent, coin, ...);
public fun calculate_price<T>(
    suins: &mut SuiNS,
    base_amount: u64,
    clock: &Clock,
    price_info_object: &PriceInfoObject,
): u64 {
    let config = suins.get_config<PaymentsConfig>();
    let payment_type = type_name::get<T>();
    let type_config = suins.get_config_for_type<T>();

    assert!(
        config.base_currency != payment_type,
        ECannotUseOracleForBaseCurrency,
    );

    let price = pyth::get_price_no_older_than(
        price_info_object,
        clock,
        config.max_age,
    );
    let price_info = price_info_object.get_price_info_from_price_info_object();

    // verify that the price feed id matches the one we have in our config.
    assert!(
        price_info.get_price_identifier().get_bytes() == type_config.price_feed_id,
        EPriceFeedIdMismatch,
    );

    let target_decimals = type_config.decimals;
    let base_decimals = config.currencies.get(&config.base_currency).decimals;
    let pyth_decimals = price.get_expo().get_magnitude_if_negative() as u8;
    let pyth_price = price.get_price().get_magnitude_if_positive();

    calculate_target_currency_amount(
        base_amount,
        target_decimals,
        base_decimals,
        pyth_price,
        pyth_decimals,
    )
}

/// Creates a new CoinTypeData struct.
public fun new_coin_type_data<T>(
    coin_metadata: &CoinMetadata<T>,
    discount_percentage: u8,
    // Pyth's price feed id for the given currency.
    // Leave empty for base currency.
    price_feed_id: vector<u8>,
): CoinTypeData {
    let type_name = type_name::get<T>();
    CoinTypeData {
        decimals: coin_metadata.get_decimals(),
        discount_percentage,
        price_feed_id,
        type_name,
    }
}

/// Creates a new PaymentsConfig struct.
/// Can be attached by the Admin to SuiNS to allow the payments module to work.
public fun new_payments_config(
    setups: vector<CoinTypeData>,
    base_currency: TypeName,
    max_age: u64,
): PaymentsConfig {
    let mut currencies: VecMap<TypeName, CoinTypeData> = vec_map::empty();

    setups.do!(|coin_type| {
        currencies.insert(coin_type.type_name, coin_type);
    });

    assert!(currencies.contains(&base_currency), EBaseCurrencySetupMissing);

    PaymentsConfig {
        currencies,
        base_currency,
        max_age,
    }
}

public fun calculate_price_after_discount<T>(
    suins: &SuiNS,
    intent: &PaymentIntent,
): u64 {
    let type_config = suins.get_config_for_type<T>();

    calculate_total_after_discount(
        intent.request_data(),
        type_config.discount_percentage,
    )
}

public(package) fun calculate_target_currency_amount(
    base_currency_amount: u64,
    target_decimals: u8,
    base_decimals: u8,
    pyth_price: u64,
    pyth_decimals: u8,
): u64 {
    assert!(pyth_price > 0, EInvalidPythPrice);

    // We use a buffer in the edge case where target_decimals + pyth_decimals <
    // base_decimals
    let exponent_with_buffer =
        BUFFER + target_decimals + pyth_decimals - base_decimals;

    // We cast to u128 to avoid overflow, which is very likely with the buffer
    let target_currency_amount =
        (base_currency_amount as u128 * 10u128.pow(exponent_with_buffer))
            .divide_and_round_up(pyth_price as u128)
            .divide_and_round_up(10u128.pow(BUFFER)) as u64;

    target_currency_amount
}

/// Applies a discount to the payment intent,
/// if the payment currency supports it.
fun apply_discount_if_eligible(
    coin_type_data: &CoinTypeData,
    suins: &mut SuiNS,
    intent: &mut PaymentIntent,
) {
    if (coin_type_data.discount_percentage == 0) return;

    intent.apply_percentage_discount(
        suins,
        PaymentsApp(),
        PAYMENT_DISCOUNT_KEY.to_string(),
        coin_type_data.discount_percentage,
        // payments package discount can be applied even if other discounts are
        // applied.
        true,
    );
}

/// Gets the configuration for a given payment type.
fun get_config_for_type<T>(suins: &SuiNS): CoinTypeData {
    let config = suins.get_config<PaymentsConfig>();
    let payment_type = type_name::get<T>();
    assert!(config.currencies.contains(&payment_type), EInvalidPaymentType);
    *config.currencies.get(&payment_type)
}
