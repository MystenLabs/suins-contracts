// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module suins::auction_tests {
    use std::string::{String, utf8};

    use sui::test_scenario::{Self, Scenario, ctx};
    use sui::sui::SUI;
    use sui::clock::{Self, Clock};
    use sui::coin::{Self, Coin};

    use suins::{
        auction::{
            Self, 
            App as AuctionApp, 
            place_bid, 
            claim, 
            AuctionHouse, 
            start_auction_and_place_bid, 
            total_balance,
            admin_finalize_auction, 
            admin_try_finalize_auctions, 
            admin_withdraw_funds, 
            collect_winning_auction_fund
        }, 
        suins_registration::SuinsRegistration, 
        config, 
        domain, 
        constants::{Self, mist_per_sui}, 
        suins::{Self, SuiNS, AdminCap}, 
        registry
    };

    const SUINS_ADDRESS: address = @0xA001;
    const FIRST_ADDRESS: address = @0xB001;
    const SECOND_ADDRESS: address = @0xB002;
    const THIRD_ADDRESS: address = @0xB003;
    const FIRST_DOMAIN_NAME: vector<u8> = b"tes-t2.sui";
    const SECOND_DOMAIN_NAME: vector<u8> = b"tesq.sui";
    const AUCTION_BIDDING_PERIOD_MS: u64 = 2 * 24 * 60 * 60 * 1000;

    public fun test_init(): Scenario {
        let mut scenario_val = test_scenario::begin(SUINS_ADDRESS);
        let scenario = &mut scenario_val;
        {
            let mut suins = suins::init_for_testing(ctx(scenario));
            suins.authorize_app_for_testing<AuctionApp>();
            suins.share_for_testing();
            auction::init_for_testing(ctx(scenario));
            let clock = clock::create_for_testing(ctx(scenario));
            clock.share_for_testing();
        };
        {
            scenario.next_tx(SUINS_ADDRESS);
            let admin_cap = scenario.take_from_sender<AdminCap>();
            let mut suins = scenario.take_shared<SuiNS>();

            registry::init_for_testing(&admin_cap, &mut suins, ctx(scenario));

            test_scenario::return_shared(suins);
            test_scenario::return_to_sender(scenario, admin_cap);
        };
        scenario_val
    }

    public fun start_auction_and_place_bid_util(
        scenario: &mut Scenario,
        sender: address,
        domain_name: String,
        amount: u64
    ) {
        scenario.next_tx(sender);
        let mut auction_house = scenario.take_shared<AuctionHouse>();
        let mut suins = scenario.take_shared<SuiNS>();
        let payment = coin::mint_for_testing<SUI>(amount, ctx(scenario));
        let clock = scenario.take_shared<Clock>();

        start_auction_and_place_bid(
            &mut auction_house,
            &mut suins,
            domain_name,
            payment,
            &clock,
            ctx(scenario)
        );

        test_scenario::return_shared(clock);
        test_scenario::return_shared(suins);
        test_scenario::return_shared(auction_house);
    }

    fun place_bid_util(scenario: &mut Scenario, sender: address, domain_name: String, value: u64, clock_tick: u64) {
        scenario.next_tx(sender);
        let mut auction_house = scenario.take_shared<AuctionHouse>();
        let payment = coin::mint_for_testing<SUI>(value, ctx(scenario));
        let mut clock = scenario.take_shared<Clock>();

        clock.increment_for_testing(clock_tick);
        place_bid(&mut auction_house, domain_name, payment, &clock, ctx(scenario));

        test_scenario::return_shared(clock);
        test_scenario::return_shared(auction_house);
    }

    public fun claim_util(
        scenario: &mut Scenario,
        sender: address,
        domain_name: String,
        clock_tick: u64
    ): SuinsRegistration {
        scenario.next_tx(sender);
        let mut auction_house = scenario.take_shared<AuctionHouse>();
        let mut clock = scenario.take_shared<Clock>();

        clock.increment_for_testing(clock_tick);
        let nft = claim(&mut auction_house, domain_name, &clock, ctx(scenario));

        test_scenario::return_shared(clock);
        test_scenario::return_shared(auction_house);
        nft
    }

    fun withdraw_util(scenario: &mut Scenario, sender: address): Coin<SUI> {
        scenario.next_tx(sender);
        let returned_payment = test_scenario::take_from_sender<Coin<SUI>>(scenario);
        returned_payment
    }

    fun admin_collect_fund_util(scenario: &mut Scenario, domain_name: String, clock_tick: u64) {
        scenario.next_tx(SUINS_ADDRESS);
        let mut auction_house = scenario.take_shared<AuctionHouse>();
        let mut clock = scenario.take_shared<Clock>();

        clock.increment_for_testing(clock_tick);
        collect_winning_auction_fund(&mut auction_house, domain_name, &clock, ctx(scenario));

        test_scenario::return_shared(clock);
        test_scenario::return_shared(auction_house);
    }

    fun admin_try_finalize_auction_util(
        scenario: &mut Scenario,
        domain: String,
        clock_tick: u64
    ) {
        scenario.next_tx(SUINS_ADDRESS);
        let admin_cap = scenario.take_from_sender<AdminCap>();
        let mut auction_house = scenario.take_shared<AuctionHouse>();
        let mut clock = scenario.take_shared<Clock>();

        clock.increment_for_testing(clock_tick);
        admin_finalize_auction(&admin_cap, &mut auction_house, domain, &clock);

        test_scenario::return_shared(clock);
        test_scenario::return_shared(auction_house);
        test_scenario::return_to_sender(scenario, admin_cap);
    }

    fun admin_try_finalize_auctions_util(scenario: &mut Scenario, operation_limit: u64, clock_tick: u64) {
        scenario.next_tx(SUINS_ADDRESS);
        let admin_cap = scenario.take_from_sender<AdminCap>();
        let mut auction_house = scenario.take_shared<AuctionHouse>();
        let mut clock = scenario.take_shared<Clock>();

        clock.increment_for_testing(clock_tick);
        admin_try_finalize_auctions(&admin_cap, &mut auction_house, operation_limit, &clock);

        test_scenario::return_shared(clock);
        test_scenario::return_shared(auction_house);
        test_scenario::return_to_sender(scenario, admin_cap);
    }

    fun admin_withdraw_funds_util(scenario: &mut Scenario): Coin<SUI> {
        scenario.next_tx(SUINS_ADDRESS);
        let admin_cap = scenario.take_from_sender<AdminCap>();
        let mut auction_house = scenario.take_shared<AuctionHouse>();

        let funds = admin_withdraw_funds(&admin_cap, &mut auction_house, ctx(scenario));

        test_scenario::return_shared(auction_house);
        test_scenario::return_to_sender(scenario, admin_cap);
        funds
    }

    fun deauthorize_app_util(scenario: &mut Scenario) {
        scenario.next_tx(SUINS_ADDRESS);
        let admin_cap = scenario.take_from_sender<AdminCap>();
        let mut suins = scenario.take_shared<SuiNS>();

        suins::deauthorize_app<AuctionApp>(&admin_cap, &mut suins);

        test_scenario::return_shared(suins);
        test_scenario::return_to_sender(scenario, admin_cap);
    }

    fun assert_balance(scenario: &mut Scenario, amount: u64) {
        scenario.next_tx(SUINS_ADDRESS);
        let auction_house = scenario.take_shared<AuctionHouse>();
        assert!(total_balance(&auction_house) == amount, 0);
        test_scenario::return_shared(auction_house);
    }

    fun assert_auction(
        scenario: &mut Scenario,
        domain_name: String,
        expected_start_ms: u64,
        expected_end_ms: u64,
        expected_winner: address,
        expected_highest_amount: u64
    ) {
        scenario.next_tx(SUINS_ADDRESS);
        let auction_house = scenario.take_shared<AuctionHouse>();
        let (mut start_ms, mut end_ms, mut winner, mut highest_amount) = auction_house.get_auction_metadata(domain_name);
        assert!(option::extract(&mut start_ms) == expected_start_ms, 0);
        assert!(option::extract(&mut end_ms) == expected_end_ms, 0);
        assert!(option::extract(&mut winner) == expected_winner, 0);
        assert!(option::extract(&mut highest_amount) == expected_highest_amount, 0);
        test_scenario::return_shared(auction_house);
    }

    public fun normal_auction_flow(scenario: &mut Scenario) {
        start_auction_and_place_bid_util(
            scenario,
            FIRST_ADDRESS,
            utf8(FIRST_DOMAIN_NAME),
            1200 * mist_per_sui()
        );
        assert_auction(
            scenario,
            utf8(FIRST_DOMAIN_NAME),
            0,
            AUCTION_BIDDING_PERIOD_MS,
            FIRST_ADDRESS,
            1200 * mist_per_sui()
        );
        place_bid_util(scenario, SECOND_ADDRESS, utf8(FIRST_DOMAIN_NAME), 1210 * mist_per_sui(), 10);
        assert_auction(
            scenario,
            utf8(FIRST_DOMAIN_NAME),
            0,
            AUCTION_BIDDING_PERIOD_MS,
            SECOND_ADDRESS,
            1210 * mist_per_sui()
        );

        let nft = claim_util(scenario, SECOND_ADDRESS, utf8(FIRST_DOMAIN_NAME), AUCTION_BIDDING_PERIOD_MS + 1);
        assert!(nft.domain() == domain::new(utf8(FIRST_DOMAIN_NAME)), 0);
        assert!(nft.expiration_timestamp_ms() == constants::year_ms(), 0);
        nft.burn_for_testing();

        let payment = withdraw_util(scenario, FIRST_ADDRESS);
        assert!(coin::value(&payment) == 1200 * mist_per_sui(), 0);
        coin::burn_for_testing(payment);
        assert_balance(scenario, 1210 * mist_per_sui());

        let funds = admin_withdraw_funds_util(scenario);
        assert!(coin::value(&funds) == 1210 * mist_per_sui(), 0);
        assert_balance(scenario, 0);
        coin::burn_for_testing(funds);
    }

    #[test]
    fun test_normal_auction_flow() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        normal_auction_flow(scenario);
        scenario_val.end();
    }

    #[test, expected_failure(abort_code = sui::dynamic_field::EFieldDoesNotExist)]
    fun test_claim_aborts_if_winner_claims_twice() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_auction_and_place_bid_util(
            scenario,
            FIRST_ADDRESS,
            utf8(FIRST_DOMAIN_NAME),
            1200 * mist_per_sui()
        );
        place_bid_util(scenario, SECOND_ADDRESS, utf8(FIRST_DOMAIN_NAME), 1210 * mist_per_sui(), 0);

        let nft = claim_util(scenario, SECOND_ADDRESS, utf8(FIRST_DOMAIN_NAME), AUCTION_BIDDING_PERIOD_MS + 1);
        nft.burn_for_testing();
        let nft = claim_util(scenario, SECOND_ADDRESS, utf8(FIRST_DOMAIN_NAME), AUCTION_BIDDING_PERIOD_MS + 1);
        nft.burn_for_testing();
        scenario_val.end();
    }

    #[test, expected_failure(abort_code = auction::EWinnerCannotPlaceBid)]
    fun test_winner_cannot_place_bid() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_auction_and_place_bid_util(
            scenario,
            FIRST_ADDRESS,
            utf8(FIRST_DOMAIN_NAME),
            1200 * mist_per_sui()
        );
        place_bid_util(scenario, SECOND_ADDRESS, utf8(FIRST_DOMAIN_NAME), 1210 * mist_per_sui(), 0);
        place_bid_util(scenario, SECOND_ADDRESS, utf8(FIRST_DOMAIN_NAME), 1210 * mist_per_sui(), 0);

        scenario_val.end();
    }

    #[test, expected_failure(abort_code = auction::EBidAmountTooLow)]
    fun test_place_bid_aborts_if_value_is_too_low() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_auction_and_place_bid_util(
            scenario,
            FIRST_ADDRESS,
            utf8(FIRST_DOMAIN_NAME),
            1210 * mist_per_sui()
        );
        place_bid_util(scenario, SECOND_ADDRESS, utf8(FIRST_DOMAIN_NAME), 1200 * mist_per_sui(), 0);

        scenario_val.end();
    }

    #[test, expected_failure(abort_code = auction::ENotWinner)]
    fun test_non_winner_cannot_claim() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_auction_and_place_bid_util(
            scenario,
            FIRST_ADDRESS,
            utf8(FIRST_DOMAIN_NAME),
            1200 * mist_per_sui()
        );
        place_bid_util(scenario, SECOND_ADDRESS, utf8(FIRST_DOMAIN_NAME), 1210 * mist_per_sui(), 0);

        let nft = claim_util(scenario, FIRST_ADDRESS, utf8(FIRST_DOMAIN_NAME), AUCTION_BIDDING_PERIOD_MS + 1);
        nft.burn_for_testing();
        scenario_val.end();
    }

    #[test]
    fun test_admin_try_finalize_auction() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_auction_and_place_bid_util(
            scenario,
            FIRST_ADDRESS,
            utf8(FIRST_DOMAIN_NAME),
            1200 * mist_per_sui()
        );
        place_bid_util(scenario, SECOND_ADDRESS, utf8(FIRST_DOMAIN_NAME), 1210 * mist_per_sui(), 0);
        place_bid_util(scenario, THIRD_ADDRESS, utf8(FIRST_DOMAIN_NAME), 1220 * mist_per_sui(), 1);

        admin_try_finalize_auction_util(scenario, utf8(FIRST_DOMAIN_NAME), AUCTION_BIDDING_PERIOD_MS + 1);
        assert_balance(scenario, 1220 * mist_per_sui());

        let nft = test_scenario::take_from_address<SuinsRegistration>(scenario, THIRD_ADDRESS);
        assert!(nft.domain() == domain::new(utf8(FIRST_DOMAIN_NAME)), 0);
        assert!(nft.expiration_timestamp_ms() == constants::year_ms(), 0);
        nft.burn_for_testing();

        let payment = test_scenario::take_from_address<Coin<SUI>>(scenario, SECOND_ADDRESS);
        assert!(coin::value(&payment) == 1210 * mist_per_sui(), 0);
        coin::burn_for_testing(payment);

        let payment = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_ADDRESS);
        assert!(coin::value(&payment) == 1200 * mist_per_sui(), 0);
        coin::burn_for_testing(payment);
        assert_balance(scenario, 1220 * mist_per_sui());

        scenario_val.end();
    }

    #[test]
    fun test_admin_try_finalize_auction_2_auctions() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_auction_and_place_bid_util(
            scenario,
            FIRST_ADDRESS,
            utf8(FIRST_DOMAIN_NAME),
            1200 * mist_per_sui()
        );
        start_auction_and_place_bid_util(
            scenario,
            SECOND_ADDRESS,
            utf8(SECOND_DOMAIN_NAME),
            1210 * mist_per_sui()
        );

        admin_try_finalize_auctions_util(scenario, 4, AUCTION_BIDDING_PERIOD_MS + 1);
        assert_balance(scenario, 2410 * mist_per_sui());

        let nft = test_scenario::take_from_address<SuinsRegistration>(scenario, SECOND_ADDRESS);
        assert!(nft.domain() == domain::new(utf8(SECOND_DOMAIN_NAME)), 0);
        assert!(nft.expiration_timestamp_ms() == constants::year_ms(), 0);
        nft.burn_for_testing();

        let nft = test_scenario::take_from_address<SuinsRegistration>(scenario, FIRST_ADDRESS);
        assert!(nft.domain() == domain::new(utf8(FIRST_DOMAIN_NAME)), 0);
        assert!(nft.expiration_timestamp_ms() == constants::year_ms(), 0);
        nft.burn_for_testing();

        scenario_val.end();
    }

    #[test, expected_failure(abort_code = auction::EAuctionNotEndedYet)]
    fun test_admin_try_finalize_auction_too_early() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_auction_and_place_bid_util(
            scenario,
            FIRST_ADDRESS,
            utf8(FIRST_DOMAIN_NAME),
            1200 * mist_per_sui()
        );

        admin_try_finalize_auction_util(scenario, utf8(FIRST_DOMAIN_NAME), 0);
        scenario_val.end();
    }

    #[test]
    fun test_admin_try_finalize_auctions_too_early() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_auction_and_place_bid_util(
            scenario,
            FIRST_ADDRESS,
            utf8(FIRST_DOMAIN_NAME),
            1200 * mist_per_sui()
        );
        admin_try_finalize_auctions_util(scenario, 3, 0);
        assert_balance(scenario, 0);

        scenario_val.end();
    }

    #[test, expected_failure(abort_code = auction::EAuctionEnded)]
    fun test_place_bid_aborts_if_too_late() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_auction_and_place_bid_util(
            scenario,
            FIRST_ADDRESS,
            utf8(FIRST_DOMAIN_NAME),
            1200 * mist_per_sui()
        );
        place_bid_util(
            scenario,
            SECOND_ADDRESS,
            utf8(FIRST_DOMAIN_NAME),
            1210 * mist_per_sui(),
            AUCTION_BIDDING_PERIOD_MS + 1
        );
        scenario_val.end();
    }

    #[test, expected_failure(abort_code = auction::ENoProfits)]
    fun test_admin_withdraw_funds_aborts_if_no_profits() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        let funds = admin_withdraw_funds_util(scenario);
        coin::burn_for_testing(funds);
        scenario_val.end();
    }

    #[test, expected_failure(abort_code = config::EInvalidTld)]
    fun test_start_auction_aborts_with_wrong_tld() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_auction_and_place_bid_util(
            scenario,
            FIRST_ADDRESS,
            utf8(b"test.move"),
            1200 * mist_per_sui()
        );
        scenario_val.end();
    }

    #[test, expected_failure(abort_code = config::ELabelTooShort)]
    fun test_start_auction_aborts_if_domain_name_too_short() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_auction_and_place_bid_util(
            scenario,
            FIRST_ADDRESS,
            utf8(b"tt.sui"),
            1200 * mist_per_sui()
        );
        scenario_val.end();
    }

    #[test, expected_failure(abort_code = domain::EInvalidDomain)]
    fun test_start_auction_aborts_if_domain_name_too_long() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_auction_and_place_bid_util(
            scenario,
            FIRST_ADDRESS,
            utf8(b"g2bst97onsyl8gwo5brfglcb-obh8i7p01lz5ccscd6zxx4qn7wnv8b1in5sectj8s.sui"),
            1200 * mist_per_sui()
        );
        scenario_val.end();
    }

    #[test, expected_failure(abort_code = domain::EInvalidDomain)]
    fun test_start_auction_aborts_if_domain_name_starts_with_dash() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_auction_and_place_bid_util(
            scenario,
            FIRST_ADDRESS,
            utf8(b"-test.sui"),
            1200 * mist_per_sui()
        );
        scenario_val.end();
    }

    #[test, expected_failure(abort_code = domain::EInvalidDomain)]
    fun test_start_auction_aborts_if_domain_name_ends_with_dash() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_auction_and_place_bid_util(
            scenario,
            FIRST_ADDRESS,
            utf8(b"test-.sui"),
            1200 * mist_per_sui()
        );
        scenario_val.end();
    }

    #[test, expected_failure(abort_code = domain::EInvalidDomain)]
    fun test_start_auction_aborts_if_domain_name_contains_uppercase_characters() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_auction_and_place_bid_util(
            scenario,
            FIRST_ADDRESS,
            utf8(b"ttABC.sui"),
            1200 * mist_per_sui()
        );
        scenario_val.end();
    }

    #[test, expected_failure(abort_code = auction::EAuctionNotStarted)]
    fun test_place_bid_aborts_if_auction_not_started() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        place_bid_util(scenario, SECOND_ADDRESS, utf8(FIRST_DOMAIN_NAME), 1210 * mist_per_sui(), 0);
        scenario_val.end();
    }

    #[test, expected_failure(abort_code = auction::EInvalidBidValue)]
    fun test_start_auction_aborts_if_not_enough_fee() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_auction_and_place_bid_util(
            scenario,
            FIRST_ADDRESS,
            utf8(b"test.sui"),
            10 * mist_per_sui()
        );
        scenario_val.end();
    }

    #[test]
    fun test_admin_collect_fund() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_auction_and_place_bid_util(
            scenario,
            FIRST_ADDRESS,
            utf8(FIRST_DOMAIN_NAME),
            1200 * mist_per_sui()
        );
        place_bid_util(
            scenario,
            SECOND_ADDRESS,
            utf8(FIRST_DOMAIN_NAME),
            1210 * mist_per_sui(),
            AUCTION_BIDDING_PERIOD_MS
        );
        assert_balance(scenario, 0);
        admin_collect_fund_util(scenario, utf8(FIRST_DOMAIN_NAME), AUCTION_BIDDING_PERIOD_MS + 1);
        assert_balance(scenario, 1210 * mist_per_sui());

        let nft = claim_util(scenario, SECOND_ADDRESS, utf8(FIRST_DOMAIN_NAME), AUCTION_BIDDING_PERIOD_MS + 1);
        assert!(nft.domain() == domain::new(utf8(FIRST_DOMAIN_NAME)), 0);
        assert!(nft.expiration_timestamp_ms() == constants::year_ms(), 0);
        nft.burn_for_testing();

        let payment = withdraw_util(scenario, FIRST_ADDRESS);
        assert!(coin::value(&payment) == 1200 * mist_per_sui(), 0);
        coin::burn_for_testing(payment);
        assert_balance(scenario, 1210 * mist_per_sui());

        let funds = admin_withdraw_funds_util(scenario);
        assert!(coin::value(&funds) == 1210 * mist_per_sui(), 0);
        assert_balance(scenario, 0);
        coin::burn_for_testing(funds);

        scenario_val.end();
    }

    #[test, expected_failure(abort_code = auction::EAuctionNotEndedYet)]
    fun test_admin_collect_fund_aborts_if_too_early() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_auction_and_place_bid_util(
            scenario,
            FIRST_ADDRESS,
            utf8(FIRST_DOMAIN_NAME),
            1200 * mist_per_sui()
        );
        admin_collect_fund_util(scenario, utf8(FIRST_DOMAIN_NAME), 0);
        scenario_val.end();
    }

    #[test, expected_failure(abort_code = ::suins::suins::EAppNotAuthorized)]
    fun test_start_auction_and_place_bid_aborts_if_auction_is_deauthorized() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        deauthorize_app_util(scenario);
        start_auction_and_place_bid_util(
            scenario,
            FIRST_ADDRESS,
            utf8(FIRST_DOMAIN_NAME),
            1200 * mist_per_sui()
        );
        scenario_val.end();
    }

    #[test]
    fun test_place_bid_and_claim_and_withdraw_works_even_if_auction_is_deauthorized() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_auction_and_place_bid_util(
            scenario,
            FIRST_ADDRESS,
            utf8(FIRST_DOMAIN_NAME),
            1200 * mist_per_sui()
        );
        deauthorize_app_util(scenario);
        place_bid_util(scenario, SECOND_ADDRESS, utf8(FIRST_DOMAIN_NAME), 1210 * mist_per_sui(), 10);
        assert_auction(
            scenario,
            utf8(FIRST_DOMAIN_NAME),
            0,
            AUCTION_BIDDING_PERIOD_MS,
            SECOND_ADDRESS,
            1210 * mist_per_sui()
        );

        let nft = claim_util(scenario, SECOND_ADDRESS, utf8(FIRST_DOMAIN_NAME), AUCTION_BIDDING_PERIOD_MS + 1);
        assert!(nft.domain() == domain::new(utf8(FIRST_DOMAIN_NAME)), 0);
        assert!(nft.expiration_timestamp_ms() == constants::year_ms(), 0);
        nft.burn_for_testing();

        let payment = withdraw_util(scenario, FIRST_ADDRESS);
        assert!(coin::value(&payment) == 1200 * mist_per_sui(), 0);
        coin::burn_for_testing(payment);
        assert_balance(scenario, 1210 * mist_per_sui());

        let funds = admin_withdraw_funds_util(scenario);
        assert!(coin::value(&funds) == 1210 * mist_per_sui(), 0);
        assert_balance(scenario, 0);
        coin::burn_for_testing(funds);

        scenario_val.end();
    }

    #[test]
    fun test_admin_try_finalize_auction_works_even_if_auction_is_deauthorized() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_auction_and_place_bid_util(
            scenario,
            FIRST_ADDRESS,
            utf8(FIRST_DOMAIN_NAME),
            1200 * mist_per_sui()
        );
        place_bid_util(scenario, SECOND_ADDRESS, utf8(FIRST_DOMAIN_NAME), 1210 * mist_per_sui(), 0);
        place_bid_util(scenario, THIRD_ADDRESS, utf8(FIRST_DOMAIN_NAME), 1220 * mist_per_sui(), 1);

        deauthorize_app_util(scenario);
        admin_try_finalize_auction_util(scenario, utf8(FIRST_DOMAIN_NAME), AUCTION_BIDDING_PERIOD_MS + 1);
        assert_balance(scenario, 1220 * mist_per_sui());

        let nft = test_scenario::take_from_address<SuinsRegistration>(scenario, THIRD_ADDRESS);
        assert!(nft.domain() == domain::new(utf8(FIRST_DOMAIN_NAME)), 0);
        assert!(nft.expiration_timestamp_ms() == constants::year_ms(), 0);
        nft.burn_for_testing();

        let payment = test_scenario::take_from_address<Coin<SUI>>(scenario, SECOND_ADDRESS);
        assert!(coin::value(&payment) == 1210 * mist_per_sui(), 0);
        coin::burn_for_testing(payment);

        let payment = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_ADDRESS);
        assert!(coin::value(&payment) == 1200 * mist_per_sui(), 0);
        coin::burn_for_testing(payment);
        assert_balance(scenario, 1220 * mist_per_sui());

        scenario_val.end();
    }

    #[test]
    fun test_admin_collect_fund_even_if_auction_is_deauthorized() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_auction_and_place_bid_util(
            scenario,
            FIRST_ADDRESS,
            utf8(FIRST_DOMAIN_NAME),
            1200 * mist_per_sui()
        );
        place_bid_util(
            scenario,
            SECOND_ADDRESS,
            utf8(FIRST_DOMAIN_NAME),
            1210 * mist_per_sui(),
            AUCTION_BIDDING_PERIOD_MS
        );
        assert_balance(scenario, 0);
        deauthorize_app_util(scenario);
        admin_collect_fund_util(scenario, utf8(FIRST_DOMAIN_NAME), AUCTION_BIDDING_PERIOD_MS + 1);
        assert_balance(scenario, 1210 * mist_per_sui());

        let nft = claim_util(scenario, SECOND_ADDRESS, utf8(FIRST_DOMAIN_NAME), AUCTION_BIDDING_PERIOD_MS + 1);
        assert!(nft.domain() == domain::new(utf8(FIRST_DOMAIN_NAME)), 0);
        assert!(nft.expiration_timestamp_ms() == constants::year_ms(), 0);
        nft.burn_for_testing();

        let payment = withdraw_util(scenario, FIRST_ADDRESS);
        assert!(payment.value() == 1200 * mist_per_sui(), 0);
        payment.burn_for_testing();
        assert_balance(scenario, 1210 * mist_per_sui());

        let funds = admin_withdraw_funds_util(scenario);
        assert!(funds.value() == 1210 * mist_per_sui(), 0);
        assert_balance(scenario, 0);
        funds.burn_for_testing();

        scenario_val.end();
    }
}
