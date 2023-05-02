#[test_only]
module suins::controller_tests {
    use std::string::utf8;

    use sui::coin::{Self, Coin};
    use sui::test_scenario::{Self, Scenario};
    use sui::clock::{Self, Clock};
    use sui::sui::SUI;
    use sui::url;
    use sui::dynamic_field;

    use suins::auction;
    use suins::registrar::{Self, RegistrationNFT};
    use suins::registry;
    use suins::suins::{Self, AdminCap, SuiNS};
    use suins::config::{Self, Config};
    use suins::controller;
    use suins::string_utils;
    use suins::promotion::{Self, Promotion};
    use suins::registrar_tests::ctx_new;

    const SUINS_ADDRESS: address = @0xA001;
    const FIRST_USER_ADDRESS: address = @0xB001;
    const SECOND_USER_ADDRESS: address = @0xB002;
    const FIRST_LABEL: vector<u8> = b"eastagile-123";
    const FIRST_DOMAIN_NAME: vector<u8> = b"eastagile-123.sui";
    const SECOND_LABEL: vector<u8> = b"suinameservice";
    const THIRD_LABEL: vector<u8> = b"thirdsuinameservice";
    const FIRST_SECRET: vector<u8> = b"oKz=QdYd)]ryKB%";
    const FIRST_INVALID_LABEL: vector<u8> = b"east.agile";
    const SECOND_INVALID_LABEL: vector<u8> = b"ea";
    const THIRD_INVALID_LABEL: vector<u8> = b"zkaoxpcbarubhtxkunajudxezneyczueajbggrynkwbepxjqjxrigrtgglhfjpax";
    const AUCTIONED_LABEL: vector<u8> = b"suins";
    const AUCTIONED_DOMAIN_NAME: vector<u8> = b"suins.sui";
    const FOURTH_INVALID_LABEL: vector<u8> = b"-eastagile";
    const FIFTH_INVALID_LABEL: vector<u8> = b"east/?agile";
    const REFERRAL_CODE: vector<u8> = b"X43kS8";
    const DISCOUNT_CODE: vector<u8> = b"DC12345";
    const BIDDING_PERIOD: u64 = 1;
    const REVEAL_PERIOD: u64 = 1;
    const START_AUCTION_START_AT: u64 = 50;
    const START_AUCTION_END_AT: u64 = 120;
    const EXTRA_PERIOD_START_AT: u64 = 127;
    const EXTRA_PERIOD_END_AT: u64 = 156;
    const START_AN_AUCTION_AT: u64 = 110;
    const EXTRA_PERIOD: u64 = 30;
    const SUI_REGISTRAR: vector<u8> = b"sui";
    const MOVE_REGISTRAR: vector<u8> = b"move";
    const BIDDING_FEE: u64 = 1000000000;
    const START_AN_AUCTION_FEE: u64 = 10_000_000_000;
    const PRICE_OF_THREE_CHARACTER_DOMAIN: u64 = 1200 * 1_000_000_000;
    const PRICE_OF_FOUR_CHARACTER_DOMAIN: u64 = 200 * 1_000_000_000;
    const PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN: u64 = 50 * 1_000_000_000;
    const GRACE_PERIOD: u64 = 30;
    const DEFAULT_TX_HASH: vector<u8> = x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532";

    public fun test_init(): Scenario {
        let scenario = test_scenario::begin(SUINS_ADDRESS);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            suins::test_setup::setup(ctx);
            clock::share_for_testing(clock::create_for_testing(ctx));
        };
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = suins::remove_config<Config>(&admin_cap, &mut suins);
            let promotion = suins::remove_config<Promotion>(&admin_cap, &mut suins);

            registrar::new_tld(&admin_cap, &mut suins, utf8(SUI_REGISTRAR), test_scenario::ctx(&mut scenario));
            registrar::new_tld(&admin_cap, &mut suins, utf8(MOVE_REGISTRAR), test_scenario::ctx(&mut scenario));
            promotion::add_referral_code(&mut promotion, utf8(REFERRAL_CODE), 10, SECOND_USER_ADDRESS);
            promotion::add_discount_code(&mut promotion, utf8(DISCOUNT_CODE), 15, FIRST_USER_ADDRESS);
            config::set_public_key(
                &mut config,
                x"0445e28df251d0ec0f66f284f7d5598db7e68b1a196396e4e13a3942d1364812ae5ed65ebb3d20cbf073ad50c6bbafa92505dc9b306e30476e57919a63ac824cab"
            );

            suins::add_config(&admin_cap, &mut suins, promotion);
            suins::add_config(&admin_cap, &mut suins, config);
            test_scenario::return_shared(suins);
            test_scenario::return_to_sender(&mut scenario, admin_cap);
        };
        scenario
    }

    public fun set_auction_config(scenario: &mut Scenario) {
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            auction::configure_auction(
                &admin_cap,
                &mut suins,
                START_AUCTION_START_AT,
                test_scenario::ctx(scenario)
            );
            test_scenario::return_shared(suins);
            test_scenario::return_to_sender(scenario, admin_cap);
        };
    }

    public fun register(scenario: &mut Scenario) {
        // register
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            // simulate user wait for next epoch to call `register`
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN + 1, &mut ctx);

            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);
            assert!(!suins::has_name_record(&suins, utf8(FIRST_DOMAIN_NAME)), 0);
            assert!(suins::balance(&suins) == 0, 0);
            assert!(!test_scenario::has_most_recent_for_sender<RegistrationNFT>(scenario), 0);

            controller::register(
                &mut suins,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                1,
                &mut coin,
                &clock,
                &mut ctx,
            );
            assert!(coin::value(&coin) == 1, 0);

            coin::burn_for_testing(coin);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);

            assert!(suins::balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, 0);
            assert!(name == utf8(FIRST_DOMAIN_NAME), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );

            let expired_at = registrar::get_record_expired_at(&suins, SUI_REGISTRAR, FIRST_LABEL);
            assert!(expired_at == EXTRA_PERIOD_END_AT + 1 + 365, 0);

            let (owner, target_address) = registry::get_name_record_all_fields(&suins, utf8(FIRST_DOMAIN_NAME));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(target_address == std::option::some(FIRST_USER_ADDRESS), 0);

            test_scenario::return_to_sender(scenario, nft);
            test_scenario::return_shared(suins);
        };
    }

    #[test, expected_failure(abort_code = controller::ENotEnoughFee)]
    fun test_register_abort_if_not_enough_fee() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            // simulate user wait for next epoch to call `register`
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(9999, &mut ctx);

            controller::register(
                &mut suins,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                1,
                &mut coin,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::ELabelUnavailable)]
    fun test_register_abort_if_label_was_registered_before() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        register(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            // simulate user wait for next epoch to call `register`
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(1000001, &mut ctx);

            assert!(suins::balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, 0);
            controller::register(
                &mut suins,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                1,
                &mut coin,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_works_if_previous_registration_is_expired() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        register(&mut scenario);

        test_scenario::next_tx(&mut scenario, SECOND_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            // simulate user wait for next epoch to call `register`
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1 + 365 + GRACE_PERIOD + 1,
                20
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, &mut ctx);

            assert!(suins::balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, 0);
            controller::register(
                &mut suins,
                utf8(FIRST_LABEL),
                SECOND_USER_ADDRESS,
                1,
                &mut coin,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
        };

        test_scenario::next_tx(&mut scenario, SECOND_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);

            assert!(suins::balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 2, 0);
            assert!(name == utf8(FIRST_DOMAIN_NAME), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );

            let expired_at = registrar::get_record_expired_at(&suins, SUI_REGISTRAR, FIRST_LABEL);
            assert!(expired_at == EXTRA_PERIOD_END_AT + 1 + 365 + GRACE_PERIOD + 1 + 365, 0);

            let (owner, target_address) = registry::get_name_record_all_fields(&suins, utf8(FIRST_DOMAIN_NAME));
            assert!(owner == SECOND_USER_ADDRESS, 0);
            assert!(target_address == std::option::some(SECOND_USER_ADDRESS), 0);

            let registrar = registrar::get_registrar(&suins, SUI_REGISTRAR);
            registrar::assert_nft_not_expires(
                registrar,
                &nft,
                test_scenario::ctx(&mut scenario)
            );

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registrar::ENFTExpired)]
    fun test_register_works_if_previous_registration_is_expired_2() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        register(&mut scenario);

        test_scenario::next_tx(&mut scenario, SECOND_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            // simulate user wait for next epoch to call `register`
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1 + 365 + GRACE_PERIOD + 1,
                20
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, &mut ctx);
            assert!(suins::balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, 0);

            controller::register(
                &mut suins,
                utf8(FIRST_LABEL),
                SECOND_USER_ADDRESS,
                1,
                &mut coin,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            let registrar = registrar::get_registrar(&suins, SUI_REGISTRAR);
            registrar::assert_nft_not_expires(
                registrar,
                &nft,
                test_scenario::ctx(&mut scenario)
            );

            test_scenario::return_shared(suins);
            test_scenario::return_to_sender(&mut scenario, nft);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 4, &mut ctx);

            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);
            assert!(!suins::has_name_record(&suins, utf8(FIRST_DOMAIN_NAME)), 0);
            assert!(suins::balance(&suins) == 0, 0);
            assert!(!test_scenario::has_most_recent_for_sender<RegistrationNFT>(&mut scenario), 0);

            controller::register(
                &mut suins,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                2,
                &mut coin,
                &clock,
                &mut ctx,
            );
            assert!(coin::value(&coin) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 2, 0);

            coin::burn_for_testing(coin);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);

            assert!(suins::balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 2, 0);
            assert!(name == utf8(FIRST_DOMAIN_NAME), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );

            let expired_at = registrar::get_record_expired_at(&suins, SUI_REGISTRAR, FIRST_LABEL);
            assert!(expired_at == EXTRA_PERIOD_END_AT + 1 + 730, 0);

            let (owner, target_address) = registry::get_name_record_all_fields(&suins, utf8(FIRST_DOMAIN_NAME));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(target_address == std::option::some(FIRST_USER_ADDRESS), 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };

        // withdraw
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            assert!(suins::balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 2, 0);
            assert!(!test_scenario::has_most_recent_for_sender<Coin<SUI>>(&mut scenario), 0);

            let coins = suins::withdraw(&admin_cap, &mut suins, test_scenario::ctx(&mut scenario));
            sui::transfer::public_transfer(coins, SUINS_ADDRESS);
            assert!(suins::balance(&suins) == 0, 0);

            test_scenario::return_shared(suins);
            test_scenario::return_to_sender(&mut scenario, admin_cap);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            assert!(test_scenario::has_most_recent_for_sender<Coin<SUI>>(&mut scenario), 0);
            let coin = test_scenario::take_from_sender<Coin<SUI>>(&mut scenario);
            assert!(coin::value(&coin) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 2, 0);
            test_scenario::return_to_sender(&mut scenario, coin);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::EAuctionNotEndYet)]
    fun test_register_with_config_aborts_with_too_short_label_and_auction_house_not_configured() {
        let scenario = test_init();

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(10001, test_scenario::ctx(&mut scenario));

            controller::register(
                &mut suins,
                utf8(SECOND_INVALID_LABEL),
                FIRST_USER_ADDRESS,
                2,
                &mut coin,
                &clock,
                test_scenario::ctx(&mut scenario),
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
        };

        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = string_utils::EInvalidLabel)]
    fun test_register_with_config_aborts_with_too_short_label() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(10001, test_scenario::ctx(&mut scenario));
            let ctx = &mut ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                START_AUCTION_END_AT + BIDDING_PERIOD + REVEAL_PERIOD + EXTRA_PERIOD + 10,
                0
            );

            controller::register(
                &mut suins,
                utf8(SECOND_INVALID_LABEL),
                FIRST_USER_ADDRESS,
                2,
                &mut coin,
                &clock,
                ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
        };

        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::EAuctionNotEndYet)]
    fun test_register_with_config_aborts_with_too_long_label_and_auction_house_not_configured() {
        let scenario = test_init();

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(1000001, test_scenario::ctx(&mut scenario));

            controller::register(
                &mut suins,
                utf8(THIRD_INVALID_LABEL),
                FIRST_USER_ADDRESS,
                2,
                &mut coin,
                &clock,
                test_scenario::ctx(&mut scenario),
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
        };

        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = string_utils::EInvalidLabel)]
    fun test_register_with_config_aborts_with_too_long_label() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(1000001, test_scenario::ctx(&mut scenario));
            let ctx = &mut ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                START_AUCTION_END_AT + BIDDING_PERIOD + REVEAL_PERIOD + EXTRA_PERIOD + 10,
                0
            );

            controller::register(
                &mut suins,
                utf8(THIRD_INVALID_LABEL),
                FIRST_USER_ADDRESS,
                2,
                &mut coin,
                &clock,
                ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
        };

        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::EAuctionNotEndYet)]
    fun test_register_aborts_if_label_starts_with_hyphen_and_auction_house_not_configured() {
        let scenario = test_init();

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(10001, test_scenario::ctx(&mut scenario));

            controller::register(
                &mut suins,
                utf8(FOURTH_INVALID_LABEL),
                FIRST_USER_ADDRESS,
                2,
                &mut coin,
                &clock,
                test_scenario::ctx(&mut scenario),
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
        };

        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = string_utils::EInvalidLabel)]
    fun test_register_with_config_aborts_if_label_starts_with_hyphen() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(10001, test_scenario::ctx(&mut scenario));
            let ctx = &mut ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                START_AUCTION_END_AT + BIDDING_PERIOD + REVEAL_PERIOD + EXTRA_PERIOD + 10,
                0
            );

            controller::register(
                &mut suins,
                utf8(FOURTH_INVALID_LABEL),
                FIRST_USER_ADDRESS,
                2,
                &mut coin,
                &clock,
                ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
        };

        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::EAuctionNotEndYet)]
    fun test_register_with_config_abort_with_invalid_label_and_auction_house_not_being_configured() {
        let scenario = test_init();

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(1000001, test_scenario::ctx(&mut scenario));

            controller::register(
                &mut suins,
                utf8(FIFTH_INVALID_LABEL),
                FIRST_USER_ADDRESS,
                2,
                &mut coin,
                &clock,
                test_scenario::ctx(&mut scenario),
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
        };

        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = string_utils::EInvalidLabel)]
    fun test_register_with_config_abort_with_invalid_label() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(1000001, test_scenario::ctx(&mut scenario));
            let ctx = &mut ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                START_AUCTION_END_AT + BIDDING_PERIOD + REVEAL_PERIOD + EXTRA_PERIOD + 10,
                0
            );
            controller::register(
                &mut suins,
                utf8(FIFTH_INVALID_LABEL),
                FIRST_USER_ADDRESS,
                2,
                &mut coin,
                &clock,
                ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
        };

        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = suins::suins::ENoProfits)]
    fun test_withdraw_abort_if_no_profits() {
        let scenario = test_init();

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let coins = suins::withdraw(&admin_cap, &mut suins, test_scenario::ctx(&mut scenario));
            sui::transfer::public_transfer(coins, SUINS_ADDRESS);
            test_scenario::return_shared(suins);
            test_scenario::return_to_sender(&mut scenario, admin_cap);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_abort_if_label_is_reserved_for_auction_but_auction_ended() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 3, test_scenario::ctx(&mut scenario));

            controller::register(
                &mut suins,
                utf8(AUCTIONED_LABEL),
                FIRST_USER_ADDRESS,
                2,
                &mut coin,
                &clock,
                &mut ctx_new(
                    SUINS_ADDRESS,
                    DEFAULT_TX_HASH,
                    EXTRA_PERIOD_END_AT + 1,
                    20
                ),
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);

            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);
            assert!(name == utf8(AUCTIONED_DOMAIN_NAME), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );

            let expired_at = registrar::get_record_expired_at(&suins, SUI_REGISTRAR, AUCTIONED_LABEL);
            assert!(expired_at == EXTRA_PERIOD_END_AT + 1 + 730, 0);

            let (owner, target_address) = registry::get_name_record_all_fields(&suins, utf8(AUCTIONED_DOMAIN_NAME));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(target_address == std::option::some(FIRST_USER_ADDRESS), 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::EAuctionNotEndYet)]
    fun test_register_abort_if_label_is_reserved_for_auction() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(10000001, test_scenario::ctx(&mut scenario));

            controller::register(
                &mut suins,
                utf8(AUCTIONED_LABEL),
                FIRST_USER_ADDRESS,
                2,
                &mut coin,
                &clock,
                test_scenario::ctx(&mut scenario),
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };

        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = string_utils::EInvalidLabel)]
    fun test_register_abort_if_label_is_invalid() {
        let scenario = test_init();
        set_auction_config(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(10001, &mut ctx);

            controller::register(
                &mut suins,
                utf8(FIRST_INVALID_LABEL),
                FIRST_USER_ADDRESS,
                2,
                &mut coin,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_renew() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        register(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 2 + 1, ctx);

            assert!(registrar::name_expires_at(&suins, utf8(SUI_REGISTRAR), utf8(FIRST_LABEL)) == 522, 0);
            assert!(suins::balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, 0);
            controller::renew(
                &mut suins,
                utf8(FIRST_LABEL),
                2,
                &mut coin,
                ctx,
            );
            assert!(coin::value(&coin) == 1, 0);
            assert!(registrar::name_expires_at(&suins, utf8(SUI_REGISTRAR), utf8(FIRST_LABEL)) == 1252, 0);

            coin::burn_for_testing(coin);
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            assert!(suins::balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 3, 0);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registrar::ELabelNotExists)]
    fun test_renew_abort_if_label_not_exists() {
        let scenario = test_init();

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, ctx);

            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);

            controller::renew(
                &mut suins,
                utf8(FIRST_LABEL),
                1,
                &mut coin,
                ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registrar::ELabelExpired)]
    fun test_renew_abort_if_label_expired() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        register(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                1051,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, &mut ctx);

            controller::renew(
                &mut suins,
                utf8(FIRST_LABEL),
                1,
                &mut coin,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::ENotEnoughFee)]
    fun test_renew_abort_if_not_enough_fee() {
        let scenario = test_init();

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(4, ctx);

            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);

            controller::renew(
                &mut suins,
                utf8(FIRST_LABEL),
                1,
                &mut coin,
                ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_with_referral_code() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 3, &mut ctx);

            assert!(suins::balance(&suins) == 0, 0);
            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);
            assert!(!suins::has_name_record(&suins, utf8(FIRST_DOMAIN_NAME)), 0);
            assert!(!test_scenario::has_most_recent_for_sender<RegistrationNFT>(&mut scenario), 0);
            assert!(!test_scenario::has_most_recent_for_address<Coin<SUI>>(SECOND_USER_ADDRESS), 0);

            controller::register_with_code(
                &mut suins,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                2,
                &mut coin,
                REFERRAL_CODE,
                b"",
                &clock,
                &mut ctx,
            );

            assert!(coin::value(&coin) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, 0);

            coin::burn_for_testing(coin);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            let coin = test_scenario::take_from_address<Coin<SUI>>(&mut scenario, SECOND_USER_ADDRESS);

            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);
            assert!(name == utf8(FIRST_DOMAIN_NAME), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );
            assert!(coin::value(&coin) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 2 / 10, 0);
            assert!(suins::balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 2 * 9/ 10, 0);

            let expired_at = registrar::get_record_expired_at(&suins, SUI_REGISTRAR, FIRST_LABEL);
            assert!(expired_at == EXTRA_PERIOD_END_AT + 1 + 730, 0);

            let (owner, target_address) = registry::get_name_record_all_fields(&suins, utf8(FIRST_DOMAIN_NAME));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(target_address == std::option::some(FIRST_USER_ADDRESS), 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_to_address(SECOND_USER_ADDRESS, coin);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_with_config_referral_code() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 4, &mut ctx);

            assert!(suins::balance(&suins) == 0, 0);
            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);
            assert!(!suins::has_name_record(&suins, utf8(FIRST_DOMAIN_NAME)), 0);
            assert!(!test_scenario::has_most_recent_for_sender<RegistrationNFT>(&mut scenario), 0);
            assert!(!test_scenario::has_most_recent_for_address<Coin<SUI>>(SECOND_USER_ADDRESS), 0);

            controller::register_with_code(
                &mut suins,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                3,
                &mut coin,
                REFERRAL_CODE,
                b"",
                &clock,
                &mut ctx,
            );
            assert!(coin::value(&coin) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, 0);
            coin::burn_for_testing(coin);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let coin = test_scenario::take_from_address<Coin<SUI>>(&mut scenario, SECOND_USER_ADDRESS);

            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);

            assert!(name == utf8(FIRST_DOMAIN_NAME), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );
            assert!(coin::value(&coin) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 30 / 100, 0);
            assert!(suins::balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 270 / 100, 0);

            let expired_at = registrar::get_record_expired_at(&suins, SUI_REGISTRAR, FIRST_LABEL);
            assert!(expired_at == EXTRA_PERIOD_END_AT + 1 + 1095, 0);

            let (owner, target_address) = registry::get_name_record_all_fields(&suins, utf8(FIRST_DOMAIN_NAME));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(target_address == std::option::some(FIRST_USER_ADDRESS), 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_to_address(SECOND_USER_ADDRESS, coin);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }


    #[test]
    fun test_apply_referral() {
        let scenario = test_init();
        test_scenario::next_tx(&mut scenario, SECOND_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let coin1 = coin::mint_for_testing<SUI>(4000000, ctx);
            let coin2 = coin::mint_for_testing<SUI>(909, ctx);

            assert!(!test_scenario::has_most_recent_for_address<Coin<SUI>>(SECOND_USER_ADDRESS), 0);
            controller::apply_referral_code_test(&mut suins, &mut coin1, 4000000, REFERRAL_CODE, ctx);
            assert!(coin::value(&coin1) == 3600000, 0);

            controller::apply_referral_code_test(&mut suins, &mut coin2, 909, REFERRAL_CODE, ctx);
            assert!(coin::value(&coin2) == 810, 0);

            coin::burn_for_testing(coin2);
            coin::burn_for_testing(coin1);
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, SECOND_USER_ADDRESS);
        {
            let coin1 = test_scenario::take_from_address<Coin<SUI>>(&mut scenario, SECOND_USER_ADDRESS);
            let coin2 = test_scenario::take_from_address<Coin<SUI>>(&mut scenario, SECOND_USER_ADDRESS);

            assert!(coin::value(&coin1) == 99, 0);
            assert!(coin::value(&coin2) == 400000, 0);

            test_scenario::return_to_address(SECOND_USER_ADDRESS, coin1);
            test_scenario::return_to_address(SECOND_USER_ADDRESS, coin2);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_with_discount_code() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 3, &mut ctx);

            assert!(suins::balance(&suins) == 0, 0);
            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);
            assert!(!suins::has_name_record(&suins, utf8(FIRST_DOMAIN_NAME)), 0);
            assert!(!test_scenario::has_most_recent_for_sender<RegistrationNFT>(&mut scenario), 0);
            assert!(!test_scenario::has_most_recent_for_address<Coin<SUI>>(SECOND_USER_ADDRESS), 0);

            controller::register_with_code(
                &mut suins,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                2,
                &mut coin,
                b"",
                DISCOUNT_CODE,
                &clock,
                &mut ctx,
            );

            assert!(coin::value(&coin) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 130 / 100, 0);

            coin::burn_for_testing(coin);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);

            assert!(!test_scenario::has_most_recent_for_address<Coin<SUI>>(SECOND_USER_ADDRESS), 0);
            assert!(name == utf8(FIRST_DOMAIN_NAME), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );
            assert!(suins::balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 170 / 100, 0);

            let expired_at = registrar::get_record_expired_at(&suins, SUI_REGISTRAR, FIRST_LABEL);
            assert!(expired_at == EXTRA_PERIOD_END_AT + 1 + 730, 0);

            let (owner, target_address) = registry::get_name_record_all_fields(&suins, utf8(FIRST_DOMAIN_NAME));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(target_address == std::option::some(FIRST_USER_ADDRESS), 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = promotion::ENotOwner)]
    fun test_register_with_discount_code_abort_if_unauthorized() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        test_scenario::next_tx(&mut scenario, SECOND_USER_ADDRESS);
        {
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let ctx = ctx_new(
                SECOND_USER_ADDRESS,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 3, &mut ctx);

            controller::register_with_code(
                &mut suins,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                2,
                &mut coin,
                b"",
                DISCOUNT_CODE,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = promotion::ENotExists)]
    fun test_register_with_discount_code_abort_with_invalid_code() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 3, &mut ctx);

            controller::register_with_code(
                &mut suins,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                2,
                &mut coin,
                b"",
                REFERRAL_CODE,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_with_config_and_discount_code() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 3, &mut ctx);

            assert!(suins::balance(&suins) == 0, 0);
            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);
            assert!(!suins::has_name_record(&suins, utf8(FIRST_DOMAIN_NAME)), 0);
            assert!(!test_scenario::has_most_recent_for_sender<RegistrationNFT>(&mut scenario), 0);
            assert!(!test_scenario::has_most_recent_for_address<Coin<SUI>>(SECOND_USER_ADDRESS), 0);

            controller::register_with_code(
                &mut suins,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                2,
                &mut coin,
                b"",
                DISCOUNT_CODE,
                &clock,
                &mut ctx,
            );
            assert!(coin::value(&coin) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN + (PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 30)/100 , 0);

            coin::burn_for_testing(coin);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);

            assert!(!test_scenario::has_most_recent_for_address<Coin<SUI>>(SECOND_USER_ADDRESS), 0);
            assert!(name == utf8(FIRST_DOMAIN_NAME), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );
            assert!(suins::balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 170 / 100, 0);

            let expired_at = registrar::get_record_expired_at(&suins, SUI_REGISTRAR, FIRST_LABEL);
            assert!(expired_at == EXTRA_PERIOD_END_AT + 1 + 730, 0);

            let (owner, target_address) = registry::get_name_record_all_fields(&suins, utf8(FIRST_DOMAIN_NAME));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(target_address == std::option::some(FIRST_USER_ADDRESS), 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = promotion::ENotOwner)]
    fun test_register_with_config_and_discount_code_abort_if_unauthorized() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        test_scenario::next_tx(&mut scenario, SECOND_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let ctx = ctx_new(
                SECOND_USER_ADDRESS,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 3, &mut ctx);

            controller::register_with_code(
                &mut suins,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                2,
                &mut coin,
                b"",
                DISCOUNT_CODE,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = promotion::ENotExists)]
    fun test_register_with_config_and_discount_code_abort_with_invalid_code() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 3, &mut ctx);

            controller::register_with_code(
                &mut suins,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                2,
                &mut coin,
                b"",
                REFERRAL_CODE,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = promotion::ENotExists)]
    fun test_register_with_discount_code_abort_if_being_used_twice() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 3, &mut ctx);

            controller::register_with_code(
                &mut suins,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                2,
                &mut coin,
                b"",
                DISCOUNT_CODE,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 3, &mut ctx);

            controller::register_with_code(
                &mut suins,
                utf8(SECOND_LABEL),
                FIRST_USER_ADDRESS,
                2,
                &mut coin,
                b"",
                DISCOUNT_CODE,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_with_referral_code_works_if_code_is_used_twice() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 3, &mut ctx);

            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);
            controller::register_with_code(
                &mut suins,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                2,
                &mut coin,
                REFERRAL_CODE,
                b"",
                &clock,
                &mut ctx,
            );
            assert!(coin::value(&coin) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, 0);

            coin::burn_for_testing(coin);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let coin = test_scenario::take_from_address<Coin<SUI>>(&mut scenario, SECOND_USER_ADDRESS);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            assert!(coin::value(&coin) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN / 5, 0);
            assert!(suins::balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 9 / 5, 0);

            test_scenario::return_to_address(SECOND_USER_ADDRESS, coin);
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            // simulate user wait for next epoch to call `register`
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                20
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 3, &mut ctx);

            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, SECOND_LABEL), 0);
            controller::register_with_code(
                &mut suins,
                utf8(SECOND_LABEL),
                FIRST_USER_ADDRESS,
                1,
                &mut coin,
                REFERRAL_CODE,
                b"",
                &clock,
                &mut ctx,
            );
            assert!(coin::value(&coin) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 2, 0);

            coin::burn_for_testing(coin);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let coin1 = test_scenario::take_from_address<Coin<SUI>>(&mut scenario, SECOND_USER_ADDRESS);
            let coin2 = test_scenario::take_from_address<Coin<SUI>>(&mut scenario, SECOND_USER_ADDRESS);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            assert!(coin::value(&coin1) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN / 10, 0);
            assert!(coin::value(&coin2) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN / 5, 0);
            assert!(suins::balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 27 / 10, 0);

            test_scenario::return_shared(suins);
            test_scenario::return_to_address(SECOND_USER_ADDRESS, coin1);
            test_scenario::return_to_address(SECOND_USER_ADDRESS, coin2);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = promotion::ENotExists)]
    fun test_register_with_referral_code_abort_with_wrong_referral_code() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 2, &mut ctx);

            controller::register_with_code(
                &mut suins,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                2,
                &mut coin,
                DISCOUNT_CODE,
                b"",
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = string_utils::EInvalidLabel)]
    fun test_register_with_emoji_aborts() {
        let scenario = test_init();
        let label = vector[104, 109, 109, 109, 49, 240, 159, 145, 180];
        let domain_name = vector[104, 109, 109, 109, 49, 240, 159, 145, 180, 46, 115, 117, 105];
        set_auction_config(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            // simulate user wait for next epoch to call `register`
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 3, &mut ctx);

            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, domain_name), 0);
            assert!(suins::balance(&suins) == 0, 0);
            assert!(!suins::has_name_record(&suins, utf8(domain_name)), 0);
            assert!(!test_scenario::has_most_recent_for_sender<RegistrationNFT>(&mut scenario), 0);

            controller::register(
                &mut suins,
                utf8(label),
                FIRST_USER_ADDRESS,
                2,
                &mut coin,
                &clock,
                &mut ctx,
            );
            assert!(coin::value(&coin) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, 0);

            coin::burn_for_testing(coin);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_with_code_apply_both_types_of_code() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            // simulate user wait for next epoch to call `register`
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 3, &mut ctx);

            assert!(suins::balance(&suins) == 0, 0);
            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);
            assert!(!suins::has_name_record(&suins, utf8(FIRST_DOMAIN_NAME)), 0);
            assert!(!test_scenario::has_most_recent_for_sender<RegistrationNFT>(&mut scenario), 0);
            assert!(!test_scenario::has_most_recent_for_address<Coin<SUI>>(SECOND_USER_ADDRESS), 0);

            controller::register_with_code(
                &mut suins,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                2,
                &mut coin,
                REFERRAL_CODE,
                DISCOUNT_CODE,
                &clock,
                &mut ctx,
            );
            assert!(coin::value(&coin) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 130 / 100, 0);

            coin::burn_for_testing(coin);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let coin = test_scenario::take_from_address<Coin<SUI>>(&mut scenario, SECOND_USER_ADDRESS);

            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);

            assert!(name == utf8(FIRST_DOMAIN_NAME), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );
            assert!(coin::value(&coin) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 17 / 100, 0);
            assert!(suins::balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 153 / 100, 0);

            let expired_at = registrar::get_record_expired_at(&suins, SUI_REGISTRAR, FIRST_LABEL);
            assert!(expired_at == EXTRA_PERIOD_END_AT + 1 + 730, 0);

            let (owner, target_address) = registry::get_name_record_all_fields(&suins, utf8(FIRST_DOMAIN_NAME));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(target_address == std::option::some(FIRST_USER_ADDRESS), 0);

            coin::burn_for_testing(coin);
            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = promotion::ENotExists)]
    fun test_register_with_code_if_use_wrong_referral_code() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 3, &mut ctx);

            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);
            controller::register_with_code(
                &mut suins,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                2,
                &mut coin,
                DISCOUNT_CODE,
                DISCOUNT_CODE,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = promotion::ENotExists)]
    fun test_register_with_code_if_use_wrong_discount_code() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 3, &mut ctx);

            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);
            controller::register_with_code(
                &mut suins,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                2,
                &mut coin,
                REFERRAL_CODE,
                REFERRAL_CODE,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_with_config_and_code_apply_both_types_of_code() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 3, &mut ctx);

            assert!(suins::balance(&suins) == 0, 0);
            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);
            assert!(!suins::has_name_record(&suins, utf8(FIRST_DOMAIN_NAME)), 0);
            assert!(!test_scenario::has_most_recent_for_sender<RegistrationNFT>(&mut scenario), 0);
            assert!(!test_scenario::has_most_recent_for_address<Coin<SUI>>(SECOND_USER_ADDRESS), 0);

            controller::register_with_code(
                &mut suins,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                2,
                &mut coin,
                REFERRAL_CODE,
                DISCOUNT_CODE,
                &clock,
                &mut ctx,
            );
            assert!(coin::value(&coin) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 130 / 100, 0);
            coin::burn_for_testing(coin);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let coin = test_scenario::take_from_address<Coin<SUI>>(&mut scenario, SECOND_USER_ADDRESS);

            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);
            assert!(name == utf8(FIRST_DOMAIN_NAME), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );
            assert!(coin::value(&coin) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 170 / 1000, 0);
            assert!(suins::balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 153 / 100, 0);

            let expired_at = registrar::get_record_expired_at(&suins, SUI_REGISTRAR, FIRST_LABEL);
            assert!(expired_at == EXTRA_PERIOD_END_AT + 1 + 730, 0);

            let (owner, target_address) = registry::get_name_record_all_fields(&suins, utf8(FIRST_DOMAIN_NAME));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(target_address == std::option::some(FIRST_USER_ADDRESS), 0);

            coin::burn_for_testing(coin);
            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = promotion::ENotExists)]
    fun test_register_with_config_and_code_if_use_wrong_referral_code() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 3, &mut ctx);

            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);
            controller::register_with_code(
                &mut suins,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                2,
                &mut coin,
                DISCOUNT_CODE,
                DISCOUNT_CODE,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = promotion::ENotExists)]
    fun test_register_with_config_and_code_if_use_wrong_discount_code() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 3, &mut ctx);

            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);
            controller::register_with_code(
                &mut suins,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                2,
                &mut coin,
                REFERRAL_CODE,
                REFERRAL_CODE,
                &clock,
                &mut ctx,
            );
            coin::burn_for_testing(coin);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::EAuctionNotEndYet)]
    fun test_register_abort_if_register_short_domain_while_auction_not_start_yet() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                21,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            controller::register(
                &mut suins,
                utf8(AUCTIONED_LABEL),
                FIRST_USER_ADDRESS,
                2,
                &mut coin,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::EAuctionNotEndYet)]
    fun test_register_aborts_if_register_long_domain_while_auction_not_started_yet() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                21,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, &mut ctx);

            controller::register(
                &mut suins,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                1,
                &mut coin,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);

            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);

            assert!(suins::balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, 0);
            assert!(name == utf8(FIRST_DOMAIN_NAME), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );

            let expired_at = registrar::get_record_expired_at(&suins, SUI_REGISTRAR, FIRST_LABEL);
            assert!(expired_at == 21 + 365, 0);

            let (owner, target_address) = registry::get_name_record_all_fields(&suins, utf8(FIRST_DOMAIN_NAME));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(target_address == std::option::some(FIRST_USER_ADDRESS), 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::EAuctionNotEndYet)]
    fun test_register_abort_if_register_short_domain_while_auction_is_happening() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                71,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            controller::register(
                &mut suins,
                utf8(AUCTIONED_LABEL),
                FIRST_USER_ADDRESS,
                2,
                &mut coin,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::EAuctionNotEndYet)]
    fun test_register_aborts_if_register_long_domain_while_auction_is_happening() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                51,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, &mut ctx);

            controller::register(
                &mut suins,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                1,
                &mut coin,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);

            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);

            assert!(suins::balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, 0);
            assert!(name == utf8(FIRST_DOMAIN_NAME), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );

            let expired_at = registrar::get_record_expired_at(&suins, SUI_REGISTRAR, FIRST_LABEL);
            assert!(expired_at == 51 + 365, 0);

            let (owner, target_address) = registry::get_name_record_all_fields(&suins, utf8(FIRST_DOMAIN_NAME));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(target_address == std::option::some(FIRST_USER_ADDRESS), 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_work_for_long_domain_if_auction_is_over() {
        let scenario = test_init();
        set_auction_config(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                221,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, &mut ctx);

            controller::register(
                &mut suins,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                1,
                &mut coin,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);

            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);

            assert!(suins::balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, 0);
            assert!(name == utf8(FIRST_DOMAIN_NAME), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );

            let expired_at = registrar::get_record_expired_at(&suins, SUI_REGISTRAR, FIRST_LABEL);
            assert!(expired_at == 221 + 365, 0);

            let (owner, target_address) = registry::get_name_record_all_fields(&suins, utf8(FIRST_DOMAIN_NAME));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(target_address == std::option::some(FIRST_USER_ADDRESS), 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_work_for_short_domain_if_auction_is_over() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                221,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, &mut ctx);

            controller::register(
                &mut suins,
                utf8(AUCTIONED_LABEL),
                FIRST_USER_ADDRESS,
                1,
                &mut coin,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);

            assert!(suins::balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, 0);
            assert!(name == utf8(AUCTIONED_DOMAIN_NAME), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );

            let expired_at = registrar::get_record_expired_at(&suins, SUI_REGISTRAR, AUCTIONED_LABEL);
            assert!(expired_at == 221 + 365, 0);

            let (owner, target_address) = registry::get_name_record_all_fields(&suins, utf8(AUCTIONED_DOMAIN_NAME));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(target_address == std::option::some(FIRST_USER_ADDRESS), 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::ERegistrationIsDisabled)]
    fun test_register_abort_if_registration_is_disabled() {
        let scenario = test_init();
        set_auction_config(&mut scenario);

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = suins::remove_config<Config>(&admin_cap, &mut suins);

            config::set_enable_controller(&mut config, false);
            suins::add_config(&admin_cap, &mut suins, config);

            test_scenario::return_to_sender(&mut scenario, admin_cap);
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                221,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            controller::register(
                &mut suins,
                utf8(AUCTIONED_LABEL),
                FIRST_USER_ADDRESS,
                1,
                &mut coin,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);

            assert!(suins::balance(&suins) == 1000000, 0);
            assert!(name == utf8(AUCTIONED_DOMAIN_NAME), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );

            let expired_at = registrar::get_record_expired_at(&suins, SUI_REGISTRAR, FIRST_LABEL);
            assert!(expired_at == 221 + 365, 0);

            let (owner, target_address) = registry::get_name_record_all_fields(&suins, utf8(AUCTIONED_DOMAIN_NAME));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(target_address == std::option::none(), 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::ERegistrationIsDisabled)]
    fun test_register_abort_if_registration_is_disabled_2() {
        let scenario = test_init();
        set_auction_config(&mut scenario);

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = suins::remove_config<Config>(&admin_cap, &mut suins);


            config::set_enable_controller(&mut config, false);
            suins::add_config(&admin_cap, &mut suins, config);

            test_scenario::return_to_sender(&mut scenario, admin_cap);
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                221,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            controller::register(
                &mut suins,
                utf8(AUCTIONED_LABEL),
                FIRST_USER_ADDRESS,
                1,
                &mut coin,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);

            assert!(suins::balance(&suins) == 1000000, 0);
            assert!(name == utf8(AUCTIONED_DOMAIN_NAME), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b""),
                0
            );

            let expired_at = registrar::get_record_expired_at(&suins, SUI_REGISTRAR, FIRST_DOMAIN_NAME);
            assert!(expired_at == 221 + 365, 0);

            let (owner, target_address) = registry::get_name_record_all_fields(&suins, utf8(AUCTIONED_DOMAIN_NAME));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(target_address == std::option::none(), 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_works_if_registration_is_reenabled() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = suins::remove_config<Config>(&admin_cap, &mut suins);

            config::set_enable_controller(&mut config, false);

            suins::add_config(&admin_cap, &mut suins, config);
            test_scenario::return_shared(suins);
            test_scenario::return_to_sender(&mut scenario, admin_cap);
        };
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);

            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = suins::remove_config<Config>(&admin_cap, &mut suins);
            config::set_enable_controller(&mut config, true);

            suins::add_config(&admin_cap, &mut suins, config);
            test_scenario::return_shared(suins);
            test_scenario::return_to_sender(&mut scenario, admin_cap);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                221,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, &mut ctx);

            controller::register(
                &mut suins,
                utf8(AUCTIONED_LABEL),
                FIRST_USER_ADDRESS,
                1,
                &mut coin,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);

            assert!(suins::balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, 0);
            assert!(name == utf8(AUCTIONED_DOMAIN_NAME), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );

            let expired_at = registrar::get_record_expired_at(&suins, SUI_REGISTRAR, AUCTIONED_LABEL);
            assert!(expired_at == 221 + 365, 0);

            let (owner, target_address) = registry::get_name_record_all_fields(&suins, utf8(AUCTIONED_DOMAIN_NAME));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(target_address == std::option::some(FIRST_USER_ADDRESS), 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_renew_with_image() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        register(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            assert!(suins::balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, 0);
            assert!(name == utf8(b"eastagile-123.sui"), 0);
            assert!(url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"), 0);

            test_scenario::return_shared(suins);
            test_scenario::return_to_sender(&mut scenario, nft);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 2 + 1, ctx);

            assert!(registrar::name_expires_at(&suins, utf8(SUI_REGISTRAR), utf8(FIRST_LABEL)) == 522, 0);
            assert!(suins::balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, 0);
            controller::renew_with_image(
                &mut suins,
                utf8(FIRST_LABEL),
                2,
                &mut coin,
                &mut nft,
                x"9fadcda7144b6f0f56cf48338d1ea8d63135bab9e528bb77aae32db9727e51a402436f33733c43ae254c66d17b9814331d59b6eab749409f5a964261b534c099",
                x"b6b240d5417941ee88363f2d792d85b8d4a7cb5778c1a37d62d62354e838f9e4",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,eastagile-123.sui,1252,everywhere",
                ctx,
            );
            assert!(coin::value(&coin) == 1, 0);
            assert!(registrar::name_expires_at(&suins, utf8(SUI_REGISTRAR), utf8(FIRST_LABEL)) == 1252, 0);

            coin::burn_for_testing(coin);
            test_scenario::return_shared(suins);
            test_scenario::return_to_sender(&mut scenario, nft);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            assert!(suins::balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 3, 0);
            assert!(name == utf8(b"eastagile-123.sui"), 0);
            assert!(url == url::new_unsafe_from_bytes(b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k"), 0);

            test_scenario::return_shared(suins);
            test_scenario::return_to_sender(&mut scenario, nft);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registrar::EInvalidImageMessage)]
    fun test_renew_with_image_aborts_with_empty_signature() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        register(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 2, ctx);

            controller::renew_with_image(
                &mut suins,
                utf8(FIRST_LABEL),
                2,
                &mut coin,
                &mut nft,
                x"",
                x"8ae97b7af21e857a343b93f0ca8a132819aa4edd4bedcee3e3a37d8f9bb89821",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,eastagile-123.sui,1146",
                ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(suins);
            test_scenario::return_to_sender(&mut scenario, nft);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registrar::EInvalidImageMessage)]
    fun test_renew_with_image_aborts_with_empty_hashed_msg() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        register(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 2, ctx);

            controller::renew_with_image(
                &mut suins,
                utf8(FIRST_LABEL),
                2,
                &mut coin,
                &mut nft,
                x"a8ae97b7af21e87a343b93f0ca8a132819aa4edd4bedcee3e3a37d8f9bb89821",
                x"",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,eastagile-123.sui,1252",
                ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(suins);
            test_scenario::return_to_sender(&mut scenario, nft);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registrar::EInvalidImageMessage)]
    fun test_renew_with_image_aborts_with_empty_raw_msg() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        register(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 2, ctx);

            controller::renew_with_image(
                &mut suins,
                utf8(FIRST_LABEL),
                2,
                &mut coin,
                &mut nft,
                x"a8ae97b7af21e85a343b93f0ca8a132819aa4edd4bedcee3e3a37d8f9bb89821",
                x"a8ae97b7af21857a343b93f0ca8a132819aa4edd4bedcee3e3a37d8f9bb89821",
                b"",
                ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(suins);
            test_scenario::return_to_sender(&mut scenario, nft);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registrar::ELabelExpired)]
    fun test_renew_with_image_aborts_if_being_called_too_late() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        register(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&scenario);
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                DEFAULT_TX_HASH,
                522 + GRACE_PERIOD + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 2, &mut ctx);

            assert!(registrar::name_expires_at(&suins, utf8(SUI_REGISTRAR), utf8(FIRST_LABEL)) == 522, 0);
            controller::renew_with_image(
                &mut suins,
                utf8(FIRST_LABEL),
                2,
                &mut coin,
                &mut nft,
                x"441b360b920f87e1a35cd5a41618b35aac5718b0086eaa7073d06a50f982aeb035414cae99bfee52524de9c9904ee15f2e67baab5274d4b1775b2bcd684254cb",
                x"f9495c8390e0eac1c7046aeab762f715100bd483826c15670804c616e66b8e21",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,eastagile-123.sui,1252,12",
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(suins);
            test_scenario::return_to_sender(&mut scenario, nft);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_renew_with_image_works_if_being_called_in_grace_time() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        register(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            assert!(suins::balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, 0);
            assert!(name == utf8(b"eastagile-123.sui"), 0);
            assert!(url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"), 0);

            test_scenario::return_shared(suins);
            test_scenario::return_to_sender(&mut scenario, nft);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&scenario);
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                DEFAULT_TX_HASH,
                450,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 2 + 1, &mut ctx);

            assert!(registrar::name_expires_at(&suins, utf8(SUI_REGISTRAR), utf8(FIRST_LABEL)) == EXTRA_PERIOD_END_AT + 1 + 365, 0);
            assert!(suins::balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, 0);

            controller::renew_with_image(
                &mut suins,
                utf8(FIRST_LABEL),
                2,
                &mut coin,
                &mut nft,
                x"06d7f8f36614b8692040f449b9b24fcfee9b25afab03e330a0482720288eeb182865d9ec9e2c1da0fef215b15d8e621f9ca2ac3722f74a92d1e2e58bf9e937fc",
                x"6ade03578ba11ed7bc483a529a2a38f205e9b38d22fef9bc36c1e7dedce78cc0",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,eastagile-123.sui,1252,abc",
                &mut ctx,
            );

            assert!(coin::value(&coin) == 1, 0);
            assert!(registrar::name_expires_at(&suins, utf8(SUI_REGISTRAR), utf8(FIRST_LABEL)) == 1252, 0);

            coin::burn_for_testing(coin);
            test_scenario::return_shared(suins);
            test_scenario::return_to_sender(&mut scenario, nft);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            assert!(suins::balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 3, 0);
            assert!(name == utf8(b"eastagile-123.sui"), 0);
            assert!(url == url::new_unsafe_from_bytes(b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k"), 0);

            test_scenario::return_shared(suins);
            test_scenario::return_to_sender(&mut scenario, nft);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_new_reserved_domains() {
        let scenario = test_init();
        let first_domain_name = b"abcde";
        let first_domain_name_sui = b"abcde.sui";
        let first_domain_name_move = b"abcde.move";
        let second_domain_name = b"abcdefghijk";
        let second_domain_name_sui = b"abcdefghijk.sui";
        let second_domain_name_move = b"abcdefghijk.move";

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let ctx = &mut ctx_new(
                SUINS_ADDRESS,
                DEFAULT_TX_HASH,
                50,
                2
            );

            assert!(registrar::is_available(&suins, utf8(SUI_REGISTRAR), utf8(first_domain_name), ctx), 0);
            assert!(registrar::is_available(&suins, utf8(MOVE_REGISTRAR), utf8(first_domain_name), ctx), 0);
            assert!(registrar::is_available(&suins, utf8(SUI_REGISTRAR), utf8(second_domain_name), ctx), 0);
            assert!(registrar::is_available(&suins, utf8(MOVE_REGISTRAR), utf8(second_domain_name), ctx), 0);

            assert!(!suins::has_name_record(&suins, utf8(first_domain_name_sui)), 0);
            assert!(!suins::has_name_record(&suins, utf8(first_domain_name_move)), 0);
            assert!(!suins::has_name_record(&suins, utf8(second_domain_name_sui)), 0);
            assert!(!suins::has_name_record(&suins, utf8(second_domain_name_move)), 0);

            controller::new_reserved_domains(
                &admin_cap,
                &mut suins,
                vector[utf8(b"abcde.sui"), utf8(b"abcde.move"), utf8(b"abcdefghijk.sui")],
                @0x0,
                ctx
            );

            test_scenario::return_shared(suins);
            test_scenario::return_to_sender(&mut scenario, admin_cap);
        };
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let ctx = &mut ctx_new(
                SUINS_ADDRESS,
                DEFAULT_TX_HASH,
                50,
                10
            );

            assert!(!registrar::is_available(&suins, utf8(SUI_REGISTRAR), utf8(first_domain_name), ctx), 0);
            assert!(!registrar::is_available(&suins, utf8(MOVE_REGISTRAR), utf8(first_domain_name), ctx), 0);
            assert!(!registrar::is_available(&suins, utf8(SUI_REGISTRAR), utf8(second_domain_name), ctx), 0);
            assert!(registrar::is_available(&suins, utf8(MOVE_REGISTRAR), utf8(second_domain_name), ctx), 0);

            let expired_at = registrar::get_record_expired_at(&suins, SUI_REGISTRAR, first_domain_name);
            assert!(expired_at == 415, 0);
            let expired_at = registrar::get_record_expired_at(&suins, MOVE_REGISTRAR, first_domain_name);
            assert!(expired_at == 415, 0);
            let expired_at = registrar::get_record_expired_at(&suins, SUI_REGISTRAR, second_domain_name);
            assert!(expired_at == 415, 0);

            assert!(suins::has_name_record(&suins, utf8(first_domain_name_sui)), 0);
            assert!(suins::has_name_record(&suins, utf8(first_domain_name_move)), 0);
            assert!(suins::has_name_record(&suins, utf8(second_domain_name_sui)), 0);
            assert!(!suins::has_name_record(&suins, utf8(second_domain_name_move)), 0);

            let (owner, target_address) = registry::get_name_record_all_fields(&suins, utf8(first_domain_name_sui));
            assert!(owner == SUINS_ADDRESS, 0);
            assert!(target_address == std::option::some(SUINS_ADDRESS), 0);
            let (owner, target_address) = registry::get_name_record_all_fields(&suins, utf8(first_domain_name_move));
            assert!(owner == SUINS_ADDRESS, 0);
            assert!(target_address == std::option::some(SUINS_ADDRESS), 0);
            let (owner, target_address) = registry::get_name_record_all_fields(&suins, utf8(second_domain_name_sui));
            assert!(owner == SUINS_ADDRESS, 0);
            assert!(target_address == std::option::some(SUINS_ADDRESS), 0);

            let first_nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&first_nft);
            assert!(name == utf8(second_domain_name_sui), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );
            let second_nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&second_nft);
            assert!(name == utf8(first_domain_name_move), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );
            let third_nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&third_nft);
            assert!(name == utf8(first_domain_name_sui), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );

            test_scenario::return_to_sender(&mut scenario, third_nft);
            test_scenario::return_to_sender(&mut scenario, second_nft);
            test_scenario::return_to_sender(&mut scenario, first_nft);
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let ctx = &mut ctx_new(
                SUINS_ADDRESS,
                DEFAULT_TX_HASH,
                52,
                20
            );

            assert!(registrar::is_available(&suins, utf8(MOVE_REGISTRAR), utf8(second_domain_name), ctx), 0);
            assert!(!suins::has_name_record(&suins, utf8(second_domain_name_move)), 0);

            controller::new_reserved_domains(&admin_cap, &mut suins, vector[utf8(b"abcdefghijk.move")], @0x0B, ctx);

            test_scenario::return_shared(suins);
            test_scenario::return_to_sender(&mut scenario, admin_cap);
        };
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let ctx = &mut ctx_new(
                SUINS_ADDRESS,
                DEFAULT_TX_HASH,
                50,
                30
            );

            assert!(!registrar::is_available(&suins, utf8(SUI_REGISTRAR), utf8(first_domain_name), ctx), 0);
            assert!(!registrar::is_available(&suins, utf8(MOVE_REGISTRAR), utf8(first_domain_name), ctx), 0);
            assert!(!registrar::is_available(&suins, utf8(SUI_REGISTRAR), utf8(second_domain_name), ctx), 0);
            assert!(!registrar::is_available(&suins, utf8(MOVE_REGISTRAR), utf8(second_domain_name), ctx), 0);

            let expired_at = registrar::get_record_expired_at(&suins, SUI_REGISTRAR, first_domain_name);
            assert!(expired_at == 415, 0);
            let expired_at = registrar::get_record_expired_at(&suins, MOVE_REGISTRAR, first_domain_name);
            assert!(expired_at == 415, 0);
            let expired_at = registrar::get_record_expired_at(&suins, SUI_REGISTRAR, second_domain_name);
            assert!(expired_at == 415, 0);
            let expired_at = registrar::get_record_expired_at(&suins, MOVE_REGISTRAR, second_domain_name);
            assert!(expired_at == 417, 0);

            assert!(suins::has_name_record(&suins, utf8(first_domain_name_sui)), 0);
            assert!(suins::has_name_record(&suins, utf8(first_domain_name_move)), 0);
            assert!(suins::has_name_record(&suins, utf8(second_domain_name_sui)), 0);
            assert!(suins::has_name_record(&suins, utf8(second_domain_name_move)), 0);

            let (owner, target_address) = registry::get_name_record_all_fields(&suins, utf8(first_domain_name_sui));
            assert!(owner == SUINS_ADDRESS, 0);
            assert!(target_address == std::option::some(SUINS_ADDRESS), 0);
            let (owner, target_address) = registry::get_name_record_all_fields(&suins, utf8(first_domain_name_move));
            assert!(owner == SUINS_ADDRESS, 0);
            assert!(target_address == std::option::some(SUINS_ADDRESS), 0);
            let (owner, target_address) = registry::get_name_record_all_fields(&suins, utf8(second_domain_name_sui));
            assert!(owner == SUINS_ADDRESS, 0);
            assert!(target_address == std::option::some(SUINS_ADDRESS), 0);
            let (owner, target_address) = registry::get_name_record_all_fields(&suins, utf8(second_domain_name_move));
            assert!(owner == @0x0B, 0);
            assert!(target_address == std::option::some(@0x0B), 0);

            let first_nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&first_nft);
            assert!(name == utf8(second_domain_name_sui), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );
            let second_nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&second_nft);
            assert!(name == utf8(first_domain_name_move), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );
            let third_nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&third_nft);
            assert!(name == utf8(first_domain_name_sui), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );

            test_scenario::return_to_sender(&mut scenario, first_nft);
            test_scenario::return_to_sender(&mut scenario, second_nft);
            test_scenario::return_to_sender(&mut scenario, third_nft);
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, @0x0B);
        {
            let first_nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&first_nft);
            assert!(name == utf8(second_domain_name_move), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );
            test_scenario::return_to_sender(&mut scenario, first_nft);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registrar::ELabelUnavailable)]
    fun test_new_reserved_domains_aborts_with_dupdated_domain_names() {
        let scenario = test_init();
        let first_domain_name = b"abcde";
        let first_domain_name_sui = b"abcde.sui";

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let ctx = &mut ctx_new(
                SUINS_ADDRESS,
                DEFAULT_TX_HASH,
                50,
                2
            );

            assert!(registrar::is_available(&suins, utf8(SUI_REGISTRAR), utf8(first_domain_name), ctx), 0);
            assert!(!suins::has_name_record(&suins, utf8(first_domain_name_sui)), 0);

            controller::new_reserved_domains(&admin_cap, &mut suins, vector[utf8(b"abcde.sui"), utf8(b"abcde.sui")], @0x0, ctx);

            test_scenario::return_shared(suins);
            test_scenario::return_to_sender(&mut scenario, admin_cap);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = dynamic_field::EFieldDoesNotExist)]
    fun test_new_reserved_domains_aborts_with_malformed_domains() {
        let scenario = test_init();

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let ctx = &mut ctx_new(
                SUINS_ADDRESS,
                DEFAULT_TX_HASH,
                50,
                2
            );

            controller::new_reserved_domains(&admin_cap, &mut suins, vector[utf8(b"abcde..sui")], @0x0, ctx);

            test_scenario::return_shared(suins);
            test_scenario::return_to_sender(&mut scenario, admin_cap);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = dynamic_field::EFieldDoesNotExist)]
    fun test_new_reserved_domains_aborts_with_non_existence_tld() {
        let scenario = test_init();

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let ctx = &mut ctx_new(
                SUINS_ADDRESS,
                DEFAULT_TX_HASH,
                50,
                2
            );

            controller::new_reserved_domains(&admin_cap, &mut suins, vector[utf8(b"abcde.suins")], @0x0, ctx);

            test_scenario::return_shared(suins);
            test_scenario::return_to_sender(&mut scenario, admin_cap);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = string_utils::EInvalidLabel)]
    fun test_new_reserved_domains_aborts_with_leading_dash_character() {
        let scenario = test_init();

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let ctx = &mut ctx_new(
                SUINS_ADDRESS,
                DEFAULT_TX_HASH,
                50,
                2
            );

            controller::new_reserved_domains(&admin_cap, &mut suins, vector[utf8(b"-abcde.sui")], @0x0, ctx);

            test_scenario::return_shared(suins);
            test_scenario::return_to_sender(&mut scenario, admin_cap);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = string_utils::EInvalidLabel)]
    fun test_new_reserved_domains_aborts_with_trailing_dash_character() {
        let scenario = test_init();

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let ctx = &mut ctx_new(
                SUINS_ADDRESS,
                DEFAULT_TX_HASH,
                50,
                2
            );

            controller::new_reserved_domains(&admin_cap, &mut suins, vector[utf8(b"abcde-.move")], @0x0, ctx);

            test_scenario::return_shared(suins);
            test_scenario::return_to_sender(&mut scenario, admin_cap);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = string_utils::EInvalidLabel)]
    fun test_new_reserved_domains_aborts_with_invalid_emoji() {
        let scenario = test_init();
        let invalid_emoji_domain_name = vector[241, 159, 152, 135, 119, 109, 109, 49, 240, 159, 145, 180, 46, 115, 117, 105];

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let ctx = &mut ctx_new(
                SUINS_ADDRESS,
                DEFAULT_TX_HASH,
                50,
                2
            );

            controller::new_reserved_domains(&admin_cap, &mut suins, vector[utf8(invalid_emoji_domain_name)], @0x0, ctx);

            test_scenario::return_shared(suins);
            test_scenario::return_to_sender(&mut scenario, admin_cap);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::ELabelUnavailable)]
    fun test_register_aborts_if_sui_name_is_reserved() {
        let scenario = test_init();
        let first_domain_name = b"abcde";
        set_auction_config(&mut scenario);
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let ctx = &mut ctx_new(
                SUINS_ADDRESS,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                2
            );

            controller::new_reserved_domains(&admin_cap, &mut suins, vector[utf8(b"abcde.sui")], SUINS_ADDRESS, ctx);

            test_scenario::return_shared(suins);
            test_scenario::return_to_sender(&mut scenario, admin_cap);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 2,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            controller::register(
                &mut suins,
                utf8(first_domain_name),
                FIRST_USER_ADDRESS,
                2,
                &mut coin,
                &clock,
                &mut ctx,
            );
            coin::burn_for_testing(coin);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_works() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 2, &mut ctx);

            assert!(!test_scenario::has_most_recent_for_sender<RegistrationNFT>(&mut scenario), 0);
            controller::register(
                &mut suins,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                2,
                &mut coin,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            assert!(test_scenario::has_most_recent_for_sender<RegistrationNFT>(&mut scenario), 0);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            let registrar = registrar::get_registrar(&suins, SUI_REGISTRAR);
            registrar::assert_nft_not_expires(
                registrar,
                &nft,
                test_scenario::ctx(&mut scenario)
            );

            test_scenario::return_shared(suins);
            test_scenario::return_to_sender(&mut scenario, nft);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_works_2() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 2, &mut ctx);

            assert!(!test_scenario::has_most_recent_for_sender<RegistrationNFT>(&mut scenario), 0);
            controller::register(
                &mut suins,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                2,
                &mut coin,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            assert!(test_scenario::has_most_recent_for_sender<RegistrationNFT>(&mut scenario), 0);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            let registrar = registrar::get_registrar(&suins, SUI_REGISTRAR);
            registrar::assert_nft_not_expires(
                registrar,
                &nft,
                test_scenario::ctx(&mut scenario)
            );

            test_scenario::return_shared(suins);
            test_scenario::return_to_sender(&mut scenario, nft);
        };
        test_scenario::end(scenario);
    }
    
    #[test, expected_failure(abort_code = controller::EInvalidNoYears)]
    fun test_register_aborts_if_more_than_5_years() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 2, &mut ctx);

            assert!(!test_scenario::has_most_recent_for_sender<RegistrationNFT>(&mut scenario), 0);
            controller::register(
                &mut suins,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                6,
                &mut coin,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::EInvalidNoYears)]
    fun test_renew_aborts_if_more_than_5_years() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        register(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 7 + 1, ctx);

            controller::renew(
                &mut suins,
                utf8(FIRST_LABEL),
                6,
                &mut coin,
                ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registrar::EInvalidNewExpiredAt)]
    fun test_renew_aborts_if_more_than_5_years_2() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        register(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 7 + 1, ctx);

            controller::renew(
                &mut suins,
                utf8(FIRST_LABEL),
                5,
                &mut coin,
                ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(suins);
		};
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = string_utils::EInvalidLabel)]
    fun test_register_aborts_if_domain_length_has_less_than_3_characters() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 3, &mut ctx);

            controller::register(
                &mut suins,
                utf8(b"ab"),
                FIRST_USER_ADDRESS,
                2,
                &mut coin,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_of_domain_name_with_3_characters() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_THREE_CHARACTER_DOMAIN * 3, &mut ctx);

            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);
            assert!(suins::balance(&suins) == 0, 0);
            assert!(!suins::has_name_record(&suins, utf8(FIRST_DOMAIN_NAME)), 0);
            assert!(!test_scenario::has_most_recent_for_sender<RegistrationNFT>(&mut scenario), 0);

            controller::register(
                &mut suins,
                utf8(b"abc"),
                FIRST_USER_ADDRESS,
                2,
                &mut coin,
                &clock,
                &mut ctx,
            );
            assert!(coin::value(&coin) == PRICE_OF_THREE_CHARACTER_DOMAIN, 0);

            coin::burn_for_testing(coin);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);

            assert!(suins::balance(&suins) == PRICE_OF_THREE_CHARACTER_DOMAIN * 2, 0);
            assert!(name == utf8(b"abc.sui"), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );

            let expired_at = registrar::get_record_expired_at(&suins, SUI_REGISTRAR, b"abc");
            assert!(expired_at == EXTRA_PERIOD_END_AT + 1 + 730, 0);

            let (owner, target_address) = registry::get_name_record_all_fields(&suins, utf8(b"abc.sui"));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(target_address == std::option::some(FIRST_USER_ADDRESS), 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_of_domain_name_with_4_characters() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FOUR_CHARACTER_DOMAIN * 3, &mut ctx);

            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);
            assert!(suins::balance(&suins) == 0, 0);
            assert!(!suins::has_name_record(&suins, utf8(FIRST_DOMAIN_NAME)), 0);
            assert!(!test_scenario::has_most_recent_for_sender<RegistrationNFT>(&mut scenario), 0);

            controller::register(
                &mut suins,
                utf8(b"abcd"),
                FIRST_USER_ADDRESS,
                2,
                &mut coin,
                &clock,
                &mut ctx,
            );
            assert!(coin::value(&coin) == PRICE_OF_FOUR_CHARACTER_DOMAIN, 0);

            coin::burn_for_testing(coin);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);

            assert!(suins::balance(&suins) == PRICE_OF_FOUR_CHARACTER_DOMAIN * 2, 0);
            assert!(name == utf8(b"abcd.sui"), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );

            let expired_at = registrar::get_record_expired_at(&suins, SUI_REGISTRAR, b"abcd");
            assert!(expired_at == EXTRA_PERIOD_END_AT + 1 + 730, 0);

            let (owner, target_address) = registry::get_name_record_all_fields(&suins, utf8(b"abcd.sui"));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(target_address == std::option::some(FIRST_USER_ADDRESS), 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_of_domain_name_with_6_characters() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 3, &mut ctx);

            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);
            assert!(suins::balance(&suins) == 0, 0);
            assert!(!suins::has_name_record(&suins, utf8(FIRST_DOMAIN_NAME)), 0);
            assert!(!test_scenario::has_most_recent_for_sender<RegistrationNFT>(&mut scenario), 0);

            controller::register(
                &mut suins,
                utf8(b"abcdef"),
                FIRST_USER_ADDRESS,
                2,
                &mut coin,
                &clock,
                &mut ctx,
            );
            assert!(coin::value(&coin) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, 0);

            coin::burn_for_testing(coin);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);

            assert!(suins::balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 2, 0);
            assert!(name == utf8(b"abcdef.sui"), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );

            let expired_at = registrar::get_record_expired_at(&suins, SUI_REGISTRAR, b"abcdef");
            assert!(expired_at == EXTRA_PERIOD_END_AT + 1 + 730, 0);

            let (owner, target_address) = registry::get_name_record_all_fields(&suins, utf8(b"abcdef.sui"));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(target_address == std::option::some(FIRST_USER_ADDRESS), 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_set_price_to_register_three_character_domain() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = suins::remove_config<Config>(&admin_cap, &mut suins);

            config::set_three_char_price(&mut config, 1_000_000_000);

            suins::add_config(&admin_cap, &mut suins, config);
            test_scenario::return_to_sender(&mut scenario, admin_cap);
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_THREE_CHARACTER_DOMAIN * 3, &mut ctx);

            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);
            assert!(suins::balance(&suins) == 0, 0);
            assert!(!suins::has_name_record(&suins, utf8(FIRST_DOMAIN_NAME)), 0);
            assert!(!test_scenario::has_most_recent_for_sender<RegistrationNFT>(&mut scenario), 0);

            controller::register(
                &mut suins,
                utf8(b"xyz"),
                FIRST_USER_ADDRESS,
                2,
                &mut coin,
                &clock,
                &mut ctx,
            );
            assert!(coin::value(&coin) == PRICE_OF_THREE_CHARACTER_DOMAIN * 3 - 1_000_000_000 * 2, 0);

            coin::burn_for_testing(coin);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);

            assert!(suins::balance(&suins) == 1_000_000_000 * 2, 0);
            assert!(name == utf8(b"xyz.sui"), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );

            let expired_at = registrar::get_record_expired_at(&suins, SUI_REGISTRAR, b"xyz");
            assert!(expired_at == EXTRA_PERIOD_END_AT + 1 + 730, 0);

            let (owner, target_address) = registry::get_name_record_all_fields(&suins, utf8(b"xyz.sui"));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(target_address == std::option::some(FIRST_USER_ADDRESS), 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = config::EInvalidPrice)]
    fun test_set_price_to_register_three_character_domain_aborts_if_new_price_too_low() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = suins::remove_config<Config>(&admin_cap, &mut suins);

            config::set_three_char_price(&mut config, 1_000_000_000 - 1);

            suins::add_config(&admin_cap, &mut suins, config);
            test_scenario::return_to_sender(&mut scenario, admin_cap);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = config::EInvalidPrice)]
    fun test_set_price_to_register_three_character_domain_aborts_if_new_price_too_high() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = suins::remove_config<Config>(&admin_cap, &mut suins);

            config::set_three_char_price(&mut config, 1_000_000 * 1_000_000_000 + 1);

            suins::add_config(&admin_cap, &mut suins, config);
            test_scenario::return_to_sender(&mut scenario, admin_cap);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_set_price_to_register_four_character_domain() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = suins::remove_config<Config>(&admin_cap, &mut suins);

            config::set_fouch_char_price(&mut config, 1_000_000_000);

            suins::add_config(&admin_cap, &mut suins, config);
            test_scenario::return_to_sender(&mut scenario, admin_cap);
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FOUR_CHARACTER_DOMAIN * 3, &mut ctx);

            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);
            assert!(suins::balance(&suins) == 0, 0);
            assert!(!suins::has_name_record(&suins, utf8(FIRST_DOMAIN_NAME)), 0);
            assert!(!test_scenario::has_most_recent_for_sender<RegistrationNFT>(&mut scenario), 0);

            controller::register(
                &mut suins,
                utf8(b"xyzt"),
                FIRST_USER_ADDRESS,
                2,
                &mut coin,
                &clock,
                &mut ctx,
            );
            assert!(coin::value(&coin) == PRICE_OF_FOUR_CHARACTER_DOMAIN * 3 - 1_000_000_000 * 2, 0);

            coin::burn_for_testing(coin);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);

            assert!(suins::balance(&suins) == 1_000_000_000 * 2, 0);
            assert!(name == utf8(b"xyzt.sui"), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );

            let expired_at = registrar::get_record_expired_at(&suins, SUI_REGISTRAR, b"xyzt");
            assert!(expired_at == EXTRA_PERIOD_END_AT + 1 + 730, 0);

            let (owner, target_address) = registry::get_name_record_all_fields(&suins, utf8(b"xyzt.sui"));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(target_address == std::option::some(FIRST_USER_ADDRESS), 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = config::EInvalidPrice)]
    fun test_set_price_to_register_four_character_domain_aborts_if_new_price_too_low() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = suins::remove_config<Config>(&admin_cap, &mut suins);

            config::set_fouch_char_price(&mut config, 1_000_000_000 - 1);

            suins::add_config(&admin_cap, &mut suins, config);
            test_scenario::return_to_sender(&mut scenario, admin_cap);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = config::EInvalidPrice)]
    fun test_set_price_to_register_four_character_domain_aborts_if_new_price_too_high() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = suins::remove_config<Config>(&admin_cap, &mut suins);

            config::set_fouch_char_price(&mut config, 1_000_000 * 1_000_000_000 + 1);

            suins::add_config(&admin_cap, &mut suins, config);
            test_scenario::return_to_sender(&mut scenario, admin_cap);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }
}
