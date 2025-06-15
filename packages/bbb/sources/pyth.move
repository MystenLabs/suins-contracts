module suins_bbb::bbb_pyth;

use sui::{
    clock::Clock,
};
use pyth::{
    price_info::PriceInfoObject,
    pyth::Self,
};

public(package) fun calc_expected_coin_out(
    coin_in_price_info_obj: &PriceInfoObject,
    coin_out_price_info_obj: &PriceInfoObject,
    coin_in_decimals: u8,
    coin_out_decimals: u8,
    coin_in_amount: u64,
    max_age_secs: u64,
    clock: &Clock,
): u64 {
    // get the price of both coins in USD
    let coin_in_price_usd = pyth::get_price_no_older_than(
        coin_in_price_info_obj,
        clock,
        max_age_secs,
    );
    let coin_out_price_usd = pyth::get_price_no_older_than(
        coin_out_price_info_obj,
        clock,
        max_age_secs,
    );

    // extract price magnitudes and decimal exponents from the `Price` structs
    let coin_in_price_mag = coin_in_price_usd.get_price().get_magnitude_if_positive();
    let coin_out_price_mag = coin_out_price_usd.get_price().get_magnitude_if_positive();
    let coin_in_price_dec = coin_in_price_usd.get_expo().get_magnitude_if_negative() as u8;
    let coin_out_price_dec = coin_out_price_usd.get_expo().get_magnitude_if_negative() as u8;

    // buffer to avoid precision loss when the computed exponent would be negative
    let buffer: u8 = 10;

    // calculate the exponent that aligns the two price / coin-decimal systems
    let exp_with_buffer =
        buffer + coin_out_decimals + coin_out_price_dec
               - coin_in_decimals  - coin_in_price_dec;

    // numerator = amount_in * price_in * 10^(buffer + exp_diff)
    let numerator = (coin_in_amount as u128)
        * (coin_in_price_mag as u128)
        * 10u128.pow(exp_with_buffer);
    // denominator = price_out
    let denominator = coin_out_price_mag as u128;

    // divide and round up, then drop the extra buffer
    let expected_coin_out = numerator
        .divide_and_round_up(denominator)
        .divide_and_round_up(10u128.pow(buffer)) as u64;

    expected_coin_out
}
