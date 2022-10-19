module suins::ipfs_images {

    use sui::object::UID;
    use sui::vec_map::VecMap;
    use sui::tx_context::TxContext;
    use sui::vec_map;
    use sui::transfer;
    use sui::object;
    use sui::url::{Self, Url};

    friend suins::base_registrar;

    struct IpfsImages has key {
        id: UID,
        // key is the day number of the end-of-year day counted from 01/01/2022, e.g., 2022 is day 365, 2023 is day 730
        urls: VecMap<u64, vector<u8>>,
        // day number counts from 01/01/2022, 01/01/2022 is day 1,
        // help to detect leap year
        contract_deployed_day: u64,
    }

    fun init(ctx: &mut TxContext) {
        let urls = vec_map::empty<u64, vector<u8>>();
        vec_map::insert(&mut urls, 365, b"ipfs://QmfWrgbTZqwzqsvdeNc3NKacggMuTaN83sQ8V7Bs2nXKRD");
        vec_map::insert(&mut urls, 730, b"ipfs://QmZsHKQk9FbQZYCy7rMYn1z6m9Raa183dNhpGCRm3fX71s");
        vec_map::insert(&mut urls, 1095, b"ipfs://QmWjyuoBW7gSxAqvkTYSNbXnNka6iUHNqs3ier9bN3g7Y2");
        vec_map::insert(&mut urls, 1461, b"ipfs://QmaWNLR6C3QsSHcPwNoFA59DPXCKdx1t8hmyyKRqBbjYB3");
        vec_map::insert(&mut urls, 1826, b"ipfs://QmRF7kbi4igtGcX6enEuthQRhvQZejc7ZKBhMimFJtTS8D");
        transfer::share_object(IpfsImages {
            id: object::new(ctx),
            urls,
            contract_deployed_day: 291,
        });
    }

    public(friend) fun get_url(images: &IpfsImages, duration: u64): Url {
        let date = images.contract_deployed_day + duration;
        let len = vec_map::size(&images.urls);
        let index = 0;
        while(index < len) {
            let (key, value) = vec_map::get_entry_by_idx(&images.urls, index);
            if (date < *key) {
                return url::new_unsafe_from_bytes(*value)
            };
            index = index + 1;
        };
        url::new_unsafe_from_bytes(b"ipfs://bafkreibngqhl3gaa7daob4i2vccziay2jjlp435cf66vhono7nrvww53ty")
    }

    #[test_only]
    friend suins::ipfs_images_tests;

    #[test_only]
    /// Wrapper of module initializer for testing
    public fun test_init(ctx: &mut TxContext) {
        init(ctx)
    }
}
