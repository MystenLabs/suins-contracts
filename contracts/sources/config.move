/// Replacement for the `configuration` module (hence - the name).
/// Simplifies config creation, removes friends, and basically can be
/// created by anyone on the network with the exception that they won't
/// be able to use it in any way. :)
module suins::config {
    /// The minimum length of a domain name.
    const MIN_DOMAIN_LENGTH: u64 = 3;

    /// The maximum length of a domain name.
    const MAX_DOMAIN_LENGTH: u64 = 63;

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

    // === Extra Constants (require package upgrade) ===

    /// The minimum length of a domain name.
    public fun min_domain_length(): u64 { MIN_DOMAIN_LENGTH }

    /// The maximum length of a domain name.
    public fun max_domain_length(): u64 { MAX_DOMAIN_LENGTH }

    /// The amount of MIST in 1 SUI.
    public fun mist_per_sui(): u64 { MIST_PER_SUI }

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

    // === Reads: one per property ===

    /// Get the value of the `public_key` field.
    public fun public_key(self: &Config): vector<u8> {
        self.public_key
    }

    /// Get the value of the `enable_controller` field.
    public fun enable_controller(self: &Config): bool {
        self.enable_controller
    }

    /// Get the value of the `three_char_price` field.
    public fun three_char_price(self: &Config): u64 {
        self.three_char_price
    }

    /// Get the value of the `fouch_char_price` field.
    public fun fouch_char_price(self: &Config): u64 {
        self.fouch_char_price
    }

    /// Get the value of the `five_plus_char_price` field.
    public fun five_plus_char_price(self: &Config): u64 {
        self.five_plus_char_price
    }
}
