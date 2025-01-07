module suins::core_config_tests;

use sui::test_utils::assert_eq;
use sui::vec_map;
use suins::constants;
use suins::core_config::{Self, CoreConfig};
use suins::domain;

#[test]
fun test_config_creation_and_field_access() {
    let config = core_config::new(
        b"",
        3,
        63,
        constants::payments_version!(),
        1,
        vector[constants::sui_tld()],
        vec_map::empty(),
    );

    assert_eq(config.public_key(), b"");
    assert_eq(config.min_label_length(), 3);
    assert_eq(config.max_label_length(), 63);
    assert_eq(config.payments_version(), constants::payments_version!());
    assert!(config.is_valid_tld(&constants::sui_tld()));
}

#[test]
fun test_valid_domains() {
    let config = core_config::default();
    let mut domain = domain::new(b"suins.sui".to_string());
    config.assert_is_valid_for_sale(&domain);

    domain = domain::new(b"sui.sui".to_string());
    config.assert_is_valid_for_sale(&domain);
}

#[test]
fun custom_config_valid_length() {
    let config = core_config::new(
        b"",
        1,
        63,
        constants::payments_version!(),
        5,
        vector[constants::sui_tld()],
        vec_map::empty(),
    );
    config.assert_is_valid_for_sale(&domain::new(b"0.sui".to_string()));
}

#[test, expected_failure(abort_code = core_config::EInvalidTld)]
fun test_invalid_tld() {
    core_config::default().assert_is_valid_for_sale(&domain::new(b"suins.move".to_string()));
}

#[test, expected_failure(abort_code = core_config::EInvalidLength)]
fun test_invalid_label_length() {
    core_config::default().assert_is_valid_for_sale(&domain::new(b"o.sui".to_string()));
}

#[test, expected_failure(abort_code = core_config::EInvalidLength)]
fun test_invalid_label_length_2() {
    custom_config(1, 5).assert_is_valid_for_sale(
        &domain::new(b"123456.sui".to_string()),
    );
}

#[test, expected_failure(abort_code = core_config::ESubnameNotSupported)]
fun test_subname_not_supported() {
    custom_config(1, 5).assert_is_valid_for_sale(
        &domain::new(b"inner.suins.sui".to_string()),
    );
}

fun custom_config(min: u8, max: u8): CoreConfig {
    core_config::new(
        b"",
        min,
        max,
        constants::payments_version!(),
        5,
        vector[constants::sui_tld()],
        vec_map::empty(),
    )
}
