module suins::pricing_config_tests;

use suins::pricing_config;

#[test]
fun test_e2e() {
    let ranges = vector[
        pricing_config::new_range(vector[1, 10]),
        pricing_config::new_range(vector[11, 20]),
        pricing_config::new_range(vector[21, 30]),
        pricing_config::new_range(vector[31, 31]),
    ];

    let pricing_config = pricing_config::new(
        ranges,
        vector[10, 20, 30, 45]
    );

    // test internal values
    assert!(pricing_config.calculate_base_price(5) == 10);
    assert!(pricing_config.calculate_base_price(15) == 20);
    assert!(pricing_config.calculate_base_price(25) == 30);

    // test upper bounds
    assert!(pricing_config.calculate_base_price(10) == 10);
    assert!(pricing_config.calculate_base_price(20) == 20);
    assert!(pricing_config.calculate_base_price(30) == 30);

    // test lower bounds
    assert!(pricing_config.calculate_base_price(1) == 10);
    assert!(pricing_config.calculate_base_price(11) == 20);
    assert!(pricing_config.calculate_base_price(21) == 30);

    // single length pricing
    assert!(pricing_config.calculate_base_price(31) == 45);
}

#[test, expected_failure(abort_code = ::suins::pricing_config::EInvalidRange)]
fun test_range_overlap_1() {
    let ranges = vector[
        pricing_config::new_range(vector[1, 10]),
        pricing_config::new_range(vector[9, 20]),
    ];

    pricing_config::new(ranges, vector[10, 20]);
}

#[test, expected_failure(abort_code = ::suins::pricing_config::EInvalidRange)]
fun test_range_overlap_2() {
    let ranges = vector[
        pricing_config::new_range(vector[1, 10]),
        pricing_config::new_range(vector[10, 20]),
    ];

    pricing_config::new(ranges, vector[10, 20]);
}

#[test, expected_failure(abort_code = ::suins::pricing_config::EInvalidRange)]
fun test_range_overlap_3() {
    let ranges = vector[
        pricing_config::new_range(vector[1, 10]),
        pricing_config::new_range(vector[21, 30]),
        pricing_config::new_range(vector[11, 20]),
    ];

    pricing_config::new(ranges, vector[10, 20, 30]);
}

#[test, expected_failure(abort_code = ::suins::pricing_config::EInvalidRange)]
fun test_range_overlap_4() {
    let ranges = vector[
        pricing_config::new_range(vector[20, 30]),
        pricing_config::new_range(vector[30, 40]),
        pricing_config::new_range(vector[40, 50]),
    ];

    pricing_config::new(ranges, vector[10, 20, 30]);
}

#[test, expected_failure(abort_code = ::suins::pricing_config::ELengthMissmatch)]
fun test_length_missmatch() {
    let ranges = vector[pricing_config::new_range(vector[10, 20])];

    pricing_config::new(ranges, vector[10, 20]);
}

#[test, expected_failure(abort_code = ::suins::pricing_config::EInvalidLength)]
fun test_range_construction_too_long() {
    pricing_config::new_range(vector[10, 20, 30]);
}

#[test, expected_failure(abort_code = ::suins::pricing_config::EInvalidRange)]
fun test_invalid_range_construction() {
    pricing_config::new_range(vector[20, 10]);
}

#[test, expected_failure(abort_code = ::suins::pricing_config::EPriceNotSet)]
fun test_price_not_set() {
    let ranges = vector[pricing_config::new_range(vector[1, 10])];

    let pricing = pricing_config::new(ranges, vector[10]);

    pricing.calculate_base_price(20);
}
