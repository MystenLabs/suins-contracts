/// Core configuration of the SuiNS application.
///
/// This configuration is used to validate domains for registration and renewal.
/// It can only be stored as a valid config in the `SuiNS` object by an admin,
/// hence why all the functions are public. Having just the config object cannot
/// pose a security risk as it cannot be used.
module suins::core_config;

use std::string::String;
use sui::vec_map::{Self, VecMap};
use sui::vec_set::{Self, VecSet};
use suins::constants;
use suins::domain::Domain;

#[error]
const EInvalidLength: vector<u8> = b"Invalid length for the label part of the domain.";

#[error]
const EInvalidTld: vector<u8> = b"Invalid TLD";

#[error]
const ESubnameNotSupported: vector<u8> = b"Subdomains are not supported for sales.";

public struct CoreConfig has copy, drop, store {
    /// Public key of the API server. Currently only used for direct setup.
    public_key: vector<u8>,
    /// Minimum length of the label part of the domain. This is different from
    /// the base `domain` checks. This is our minimum acceptable length (for sales).
    /// TODO: Shoudl we consider removing this? Our range is [1,63] by design, and
    /// the `PricingConfig` won't have 1,2 digits if we don't want to have.
    min_label_length: u8,
    /// Maximum length of the label part of the domain.
    max_label_length: u8,
    /// List of valid TLDs for registration / renewals.
    valid_tlds: VecSet<String>,
    /// The `PaymentIntent` version that can be used for handling sales.
    payments_version: u8,
    /// Maximum number of years available for a domain.
    max_years: u8,
    // Extra fields for future use.
    extra: VecMap<String, String>,
}

public fun new(
    public_key: vector<u8>,
    min_label_length: u8,
    max_label_length: u8,
    payments_version: u8,
    max_years: u8,
    valid_tlds: vector<String>,
    extra: VecMap<String, String>,
): CoreConfig {
    CoreConfig {
        public_key,
        min_label_length,
        max_label_length,
        payments_version,
        max_years,
        valid_tlds: vec_set::from_keys(valid_tlds),
        extra,
    }
}

public fun public_key(config: &CoreConfig): vector<u8> {
    config.public_key
}

public fun min_label_length(config: &CoreConfig): u8 {
    config.min_label_length
}

public fun max_label_length(config: &CoreConfig): u8 {
    config.max_label_length
}

public fun is_valid_tld(config: &CoreConfig, tld: &String): bool {
    config.valid_tlds.contains(tld)
}

public fun payments_version(config: &CoreConfig): u8 {
    config.payments_version
}

public fun max_years(config: &CoreConfig): u8 {
    config.max_years
}

public(package) fun assert_is_valid_for_sale(config: &CoreConfig, domain: &Domain) {
    assert!(!domain.is_subdomain(), ESubnameNotSupported);
    assert!(config.is_valid_tld(domain.tld()), EInvalidTld);

    let sld_len = domain.sld().length();
    assert!(
        sld_len >= (config.min_label_length as u64) && sld_len <= (config.max_label_length as u64),
        EInvalidLength,
    );
}

#[test_only]
public fun default(): CoreConfig {
    new(
        b"",
        3,
        63,
        constants::payments_version!(),
        5,
        vector[constants::sui_tld()],
        vec_map::empty(),
    )
}
