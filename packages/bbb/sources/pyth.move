module suins_bbb::bbb_pyth;

use pyth_pro_compatible::{price_info::PriceInfoObject as ProPriceInfoObject, pyth as pyth_pro};
use sui::clock::Clock;

const EInvalidPriceIn: u64 = 1000;
const EInvalidPriceOut: u64 = 1001;

/// Reads the Pro-compatible Pyth feed to compute the output amount, for use after the
/// Pyth Core to Pro cutover.
public(package) fun calc_amount_out_pro(
    info_in: &ProPriceInfoObject,
    info_out: &ProPriceInfoObject,
    decimals_in: u8,
    decimals_out: u8,
    amount_in: u64,
    max_age_secs: u64,
    clock: &Clock,
): u64 {
    // get the USD price and decimal exponent for both coins
    let price_in = pyth_pro::get_price_no_older_than(info_in, clock, max_age_secs);
    let price_usd_in = price_in.get_price().get_magnitude_if_positive();
    let price_exp_in = price_in.get_expo().get_magnitude_if_negative() as u8;
    let price_out = pyth_pro::get_price_no_older_than(info_out, clock, max_age_secs);
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
