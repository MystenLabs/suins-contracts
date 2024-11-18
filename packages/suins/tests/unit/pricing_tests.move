module suins::pricing_tests;

use sui::coin::Coin;
use sui::sui::SUI;
use suins::pricing;

#[test]
fun test_e2e() {
    let ranges = vector[
        pricing::new_range(vector[1, 10]),
        pricing::new_range(vector[11, 20]),
        pricing::new_range(vector[21, 30]),
        pricing::new_range(vector[31, 31]),
    ];

    let pricing_config = pricing::new(
        ranges,
        vector[10, 20, 30, 45],
    );

    // test internal values
    assert!(pricing_config.calculate_price(5) == 10);
    assert!(pricing_config.calculate_price(15) == 20);
    assert!(pricing_config.calculate_price(25) == 30);

    // test upper bounds
    assert!(pricing_config.calculate_price(10) == 10);
    assert!(pricing_config.calculate_price(20) == 20);
    assert!(pricing_config.calculate_price(30) == 30);

    // test lower bounds
    assert!(pricing_config.calculate_price(1) == 10);
    assert!(pricing_config.calculate_price(11) == 20);
    assert!(pricing_config.calculate_price(21) == 30);

    // single length pricing
    assert!(pricing_config.calculate_price(31) == 45);
}

#[test, expected_failure(abort_code = ::suins::pricing::EInvalidRange)]
fun test_range_overlap_1() {
    let ranges = vector[
        pricing::new_range(vector[1, 10]),
        pricing::new_range(vector[9, 20]),
    ];

    pricing::new(ranges, vector[10, 20]);
}

#[test, expected_failure(abort_code = ::suins::pricing::EInvalidRange)]
fun test_range_overlap_2() {
    let ranges = vector[
        pricing::new_range(vector[1, 10]),
        pricing::new_range(vector[10, 20]),
    ];

    pricing::new(ranges, vector[10, 20]);
}

#[test, expected_failure(abort_code = ::suins::pricing::EInvalidRange)]
fun test_range_overlap_3() {
    let ranges = vector[
        pricing::new_range(vector[1, 10]),
        pricing::new_range(vector[21, 30]),
        pricing::new_range(vector[11, 20]),
    ];

    pricing::new(ranges, vector[10, 20, 30]);
}

#[test, expected_failure(abort_code = ::suins::pricing::EInvalidRange)]
fun test_range_overlap_4() {
    let ranges = vector[
        pricing::new_range(vector[20, 30]),
        pricing::new_range(vector[30, 40]),
        pricing::new_range(vector[40, 50]),
    ];

    pricing::new(ranges, vector[10, 20, 30]);
}

#[test, expected_failure(abort_code = ::suins::pricing::ELengthMissmatch)]
fun test_length_missmatch() {
    let ranges = vector[pricing::new_range(vector[10, 20])];

    pricing::new(ranges, vector[10, 20]);
}

#[test, expected_failure(abort_code = ::suins::pricing::EInvalidLength)]
fun test_range_construction_too_long() {
    pricing::new_range(vector[10, 20, 30]);
}

#[test, expected_failure(abort_code = ::suins::pricing::EInvalidRange)]
fun test_invalid_range_construction() {
    pricing::new_range(vector[20, 10]);
}

#[test, expected_failure(abort_code = ::suins::pricing::EPriceNotSet)]
fun test_price_not_set() {
    let ranges = vector[pricing::new_range(vector[1, 10])];

    let pricing = pricing::new(ranges, vector[10]);

    pricing.calculate_price(20);
}
