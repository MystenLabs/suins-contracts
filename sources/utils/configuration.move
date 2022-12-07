module suins::configuration {

    use sui::object::UID;
    use sui::vec_map::VecMap;
    use sui::tx_context::TxContext;
    use sui::vec_map;
    use sui::transfer;
    use sui::object;
    use sui::url::{Self, Url};
    use sui::event;
    use suins::base_registry::AdminCap;
    use std::ascii;
    use std::option;
    use std::option::Option;

    friend suins::base_registrar;
    friend suins::controller;

    // errors in the range of 401..500 indicate Sui Configuration errors
    const EInvalidRate: u64 = 401;
    const EInvalidReferralCode: u64 = 402;

    struct NetworkFirstDayChangedEvent has copy, drop {
        new_day: u64,
    }

    struct ReferralCodeAddedEvent has copy, drop {
        code: ascii::String,
    }

    struct ReferralCodeRemovedEvent has copy, drop {
        code: ascii::String,
    }

    struct ReferralValue has store, drop {
        rate: u8,
        partner: address,
    }

    struct Configuration has key {
        id: UID,
        // key is the day number of the end-of-year day counted from 01/01/2022, e.g., 2022 is day 365, 2023 is day 730
        ipfs_urls: VecMap<u64, vector<u8>>,
        // day number when the network is deployed, counts from 01/01/2022, 01/01/2022 is day 1,
        // help to detect leap year
        network_first_day: u64,
        referral_codes: VecMap<ascii::String, ReferralValue>,
    }

    fun init(ctx: &mut TxContext) {
        let ipfs_urls = vec_map::empty<u64, vector<u8>>();
        vec_map::insert(&mut ipfs_urls, 365, b"ipfs://QmfWrgbTZqwzqsvdeNc3NKacggMuTaN83sQ8V7Bs2nXKRD");
        vec_map::insert(&mut ipfs_urls, 730, b"ipfs://QmZsHKQk9FbQZYCy7rMYn1z6m9Raa183dNhpGCRm3fX71s");
        vec_map::insert(&mut ipfs_urls, 1096, b"ipfs://QmWjyuoBW7gSxAqvkTYSNbXnNka6iUHNqs3ier9bN3g7Y2");
        vec_map::insert(&mut ipfs_urls, 1461, b"ipfs://QmaWNLR6C3QsSHcPwNoFA59DPXCKdx1t8hmyyKRqBbjYB3");
        vec_map::insert(&mut ipfs_urls, 1826, b"ipfs://QmRF7kbi4igtGcX6enEuthQRhvQZejc7ZKBhMimFJtTS8D");
        vec_map::insert(&mut ipfs_urls, 2191, b"ipfs://QmfG5ngyNak9Baxg39whWUFnm5i52p64hgBWqfKJfUKjWr");
        transfer::share_object(Configuration {
            id: object::new(ctx),
            ipfs_urls,
            network_first_day: 0,
            referral_codes: vec_map::empty(),
        });
    }

    public entry fun set_network_first_day(_: &AdminCap, config: &mut Configuration, new_day: u64) {
        config.network_first_day = new_day;
        event::emit(NetworkFirstDayChangedEvent { new_day })
    }

    // discount in percentage, e.g. discount = 10 means 10%;
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
        event::emit(ReferralCodeAddedEvent { code })

    }

    public entry fun remove_referral_code(_: &AdminCap, config: &mut Configuration, code: vector<u8>) {
        let code = ascii::string(code);
        vec_map::remove(&mut config.referral_codes, &code);
        event::emit(ReferralCodeRemovedEvent { code })
    }

    public(friend) fun get_invalid_rate_error(): u64 {
        EInvalidRate
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

    public(friend) fun get_referral_code(config: &Configuration, code: vector<u8>): Option<ReferralValue> {
        let code = ascii::string(code);
        if (vec_map::contains(&config.referral_codes, &code)) {
            let value = vec_map::get(&config.referral_codes, &code);
            return option::some(ReferralValue{ rate: value.rate, partner: value.partner })
        };
        option::none()
    }

    public(friend) fun get_referral_rate(referral_value: &ReferralValue): u8 {
        referral_value.rate
    }

    public(friend) fun get_referral_partner(referral_value: &ReferralValue): address {
        referral_value.partner
    }

    #[test_only]
    friend suins::configuration_tests;

    #[test_only]
    /// Wrapper of module initializer for testing
    public fun test_init(ctx: &mut TxContext) {
        let ipfs_urls = vec_map::empty<u64, vector<u8>>();
        vec_map::insert(&mut ipfs_urls, 365, b"ipfs://QmfWrgbTZqwzqsvdeNc3NKacggMuTaN83sQ8V7Bs2nXKRD");
        vec_map::insert(&mut ipfs_urls, 730, b"ipfs://QmZsHKQk9FbQZYCy7rMYn1z6m9Raa183dNhpGCRm3fX71s");
        vec_map::insert(&mut ipfs_urls, 1096, b"ipfs://QmWjyuoBW7gSxAqvkTYSNbXnNka6iUHNqs3ier9bN3g7Y2");
        vec_map::insert(&mut ipfs_urls, 1461, b"ipfs://QmaWNLR6C3QsSHcPwNoFA59DPXCKdx1t8hmyyKRqBbjYB3");
        vec_map::insert(&mut ipfs_urls, 1826, b"ipfs://QmRF7kbi4igtGcX6enEuthQRhvQZejc7ZKBhMimFJtTS8D");
        vec_map::insert(&mut ipfs_urls, 2191, b"ipfs://QmfG5ngyNak9Baxg39whWUFnm5i52p64hgBWqfKJfUKjWr");
        transfer::share_object(Configuration {
            id: object::new(ctx),
            ipfs_urls,
            network_first_day: 0,
            referral_codes: vec_map::empty(),
        });
    }
}
