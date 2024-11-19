module payments::payments_tests;

#[test]
fun test_math() {
    let buffer = 10;
    let target_decimals: u8 = 9;
    let base_decimals: u8 = 6;
    let pyth_decimals: u8 = 8;
    let pyth_price = 380000000; // SUI price 3.8
    let base_currency_amount = 100 * 1_000_000; // 100 USDC

    let exponent_with_buffer =
        buffer + target_decimals + pyth_decimals - base_decimals;
    let target_currency_amount =
        (base_currency_amount as u128 * 10u128.pow(exponent_with_buffer))
            .divide_and_round_up(pyth_price as u128)
            .divide_and_round_up(10u128.pow(buffer)) as u64;

    assert!(target_currency_amount == 26315789474, 1); // 26.315789474 SUI
}

#[test]
fun test_math_2() {
    let buffer = 10;
    let target_decimals: u8 = 0; // TOKEN has no decimals
    let base_decimals: u8 = 6;
    let pyth_decimals: u8 = 3;
    let pyth_price = 3800; // TOKEN price 3.8
    let base_currency_amount = 100 * 1_000_000; // 100 USDC

    let exponent_with_buffer =
        buffer + target_decimals + pyth_decimals - base_decimals;
    let target_currency_amount =
        (base_currency_amount as u128 * 10u128.pow(exponent_with_buffer))
            .divide_and_round_up(pyth_price as u128)
            .divide_and_round_up(10u128.pow(buffer)) as u64;

    assert!(target_currency_amount == 27, 1); // 27 TOKEN
}
