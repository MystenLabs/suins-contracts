#[test_only]
module suins::configuration_tests {

    use sui::test_scenario;
    use sui::test_scenario::Scenario;
    use sui::vec_map;
    use suins::configuration::{Self, Configuration};
    use suins::registry::{Self, AdminCap};
    use std::ascii;
    use std::option;

    const SUINS_ADDRESS: address = @0xA001;
    const FIRST_CODE: vector<u8> = b"ThisIsCode1";
    const FIRST_DOMAIN_BATCH: vector<u8> = b"google;suins;medium";
    const SECOND_CODE: vector<u8> = b"DF1234";
    const ADD_CODE_BATCH: vector<u8> = b"ThisIsCode1,30,0xABCDef;DF1234,10,0x0000000000000000000000000000000c9310f87e";
    const REMOVE_CODE_BATCH: vector<u8> = b"ThisIsCode1;DF1234;";
    const FIRST_INVALID_CODE: vector<u8> = vector[1, 2];
    const SECOND_INVALID_CODE: vector<u8> = vector[150];
    const FIRST_RATE: u8 = 10;
    const SECOND_RATE: u8 = 20;
    const FIRST_USER_ADDRESS: address = @0xB001;
    const FIRST_USER_ADDRESS_STR: vector<u8> = b"000000000000000000000000000000000000000000000000000000000000b001";
    const SECOND_USER_ADDRESS: address = @0xB002;
    const SECOND_USER_ADDRESS_STR: vector<u8> = b"000000000000000000000000000000000000000000000000000000000000b002";

    fun test_init(): Scenario {
        let scenario = test_scenario::begin(SUINS_ADDRESS);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            registry::test_init(ctx);
            configuration::test_init(ctx);
        };
        scenario
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
                FIRST_CODE,
                FIRST_RATE,
                FIRST_USER_ADDRESS,
            );
            test_scenario::return_to_sender(&mut scenario, admin_cap);
            test_scenario::return_shared(config);
        };
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let first_code = ascii::string(FIRST_CODE);
            let referral_value = option::extract(&mut configuration::get_referral_code(&config, &first_code));
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
                FIRST_CODE,
                SECOND_RATE,
                SECOND_USER_ADDRESS,
            );
            test_scenario::return_to_sender(&mut scenario, admin_cap);
            test_scenario::return_shared(config);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let first_code = ascii::string(FIRST_CODE);
            let referral_value = option::extract(&mut configuration::get_referral_code(&config, &first_code));
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
                FIRST_CODE,
            );
            test_scenario::return_to_sender(&mut scenario, admin_cap);
            test_scenario::return_shared(config);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let first_code = ascii::string(FIRST_CODE);
            assert!(option::is_none(&mut configuration::get_referral_code(&config, &first_code)), 0);
            test_scenario::return_shared(config);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = configuration::EInvalidRate)]
    fun test_new_referral_code_abort_if_discount_greater_than_100() {
        let scenario = test_init();

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            configuration::new_referral_code(
                &admin_cap,
                &mut config,
                FIRST_CODE,
                101,
                FIRST_USER_ADDRESS
            );
            test_scenario::return_to_sender(&mut scenario, admin_cap);
            test_scenario::return_shared(config);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = configuration::EInvalidRate)]
    fun test_new_referral_code_abort_with_zero_discount() {
        let scenario = test_init();

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            configuration::new_referral_code(
                &admin_cap,
                &mut config,
                FIRST_CODE,
                0,
                FIRST_USER_ADDRESS
            );
            test_scenario::return_to_sender(&mut scenario, admin_cap);
            test_scenario::return_shared(config);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = configuration::EInvalidReferralCode)]
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

    #[test, expected_failure(abort_code = ascii::EINVALID_ASCII_CHARACTER)]
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

    #[test, expected_failure(abort_code = vec_map::EKeyDoesNotExist)]
    fun test_remove_referral_code_abort_if_not_exists() {
        let scenario = test_init();
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            configuration::remove_referral_code(
                &admin_cap,
                &mut config,
                FIRST_CODE,
            );
            test_scenario::return_to_sender(&mut scenario, admin_cap);
            test_scenario::return_shared(config);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_set_then_remove_new_discount_code() {
        let scenario = test_init();
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            assert!(configuration::get_no_discount_codes(&config) == 0, 0);
            configuration::new_discount_code(
                &admin_cap,
                &mut config,
                FIRST_CODE,
                FIRST_RATE,
                FIRST_USER_ADDRESS,
            );
            test_scenario::return_to_sender(&mut scenario, admin_cap);
            test_scenario::return_shared(config);
        };
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            assert!(configuration::get_no_discount_codes(&config) == 1, 0);
            let first_code = ascii::string(FIRST_CODE);
            let referral_value = option::extract(&mut configuration::get_discount_code(&config, &first_code));
            assert!(configuration::get_discount_rate(&referral_value) == FIRST_RATE, 0);
            assert!(configuration::get_discount_owner(&referral_value) == ascii::string(FIRST_USER_ADDRESS_STR), 0);
            test_scenario::return_shared(config);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            configuration::new_discount_code(
                &admin_cap,
                &mut config,
                FIRST_CODE,
                SECOND_RATE,
                SECOND_USER_ADDRESS,
            );
            test_scenario::return_to_sender(&mut scenario, admin_cap);
            test_scenario::return_shared(config);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let first_code = ascii::string(FIRST_CODE);
            let referral_value = option::extract(&mut configuration::get_discount_code(&config, &first_code));
            assert!(configuration::get_discount_rate(&referral_value) == SECOND_RATE, 0);
            assert!(configuration::get_discount_owner(&referral_value) == ascii::string(SECOND_USER_ADDRESS_STR), 0);
            test_scenario::return_shared(config);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            configuration::remove_discount_code(
                &admin_cap,
                &mut config,
                FIRST_CODE,
            );
            test_scenario::return_to_sender(&mut scenario, admin_cap);
            test_scenario::return_shared(config);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let first_code = ascii::string(FIRST_CODE);
            assert!(option::is_none(&mut configuration::get_discount_code(&config, &first_code)), 0);
            test_scenario::return_shared(config);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = configuration::EInvalidRate)]
    fun test_new_discount_code_abort_if_rate_greater_than_100() {
        let scenario = test_init();

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            configuration::new_discount_code(
                &admin_cap,
                &mut config,
                FIRST_CODE,
                101,
                FIRST_USER_ADDRESS
            );
            test_scenario::return_to_sender(&mut scenario, admin_cap);
            test_scenario::return_shared(config);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = configuration::EInvalidRate)]
    fun test_new_discounnt_code_abort_with_zero_rate() {
        let scenario = test_init();

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            configuration::new_discount_code(
                &admin_cap,
                &mut config,
                FIRST_CODE,
                0,
                FIRST_USER_ADDRESS
            );
            test_scenario::return_to_sender(&mut scenario, admin_cap);
            test_scenario::return_shared(config);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = configuration::EInvalidDiscountCode)]
    fun test_set_new_discount_code_abort_with_unprintable_string() {
        let scenario = test_init();
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            configuration::new_discount_code(
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

    #[test, expected_failure(abort_code = ascii::EINVALID_ASCII_CHARACTER)]
    fun test_set_new_discount_code_abort_with_invalid_ascii_string() {
        let scenario = test_init();
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            configuration::new_discount_code(
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

    #[test, expected_failure(abort_code = vec_map::EKeyDoesNotExist)]
    fun test_remove_discount_code_abort_if_not_exists() {
        let scenario = test_init();
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            configuration::remove_discount_code(
                &admin_cap,
                &mut config,
                FIRST_CODE,
            );
            test_scenario::return_to_sender(&mut scenario, admin_cap);
            test_scenario::return_shared(config);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_set_then_remove_discount_code_batch() {
        let scenario = test_init();
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            assert!(configuration::get_no_discount_codes(&config) == 0, 0);
            configuration::new_discount_code_batch(
                &admin_cap,
                &mut config,
                ADD_CODE_BATCH,
            );
            test_scenario::return_to_sender(&mut scenario, admin_cap);
            test_scenario::return_shared(config);
        };
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            assert!(configuration::get_no_discount_codes(&config) == 2, 0);
            let first_code = ascii::string(FIRST_CODE);
            let referral_value = option::extract(&mut configuration::get_discount_code(&config, &first_code));
            assert!(configuration::get_discount_rate(&referral_value) == 30, 0);
            assert!(
                configuration::get_discount_owner(&referral_value) == ascii::string(b"0000000000000000000000000000000000abcdef"),
                0
            );
            let second_code = ascii::string(SECOND_CODE);
            let referral_value = option::extract(&mut configuration::get_discount_code(&config, &second_code));
            assert!(configuration::get_discount_rate(&referral_value) == 10, 0);
            assert!(
                configuration::get_discount_owner(&referral_value) == ascii::string(b"0000000000000000000000000000000c9310f87e"),
                0
            );
            test_scenario::return_shared(config);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            assert!(configuration::get_no_discount_codes(&config) == 2, 0);
            configuration::remove_discount_code_batch(&admin_cap, &mut config, REMOVE_CODE_BATCH);
            assert!(configuration::get_no_discount_codes(&config) == 0, 0);
            test_scenario::return_to_sender(&mut scenario, admin_cap);
            test_scenario::return_shared(config);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_use_discount_code() {
        let scenario = test_init();
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            assert!(configuration::get_no_discount_codes(&config) == 0, 0);
            configuration::new_discount_code(
                &admin_cap,
                &mut config,
                FIRST_CODE,
                FIRST_RATE,
                FIRST_USER_ADDRESS,
            );
            test_scenario::return_to_sender(&mut scenario, admin_cap);
            test_scenario::return_shared(config);
        };
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let first_code = ascii::string(FIRST_CODE);
            let referral_value = configuration::get_discount_code(&config, &first_code);
            assert!(option::is_some(&referral_value), 0);
            test_scenario::return_shared(config);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let rate = configuration::use_discount_code(
                &mut config,
                &ascii::string(FIRST_CODE),
                test_scenario::ctx(&mut scenario),
            );
            assert!(rate == FIRST_RATE, 0);
            test_scenario::return_shared(config);
        };
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let first_code = ascii::string(FIRST_CODE);
            let referral_value = configuration::get_discount_code(&config, &first_code);
            assert!(option::is_none(&referral_value), 0);
            test_scenario::return_shared(config);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_new_discount_code_batch_overrides_old_code() {
        let scenario = test_init();
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            assert!(configuration::get_no_discount_codes(&config) == 0, 0);
            configuration::new_discount_code(
                &admin_cap,
                &mut config,
                FIRST_CODE,
                FIRST_RATE,
                FIRST_USER_ADDRESS,
            );
            assert!(configuration::get_no_discount_codes(&config) == 1, 0);
            test_scenario::return_to_sender(&mut scenario, admin_cap);
            test_scenario::return_shared(config);
        };
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let first_code = ascii::string(FIRST_CODE);
            let referral_value = option::extract(&mut configuration::get_discount_code(&config, &first_code));
            assert!(configuration::get_discount_rate(&referral_value) == 10, 0);
            assert!(
                configuration::get_discount_owner(&referral_value) == ascii::string(FIRST_USER_ADDRESS_STR),
                0
            );
            test_scenario::return_shared(config);
        };
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            configuration::new_discount_code_batch(
                &admin_cap,
                &mut config,
                ADD_CODE_BATCH,
            );
            assert!(configuration::get_no_discount_codes(&config) == 2, 0);
            test_scenario::return_to_sender(&mut scenario, admin_cap);
            test_scenario::return_shared(config);
        };
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let first_code = ascii::string(FIRST_CODE);
            let referral_value = option::extract(&mut configuration::get_discount_code(&config, &first_code));
            assert!(configuration::get_discount_rate(&referral_value) == 30, 0);
            assert!(
                configuration::get_discount_owner(&referral_value) == ascii::string(b"0000000000000000000000000000000000abcdef"),
                0
            );
            test_scenario::return_shared(config);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_set_then_remove_new_reserve_domains() {
        let scenario = test_init();

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            assert!(!configuration::is_label_reserved(&config, b"google"), 0);
            assert!(!configuration::is_label_reserved(&config, b"suins"), 0);
            assert!(!configuration::is_label_reserved(&config, b"medium"), 0);

            configuration::new_reserve_domains(
                &admin_cap,
                &mut config,
                FIRST_DOMAIN_BATCH,
            );

            assert!(configuration::is_label_reserved(&config, b"google"), 0);
            assert!(configuration::is_label_reserved(&config, b"suins"), 0);
            assert!(configuration::is_label_reserved(&config, b"medium"), 0);

            configuration::remove_reserve_domains(
                &admin_cap,
                &mut config,
                b"google",
            );
            assert!(!configuration::is_label_reserved(&config, b"google"), 0);

            configuration::remove_reserve_domains(
                &admin_cap,
                &mut config,
                FIRST_DOMAIN_BATCH,
            );
            assert!(!configuration::is_label_reserved(&config, b"suins"), 0);
            assert!(!configuration::is_label_reserved(&config, b"medium"), 0);

            configuration::new_reserve_domains(
                &admin_cap,
                &mut config,
                b"github",
            );
            assert!(configuration::is_label_reserved(&config, b"github"), 0);

            test_scenario::return_to_sender(&mut scenario, admin_cap);
            test_scenario::return_shared(config);
        };
        test_scenario::end(scenario);
    }
}
