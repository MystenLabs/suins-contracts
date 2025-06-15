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
    let price_usd_in = usd_price_in.get_price().get_magnitude_if_positive();
    let price_usd_out = usd_price_out.get_price().get_magnitude_if_positive();
    let price_exp_in = usd_price_in.get_expo().get_magnitude_if_negative() as u8;
    let price_exp_out = usd_price_out.get_expo().get_magnitude_if_negative() as u8;

    calc(
        price_usd_in,
        price_usd_out,
        price_exp_in,
        price_exp_out,
        decimals_in,
        decimals_out,
        amount_in,
    )
}

public(package) fun calc(
    price_usd_in: u64,
    price_usd_out: u64,
    price_exp_in: u8,
    price_exp_out: u8,
    decimals_in: u8,
    decimals_out: u8,
    amount_in: u64,
): u64 {
    // buffer to avoid precision loss when the computed exponent would be negative
    let buffer: u8 = 10;

    // calculate the exponent that aligns the two price / coin-decimal systems
    let exp_with_buffer =
        buffer + decimals_out + price_exp_out
               - decimals_in  - price_exp_in;

    // numerator = amount_in * price_in * 10^(buffer + exp_diff)
    let numerator = (amount_in as u128)
        * (price_usd_in as u128)
        * 10u128.pow(exp_with_buffer);
    // denominator = price_out
    let denominator = price_usd_out as u128;

    // divide, then drop the extra buffer
    let expected_coin_out = numerator
        / denominator
        / 10u128.pow(buffer);

    expected_coin_out as u64
}
