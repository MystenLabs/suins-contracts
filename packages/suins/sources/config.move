// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// Module holding the application configuration for the V1 of the SuiNS
/// application. Responsible for providing the configuration type `Config` as
/// well as methods to read it. Additionally, implements necessary input checks
/// to lessen the chance of a mistake during deployment / configuration stages.
///
/// Contains no access-control checks and all methods are public for the
/// following reasons:
/// - configuration can only be attached by the application Admin;
/// - attached to the SuiNS object directly and can only be *read* by other parts of the system;
///
/// Notes:
/// - set_* methods are currently not used;
/// - a simpler way to update the configuration would be to remove it completely
/// and set again within the same Programmable Transaction Block (can only be
/// performed by Admin)
module suins::config {
    use suins::{constants, domain::Domain};

    /// A label is too short to be registered.
    const ELabelTooShort: u64 = 0;
    /// A label is too long to be registered.
    const ELabelTooLong: u64 = 1;
    /// The price value is invalid.
    const EInvalidPrice: u64 = 2;
    /// The public key is not a Secp256k1 public key which is of length 33 bytes
    const EInvalidPublicKey: u64 = 3;
    /// Incorrect number of years passed to the function.
    const ENoYears: u64 = 4;
    /// Trying to register a subdomain (only *.sui is currently allowed).
    const EInvalidDomain: u64 = 5;
    /// Trying to register a domain name in a different TLD (not .sui).
    const EInvalidTld: u64 = 6;

    /// The configuration object, holds current settings of the SuiNS
    /// application. Does not carry any business logic and can easily
    /// be replaced with any other module providing similar interface
    /// and fitting the needs of the application.
    public struct Config has store, drop {
        public_key: vector<u8>,
        three_char_price: u64,
        four_char_price: u64,
        five_plus_char_price: u64,
    }

    /// Create a new instance of the configuration object.
    /// Define all properties from the start.
    public fun new(
        public_key: vector<u8>,
        three_char_price: u64,
        four_char_price: u64,
        five_plus_char_price: u64,
    ): Config {
        assert!(public_key.length() == 33, EInvalidPublicKey);

        Config {
            public_key,
            three_char_price,
            four_char_price,
            five_plus_char_price,
        }
    }

    // === Modification: one per property ===

    /// Change the value of the `public_key` field.
    public fun set_public_key(self: &mut Config, value: vector<u8>) {
        assert!(value.length() == 33, EInvalidPublicKey);
        self.public_key = value;
    }

    /// Change the value of the `three_char_price` field.
    public fun set_three_char_price(self: &mut Config, value: u64) {
        check_price(value);
        self.three_char_price = value;
    }

    /// Change the value of the `four_char_price` field.
    public fun set_four_char_price(self: &mut Config, value: u64) {
        check_price(value);
        self.four_char_price = value;
    }

    /// Change the value of the `five_plus_char_price` field.
    public fun set_five_plus_char_price(self: &mut Config, value: u64) {
        check_price(value);
        self.five_plus_char_price = value;
    }

    // === Price calculations ===

    /// Calculate the price of a label.
    public fun calculate_price(self: &Config, length: u8, years: u8): u64 {
        assert!(years > 0, ENoYears);
        assert!(length >= constants::min_domain_length(), ELabelTooShort);
        assert!(length <= constants::max_domain_length(), ELabelTooLong);

        let price = if (length == 3) {
            self.three_char_price
        } else if (length == 4) {
            self.four_char_price
        } else {
            self.five_plus_char_price
        };

        ((price as u64) * (years as u64))
    }


    // === Reads: one per property ===

    /// Get the value of the `public_key` field.
    public fun public_key(self: &Config): &vector<u8> { &self.public_key }

    /// Get the value of the `three_char_price` field.
    public fun three_char_price(self: &Config): u64 { self.three_char_price }

    /// Get the value of the `four_char_price` field.
    public fun four_char_price(self: &Config): u64 { self.four_char_price }

    /// Get the value of the `five_plus_char_price` field.
    public fun five_plus_char_price(self: &Config): u64 { self.five_plus_char_price }

    // === Helpers ===

    /// Asserts that a domain is registerable by a user:
    /// - TLD is "sui"
    /// - only has 1 label, "name", other than the TLD
    /// - "name" is >= 3 characters long
    public fun assert_valid_user_registerable_domain(domain: &Domain) {
        assert!(domain.number_of_levels() == 2, EInvalidDomain);
        assert!(domain.tld() == &constants::sui_tld(), EInvalidTld);
        let length = domain.sld().length();
        assert!(length >= (constants::min_domain_length() as u64), ELabelTooShort);
        assert!(length <= (constants::max_domain_length() as u64), ELabelTooLong);
    }

    // === Internal ===

    /// Assert that the price is within the allowed range (1-1M).
    /// TODO: revisit, are we sure we can't use less than 1 SUI?
    fun check_price(price: u64) {
        assert!(
            constants::mist_per_sui() <= price
            && price <= constants::mist_per_sui() * 1_000_000
        , EInvalidPrice);
    }
}
