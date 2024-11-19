
// module payments::payments_tests;

// use std::u64;

// #[test]
// fun test_ugly_math() {

//     let chain_decimals = 6;
//     let pyth_decimals = 8; // -8 equivalent
//     let target_decimals = 6;

//     let pyth_price = 37017259;

//     let exponent = 0;

//     let val = (2_000_000 * 1_000_000 * 10u64.pow(exponent as u8)).divide_and_round_up(pyth_price);

//     std::debug::print(&val);

//     // 10^(chain_decimal_ns - pyth_expo - usdc_decimal) / pyth_price * x
// }
