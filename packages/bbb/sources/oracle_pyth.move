module suins_bbb::oracle_pyth;

use sui::{
    clock::Clock,
};
use pyth::{
    price_info::PriceInfoObject,
    pyth::Self,
};
use suins_bbb::{
    bbb_config::{AftermathSwapConfig, BBBConfig},
};

// === errors ===

const ECoinInPriceFeedIdMismatch: u64 = 100;
const ECoinOutPriceFeedIdMismatch: u64 = 101;

public(package) fun calc_expected_coin_out(
    bbb_conf: &BBBConfig,
    swap_conf: &AftermathSwapConfig,
    coin_in_price_info_obj: &PriceInfoObject,
    coin_out_price_info_obj: &PriceInfoObject,
    coin_in_amount: u64,
    clock: &Clock,
): u64 {
    // check that the price feed ids match the swap configuration
    let coin_in_price_info = coin_in_price_info_obj.get_price_info_from_price_info_object();
    let coin_out_price_info = coin_out_price_info_obj.get_price_info_from_price_info_object();
    assert!(
        coin_in_price_info.get_price_identifier().get_bytes() == swap_conf.coin_in_feed_id(),
        ECoinInPriceFeedIdMismatch,
    );
    assert!(
        coin_out_price_info.get_price_identifier().get_bytes() == swap_conf.coin_out_feed_id(),
        ECoinOutPriceFeedIdMismatch,
    );

    // get the price of both coins in USD
    let coin_in_price_usd = pyth::get_price_no_older_than(
        coin_in_price_info_obj,
        clock,
        bbb_conf.max_age_secs(),
    );
    let coin_out_price_usd = pyth::get_price_no_older_than(
        coin_out_price_info_obj,
        clock,
        bbb_conf.max_age_secs(),
    );

    // extract price magnitudes and decimal exponents from the `Price` structs
    let coin_in_price_mag = coin_in_price_usd.get_price().get_magnitude_if_positive();
    let coin_out_price_mag = coin_out_price_usd.get_price().get_magnitude_if_positive();
    let coin_in_price_dec = coin_in_price_usd.get_expo().get_magnitude_if_negative() as u8;
    let coin_out_price_dec = coin_out_price_usd.get_expo().get_magnitude_if_negative() as u8;

    // buffer to avoid precision loss when the computed exponent would be negative
    let buffer: u8 = 10;

    // calculate the exponent that aligns the two price / coin-decimal systems
    let coin_in_decimals = swap_conf.coin_in_decimals();
    let coin_out_decimals = swap_conf.coin_out_decimals();
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
