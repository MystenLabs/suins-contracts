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

    friend suins::base_registrar;
    friend suins::helper;

    // errors in the range of 401..500 indicate Sui Configuration errors
    const EInvalidDiscount: u64 = 401;

    struct NetworkFirstDayChangedEvent has copy, drop {
        new_day: u64,
    }

    struct Configuration has key {
        id: UID,
        // key is the day number of the end-of-year day counted from 01/01/2022, e.g., 2022 is day 365, 2023 is day 730
        ipfs_urls: VecMap<u64, vector<u8>>,
        // day number when the network is deployed, counts from 01/01/2022, 01/01/2022 is day 1,
        // help to detect leap year
        network_first_day: u64,
        referral_codes: VecMap<ascii::String, u8>,
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
    public entry fun new_referral_code(_: &AdminCap, config: &mut Configuration, code: vector<u8>, discount: u8) {
        assert!(0 < discount && discount <= 100, EInvalidDiscount);
        let code = ascii::string(code);
        if (vec_map::contains(&config.referral_codes, &code)) {
            let current_discount = vec_map::get_mut(&mut config.referral_codes, &code);
            *current_discount = discount;
        } else {
            vec_map::insert(&mut config.referral_codes, code, discount);
        }
    }

    public(friend) fun getInvalidDiscountError(): u64 {
        EInvalidDiscount
    }

    public(friend) fun get_url(config: &Configuration, duration: u64, current_epoch: u64): Url {
        // duration cannot be less than 0
        let day = config.network_first_day + current_epoch + duration;
        let len = vec_map::size(&config.ipfs_urls);
        let index = 0;
        while(index < len) {
            let (key, value) = vec_map::get_entry_by_idx(&config.ipfs_urls, index);
            if (day <= *key) {
                return url::new_unsafe_from_bytes(*value)
            };
            index = index + 1;
        };
        url::new_unsafe_from_bytes(b"ipfs://bafkreibngqhl3gaa7daob4i2vccziay2jjlp435cf66vhono7nrvww53ty")
    }

    #[test_only]
    friend suins::configuration_tests;

    #[test_only]
    public(friend) fun get_referral_code(config: &Configuration, code: vector<u8>): u8 {
        *vec_map::get(&config.referral_codes, &ascii::string(code))
    }

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
