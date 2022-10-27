#[test_only]
module suins::configuration_tests {

    use sui::test_scenario;
    use sui::url;
    use suins::configuration::{Self, Configuration};

    #[test]
    fun test_get_url() {
        let scenario = test_scenario::begin(@0x1);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            configuration::test_init(ctx);
        };

        test_scenario::next_tx(&mut scenario, @0x1);
        let config = test_scenario::take_shared<Configuration>(&mut scenario);
        configuration::set_network_first_day_test(&mut config, 365); // 31-12-2022

        let test_url = configuration::get_url(&config, 0, 0);
        assert!(test_url == url::new_unsafe_from_bytes(b"ipfs://QmfWrgbTZqwzqsvdeNc3NKacggMuTaN83sQ8V7Bs2nXKRD"), 0); // 31-12-2022
        let test_url = configuration::get_url(&config, 365, 0);
        assert!(test_url == url::new_unsafe_from_bytes(b"ipfs://QmZsHKQk9FbQZYCy7rMYn1z6m9Raa183dNhpGCRm3fX71s"), 0); // 31-12-2023
        let test_url = configuration::get_url(&config, 365, 1);
        assert!(test_url == url::new_unsafe_from_bytes(b"ipfs://QmWjyuoBW7gSxAqvkTYSNbXnNka6iUHNqs3ier9bN3g7Y2"), 0); // 01-01-2024
        // test leap year
        let test_url = configuration::get_url(&config, 730, 1);
        assert!(test_url == url::new_unsafe_from_bytes(b"ipfs://QmWjyuoBW7gSxAqvkTYSNbXnNka6iUHNqs3ier9bN3g7Y2"), 0); // 31-12-2024
        let test_url = configuration::get_url(&config, 731, 1);
        assert!(test_url == url::new_unsafe_from_bytes(b"ipfs://QmaWNLR6C3QsSHcPwNoFA59DPXCKdx1t8hmyyKRqBbjYB3"), 0); // 01-01-2025
        let test_url = configuration::get_url(&config, 7300, 1);
        assert!(test_url == url::new_unsafe_from_bytes(b"ipfs://bafkreibngqhl3gaa7daob4i2vccziay2jjlp435cf66vhono7nrvww53ty"), 0);

        test_scenario::return_shared(config);
        test_scenario::end(scenario);
    }
}
