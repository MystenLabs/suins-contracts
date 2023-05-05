/// Promotion mechanics: referral and discount codes.
///
/// It's a separate configuration object stored the same way as the `Config`.
/// Serves its purpose, does not affect any public signatures of the suins nor
/// Auction nor anything else, so can safely be injected or ejected whenever
/// needed.
module suins::promotion {
    use std::string::String;
    use sui::vec_map::{Self, VecMap};
    use sui::tx_context::{sender, TxContext};

    use suins::string_utils;
    use suins::constants;

    /// Trying to input an invalid BPS value.
    const EInvalidBpsValue: u64 = 0;
    /// ASCII validation failure on the UTF8 input.
    const EInvalidCharacter: u64 = 1;
    /// Trying to use a value that does not exist.
    const ENotExists: u64 = 2;
    /// Attempt to use Discount code that does not belong to the sender.
    const ENotOwner: u64 = 3;

    /// An object storing configuration for the promotion mechanics.
    /// Currently supported ones are referral and discount codes.
    ///
    /// Attached as a dynamic field and carried by the `SuiNS` object.
    // struct Promotion<phantom App> has store, drop {
    struct Promotion has store, drop {
        referral_codes: VecMap<String, Referral>,
        discount_codes: VecMap<String, Discount>,
    }

    /// Create new instance of the `Promotion` configuration.
    public fun new(): Promotion {
        Promotion {
            referral_codes: vec_map::empty(),
            discount_codes: vec_map::empty(),
        }
    }

    // === Referral codes ===

    /// Internal struct to store Referral values.
    struct Referral has store, drop {
        /// The rate of referral reward in base points, e.g. 1000 means 10%.
        rate: u16,
        /// The address of a parther to send referral reward to.
        partner: address,
    }

    /// Add a referral code to the promotion configuration.
    public fun add_referral_code(
        self: &mut Promotion, code: String, rate: u16, partner: address
    ) {
        assert_bps(rate);
        assert!(string_utils::is_valid_ascii(code), EInvalidCharacter);

        let new_value = Referral { rate, partner };
        if (vec_map::contains(&self.referral_codes, &code)) {
            let current_value = vec_map::get_mut(&mut self.referral_codes, &code);
            *current_value = new_value;
        } else {
            vec_map::insert(&mut self.referral_codes, code, new_value);
        };
    }

    public fun remove_referral_code(self: &mut Promotion, code: String) {
        vec_map::remove(&mut self.referral_codes, &code);
    }

    // returns referral code's rate and partner address
    public fun use_referral_code(self: &Promotion, code: &String): (u16, address) {
        assert!(vec_map::contains(&self.referral_codes, code), ENotExists);
        let value = vec_map::get(&self.referral_codes, code);
        (value.rate, value.partner)
    }


    // === Discount codes ===

    ///
    struct Discount has store, drop {
        rate: u16,
        user: address,
    }

    /// Add a discount code to the promotion configuration.
    ///
    public fun add_discount_code(
        self: &mut Promotion, code: String, rate: u16, user: address
    ) {
        assert_bps(rate);
        assert!(string_utils::is_valid_ascii(code), EInvalidCharacter);

        let new_value = Discount { rate, user };
        if (vec_map::contains(&self.discount_codes, &code)) {
            let current_value = vec_map::get_mut(&mut self.discount_codes, &code);
            *current_value = new_value;
        } else {
            vec_map::insert(&mut self.discount_codes, code, new_value);
        };
    }

    /// Remove a discount code from the promotion configuration.
    public fun remove_discount_code(self: &mut Promotion, code: String) {
        vec_map::remove(&mut self.discount_codes, &code);
    }

    /// Use a discount code. Check that the code exists and belongs to the
    /// sender, aborts otherwise.
    public fun use_discount_code(
        self: &mut Promotion, code: &String, ctx: &TxContext
    ): u16 {
        assert!(vec_map::contains(&self.discount_codes, code), ENotExists);
        let (_, discount_value) = vec_map::remove(&mut self.discount_codes, code);
        let Discount { rate, user } = discount_value;
        assert!(user == sender(ctx), ENotOwner);
        rate
    }

    /// Internal check for BPS.
    fun assert_bps(bps: u16) {
        assert!(bps <= constants::max_bps(), EInvalidBpsValue);
    }
}
