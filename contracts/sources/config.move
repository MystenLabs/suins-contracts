/// Replacement for the `configuration` module (hence - the name).
/// Simplifies config creation, removes friends, and basically can be
/// created by anyone on the network with the exception that they won't
/// be able to use it in any way. :)
///
/// This module is (almost) free from any non-framework dependencies.
module suins::config {
    use std::vector;
    use suins::constants;

    /// A label is too short to be registered.
    const ELabelTooShort: u64 = 0;
    /// A label is too long to be registered.
    const ELabelTooLong: u64 = 1;
    /// The price value is invalid.
    const EInvalidPrice: u64 = 2;
    /// The public key length is not 32 bytes.
    const EInvalidPublicKey: u64 = 3;
    /// Incorrect number of years passed to the function.
    const ENoYears: u64 = 4;

    /// The configuration object, holds current settings of the SuiNS
    /// application. Does not carry any business logic and can easily
    /// be replaced with any other module providing similar interface
    /// and fitting the needs of the application.
    struct Config has store, drop {
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
        assert!(vector::length(&public_key) == 32, EInvalidPublicKey);

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
        assert!(vector::length(&value) == 32, EInvalidPublicKey);
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
