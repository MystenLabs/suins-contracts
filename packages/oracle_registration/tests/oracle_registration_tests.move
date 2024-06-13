// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module oracle_registration::register_tests {
    use std::string::{utf8, String};

    use sui::{
        test_scenario::{Self, Scenario, ctx, begin},
        clock::{Self, Clock},
        coin,
        sui::SUI,
    };

    use oracle_registration::register::{Self, Register, register};
    use suins::constants::{mist_per_sui, grace_period_ms, year_ms};
    use suins::suins::{Self, SuiNS, total_balance, AdminCap};
    use suins::suins_registration::SuinsRegistration;
    use suins::suins_registration;
    use suins::domain;
    use suins::registry;
    use suins::config;
    use suins::auction_tests;
    use suins::auction::{Self, App as AuctionApp};

    use pyth::price_identifier;
    use pyth::price_feed;
    use pyth::price_info::{Self, PriceInfoObject};
    use pyth::price;
    use pyth::i64;

    const SUINS_ADDRESS: address = @0xA001;
    const AUCTIONED_DOMAIN_NAME: vector<u8> = b"tes-t2.sui";
    const DOMAIN_NAME: vector<u8> = b"abc.sui";

    public fun test_init(): Scenario {
        let mut test = begin(SUINS_ADDRESS);
        {
            let mut suins = suins::init_for_testing(test.ctx());
            suins.authorize_app_for_testing<Register>();
            suins.authorize_app_for_testing<AuctionApp>();
            suins.share_for_testing();
            let clock = clock::create_for_testing(test.ctx());
            clock.share_for_testing();
        };
        {
            test.next_tx(SUINS_ADDRESS);
            let admin_cap = test.take_from_sender<AdminCap>();
            let mut suins = test.take_shared<SuiNS>();

            registry::init_for_testing(&admin_cap, &mut suins, test.ctx());

            test_scenario::return_shared(suins);
            test.return_to_sender(admin_cap);
        };
        
        test
    }

    public fun oracle_util(
        desired_price_6_decimals: u64,
        scenario: &mut Scenario
    ): PriceInfoObject {
        let price_identifier = price_identifier::from_byte_vec(x"23d7315113f5b1d3ba7a83604c44b94d79f4fd69af77f804fc7f920a6dc65744");
        let price_i64 = i64::new(desired_price_6_decimals, false); // ie: 1.610000
        let expo_i64 = i64::new(6, true); // 10^-6
        let price = price::new(price_i64, 10000, expo_i64, 0); // confidence is 1 cent
        let ema_price = copy(price);
        let price_feed = price_feed::new(price_identifier, price, ema_price);
        let price_info = price_info::new_price_info(0, 0, price_feed);

        price_info::new_test_price_info_object(price_info, ctx(scenario))
    }

    public fun register_util(
        scenario: &mut Scenario,
        domain_name: String,
        no_years: u8,
        amount: u64,
        price_info: &PriceInfoObject,
        clock_tick: u64
    ): SuinsRegistration {
        scenario.next_tx(SUINS_ADDRESS);
        let mut suins = test_scenario::take_shared<SuiNS>(scenario);
        let payment = coin::mint_for_testing<SUI>(amount, scenario.ctx());
        let mut clock = test_scenario::take_shared<Clock>(scenario);

        clock.increment_for_testing(clock_tick);
        let nft = register(&mut suins, domain_name, no_years, payment, price_info, &clock, scenario.ctx());

        test_scenario::return_shared(clock);
        test_scenario::return_shared(suins);

        nft
    }

    fun deauthorize_app_util(scenario: &mut Scenario) {
        scenario.next_tx(SUINS_ADDRESS);
        let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
        let mut suins = test_scenario::take_shared<SuiNS>(scenario);
        suins::deauthorize_app<Register>(&admin_cap, &mut suins);

        test_scenario::return_shared(suins);
        test_scenario::return_to_sender(scenario, admin_cap);
    }

    public fun assert_balance(scenario: &mut Scenario, amount: u64) {
        scenario.next_tx(SUINS_ADDRESS);
        let auction_house = test_scenario::take_shared<SuiNS>(scenario);
        assert!(total_balance(&auction_house) == amount, 0);
        test_scenario::return_shared(auction_house);
    }

    #[test]
    fun test_register() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        let price_info_object = oracle_util(1000000, scenario); // $1

        let nft = register_util(scenario, utf8(DOMAIN_NAME), 1, 1200 * mist_per_sui(), &price_info_object, 10);
        assert_balance(scenario, 1200 * mist_per_sui());
        assert!(suins_registration::domain(&nft) == domain::new(utf8(DOMAIN_NAME)), 0);
        assert!(suins_registration::expiration_timestamp_ms(&nft) == year_ms() + 10, 0);
        suins_registration::burn_for_testing(nft);

        let nft = register_util(scenario, utf8(b"abcd.sui"), 2, 400 * mist_per_sui(), &price_info_object, 20);
        assert_balance(scenario, 1600 * mist_per_sui());
        assert!(suins_registration::domain(&nft) == domain::new(utf8(b"abcd.sui")), 0);
        assert!(suins_registration::expiration_timestamp_ms(&nft) == 2 * year_ms() + 30, 0);
        suins_registration::burn_for_testing(nft);

        let nft = register_util(scenario, utf8(b"abce-f12.sui"), 3, 150 * mist_per_sui(), &price_info_object, 30);
        assert_balance(scenario, 1750 * mist_per_sui());
        assert!(suins_registration::domain(&nft) == domain::new(utf8(b"abce-f12.sui")), 0);
        assert!(suins_registration::expiration_timestamp_ms(&nft) == 3 * year_ms() + 60, 0);
        suins_registration::burn_for_testing(nft);

        price_info::destroy(price_info_object);
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_register_oracle() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        let price_info_object = oracle_util(5000000, scenario); // $5

        let nft = register_util(scenario, utf8(DOMAIN_NAME), 1, 240 * mist_per_sui(), &price_info_object, 10);
        assert_balance(scenario, 240 * mist_per_sui());
        assert!(suins_registration::domain(&nft) == domain::new(utf8(DOMAIN_NAME)), 0);
        assert!(suins_registration::expiration_timestamp_ms(&nft) == year_ms() + 10, 0);
        suins_registration::burn_for_testing(nft);

        let nft = register_util(scenario, utf8(b"abcd.sui"), 2, 80 * mist_per_sui(), &price_info_object, 20);
        assert_balance(scenario, 320 * mist_per_sui());
        assert!(suins_registration::domain(&nft) == domain::new(utf8(b"abcd.sui")), 0);
        assert!(suins_registration::expiration_timestamp_ms(&nft) == 2 * year_ms() + 30, 0);
        suins_registration::burn_for_testing(nft);

        let nft = register_util(scenario, utf8(b"abce-f12.sui"), 3, 30 * mist_per_sui(), &price_info_object, 30);
        assert_balance(scenario, 350 * mist_per_sui());
        assert!(suins_registration::domain(&nft) == domain::new(utf8(b"abce-f12.sui")), 0);
        assert!(suins_registration::expiration_timestamp_ms(&nft) == 3 * year_ms() + 60, 0);
        suins_registration::burn_for_testing(nft);

        price_info::destroy(price_info_object);
        let price_info_object = oracle_util(500000, scenario); // $0.5

        let nft = register_util(scenario, utf8(b"abce-f123.sui"), 3, 300 * mist_per_sui(), &price_info_object, 30);
        assert_balance(scenario, 650 * mist_per_sui());
        assert!(suins_registration::domain(&nft) == domain::new(utf8(b"abce-f123.sui")), 0);
        assert!(suins_registration::expiration_timestamp_ms(&nft) == 3 * year_ms() + 90, 0);
        suins_registration::burn_for_testing(nft);

        price_info::destroy(price_info_object);
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = config::EInvalidTld)]
    fun test_register_if_not_sui_tld() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        let price_info_object = oracle_util(1000000, scenario);

        let nft = register_util(scenario, utf8(b"abc.move"), 1, 1200 * mist_per_sui(), &price_info_object, 10);
        suins_registration::burn_for_testing(nft);

        price_info::destroy(price_info_object);
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = register::EIncorrectAmount)]
    fun test_register_if_incorrect_amount() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        let price_info_object = oracle_util(1000000, scenario);

        let nft = register_util(scenario, utf8(DOMAIN_NAME), 1, 1220 * mist_per_sui(), &price_info_object, 10);
        suins_registration::burn_for_testing(nft);

        price_info::destroy(price_info_object);
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = register::EIncorrectAmount)]
    fun test_register_if_incorrect_amount_2() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        let price_info_object = oracle_util(1000000, scenario);

        let nft = register_util(scenario, utf8(DOMAIN_NAME), 1, 90 * mist_per_sui(), &price_info_object, 10);
        suins_registration::burn_for_testing(nft);

        price_info::destroy(price_info_object);
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = register::EIncorrectAmount)]
    fun test_register_if_incorrect_amount_with_oracle_too_few() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        let price_info_object = oracle_util(1500000, scenario); // $1.50

        let nft = register_util(scenario, utf8(DOMAIN_NAME), 1, 150 * mist_per_sui(), &price_info_object, 10);
        suins_registration::burn_for_testing(nft);

        price_info::destroy(price_info_object);
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = register::EIncorrectAmount)]
    fun test_register_if_incorrect_amount_with_oracle_too_much() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        let price_info_object = oracle_util(1500000, scenario); // $1.50

        let nft = register_util(scenario, utf8(DOMAIN_NAME), 1, 250 * mist_per_sui(), &price_info_object, 10);
        suins_registration::burn_for_testing(nft);

        price_info::destroy(price_info_object);
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = register::EInvalidYearsArgument)]
    fun test_register_if_no_years_more_than_5_years() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        let price_info_object = oracle_util(1000000, scenario);

        let nft = register_util(scenario, utf8(DOMAIN_NAME), 6, 6 * 1200 * mist_per_sui(), &price_info_object, 10);
        suins_registration::burn_for_testing(nft);

        price_info::destroy(price_info_object);
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = register::EInvalidYearsArgument)]
    fun test_register_if_no_years_is_zero() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        let price_info_object = oracle_util(1000000, scenario);

        let nft = register_util(scenario, utf8(DOMAIN_NAME), 0, 1200 * mist_per_sui(), &price_info_object,  10);
        suins_registration::burn_for_testing(nft);

        price_info::destroy(price_info_object);
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = register::EIncorrectPriceFeedID)]
    fun test_register_incorrect_feed_id() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;

        let price_identifier = price_identifier::from_byte_vec(x"abcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabcd");
        let price_i64 = i64::new(1000000, false); // ie: 1.610000
        let expo_i64 = i64::new(6, true); // 10^-6
        let price = price::new(price_i64, 10000, expo_i64, 0); // confidence is 1 cent
        let ema_price = copy(price);
        let price_feed = price_feed::new(price_identifier, price, ema_price);
        let price_info = price_info::new_price_info(0, 0, price_feed);
        let price_info_object = price_info::new_test_price_info_object(price_info, ctx(scenario));

        let nft = register_util(scenario, utf8(DOMAIN_NAME), 3, 1200 * mist_per_sui(), &price_info_object,  10);
        suins_registration::burn_for_testing(nft);

        price_info::destroy(price_info_object);
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_register_if_expired() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        let price_info_object = oracle_util(1000000, scenario);

        let nft = register_util(scenario, utf8(DOMAIN_NAME), 1, 1200 * mist_per_sui(), &price_info_object,  10);
        assert_balance(scenario, 1200 * mist_per_sui());
        assert!(suins_registration::domain(&nft) == domain::new(utf8(DOMAIN_NAME)), 0);
        assert!(suins_registration::expiration_timestamp_ms(&nft) == year_ms() + 10, 0);
        suins_registration::burn_for_testing(nft);

        let nft = register_util(
            scenario,
            utf8(DOMAIN_NAME),
            1,
            1200 * mist_per_sui(),
            &price_info_object, 
            year_ms() + grace_period_ms() + 20,
        );
        assert_balance(scenario, 2400 * mist_per_sui());
        assert!(suins_registration::domain(&nft) == domain::new(utf8(DOMAIN_NAME)), 0);
        assert!(
            suins_registration::expiration_timestamp_ms(&nft) == 2 * year_ms() + grace_period_ms() + 30,
            0
        );
        suins_registration::burn_for_testing(nft);

        price_info::destroy(price_info_object);
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = registry::ERecordNotExpired)]
    fun test_register_if_not_expired() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        let price_info_object = oracle_util(1000000, scenario);

        let nft = register_util(scenario, utf8(DOMAIN_NAME), 1, 1200 * mist_per_sui(), &price_info_object, 10);
        assert_balance(scenario, 1200 * mist_per_sui());
        assert!(suins_registration::domain(&nft) == domain::new(utf8(DOMAIN_NAME)), 0);
        assert!(suins_registration::expiration_timestamp_ms(&nft) == year_ms() + 10, 0);
        suins_registration::burn_for_testing(nft);

        let nft = register_util(scenario, utf8(DOMAIN_NAME), 1, 1200 * mist_per_sui(), &price_info_object, 20);
        suins_registration::burn_for_testing(nft);

        price_info::destroy(price_info_object);
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = domain::EInvalidDomain)]
    fun test_register_if_domain_name_starts_with_dash() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        let price_info_object = oracle_util(1000000, scenario);

        let nft = register_util(scenario, utf8(b"-ab.sui"), 1, 1200 * mist_per_sui(), &price_info_object, 10);
        suins_registration::burn_for_testing(nft);

        price_info::destroy(price_info_object);
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = domain::EInvalidDomain)]
    fun test_register_if_domain_name_ends_with_dash() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        let price_info_object = oracle_util(1000000, scenario);

        let nft = register_util(scenario, utf8(b"ab-.sui"), 1, 1200 * mist_per_sui(), &price_info_object, 10);
        suins_registration::burn_for_testing(nft);

        price_info::destroy(price_info_object);
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = domain::EInvalidDomain)]
    fun test_register_if_domain_name_contains_uppercase_character() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        let price_info_object = oracle_util(1000000, scenario);

        let nft = register_util(scenario, utf8(b"Abc.com"), 1, 1200 * mist_per_sui(), &price_info_object, 10);
        suins_registration::burn_for_testing(nft);

        price_info::destroy(price_info_object);
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = config::ELabelTooShort)]
    fun test_register_if_domain_name_too_short() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        let price_info_object = oracle_util(1000000, scenario);

        let nft = register_util(scenario, utf8(b"ab.sui"), 1, 1200 * mist_per_sui(), &price_info_object, 10);
        suins_registration::burn_for_testing(nft);

        price_info::destroy(price_info_object);
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = config::EInvalidDomain)]
    fun test_register_if_domain_name_contains_subdomain() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        let price_info_object = oracle_util(1000000, scenario);

        let nft = register_util(scenario, utf8(b"abc.xyz.sui"), 1, 1200 * mist_per_sui(), &price_info_object, 10);
        suins_registration::burn_for_testing(nft);

        price_info::destroy(price_info_object);
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = registry::ERecordNotExpired)]
    fun test_register_aborts_if_domain_name_went_through_auction() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        auction::init_for_testing(ctx(scenario));
        let price_info_object = oracle_util(1000000, scenario);

        auction_tests::normal_auction_flow(scenario);
        let nft = register_util(scenario, utf8(AUCTIONED_DOMAIN_NAME), 1, 50 * mist_per_sui(), &price_info_object, 10);
        suins_registration::burn_for_testing(nft);

        price_info::destroy(price_info_object);
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_register_works_if_auctioned_domain_name_expired() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        auction::init_for_testing(ctx(scenario));
        let price_info_object = oracle_util(1000000, scenario);

        auction_tests::normal_auction_flow(scenario);
        let nft = register_util(
            scenario,
            utf8(AUCTIONED_DOMAIN_NAME),
            1,
            50 * mist_per_sui(),
            &price_info_object,
            year_ms() + grace_period_ms() + 20,
        );
        assert_balance(scenario, 50 * mist_per_sui());
        assert!(suins_registration::domain(&nft) == domain::new(utf8(AUCTIONED_DOMAIN_NAME)), 0);
        suins_registration::burn_for_testing(nft);

        price_info::destroy(price_info_object);
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = suins::EAppNotAuthorized)]
    fun test_register_aborts_if_register_is_deauthorized() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        let price_info_object = oracle_util(1000000, scenario);

        deauthorize_app_util(scenario);
        let nft = register_util(scenario, utf8(DOMAIN_NAME), 1, 1200 * mist_per_sui(), &price_info_object, 10);
        suins_registration::burn_for_testing(nft);

        price_info::destroy(price_info_object);
        test_scenario::end(scenario_val);
    }
}