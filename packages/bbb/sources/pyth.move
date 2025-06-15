module suins_bbb::bbb_pyth;

use sui::{
    clock::Clock,
};
use pyth::{
    price_info::PriceInfoObject,
    pyth::Self,
};

public(package) fun calc_expected_coin_out(
    info_in: &PriceInfoObject,
    info_out: &PriceInfoObject,
    decimals_in: u8,
    decimals_out: u8,
    amount_in: u64,
    max_age_secs: u64,
    clock: &Clock,
): u64 {
    // get the price of both coins in USD
    let usd_price_in = pyth::get_price_no_older_than(
        info_in,
        clock,
        max_age_secs,
    );
    let usd_price_out = pyth::get_price_no_older_than(
        info_out,
        clock,
        max_age_secs,
    );

    // extract price magnitudes and decimal exponents from the `Price` structs
    let mag_in = usd_price_in.get_price().get_magnitude_if_positive();
    let mag_out = usd_price_out.get_price().get_magnitude_if_positive();
    let dec_in = usd_price_in.get_expo().get_magnitude_if_negative() as u8;
    let dec_out = usd_price_out.get_expo().get_magnitude_if_negative() as u8;

    // buffer to avoid precision loss when the computed exponent would be negative
    let buffer: u8 = 10;

    // calculate the exponent that aligns the two price / coin-decimal systems
    let exp_with_buffer =
        buffer + decimals_out + dec_out
               - decimals_in  - dec_in;

    // numerator = amount_in * price_in * 10^(buffer + exp_diff)
    let numerator = (amount_in as u128)
        * (mag_in as u128)
        * 10u128.pow(exp_with_buffer);
    // denominator = price_out
    let denominator = mag_out as u128;

    // divide and round up, then drop the extra buffer
    let expected_coin_out = numerator
        .divide_and_round_up(denominator)
        .divide_and_round_up(10u128.pow(buffer)) as u64;

    expected_coin_out
}
