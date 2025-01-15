// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module payments::unit_tests;

use payments::payments::calculate_target_currency_amount;

#[test]
fun test_calculate_target_currency() {
    let target_decimals: u8 = 9;
    let base_decimals: u8 = 6;
    let pyth_decimals: u8 = 8;
    let pyth_price = 380000000; // SUI price 3.8
    let base_currency_amount = 100 * 1_000_000; // 100 USDC

    let target_currency_amount = calculate_target_currency_amount(
        base_currency_amount,
        target_decimals,
        base_decimals,
        pyth_price,
        pyth_decimals,
    );

    assert!(target_currency_amount == 26315789474, 1); // 26.315789474 SUI
}

#[test]
fun test_calculate_target_currency_2() {
    let target_decimals: u8 = 0; // TOKEN has no decimals
    let base_decimals: u8 = 6;
    let pyth_decimals: u8 = 3;
    let pyth_price = 3800; // TOKEN price 3.8
    let base_currency_amount = 100 * 1_000_000; // 100 USDC

    let target_currency_amount = calculate_target_currency_amount(
        base_currency_amount,
        target_decimals,
        base_decimals,
        pyth_price,
        pyth_decimals,
    );

    assert!(target_currency_amount == 27, 1); // 27 TOKEN
}

#[test, expected_failure(abort_code = ::payments::payments::EInvalidPythPrice)]
fun test_calculate_target_currency_invalid_pyth_price() {
    let target_decimals: u8 = 9;
    let base_decimals: u8 = 6;
    let pyth_decimals: u8 = 8;
    let pyth_price = 0; // Price 0
    let base_currency_amount = 100 * 1_000_000;

    calculate_target_currency_amount(
        base_currency_amount,
        target_decimals,
        base_decimals,
        pyth_price,
        pyth_decimals,
    );
}
