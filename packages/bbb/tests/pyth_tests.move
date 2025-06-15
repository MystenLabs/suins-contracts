#[test_only]
module suins_bbb::bbb_pyth_tests;

use std::{
    unit_test::assert_eq,
};
use suins_bbb::{
    bbb_pyth::calc,
};

const ONE_SUI: u64 = 1_000_000_000;
const ONE_NS: u64 = 1_000_000;
const ONE_USDC: u64 = 1_000_000;

const SUI_DECIMALS: u8 = 9;
const SUI_PRICE_USD: u64 = 300773283;
const SUI_PRICE_EXP: u8 = 8;

const NS_DECIMALS: u8 = 6;
const NS_PRICE_USD: u64 = 16268455;
const NS_PRICE_EXP: u8 = 8;

const USDC_DECIMALS: u8 = 6;
const USDC_PRICE_USD: u64 = 99979863;
const USDC_PRICE_EXP: u8 = 8;

#[test]
fun test_pyth_calculations() {
    // SUI->USDC
    // 3 SUI to USDC = 3 * 300773283/99979863 * 10^6 = 9025015.85744
    let sui_amount = 3 * ONE_SUI;
    let usdc_expected = 9025015;
    let usdc_amount = calc(
        SUI_PRICE_USD,
        USDC_PRICE_USD,
        SUI_PRICE_EXP,
        USDC_PRICE_EXP,
        SUI_DECIMALS,
        USDC_DECIMALS,
        sui_amount,
    );
    assert_eq!(usdc_expected, usdc_amount);

    // 3 USDC to SUI = 3 * 99979863/300773283 * 10^9 = 997228164.71
    let usdc_amount = 3 * ONE_USDC;
    let sui_expected = 997228164;
    let sui_amount = calc(
        USDC_PRICE_USD,
        SUI_PRICE_USD,
        USDC_PRICE_EXP,
        SUI_PRICE_EXP,
        USDC_DECIMALS,
        SUI_DECIMALS,
        usdc_amount,
    );
    assert_eq!(sui_expected, sui_amount);

    // 3 NS to USDC = 3 * 16268455/99979863 * 10^6 = 488151.949158
    let ns_amount = 3 * ONE_NS;
    let usdc_expected = 488151;
    let usdc_amount = calc(
        NS_PRICE_USD,
        USDC_PRICE_USD,
        NS_PRICE_EXP,
        USDC_PRICE_EXP,
        NS_DECIMALS,
        USDC_DECIMALS,
        ns_amount,
    );
    assert_eq!(usdc_expected, usdc_amount);

    // 3 USDC to NS = 3 * 99979863/16268455 * 10^6 = 18436882.2362
    let usdc_amount = 3 * ONE_USDC;
    let ns_expected = 18436882;
    let ns_amount = calc(
        USDC_PRICE_USD,
        NS_PRICE_USD,
        USDC_PRICE_EXP,
        NS_PRICE_EXP,
        USDC_DECIMALS,
        NS_DECIMALS,
        usdc_amount,
    );
    assert_eq!(ns_expected, ns_amount);

    // 3 SUI to NS = 3 * 300773283/16268455 * 10^6 = 55464384.8479
    let sui_amount = 3 * ONE_SUI;
    let ns_expected = 55464384;
    let ns_amount = calc(
        SUI_PRICE_USD,
        NS_PRICE_USD,
        SUI_PRICE_EXP,
        NS_PRICE_EXP,
        SUI_DECIMALS,
        NS_DECIMALS,
        sui_amount,
    );
    assert_eq!(ns_expected, ns_amount);

    // 3 NS to SUI = 3 * 16268455/300773283 * 10^9 = 162266290.786
    let ns_amount = 3 * ONE_NS;
    let sui_expected = 162266290;
    let sui_amount = calc(
        NS_PRICE_USD,
        SUI_PRICE_USD,
        NS_PRICE_EXP,
        SUI_PRICE_EXP,
        NS_DECIMALS,
        SUI_DECIMALS,
        ns_amount,
    );
    assert_eq!(sui_expected, sui_amount);
}
