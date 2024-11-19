module payments::payments;

use pyth::price_info::{Self, PriceInfoObject};
use pyth::pyth;
use std::type_name::{Self, TypeName};
use sui::clock::Clock;
use sui::coin::Coin;
use sui::vec_map::{Self, VecMap};
use suins::payment::{Receipt, PaymentIntent};
use suins::suins::SuiNS;

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

public struct CoinTypeData has store, drop {
    /// The coin's decimals.
    decimals: u8,
    // A discount can be applied if the user pays with this currency.
    discount_percentage: u8,
    // Pyth's price feed id for the given currency. Make sure you omit the `0x` prefix.
    price_feed_id: vector<u8>,
}

/// This has to be called with our base payment currency.
/// The payment has to be equal to the base price of the domain.
/// We do not need to check the price feed for the base currency.
public fun handle_base_payment<T>(
    suins: &mut SuiNS,
    intent: PaymentIntent,
    payment: Coin<T>,
): Receipt {
    let payment_type = type_name::get<T>();
    let config = suins.get_config<PaymentsConfig>();

    assert!(payment_type == config.base_currency, EInvalidPaymentType);

    let price = intent.request_data().base_amount();
    assert!(payment.value() == price, EInsufficientPayment);

    intent.finalize_payment(suins, PaymentsApp(), payment)
}

public fun handle_payment<T>(
    suins: &mut SuiNS,
    intent: PaymentIntent,
    payment: Coin<T>,
    clock: &Clock,
    price_info_object: &PriceInfoObject,
): Receipt {
    let payment_type = type_name::get<T>();
    let config = suins.get_config<PaymentsConfig>();

    assert!(config.currencies.contains(&payment_type), EInvalidPaymentType);

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
        price_info.get_price_identifier().get_bytes() == config.currencies.get(&payment_type).price_feed_id,
        EPriceFeedIdMismatch,
    );

    // The amount that has to be paid in base currency.
    let base_currency_price = intent.request_data().base_amount();

    // Now we need to calculate the amount of `T` coins that the user needs to pay.
    // We know that the price we'll be getting is relative to the base currency 
    // (In our scenario, USD)
    let decimal_i64 = price.get_expo();
    let price = price.get_price();

    // get the u64 price of SUI.
    let price_u64 = price.get_magnitude_if_positive();


    // TODO: Calculate the price, and if payment is sufficient, finalize or abort.
    // Math needed :)

    intent.finalize_payment(suins, PaymentsApp(), payment)
}

/// Creates a new CoinTypeData struct.
public fun new_coin_type_data(
    decimals: u8,
    discount_percentage: u8,
    // Pyth's price feed id for the given currency.
    // Leave empty for base currency.
    price_feed_id: vector<u8>,
): CoinTypeData {
    CoinTypeData {
        decimals,
        discount_percentage,
        price_feed_id,
    }
}

/// Creates a new PaymentsConfig struct.
/// Can be attached by the Admin to SuiNS to allow the payments module to work.
public fun new_payments_config(
    types: vector<TypeName>,
    setups: vector<CoinTypeData>,
    base_currency: TypeName,
    max_age: u64,
): PaymentsConfig {
    let currencies = vec_map::from_keys_values(types, setups);
    assert!(currencies.contains(&base_currency), EBaseCurrencySetupMissing);

    PaymentsConfig {
        currencies,
        base_currency,
        max_age,
    }
}
