module suins_bbb::bbb_pyth;

use sui::{
    clock::Clock,
};
use pyth::{
    price_info::PriceInfoObject,
    pyth::Self,
};

const EInvalidPriceIn: u64 = 100;
const EInvalidPriceOut: u64 = 101;

/// Calculate the expected output amount for a swap using Pyth price feeds.
/// Converts `amount_in` of the input coin to equivalent value in output coin.
/// E.g. if 1 SUI is worth $3, then 1e9 SUI (amount_in) -> 3e6 USDC (return value)
public(package) fun calc_amount_out(
    info_in: &PriceInfoObject,
    info_out: &PriceInfoObject,
    decimals_in: u8,
    decimals_out: u8,
    amount_in: u64,
    max_age_secs: u64,
    clock: &Clock,
): u64 {
    // get the USD price and decimal exponent for both coins
    let price_in = pyth::get_price_no_older_than(info_in, clock, max_age_secs);
    let price_usd_in = price_in.get_price().get_magnitude_if_positive();
    let price_exp_in = price_in.get_expo().get_magnitude_if_negative() as u8;
    let price_out = pyth::get_price_no_older_than(info_out, clock, max_age_secs);
    let price_usd_out = price_out.get_price().get_magnitude_if_positive();
    let price_exp_out = price_out.get_expo().get_magnitude_if_negative() as u8;

    assert!(price_usd_in > 0, EInvalidPriceIn);
    assert!(price_usd_out > 0, EInvalidPriceOut);

    // do the math
    calc_amount_out_internal(
        price_usd_in,
        price_exp_in,
        decimals_in,
        price_usd_out,
        price_exp_out,
        decimals_out,
        amount_in,
    )
}

/// Internal price calculation.
/// Function is not private only so we can unit test.
public(package) fun calc_amount_out_internal(
    price_usd_in: u64,
    price_exp_in: u8,
    coin_decimals_in: u8,
    price_usd_out: u64,
    price_exp_out: u8,
    coin_decimals_out: u8,
    amount_in: u64,
): u64 {
    // combine price and coin decimal places
    let total_exp_in = price_exp_in + coin_decimals_in;
    let total_exp_out = price_exp_out + coin_decimals_out;

    // determine scaling to align decimal places
    let (scale_numerator, scale_denominator) = if (total_exp_in >= total_exp_out) {
        let diff = total_exp_in - total_exp_out;
        (1u256, 10u256.pow(diff))
    } else {
        let diff = total_exp_out - total_exp_in;
        (10u256.pow(diff), 1u256)
    };

    let numerator = (amount_in as u256) * (price_usd_in as u256) * scale_numerator;
    let denominator = (price_usd_out as u256) * scale_denominator;

    (numerator / denominator) as u64
}
