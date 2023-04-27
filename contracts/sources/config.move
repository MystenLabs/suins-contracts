/// Replacement for the `configuration` module (hence - the name).
/// Simplifies config creation, removes friends, and basically can be
/// created by anyone on the network with the exception that they won't
/// be able to use it in any way. :)
module suins::config {
    use std::string::{Self, String};
    use std::ascii;
    use sui::vec_map::{Self, VecMap};

    /// A label is too short to be registered.
    const ELabelTooShort: u64 = 0;
    /// A label is too long to be registered.
    const ELabelTooLong: u64 = 1;
    /// The price value is invalid.
    const EInvalidPrice: u64 = 2;

    //TODO check these
    const EInvalidRate: u64 = 401;
    const EInvalidReferralCode: u64 = 402;
    const EInvalidDiscountCode: u64 = 403;
    const EOwnerUnauthorized: u64 = 404;
    const EDiscountCodeNotExists: u64 = 405;
    const EReferralCodeNotExists: u64 = 406;
    const EInvalidLabelLength: u64 = 407;
    const EInvalidNewPrice: u64 = 408;

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
        public_key: vector<u8>,
        enable_controller: bool,
        three_char_price: u64,
        fouch_char_price: u64,
        five_plus_char_price: u64,

        referral_codes: VecMap<String, ReferralValue>,
        discount_codes: VecMap<String, DiscountValue>,
    }

    struct ReferralValue has store, drop {
        rate: u8,
        partner: address,
    }

    struct DiscountValue has store, drop {
        rate: u8,
        user: address,
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
            referral_codes: vec_map::empty(),
            discount_codes: vec_map::empty(),
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
        check_price(value);
        self.three_char_price = value;
    }

    /// Change the value of the `fouch_char_price` field.
    public fun set_fouch_char_price(self: &mut Config, value: u64) {
        check_price(value);
        self.fouch_char_price = value;
    }

    /// Change the value of the `five_plus_char_price` field.
    public fun set_five_plus_char_price(self: &mut Config, value: u64) {
        check_price(value);
        self.five_plus_char_price = value;
    }

    public fun add_referral_code(self: &mut Config, code: String, rate: u8, partner: address) {
        assert!(0 < rate && rate <= 100, EInvalidRate);
        let ascii = string::to_ascii(code);
        assert!(ascii::all_characters_printable(&ascii), EInvalidReferralCode);

        let new_value = ReferralValue { rate, partner };
        if (vec_map::contains(&self.referral_codes, &code)) {
            let current_value = vec_map::get_mut(&mut self.referral_codes, &code);
            *current_value = new_value;
        } else {
            vec_map::insert(&mut self.referral_codes, code, new_value);
        };
    }

    public fun remove_referral_code(self: &mut Config, code: String) {
        vec_map::remove(&mut self.referral_codes, &code);
    }

    // rate in percentage, e.g. discount = 10 means 10%;
    public fun new_discount_code(self: &mut Config, code: String, rate: u8, user: address) {
        assert!(0 < rate && rate <= 100, EInvalidRate);
        let ascii = string::to_ascii(code);
        assert!(ascii::all_characters_printable(&ascii), EInvalidDiscountCode);

        let new_value = DiscountValue { rate, user };
        if (vec_map::contains(&self.discount_codes, &code)) {
            let current_value = vec_map::get_mut(&mut self.discount_codes, &code);
            *current_value = new_value;
        } else {
            vec_map::insert(&mut self.discount_codes, code, new_value);
        };
    }

    public fun remove_discount_code(self: &mut Config, code: String) {
        vec_map::remove(&mut self.discount_codes, &code);
    }

    // public(friend) fun use_discount_code(config: &mut Configuration, code: &ascii::String, ctx: &TxContext): u8 {
    //     assert!(vec_map::contains(&config.discount_codes, code), EDiscountCodeNotExists);

    //     let value = vec_map::get(&config.discount_codes, code);
    //     let owner = value.owner;
    //     let sender = hex::encode(address::to_bytes(sender(ctx)));
    //     assert!(owner == ascii::string(sender), EOwnerUnauthorized);

    //     let rate = value.rate;
    //     vec_map::remove(&mut config.discount_codes, code);
    //     rate
    // }

    // // returns referral code's rate and partner address
    // public(friend) fun use_referral_code(config: &Configuration, code: &ascii::String): (u8, address) {
    //     assert!(vec_map::contains(&config.referral_codes, code), EReferralCodeNotExists);
    //     let value = vec_map::get(&config.referral_codes, code);
    //     (value.rate, value.partner)
    // }

    // === Price calculations ===

    /// Calculate the price of a label.
    public fun calculate_price(self: &Config, length: u8, years: u8): u64 {
        assert!(length >= MIN_DOMAIN_LENGTH, ELabelTooShort);
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


    // === Internal ===

    /// Assert that the price is within the allowed range (1-1M).
    fun check_price(price: u64) {
        assert!(
            mist_per_sui() <= price
            && price <= mist_per_sui() * 1_000_000
        , EInvalidPrice);
    }
}
