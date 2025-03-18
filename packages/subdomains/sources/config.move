// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module subdomains::config;

use std::string::String;
use suins::{constants::sui_tld, domain::{Domain, is_parent_of}};

/// the minimum size a subdomain label can have.
const MIN_LABEL_SIZE: u8 = 3;
/// the maximum depth a subdomain can have -> 8 (+ 2 for TLD, SLD)
const MAX_SUBDOMAIN_DEPTH: u8 = 10;
/// Minimum duration for a subdomain in milliseconds. (1 day)
const MINIMUM_SUBDOMAIN_DURATION: u64 = 24 * 60 * 60 * 1000;

/// tries to register a subdomain with a depth more than the one allowed.
const EDepthOutOfLimit: u64 = 1;
/// tries to register a subdomain with the wrong parent (based on name)
const EInvalidParent: u64 = 2;
/// tries to register a label of size less than 3.
const EInvalidLabelSize: u64 = 3;
/// tries to register a domain with an unsupported tld.
const ENotSupportedTLD: u64 = 4;

/// A Subdomain configuration object.
/// Holds the allow-listed tlds, the max depth and the minimum label size.
public struct SubDomainConfig has copy, drop, store {
    allowed_tlds: vector<String>,
    max_depth: u8,
    min_label_size: u8,
    minimum_duration: u64,
}

public fun default(): SubDomainConfig {
    SubDomainConfig {
        allowed_tlds: vector[sui_tld()],
        max_depth: MAX_SUBDOMAIN_DEPTH,
        min_label_size: MIN_LABEL_SIZE,
        minimum_duration: MINIMUM_SUBDOMAIN_DURATION,
    }
}

// Generates a custom config for Subdomains.
public fun new(
    allowed_tlds: vector<String>,
    max_depth: u8,
    min_label_size: u8,
    minimum_duration: u64,
): SubDomainConfig {
    SubDomainConfig {
        allowed_tlds,
        max_depth,
        min_label_size,
        minimum_duration,
    }
}

/// Validates that the child name is a valid child for parent.
public fun assert_is_valid_subdomain(parent: &Domain, child: &Domain, config: &SubDomainConfig) {
    assert!(is_valid_tld(child, config), ENotSupportedTLD);
    assert!(is_valid_label(child, config), EInvalidLabelSize);
    assert!(has_valid_depth(child, config), EDepthOutOfLimit);
    assert!(is_parent_of(parent, child), EInvalidParent);
}

public fun minimum_duration(config: &SubDomainConfig): u64 {
    config.minimum_duration
}

/// Validate that the depth of the subdomain is with the allowed range.
public fun has_valid_depth(domain: &Domain, config: &SubDomainConfig): bool {
    domain.number_of_levels() <= (config.max_depth as u64)
}

/// Validates that the TLD of the domain is supported for subdomains.
/// In the beginning, only .sui names will be supported but we might
/// want to add support for others (or not allow).
/// (E.g., with `.move` service, we might want to restrict how subdomains are created)
public fun is_valid_tld(domain: &Domain, config: &SubDomainConfig): bool {
    let mut i = 0;
    while (i < config.allowed_tlds.length()) {
        if (domain.tld() == &config.allowed_tlds[i]) {
            return true
        };
        i = i + 1;
    };
    return false
}

/// Validate that the subdomain label (e.g. `sub` in `sub.example.sui`) is valid.
/// We do not need to check for max length (64), as this is already checked
/// in the `Domain` construction.
public fun is_valid_label(domain: &Domain, config: &SubDomainConfig): bool {
    // our label is the last vector element, as labels are stored in reverse order.
    let label = domain.label(domain.number_of_levels() - 1);
    label.length() >= (config.min_label_size as u64)
}
