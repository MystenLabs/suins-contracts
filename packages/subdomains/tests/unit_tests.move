// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module suins_subdomains::unit_tests;

use std::string::utf8;
use suins::domain::{Self, new as new_domain, parent};
use suins_subdomains::config::{Self, assert_is_valid_subdomain, default};

// === Validity of subdomain | parent lengths (based on string) ===
#[test]
fun test_parent_relationships() {
    assert_is_valid_subdomain(
        &new_domain(utf8(b"example.sui")),
        &new_domain(utf8(b"sub.example.sui")),
        &default(),
    );
    assert_is_valid_subdomain(
        &new_domain(utf8(b"sub.example.sui")),
        &new_domain(utf8(b"sub.sub.example.sui")),
        &default(),
    );
    assert_is_valid_subdomain(
        &new_domain(utf8(b"sub.sub.example.sui")),
        &new_domain(utf8(b"sub.sub.sub.example.sui")),
        &default(),
    );
    assert_is_valid_subdomain(
        &new_domain(utf8(b"sub.sub.sub.sub.sub.example.sui")),
        &new_domain(utf8(b"sub.sub.sub.sub.sub.sub.example.sui")),
        &default(),
    );
}

#[test, expected_failure(abort_code = ::suins_subdomains::config::EDepthOutOfLimit)]
fun test_too_large_subdomain_failure() {
    assert_is_valid_subdomain(
        &new_domain(utf8(b"example.sui")),
        &new_domain(utf8(b"sub.sub.sub.sub.sub.sub.sub.sub.sub.example.sui")),
        &default(),
    );
}

#[test, expected_failure(abort_code = ::suins_subdomains::config::EInvalidParent)]
fun test_invalid_parent_length_failure() {
    assert_is_valid_subdomain(
        &new_domain(utf8(b"example.sui")),
        &new_domain(utf8(b"sub.sub.example.sui")),
        &default(),
    );
}

#[test, expected_failure(abort_code = ::suins_subdomains::config::EInvalidParent)]
fun test_invalid_parent_smaller_length_failure() {
    assert_is_valid_subdomain(
        &new_domain(utf8(b"sub.sub.example.sui")),
        &new_domain(utf8(b"sub.example.sui")),
        &default(),
    );
}

#[test, expected_failure(abort_code = ::suins_subdomains::config::EInvalidParent)]
fun test_invalid_parent_failure() {
    assert_is_valid_subdomain(
        &new_domain(utf8(b"test.example.sui")),
        &new_domain(utf8(b"sub.sub.example.sui")),
        &default(),
    );
}

#[test, expected_failure(abort_code = ::suins_subdomains::config::EInvalidParent)]
fun test_invalid_parent_tld_failure() {
    assert_is_valid_subdomain(
        &new_domain(utf8(b"sub.example.move")),
        &new_domain(utf8(b"sub.sub.example.sui")),
        &default(),
    );
}
#[test, expected_failure(abort_code = ::suins_subdomains::config::EInvalidParent)]
fun test_invalid_parent_sld_failure() {
    assert_is_valid_subdomain(
        &new_domain(utf8(b"sub.exampl.sui")),
        &new_domain(utf8(b"sub.sub.example.sui")),
        &default(),
    );
}

#[test]
fun test_short_label_subdomains() {
    // 1-char and 2-char subdomain labels are valid with the default config (min_label_size = 1)
    assert_is_valid_subdomain(
        &new_domain(utf8(b"example.sui")),
        &new_domain(utf8(b"a.example.sui")),
        &default(),
    );
    assert_is_valid_subdomain(
        &new_domain(utf8(b"example.sui")),
        &new_domain(utf8(b"ab.example.sui")),
        &default(),
    );
}

#[test, expected_failure(abort_code = ::suins_subdomains::config::EInvalidLabelSize)]
fun test_invalid_child_label_size_with_custom_config() {
    // A custom config with min_label_size = 3 should reject 2-char labels
    let custom_config = config::new(
        vector[utf8(b"sui")],
        10,
        3,
        24 * 60 * 60 * 1000,
    );
    assert_is_valid_subdomain(
        &new_domain(utf8(b"example.sui")),
        &new_domain(utf8(b"ob.example.sui")),
        &custom_config,
    );
}

#[test, expected_failure(abort_code = ::suins_subdomains::config::ENotSupportedTLD)]
fun test_not_supported_tld_failure() {
    assert_is_valid_subdomain(
        &new_domain(utf8(b"sub.sub.example.move")),
        &new_domain(utf8(b"sub.example.move")),
        &default(),
    );
}

#[test]
fun derive_parent_from_child() {
    let parent = parent(&new_domain(utf8(b"sub.example.sui")));
    assert!(domain::to_string(&parent) == utf8(b"example.sui"), 0);

    let parent = parent(&new_domain(utf8(b"sub.sub.sub.sub.sub.sub.example.sui")));
    assert!(domain::to_string(&parent) == utf8(b"sub.sub.sub.sub.sub.example.sui"), 0);
}
