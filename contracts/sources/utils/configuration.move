module suins::configuration {

    use sui::object::{Self, UID};
    use sui::vec_map::{Self, VecMap};
    use sui::transfer;
    use sui::event;
    use sui::tx_context::{TxContext, sender};
    use sui::table::{Self, Table};
    use suins::remove_later;
    use suins::converter;
    use suins::base_registry::AdminCap;
    use suins::emoji::{Self, EmojiConfiguration};
    use std::ascii::{Self, String};
    use std::vector;
    use std::string;

    friend suins::base_registrar;
    friend suins::controller;
    friend suins::auction;

    // errors in the range of 401..500 indicate Sui Configuration errors
    const EmojiConfig: vector<u8> = b"emoji_config";

    const EInvalidRate: u64 = 401;
    const EInvalidReferralCode: u64 = 402;
    const EInvalidDiscountCode: u64 = 403;
    const EOwnerUnauthorized: u64 = 404;
    const EDiscountCodeNotExists: u64 = 405;
    const EReferralCodeNotExists: u64 = 406;

    struct NetworkFirstDayChangedEvent has copy, drop {
        new_day: u64,
    }

    struct ReferralCodeAddedEvent has copy, drop {
        code: String,
        rate: u8,
        partner: address,
    }

    struct DiscountCodeAddedEvent has copy, drop {
        code: String,
        rate: u8,
        owner: String,
    }

    struct ReserveDomainAddedEvent has copy, drop {
        domain: string::String,
    }

    struct ReferralCodeRemovedEvent has copy, drop {
        code: String,
    }

    struct DiscountCodeRemovedEvent has copy, drop {
        code: String,
    }

    struct ReferralValue has store, drop {
        rate: u8,
        partner: address,
    }

    struct DiscountValue has store, drop {
        rate: u8,
        owner: String,
    }

    struct Configuration has key {
        id: UID,
        referral_codes: VecMap<String, ReferralValue>,
        discount_codes: VecMap<String, DiscountValue>,
        /// if `key` doesn't contains TLD, it means we reserve both .sui and .move
        reserve_domains: Table<string::String, bool>,
        emoji_config: EmojiConfiguration,
        public_key: vector<u8>,
    }

    public entry fun set_public_key(_: &AdminCap, config: &mut Configuration, new_public_key: vector<u8>) {
        config.public_key = new_public_key
    }

    // TODO: handle .sui and .move separately
    public entry fun new_reserve_domains(_: &AdminCap, config: &mut Configuration, domains: vector<u8>) {
        let domains = remove_later::deserialize_reserve_domains(domains);
        let len = vector::length(&domains);
        let index = 0;

        while (index < len) {
            let domain = vector::borrow(&domains, index);
            // TODO: validate or not?
            if (!table::contains(&config.reserve_domains, *domain)) {
                table::add(&mut config.reserve_domains, *domain, true);
            };
            event::emit(ReserveDomainAddedEvent { domain: *domain });
            index = index + 1;
        };
    }

    public entry fun remove_reserve_domains(_: &AdminCap, config: &mut Configuration, domains: vector<u8>) {
        let domains = remove_later::deserialize_reserve_domains(domains);
        let len = vector::length(&domains);
        let index = 0;

        while (index < len) {
            let domain = vector::borrow(&domains, index);
            if (table::contains(&config.reserve_domains, *domain)) {
                table::remove(&mut config.reserve_domains, *domain);
            };
            event::emit(ReserveDomainAddedEvent { domain: *domain });
            index = index + 1;
        };
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

        let owner = ascii::string(converter::address_to_string(owner));
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

    // === Friend and Private Functions ===

    public(friend) fun use_discount_code(config: &mut Configuration, code: &String, ctx: &TxContext): u8 {
        assert!(vec_map::contains(&config.discount_codes, code), EDiscountCodeNotExists);

        let value = vec_map::get(&config.discount_codes, code);
        let owner = value.owner;
        let sender = converter::address_to_string(sender(ctx));
        assert!(owner == ascii::string(sender), EOwnerUnauthorized);

        let rate = value.rate;
        vec_map::remove(&mut config.discount_codes, code);
        rate
    }

    // returns referral code's rate and partner address
    public(friend) fun use_referral_code(config: &Configuration, code: &String): (u8, address) {
        assert!(vec_map::contains(&config.referral_codes, code), EReferralCodeNotExists);
        let value = vec_map::get(&config.referral_codes, code);
        (value.rate, value.partner)
    }

    public(friend) fun emoji_config(config: &Configuration): &EmojiConfiguration {
        &config.emoji_config
    }

    public(friend) fun public_key(config: &Configuration): &vector<u8> {
        &config.public_key
    }

    fun init(ctx: &mut TxContext) {
        transfer::share_object(Configuration {
            id: object::new(ctx),
            referral_codes: vec_map::empty(),
            discount_codes: vec_map::empty(),
            reserve_domains: table::new(ctx),
            emoji_config: emoji::init_emoji_config(),
            public_key: vector::empty(),
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
    public(friend) fun get_discount_owner(discount_value: &DiscountValue): String {
        discount_value.owner
    }

    #[test_only]
    public(friend) fun get_no_discount_codes(config: &Configuration): u64 {
        vec_map::size(&config.discount_codes)
    }

    #[test_only]
    public(friend) fun get_referral_code(config: &Configuration, code: &String): Option<ReferralValue> {
        if (vec_map::contains(&config.referral_codes, code)) {
            let value = vec_map::get(&config.referral_codes, code);
            return option::some(ReferralValue { rate: value.rate, partner: value.partner })
        };
        option::none()
    }

    #[test_only]
    public(friend) fun is_label_reserved(config: &Configuration, label: vector<u8>): bool {
        let label = string::utf8(label);
        if (table::contains(&config.reserve_domains, label)) {
            return true
        };
        false
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
    public(friend) fun get_discount_code(config: &Configuration, code: &String): Option<DiscountValue> {
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
            reserve_domains: table::new(ctx),
            emoji_config: emoji::init_emoji_config(),
            public_key: vector::empty(),
        });
    }
}
