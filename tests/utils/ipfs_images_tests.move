#[test_only]
module suins::ipfs_images_tests {

    use sui::test_scenario;
    use sui::url;
    use suins::ipfs_images::{Self, IpfsImages};

    #[test]
    fun test_get_url() {
        {
            let scenario = test_scenario::begin(&@0x1);
            {
                let ctx = test_scenario::ctx(&mut scenario);
                ipfs_images::test_init(ctx);
            };

            test_scenario::next_tx(&mut scenario, &@0x1);
            let images_wrapper = test_scenario::take_shared<IpfsImages>(&mut scenario);
            let images = test_scenario::borrow_mut(&mut images_wrapper);

            let test_url = ipfs_images::get_url(images, 1);
            assert!(test_url == url::new_unsafe_from_bytes(b"ipfs://QmfWrgbTZqwzqsvdeNc3NKacggMuTaN83sQ8V7Bs2nXKRD"), 0);
            let test_url = ipfs_images::get_url(images, 366);
            assert!(test_url == url::new_unsafe_from_bytes(b"ipfs://QmZsHKQk9FbQZYCy7rMYn1z6m9Raa183dNhpGCRm3fX71s"), 0);
            let test_url = ipfs_images::get_url(images, 730);
            assert!(test_url == url::new_unsafe_from_bytes(b"ipfs://QmWjyuoBW7gSxAqvkTYSNbXnNka6iUHNqs3ier9bN3g7Y2"), 0);
            let test_url = ipfs_images::get_url(images, 7300);
            assert!(test_url == url::new_unsafe_from_bytes(b"ipfs://bafkreibngqhl3gaa7daob4i2vccziay2jjlp435cf66vhono7nrvww53ty"), 0);

            test_scenario::return_shared(&mut scenario, images_wrapper);
        };
    }
}