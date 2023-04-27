/// Replacement for the `configuration` module (hence - the name).
/// Simplifies config creation, removes friends, and basically can be
/// created by anyone on the network with the exception that they won't
/// be able to use it in any way. :)
module suins::config {
    /// A label is too short to be registered.
    const ELabelTooShort: u64 = 0;
    /// A label is too long to be registered.
    const ELabelTooLong: u64 = 1;

    /// The minimum length of a domain name.
    const MIN_DOMAIN_LENGTH: u8 = 3;

    /// The maximum length of a domain name.
    const MAX_DOMAIN_LENGTH: u8 = 63;

    /// The amount of MIST in 1 SUI.
    const MIST_PER_SUI: u64 = 1_000_000_000;

    /// The configuration object, holds current settings of the SuiNS
    /// application. Does not carry any business logic and can easily
    /// be replaced with any other module providing similar interface
    /// and fitting the needs of the application.
    struct Config has store, drop {

        // TODO: currently disabled fields, figure the need
        // referral_codes: VecMap<ascii::String, ReferralValue>,
        // discount_codes: VecMap<ascii::String, DiscountValue>,

        public_key: vector<u8>,
        enable_controller: bool,
        three_char_price: u64,
        fouch_char_price: u64,
        five_plus_char_price: u64,
    }

    /// Create a new instance of the configuration object.
    /// Define all properties from the start.
    public fun new(
        public_key: vector<u8>,
        enable_controller: bool,
        three_char_price: u64,
        fouch_char_price: u64,
        five_plus_char_price: u64,
    ): Config {
        Config {
            public_key,
            enable_controller,
            three_char_price,
            fouch_char_price,
            five_plus_char_price,
        }
    }


    // === Modification: one per property ===

    /// Change the value of the `public_key` field.
    public fun set_public_key(self: &mut Config, value: vector<u8>) {
        self.public_key = value;
    }

    /// Change the value of the `enable_controller` field.
    public fun set_enable_controller(self: &mut Config, value: bool) {
        self.enable_controller = value;
    }

    /// Change the value of the `three_char_price` field.
    public fun set_three_char_price(self: &mut Config, value: u64) {
        self.three_char_price = value;
    }

    /// Change the value of the `fouch_char_price` field.
    public fun set_fouch_char_price(self: &mut Config, value: u64) {
        self.fouch_char_price = value;
    }

    /// Change the value of the `five_plus_char_price` field.
    public fun set_five_plus_char_price(self: &mut Config, value: u64) {
        self.five_plus_char_price = value;
    }


    // === Price calculations ===

    /// Calculate the price of a label.
    public fun calculate_price(self: &Config, length: u8, years: u8): u64 {
        assert!(length > MIN_DOMAIN_LENGTH, ELabelTooShort);
        assert!(length <= MAX_DOMAIN_LENGTH, ELabelTooLong);

        let price = if (length == 3) {
            self.three_char_price
        } else if (length == 4) {
            self.fouch_char_price
        } else {
            self.five_plus_char_price
        };

        ((price as u64) * (years as u64))
    }


    // === Reads: one per property ===

    /// Get the value of the `public_key` field.
    public fun public_key(self: &Config): vector<u8> { self.public_key }

    /// Get the value of the `enable_controller` field.
    public fun enable_controller(self: &Config): bool {  self.enable_controller }

    /// Get the value of the `three_char_price` field.
    public fun three_char_price(self: &Config): u64 { self.three_char_price }

    /// Get the value of the `fouch_char_price` field.
    public fun fouch_char_price(self: &Config): u64 { self.fouch_char_price }

    /// Get the value of the `five_plus_char_price` field.
    public fun five_plus_char_price(self: &Config): u64 { self.five_plus_char_price }


    // === Extra Constants (require package upgrade to change) ===

    /// The minimum length of a domain name.
    public fun min_domain_length(): u8 { MIN_DOMAIN_LENGTH }

    /// The maximum length of a domain name.
    public fun max_domain_length(): u8 { MAX_DOMAIN_LENGTH }

    /// The amount of MIST in 1 SUI.
    public fun mist_per_sui(): u64 { MIST_PER_SUI }
}
