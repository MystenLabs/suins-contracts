#[test_only]
module suins::configuration_tests {

    use sui::test_scenario;
    use sui::url;
    use sui::test_scenario::Scenario;
    use suins::configuration::{Self, Configuration};
    use suins::base_registry::{Self, AdminCap};
    use std::option;

    const SUINS_ADDRESS: address = @0xA001;
    const VALID_CODE: vector<u8> = b"RF1234";
    const FIRST_INVALID_CODE: vector<u8> = b"thisisacode";
    const SECOND_INVALID_CODE: vector<u8> = b"123456";
    const FIRST_RATE: u8 = 10;
    const SECOND_RATE: u8 = 20;
    const FIRST_USER_ADDRESS: address = @0xB001;
    const SECOND_USER_ADDRESS: address = @0xB002;

    fun test_init(): Scenario {
        let scenario = test_scenario::begin(SUINS_ADDRESS);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            base_registry::test_init(ctx);
            configuration::test_init(ctx);
        };
        scenario
    }

    #[test]
    fun test_get_url() {
        let scenario = test_init();

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            configuration::set_network_first_day(&admin_cap, &mut config, 365); // 31-12-2022

            let test_url = configuration::get_url(&config, 0, 0);
            assert!(test_url == url::new_unsafe_from_bytes(b"ipfs://QmfWrgbTZqwzqsvdeNc3NKacggMuTaN83sQ8V7Bs2nXKRD"), 0); // 31-12-2022
            test_url = configuration::get_url(&config, 365, 0);
            assert!(test_url == url::new_unsafe_from_bytes(b"ipfs://QmZsHKQk9FbQZYCy7rMYn1z6m9Raa183dNhpGCRm3fX71s"), 0); // 31-12-2023
            test_url = configuration::get_url(&config, 365, 1);
            assert!(test_url == url::new_unsafe_from_bytes(b"ipfs://QmWjyuoBW7gSxAqvkTYSNbXnNka6iUHNqs3ier9bN3g7Y2"), 0); // 01-01-2024
            // test leap year
            test_url = configuration::get_url(&config, 730, 1);
            assert!(test_url == url::new_unsafe_from_bytes(b"ipfs://QmWjyuoBW7gSxAqvkTYSNbXnNka6iUHNqs3ier9bN3g7Y2"), 0); // 31-12-2024
            test_url = configuration::get_url(&config, 731, 1);
            assert!(test_url == url::new_unsafe_from_bytes(b"ipfs://QmaWNLR6C3QsSHcPwNoFA59DPXCKdx1t8hmyyKRqBbjYB3"), 0); // 01-01-2025
            test_url = configuration::get_url(&config, 7300, 1);
            assert!(test_url == url::new_unsafe_from_bytes(b"ipfs://bafkreibngqhl3gaa7daob4i2vccziay2jjlp435cf66vhono7nrvww53ty"), 0);

            test_scenario::return_to_sender(&mut scenario, admin_cap);
            test_scenario::return_shared(config);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_set_then_remove_new_referral_code() {
        let scenario = test_init();

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            configuration::new_referral_code(
                &admin_cap,
                &mut config,
                VALID_CODE,
                FIRST_RATE,
                FIRST_USER_ADDRESS,
            );
            test_scenario::return_to_sender(&mut scenario, admin_cap);
            test_scenario::return_shared(config);
        };
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let referral_value = option::extract(&mut configuration::get_referral_code(&config, VALID_CODE));
            assert!(configuration::get_referral_rate(&referral_value) == FIRST_RATE, 0);
            assert!(configuration::get_referral_partner(&referral_value) == FIRST_USER_ADDRESS, 0);
            test_scenario::return_shared(config);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            configuration::new_referral_code(
                &admin_cap,
                &mut config,
                VALID_CODE,
                SECOND_RATE,
                SECOND_USER_ADDRESS,
            );
            test_scenario::return_to_sender(&mut scenario, admin_cap);
            test_scenario::return_shared(config);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let referral_value = option::extract(&mut configuration::get_referral_code(&config, VALID_CODE));
            assert!(configuration::get_referral_rate(&referral_value) == SECOND_RATE, 0);
            assert!(configuration::get_referral_partner(&referral_value) == SECOND_USER_ADDRESS, 0);

            test_scenario::return_shared(config);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            configuration::remove_referral_code(
                &admin_cap,
                &mut config,
                VALID_CODE,
            );
            test_scenario::return_to_sender(&mut scenario, admin_cap);
            test_scenario::return_shared(config);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            assert!(option::is_none(&mut configuration::get_referral_code(&config, VALID_CODE)), 0);
            test_scenario::return_shared(config);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 401)]
    fun test_new_referral_code_abort_if_discount_greater_than_100() {
        let scenario = test_init();

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            configuration::new_referral_code(
                &admin_cap,
                &mut config,
                VALID_CODE,
                101,
                FIRST_USER_ADDRESS
            );
            test_scenario::return_to_sender(&mut scenario, admin_cap);
            test_scenario::return_shared(config);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 401)]
    fun test_new_referral_code_abort_with_zero_discount() {
        let scenario = test_init();

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            configuration::new_referral_code(
                &admin_cap,
                &mut config,
                VALID_CODE,
                0,
                FIRST_USER_ADDRESS
            );
            test_scenario::return_to_sender(&mut scenario, admin_cap);
            test_scenario::return_shared(config);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 402)]
    fun test_set_new_referral_code_abort_with_unprintable_string() {
        let scenario = test_init();
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            configuration::new_referral_code(
                &admin_cap,
                &mut config,
                FIRST_INVALID_CODE,
                FIRST_RATE,
                FIRST_USER_ADDRESS
            );
            test_scenario::return_to_sender(&mut scenario, admin_cap);
            test_scenario::return_shared(config);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 402)]
    fun test_set_new_referral_code_abort_with_invalid_ascii_string() {
        let scenario = test_init();
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            configuration::new_referral_code(
                &admin_cap,
                &mut config,
                SECOND_INVALID_CODE,
                FIRST_RATE,
                FIRST_USER_ADDRESS,
            );
            test_scenario::return_to_sender(&mut scenario, admin_cap);
            test_scenario::return_shared(config);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1)]
    fun test_remove_referral_code_abort_if_not_exists() {
        let scenario = test_init();
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            configuration::remove_referral_code(
                &admin_cap,
                &mut config,
                VALID_CODE,
            );
            test_scenario::return_to_sender(&mut scenario, admin_cap);
            test_scenario::return_shared(config);
        };
        test_scenario::end(scenario);
    }
}
