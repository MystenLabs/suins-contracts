module suins::configuration {

    use sui::object::{Self, UID};
    use sui::vec_map::{Self, VecMap};
    use sui::transfer;
    use sui::url::{Self, Url};
    use sui::event;
    use sui::tx_context::{Self, TxContext};
    use sui::table::{Self, Table};
    use std::ascii::{Self, String};
    use std::vector;
    use suins::remove_later;
    use suins::converter;
    use suins::base_registry::AdminCap;
    use suins::emoji::{Self, EmojiConfiguration};
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
        // key is the day number of the end-of-year day counted from 01/01/2022, e.g., 2022 is day 365, 2023 is day 730
        ipfs_urls: VecMap<u64, vector<u8>>,
        // day number when the network is deployed, counts from 01/01/2022, 01/01/2022 is day 1,
        // help to detect leap year
        network_first_day: u64,
        referral_codes: VecMap<String, ReferralValue>,
        discount_codes: VecMap<String, DiscountValue>,
        // if `key` doesn't contains TLD, it means we reserve both .sui and .move
        reserve_domains: Table<string::String, bool>,
        // hold hardcoded value
        // TODO: change this to `Bag`
        resources: Table<String, EmojiConfiguration>,
    }

    fun init(ctx: &mut TxContext) {
        let ipfs_urls = vec_map::empty<u64, vector<u8>>();
        vec_map::insert(&mut ipfs_urls, 365, b"ipfs://QmZsHKQk9FbQZYCy7rMYn1z6m9Raa183dNhpGCRm3fX71s");
        vec_map::insert(&mut ipfs_urls, 731, b"ipfs://QmWjyuoBW7gSxAqvkTYSNbXnNka6iUHNqs3ier9bN3g7Y2");
        vec_map::insert(&mut ipfs_urls, 1096, b"ipfs://QmaWNLR6C3QsSHcPwNoFA59DPXCKdx1t8hmyyKRqBbjYB3");
        vec_map::insert(&mut ipfs_urls, 1461, b"ipfs://QmRF7kbi4igtGcX6enEuthQRhvQZejc7ZKBhMimFJtTS8D");
        vec_map::insert(&mut ipfs_urls, 1826, b"ipfs://QmfG5ngyNak9Baxg39whWUFnm5i52p64hgBWqfKJfUKjWr");
        let resources = table::new<String, EmojiConfiguration>(ctx);
        table::add(&mut resources, ascii::string(EmojiConfig), emoji::init_emoji_config());
        // TODO: hardcode reserve domain
        transfer::share_object(Configuration {
            id: object::new(ctx),
            ipfs_urls,
            network_first_day: 0,
            referral_codes: vec_map::empty(),
            discount_codes: vec_map::empty(),
            reserve_domains: table::new(ctx),
            resources,
        });
    }

    public entry fun set_network_first_day(_: &AdminCap, config: &mut Configuration, new_day: u64) {
        config.network_first_day = new_day;
        event::emit(NetworkFirstDayChangedEvent { new_day })
    }

    // TODO: handle .sui and .move separately
    public entry fun new_reserve_domains(_: &AdminCap, config: &mut Configuration, domains: vector<u8>) {
        let domains = remove_later::deserialize_reserve_domains(domains);
        let len = vector::length(&domains);
        let index = 0;
        // let emoji_config = table::borrow(&config.resources, ascii::string(EmojiConfig));
        while (index < len) {
            let domain = vector::borrow(&domains, index);
            // TODO: validate or not
            // emoji::validate_label(emoji_config, *string::bytes(domain));
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
        // let emoji_config = table::borrow(&config.resources, ascii::string(EmojiConfig));
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

    public(friend) fun get_url(config: &Configuration, duration: u64, current_epoch: u64): Url {
        let end_date = config.network_first_day + current_epoch + duration;
        let len = vec_map::size(&config.ipfs_urls);
        let index = 0;
        while (index < len) {
            let (key, value) = vec_map::get_entry_by_idx(&config.ipfs_urls, index);
            if (end_date <= *key) {
                return url::new_unsafe_from_bytes(*value)
            };
            index = index + 1;
        };
        url::new_unsafe_from_bytes(b"ipfs://bafkreibngqhl3gaa7daob4i2vccziay2jjlp435cf66vhono7nrvww53ty")
    }

    public(friend) fun use_discount_code(config: &mut Configuration, code: &String, ctx: &TxContext): u8 {
        assert!(vec_map::contains(&config.discount_codes, code), EDiscountCodeNotExists);
        let value = vec_map::get(&config.discount_codes, code);
        let owner = value.owner;
        let sender = converter::address_to_string(tx_context::sender(ctx));
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

    public(friend) fun get_emoji_config(config: &Configuration): &EmojiConfiguration {
        table::borrow(&config.resources, ascii::string(EmojiConfig))
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
        // mimic logic in `init`
        let ipfs_urls = vec_map::empty<u64, vector<u8>>();
        vec_map::insert(&mut ipfs_urls, 365, b"ipfs://QmZsHKQk9FbQZYCy7rMYn1z6m9Raa183dNhpGCRm3fX71s");
        vec_map::insert(&mut ipfs_urls, 731, b"ipfs://QmWjyuoBW7gSxAqvkTYSNbXnNka6iUHNqs3ier9bN3g7Y2");
        vec_map::insert(&mut ipfs_urls, 1096, b"ipfs://QmaWNLR6C3QsSHcPwNoFA59DPXCKdx1t8hmyyKRqBbjYB3");
        vec_map::insert(&mut ipfs_urls, 1461, b"ipfs://QmRF7kbi4igtGcX6enEuthQRhvQZejc7ZKBhMimFJtTS8D");
        vec_map::insert(&mut ipfs_urls, 1826, b"ipfs://QmfG5ngyNak9Baxg39whWUFnm5i52p64hgBWqfKJfUKjWr");
        let resources = table::new<String, EmojiConfiguration>(ctx);
        table::add(&mut resources, ascii::string(b"emoji_config"), emoji::init_emoji_config());

        transfer::share_object(Configuration {
            id: object::new(ctx),
            ipfs_urls,
            network_first_day: 1,
            referral_codes: vec_map::empty(),
            discount_codes: vec_map::empty(),
            reserve_domains: table::new(ctx),
            resources,
        });
    }
}
