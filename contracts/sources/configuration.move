/// This module manages all contract's options, which can be accessed from any part of the codebase.
/// These options can be modified dynamically at runtime by the admin.
module suins::configuration {

    use sui::object::{Self, UID};
    use sui::vec_map::{Self, VecMap};
    use sui::transfer;
    use sui::event;
    use sui::tx_context::{TxContext, sender};
    use suins::remove_later;
    use suins::suins::AdminCap;
    use std::ascii;
    use std::vector;
    use sui::address;
    use sui::hex;

    friend suins::registrar;
    friend suins::controller;
    friend suins::auction;

    const MAX_DOMAIN_LENGTH: u64 = 63;
    const MIN_DOMAIN_LENGTH: u64 = 3;
    const MIST_PER_SUI: u64 = 1_000_000_000;

    const EInvalidRate: u64 = 401;
    const EInvalidReferralCode: u64 = 402;
    const EInvalidDiscountCode: u64 = 403;
    const EOwnerUnauthorized: u64 = 404;
    const EDiscountCodeNotExists: u64 = 405;
    const EReferralCodeNotExists: u64 = 406;
    const EInvalidLabelLength: u64 = 407;
    const EInvalidNewPrice: u64 = 408;

    /// This share object is the parent of reverse_domains
    /// The keys of dynamic child objects may or may not contain TLD.
    /// If it doesn't, it means we reserve both .sui and .move
    struct Configuration has key {
        id: UID,
        referral_codes: VecMap<ascii::String, ReferralValue>,
        discount_codes: VecMap<ascii::String, DiscountValue>,
        public_key: vector<u8>,
        enable_controller: bool,
        price_of_three_character_domain: u64,
        price_of_four_character_domain: u64,
        price_of_five_and_above_character_domain: u64,
    }

    struct NetworkFirstDayChangedEvent has copy, drop {
        new_day: u64,
    }

    struct ReferralCodeAddedEvent has copy, drop {
        code: ascii::String,
        rate: u8,
        partner: address,
    }

    struct DiscountCodeAddedEvent has copy, drop {
        code: ascii::String,
        rate: u8,
        owner: ascii::String,
    }

    struct ReferralCodeRemovedEvent has copy, drop {
        code: ascii::String,
    }

    struct DiscountCodeRemovedEvent has copy, drop {
        code: ascii::String,
    }

    struct ReferralValue has store, drop {
        rate: u8,
        partner: address,
    }

    struct DiscountValue has store, drop {
        rate: u8,
        owner: ascii::String,
    }

    /// #### Notice
    /// The admin uses this function to enable or disable registration.
    ///
    ///
    /// #### Params
    /// `new_value`: false to enable registration, true to disable it.
    public entry fun set_enable_controller(_: &AdminCap, config: &mut Configuration, new_value: bool) {
        config.enable_controller = new_value;
    }

    public entry fun set_public_key(_: &AdminCap, config: &mut Configuration, new_public_key: vector<u8>) {
        config.public_key = new_public_key
    }

    // rate in percentage, e.g. discount = 10 means 10%;
    public entry fun new_referral_code(_: &AdminCap, config: &mut Configuration, code: vector<u8>, rate: u8, partner: address) {
        assert!(0 < rate && rate <= 100, EInvalidRate);
        let code = ascii::string(code);
        assert!(ascii::all_characters_printable(&code), EInvalidReferralCode);

        let new_value = ReferralValue { rate, partner };
        if (vec_map::contains(&config.referral_codes, &code)) {
            let current_value = vec_map::get_mut(&mut config.referral_codes, &code);
            *current_value = new_value;
        } else {
            vec_map::insert(&mut config.referral_codes, code, new_value);
        };
        event::emit(ReferralCodeAddedEvent { code, rate, partner })
    }

    public entry fun remove_referral_code(_: &AdminCap, config: &mut Configuration, code: vector<u8>) {
        let code = ascii::string(code);
        vec_map::remove(&mut config.referral_codes, &code);
        event::emit(ReferralCodeRemovedEvent { code })
    }

    // rate in percentage, e.g. discount = 10 means 10%;
    public entry fun new_discount_code(_: &AdminCap, config: &mut Configuration, code: vector<u8>, rate: u8, owner: address) {
        assert!(0 < rate && rate <= 100, EInvalidRate);
        let code = ascii::string(code);
        assert!(ascii::all_characters_printable(&code), EInvalidDiscountCode);

        let owner = ascii::string(hex::encode(address::to_bytes(owner)));
        let new_value = DiscountValue { rate, owner };
        if (vec_map::contains(&config.discount_codes, &code)) {
            let current_value = vec_map::get_mut(&mut config.discount_codes, &code);
            *current_value = new_value;
        } else {
            vec_map::insert(&mut config.discount_codes, code, new_value);
        };
        event::emit(DiscountCodeAddedEvent { code, rate, owner })
    }

    // code_batch has format: code1:rate1:owner1;code2:rate2:owner2;
    // owner must have '0x'
    public entry fun new_discount_code_batch(_: &AdminCap, config: &mut Configuration, code_batch: vector<u8>) {
        let discount_codes = remove_later::deserialize_new_discount_code_batch(code_batch);
        let len = vector::length(&discount_codes);
        let index = 0;

        while(index < len) {
            let discount_code = vector::borrow(&discount_codes, index);
            let (code, rate, owner) = remove_later::get_discount_fields(discount_code);
            let new_value = DiscountValue { rate, owner };

            if (vec_map::contains(&config.discount_codes, &code)) {
                let current_value = vec_map::get_mut(&mut config.discount_codes, &code);
                *current_value = new_value;
            } else {
                vec_map::insert(&mut config.discount_codes, code, new_value);
            };
            event::emit(DiscountCodeAddedEvent { code, rate, owner });
            index = index + 1;
        };
    }

    public entry fun remove_discount_code(_: &AdminCap, config: &mut Configuration, code: vector<u8>) {
        let code = ascii::string(code);
        vec_map::remove(&mut config.discount_codes, &code);
        event::emit(DiscountCodeRemovedEvent { code })
    }

    // code_batch has format: code1;code2;;
    public entry fun remove_discount_code_batch(_: &AdminCap, config: &mut Configuration, code_batch: vector<u8>) {
        let codes = remove_later::deserialize_remove_discount_code_batch(code_batch);
        let len = vector::length(&codes);
        let index = 0;

        while(index < len) {
            let code = vector::borrow(&codes, index);
            vec_map::remove(&mut config.discount_codes, code);
            event::emit(DiscountCodeRemovedEvent { code: *code });
            index = index + 1;
        };
    }

    public entry fun set_price_of_three_character_domain(_: &AdminCap, config: &mut Configuration, new_price: u64) {
        assert!(
            mist_per_sui() <= new_price && new_price <= mist_per_sui() * 1_000_000,
            EInvalidNewPrice
        );
        config.price_of_three_character_domain = new_price;
    }

    public entry fun set_price_of_four_character_domain(_: &AdminCap, config: &mut Configuration, new_price: u64) {
        assert!(
            mist_per_sui() <= new_price && new_price <= mist_per_sui() * 1_000_000,
            EInvalidNewPrice
        );
        config.price_of_four_character_domain = new_price;
    }

    public entry fun set_price_of_five_and_above_character_domain(_: &AdminCap, config: &mut Configuration, new_price: u64) {
        assert!(
            mist_per_sui() <= new_price && new_price <= mist_per_sui() * 1_000_000,
            EInvalidNewPrice
        );
        config.price_of_five_and_above_character_domain = new_price;
    }

    // === Public Functions ===

    public fun price_of_five_and_above_character_domain(config: &Configuration): u64 {
        config.price_of_five_and_above_character_domain
    }

    public fun price_for_label(config: &Configuration, label_length: u64, no_years: u64): u64 {
        assert!(label_length > 2, EInvalidLabelLength);
        let price_per_year =
            if (label_length == 3) config.price_of_three_character_domain
            else if (label_length == 4) config.price_of_four_character_domain
            else config.price_of_five_and_above_character_domain;

        price_per_year * no_years
    }

    public fun public_key(config: &Configuration): &vector<u8> {
        &config.public_key
    }

    public fun min_domain_length(): u64 {
        MIN_DOMAIN_LENGTH
    }

    public fun max_domain_length(): u64 {
        MAX_DOMAIN_LENGTH
    }

    public fun is_controller_enabled(config: &Configuration): bool {
        config.enable_controller
    }

    public fun mist_per_sui(): u64 {
        MIST_PER_SUI
    }

    // === Friend and Private Functions ===

    public(friend) fun use_discount_code(config: &mut Configuration, code: &ascii::String, ctx: &TxContext): u8 {
        assert!(vec_map::contains(&config.discount_codes, code), EDiscountCodeNotExists);

        let value = vec_map::get(&config.discount_codes, code);
        let owner = value.owner;
        let sender = hex::encode(address::to_bytes(sender(ctx)));
        assert!(owner == ascii::string(sender), EOwnerUnauthorized);

        let rate = value.rate;
        vec_map::remove(&mut config.discount_codes, code);
        rate
    }

    // returns referral code's rate and partner address
    public(friend) fun use_referral_code(config: &Configuration, code: &ascii::String): (u8, address) {
        assert!(vec_map::contains(&config.referral_codes, code), EReferralCodeNotExists);
        let value = vec_map::get(&config.referral_codes, code);
        (value.rate, value.partner)
    }

    fun init(ctx: &mut TxContext) {
        transfer::share_object(Configuration {
            id: object::new(ctx),
            referral_codes: vec_map::empty(),
            discount_codes: vec_map::empty(),
            public_key: vector::empty(),
            enable_controller: true,
            price_of_three_character_domain: 1200 * MIST_PER_SUI,
            price_of_four_character_domain: 200 * MIST_PER_SUI,
            price_of_five_and_above_character_domain: 50 * MIST_PER_SUI,
        });
    }

    #[test_only]
    friend suins::configuration_tests;

    #[test_only]
    use std::option::{Self, Option};

    #[test_only]
    public(friend) fun get_discount_rate(discount_value: &DiscountValue): u8 {
        discount_value.rate
    }

    #[test_only]
    public(friend) fun get_discount_owner(discount_value: &DiscountValue): ascii::String {
        discount_value.owner
    }

    #[test_only]
    public(friend) fun get_no_discount_codes(config: &Configuration): u64 {
        vec_map::size(&config.discount_codes)
    }

    #[test_only]
    public(friend) fun get_referral_code(config: &Configuration, code: &ascii::String): Option<ReferralValue> {
        if (vec_map::contains(&config.referral_codes, code)) {
            let value = vec_map::get(&config.referral_codes, code);
            return option::some(ReferralValue { rate: value.rate, partner: value.partner })
        };
        option::none()
    }

    #[test_only]
    public(friend) fun get_referral_partner(referral_value: &ReferralValue): address {
        referral_value.partner
    }

    #[test_only]
    public(friend) fun get_referral_rate(referral_value: &ReferralValue): u8 {
        referral_value.rate
    }

    #[test_only]
    public(friend) fun get_discount_code(config: &Configuration, code: &ascii::String): Option<DiscountValue> {
        if (vec_map::contains(&config.discount_codes, code)) {
            let value = vec_map::get(&config.discount_codes, code);
            return option::some(DiscountValue { rate: value.rate, owner: value.owner })
        };
        option::none()
    }

    #[test_only]
    /// Wrapper of module initializer for testing
    public fun test_init(ctx: &mut TxContext) {
        transfer::share_object(Configuration {
            id: object::new(ctx),
            referral_codes: vec_map::empty(),
            discount_codes: vec_map::empty(),
            public_key: vector::empty(),
            enable_controller: true,
            price_of_three_character_domain: 1200 * MIST_PER_SUI,
            price_of_four_character_domain: 200 * MIST_PER_SUI,
            price_of_five_and_above_character_domain: 50 * MIST_PER_SUI,
        });
    }
}
