#[test_only]
module suins::auction_tests_5 {

    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use suins::auction::{Self, make_seal_bid, AuctionHouse, get_bids_by_bidder, get_bid_detail_fields, withdraw};
    use suins::configuration::Configuration;
    use std::vector;
    use std::option;
    use suins::auction_tests::{test_init, start_an_auction_util, place_bid_util, reveal_bid_util, ctx_new, get_bid_util, ctx_util, get_entry_util, finalize_auction_util};
    use suins::entity::SuiNS;
    use suins::controller;
    use suins::registry::{AdminCap};
    use sui::test_scenario;
    use suins::registrar;
    use suins::registry;
    use suins::configuration;
    use suins::registrar::RegistrationNFT;
    use std::string::utf8;
    use sui::clock::Clock;

    const SUINS_ADDRESS: address = @0xA001;
    const FIRST_USER_ADDRESS: address = @0xB001;
    const SECOND_USER_ADDRESS: address = @0xB002;
    const THIRD_USER_ADDRESS: address = @0xB003;
    const HASH: vector<u8> = b"vUAgEwNmPr";
    const FIRST_DOMAIN_NAME: vector<u8> = vector[
        97, // 'a'
        98, // 'b'
        99, // 'c'
        102,
        105,
    ];
    const FIRST_DOMAIN_NAME_SUI: vector<u8> = vector[
        97, // 'a'
        98, // 'b'
        99, // 'c'
        102,
        105,
        46, // .
        115, // s
        117, // u
        105, // i
    ];
    const SECOND_DOMAIN_NAME: vector<u8> = b"suins2";
    const SECOND_DOMAIN_NAME_SUI: vector<u8> = b"suins2.sui";
    const THIRD_DOMAIN_NAME: vector<u8> = b"suins3";
    const FIRST_SECRET: vector<u8> = b"CnRGhPvfCu";
    const SECOND_SECRET: vector<u8> = b"ZuaRzPvzUq";
    const START_AN_AUCTION_AT: u64 = 110;
    const BIDDING_PERIOD: u64 = 1;
    const REVEAL_PERIOD: u64 = 1;
    const AUCTION_STATE_NOT_AVAILABLE: u8 = 0;
    const AUCTION_STATE_OPEN: u8 = 1;
    const AUCTION_STATE_PENDING: u8 = 2;
    const AUCTION_STATE_BIDDING: u8 = 3;
    const AUCTION_STATE_REVEAL: u8 = 4;
    const AUCTION_STATE_FINALIZING: u8 = 5;
    const AUCTION_STATE_OWNED: u8 = 6;
    const AUCTION_STATE_REOPENED: u8 = 7;
    const START_AUCTION_START_AT: u64 = 100;
    const START_AUCTION_END_AT: u64 = 200;
    const EXTRA_PERIOD_START_AT: u64 = 207;
    const EXTRA_PERIOD: u64 = 30;
    const MOVE_REGISTRAR: vector<u8> = b"move";
    const SUI_REGISTRAR: vector<u8> = b"sui";
    const DEFAULT_TX_HASH: vector<u8> = x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532";
    const FIRST_TX_HASH: vector<u8> = x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431533";
    const SECOND_TX_HASH: vector<u8> = x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431534";
    const BIDDING_FEE: u64 = 1_000_000_000;
    const START_AN_AUCTION_FEE: u64 = 10_000_000_000;
    const EXTRA_PERIOD_END_AT: u64 = 232;

    #[test]
    fun test_set_start_an_auction_fee_works() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AN_AUCTION_AT,
                10
            );
            let ctx = &mut ctx;
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let coin = coin::mint_for_testing<SUI>(3 * START_AN_AUCTION_FEE, ctx);

            auction::start_an_auction(&mut auction, &mut suins, utf8(FIRST_DOMAIN_NAME), &mut coin, ctx);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            coin::burn_for_testing(coin);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction_house = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);

            assert!(controller::get_balance(&suins) == START_AN_AUCTION_FEE, 0);

            test_scenario::return_shared(auction_house);
            test_scenario::return_shared(suins);
        };
        let new_fee = 1200000000;
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let auction_house = test_scenario::take_shared<AuctionHouse>(scenario);

            auction::set_start_an_auction_fee(&admin_cap, &mut auction_house, new_fee);

            test_scenario::return_to_sender(scenario, admin_cap);
            test_scenario::return_shared(auction_house);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AN_AUCTION_AT,
                10
            );
            let ctx = &mut ctx;
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let coin = coin::mint_for_testing<SUI>(3 * START_AN_AUCTION_FEE, ctx);

            auction::start_an_auction(&mut auction, &mut suins, utf8(SECOND_DOMAIN_NAME), &mut coin, ctx);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            coin::burn_for_testing(coin);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction_house = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);

            assert!(controller::get_balance(&suins) == START_AN_AUCTION_FEE + new_fee, 0);

            test_scenario::return_shared(auction_house);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_set_start_an_auction_fee_works_2() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        let new_fee = 1200000000;
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let auction_house = test_scenario::take_shared<AuctionHouse>(scenario);

            auction::set_start_an_auction_fee(&admin_cap, &mut auction_house, new_fee);

            test_scenario::return_to_sender(scenario, admin_cap);
            test_scenario::return_shared(auction_house);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AN_AUCTION_AT,
                10
            );
            let ctx = &mut ctx;
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let coin = coin::mint_for_testing<SUI>(3 * START_AN_AUCTION_FEE, ctx);

            auction::start_an_auction(&mut auction, &mut suins, utf8(FIRST_DOMAIN_NAME), &mut coin, ctx);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            coin::burn_for_testing(coin);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction_house = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);

            assert!(controller::get_balance(&suins) == new_fee, 0);

            test_scenario::return_shared(auction_house);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EInvalidBiddingFee)]
    fun test_set_start_an_auction_fee_aborts_if_new_value_is_too_low() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        let new_fee = BIDDING_FEE - 1;
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let auction_house = test_scenario::take_shared<AuctionHouse>(scenario);

            auction::set_start_an_auction_fee(&admin_cap, &mut auction_house, new_fee);

            test_scenario::return_to_sender(scenario, admin_cap);
            test_scenario::return_shared(auction_house);
        };
        test_scenario::end(scenario_val);
    }
    //
    #[test, expected_failure(abort_code = auction::EInvalidBiddingFee)]
    fun test_set_start_an_auction_fee_aborts_if_new_value_is_too_high() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        let new_fee = 1_000_000_000_000_001;
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let auction_house = test_scenario::take_shared<AuctionHouse>(scenario);

            auction::set_start_an_auction_fee(&admin_cap, &mut auction_house, new_fee);

            test_scenario::return_to_sender(scenario, admin_cap);
            test_scenario::return_shared(auction_house);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_finalize_all_auctions_by_admin_after_extra_period_with_1_winning_auction() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, FIRST_DOMAIN_NAME);
        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, FIRST_USER_ADDRESS, 1200 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 10230 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);

            get_bid_util(&auction, seal_bid, FIRST_USER_ADDRESS, option::some(10230 * configuration::mist_per_sui()));
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                FIRST_DOMAIN_NAME,
                1200 * configuration::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );
            assert!(auction::get_balance(&auction) == 10230 * configuration::mist_per_sui(), 0);
            assert!(controller::get_balance(&suins) == BIDDING_FEE + START_AN_AUCTION_FEE, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
        };
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);

            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);

            get_entry_util(&mut auction, FIRST_DOMAIN_NAME, START_AN_AUCTION_AT + 1, 1200 * configuration::mist_per_sui(), 0, FIRST_USER_ADDRESS, false);
            auction::finalize_all_auctions_by_admin(
                &admin_cap,
                &mut auction,
                &mut suins,
                &config,
                &mut ctx_util(FIRST_USER_ADDRESS, EXTRA_PERIOD_END_AT + 1, 20),
            );
            get_entry_util(&mut auction, FIRST_DOMAIN_NAME, START_AN_AUCTION_AT + 1, 1200 * configuration::mist_per_sui(), 0, FIRST_USER_ADDRESS, true);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(scenario, admin_cap);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);
            let coin = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin) == 9030 * configuration::mist_per_sui(), 0);
            assert!(!test_scenario::has_most_recent_for_address<RegistrationNFT>(FIRST_USER_ADDRESS), 0);

            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);

            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_DOMAIN_NAME), 0);
            assert!(!registry::record_exists(&suins, utf8(FIRST_DOMAIN_NAME_SUI)), 0);

            assert!(controller::get_balance(&suins) == BIDDING_FEE + START_AN_AUCTION_FEE + 1200 * configuration::mist_per_sui(), 0);
            assert!(auction::get_balance(&auction) == 0, 0);

            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_finalize_all_auctions_by_admin_after_extra_period_with_1_winning_auction_2() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, FIRST_DOMAIN_NAME);
        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, FIRST_USER_ADDRESS, 1200 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 10230 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 15);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);

            get_bid_util(&auction, seal_bid, FIRST_USER_ADDRESS, option::some(10230 * configuration::mist_per_sui()));
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                FIRST_DOMAIN_NAME,
                1200 * configuration::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );
            assert!(auction::get_balance(&auction) == 10230 * configuration::mist_per_sui(), 0);
            assert!(controller::get_balance(&suins) == BIDDING_FEE + START_AN_AUCTION_FEE, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
        };
        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, SECOND_USER_ADDRESS, 1500 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 2000 * configuration::mist_per_sui(), SECOND_USER_ADDRESS, 0, option::none(), 10);
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);

            get_bid_util(&auction, seal_bid, SECOND_USER_ADDRESS, option::some(2000 * configuration::mist_per_sui()));
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                FIRST_DOMAIN_NAME,
                1500 * configuration::mist_per_sui(),
                FIRST_SECRET,
                SECOND_USER_ADDRESS,
                2
            );
            assert!(auction::get_balance(&auction) == 12230 * configuration::mist_per_sui(), 0);
            assert!(controller::get_balance(&suins) == BIDDING_FEE * 2 + START_AN_AUCTION_FEE, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
        };
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(SECOND_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);

            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);

            get_entry_util(&mut auction, FIRST_DOMAIN_NAME, START_AN_AUCTION_AT + 1, 1500 * configuration::mist_per_sui(), 1200 * configuration::mist_per_sui(), SECOND_USER_ADDRESS, false);
            auction::finalize_all_auctions_by_admin(
                &admin_cap,
                &mut auction,
                &mut suins,
                &config,
                &mut ctx_util(FIRST_USER_ADDRESS, EXTRA_PERIOD_END_AT + 1, 20),
            );
            get_entry_util(&mut auction, FIRST_DOMAIN_NAME, START_AN_AUCTION_AT + 1, 1500 * configuration::mist_per_sui(), 1200 * configuration::mist_per_sui(), SECOND_USER_ADDRESS, true);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(scenario, admin_cap);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);
            assert!(!test_scenario::has_most_recent_for_address<RegistrationNFT>(FIRST_USER_ADDRESS), 0);

            let ids = test_scenario::ids_for_address<Coin<SUI>>(SECOND_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);
            let coin = test_scenario::take_from_address<Coin<SUI>>(scenario, SECOND_USER_ADDRESS);
            assert!(coin::value(&coin) == 800 * configuration::mist_per_sui(), 0);
            assert!(!test_scenario::has_most_recent_for_address<RegistrationNFT>(SECOND_USER_ADDRESS), 0);
            test_scenario::return_to_address(SECOND_USER_ADDRESS, coin);

            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);

            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_DOMAIN_NAME), 0);
            assert!(!registry::record_exists(&suins, utf8(FIRST_DOMAIN_NAME_SUI)), 0);

            assert!(controller::get_balance(&suins) == BIDDING_FEE * 2 + START_AN_AUCTION_FEE + 1200 * configuration::mist_per_sui(), 0);
            assert!(auction::get_balance(&auction) == 10230 * configuration::mist_per_sui(), 0);

            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EAlreadyFinalized)]
    fun test_finalize_all_auctions_by_admin_after_extra_period_with_1_winning_auction_aborts_if_winner_calls_finalize() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, FIRST_DOMAIN_NAME);
        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, FIRST_USER_ADDRESS, 1200 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 10230 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);

            get_bid_util(&auction, seal_bid, FIRST_USER_ADDRESS, option::some(10230 * configuration::mist_per_sui()));
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                FIRST_DOMAIN_NAME,
                1200 * configuration::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );
            assert!(auction::get_balance(&auction) == 10230 * configuration::mist_per_sui(), 0);
            assert!(controller::get_balance(&suins) == BIDDING_FEE + START_AN_AUCTION_FEE, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
        };
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);

            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);

            get_entry_util(&mut auction, FIRST_DOMAIN_NAME, START_AN_AUCTION_AT + 1, 1200 * configuration::mist_per_sui(), 0, FIRST_USER_ADDRESS, false);
            auction::finalize_all_auctions_by_admin(
                &admin_cap,
                &mut auction,
                &mut suins,
                &config,
                &mut ctx_util(FIRST_USER_ADDRESS, EXTRA_PERIOD_END_AT + 1, 20),
            );
            get_entry_util(&mut auction, FIRST_DOMAIN_NAME, START_AN_AUCTION_AT + 1, 1200 * configuration::mist_per_sui(), 0, FIRST_USER_ADDRESS, true);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(scenario, admin_cap);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            finalize_auction_util(
                scenario,
                &mut auction,
                FIRST_DOMAIN_NAME,
                FIRST_USER_ADDRESS,
                EXTRA_PERIOD_END_AT,
                10
            );
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_finalize_all_auctions_by_admin_after_extra_period_being_called_twice() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            auction::finalize_all_auctions_by_admin(
                &admin_cap,
                &mut auction,
                &mut suins,
                &config,
                &mut ctx_util(FIRST_USER_ADDRESS, EXTRA_PERIOD_END_AT + 1, 20),
            );
            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(scenario, admin_cap);
        };
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            auction::finalize_all_auctions_by_admin(
                &admin_cap,
                &mut auction,
                &mut suins,
                &config,
                &mut ctx_util(FIRST_USER_ADDRESS, EXTRA_PERIOD_END_AT + 2, 20),
            );
            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(scenario, admin_cap);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_bids_multiple_times_same_domain_and_finalize() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, FIRST_DOMAIN_NAME);

        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, FIRST_USER_ADDRESS, 1000 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1300 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);
        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, FIRST_USER_ADDRESS, 2000 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 12200 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 15);
        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, FIRST_USER_ADDRESS, 3000 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 10200 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 20);

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            assert!(auction::get_balance(&auction) == 23700 * configuration::mist_per_sui(), 0);
            let coin = test_scenario::most_recent_id_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(option::is_none(&coin), 0);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 3, 0);

            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 1300 * configuration::mist_per_sui(), 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 1);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 12200 * configuration::mist_per_sui(), 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 2);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 10200 * configuration::mist_per_sui(), 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                FIRST_DOMAIN_NAME,
                3000 * configuration::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 3, 0);
            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 1300 * configuration::mist_per_sui(), 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 1);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 12200 * configuration::mist_per_sui(), 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 2);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 10200 * configuration::mist_per_sui(), 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(is_unsealed, 0);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 3, 0);

            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 1300 * configuration::mist_per_sui(), 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 1);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 12200 * configuration::mist_per_sui(), 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 2);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 10200 * configuration::mist_per_sui(), 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(is_unsealed, 0);

            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 3, 0);

            finalize_auction_util(
                scenario,
                &mut auction,
                FIRST_DOMAIN_NAME,
                FIRST_USER_ADDRESS,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD,
                10
            );
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 2, 0);

            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 1300 * configuration::mist_per_sui(), 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 1);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 12200 * configuration::mist_per_sui(), 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);

            let coin1 = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin1) == 7200 * configuration::mist_per_sui(), 0);

            assert!(auction::get_balance(&auction) == 13500 * configuration::mist_per_sui(), 0);
            assert!(controller::get_balance(&suins) == START_AN_AUCTION_FEE + 3000 * configuration::mist_per_sui() + BIDDING_FEE * 3, 0);

            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin1);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AN_AUCTION_AT + 200 * configuration::mist_per_sui(),
                20
            );
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 2, 0);
            withdraw(&mut auction, &mut ctx);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 0, 0);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 3, 0);

            let coin1 = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin1) == 12200 * configuration::mist_per_sui(), 0);
            let coin2 = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin2) == 1300 * configuration::mist_per_sui(), 0);
            let coin3 = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin3) == 7200 * configuration::mist_per_sui(), 0);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 0, 0);

            assert!(auction::get_balance(&auction) == 0, 0);
            assert!(controller::get_balance(&suins) == START_AN_AUCTION_FEE + 3000 * configuration::mist_per_sui() + BIDDING_FEE * 3, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin1);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin2);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin3);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_bids_multiple_times_same_domain_and_same_highest_value_then_finalize() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, FIRST_DOMAIN_NAME);

        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, FIRST_USER_ADDRESS, 2000 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 3300 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 15);
        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, FIRST_USER_ADDRESS, 2000 * configuration::mist_per_sui(), SECOND_SECRET);
        place_bid_util(scenario, seal_bid, 12200 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::some(FIRST_TX_HASH), 20);

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            assert!(auction::get_balance(&auction) == 15500 * configuration::mist_per_sui(), 0);
            let coin = test_scenario::most_recent_id_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(option::is_none(&coin), 0);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 2, 0);

            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 3300 * configuration::mist_per_sui(), 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 1);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 12200 * configuration::mist_per_sui(), 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                FIRST_DOMAIN_NAME,
                2000 * configuration::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );

            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                FIRST_DOMAIN_NAME,
                2000 * configuration::mist_per_sui(),
                SECOND_SECRET,
                FIRST_USER_ADDRESS,
                2
            );

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 2, 0);
            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 3300 * configuration::mist_per_sui(), 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 1);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 12200 * configuration::mist_per_sui(), 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(is_unsealed, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 2, 0);

            finalize_auction_util(
                scenario,
                &mut auction,
                FIRST_DOMAIN_NAME,
                FIRST_USER_ADDRESS,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD,
                10
            );
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 0, 0);

            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 3, 0);

            let first_coin = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&first_coin) == 12200 * configuration::mist_per_sui(), 0);
            let second_coin = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&second_coin) == 100 * configuration::mist_per_sui(), 0);
            let third_coin = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&third_coin) == 1300 * configuration::mist_per_sui(), 0);

            assert!(auction::get_balance(&auction) == 0, 0);
            assert!(controller::get_balance(&suins) == START_AN_AUCTION_FEE + 1900 * configuration::mist_per_sui() + BIDDING_FEE * 2, 0);

            test_scenario::return_to_address(FIRST_USER_ADDRESS, first_coin);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, second_coin);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, third_coin);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EPaymentNotEnough)]
    fun test_place_bid_aborts_if_payment_is_not_enough_2() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                DEFAULT_TX_HASH,
                START_AN_AUCTION_AT + 1,
                15
            );
            let ctx = &mut ctx;
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let coin = coin::mint_for_testing<SUI>(1000 * configuration::mist_per_sui(), ctx);
            let clock = test_scenario::take_shared<Clock>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);

            auction::place_bid(&mut auction, &mut suins, &config, FIRST_SECRET, 1000 * configuration::mist_per_sui(), &mut coin, &clock, ctx);

            coin::burn_for_testing(coin);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_place_bid_works_if_has_enough_payment() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                DEFAULT_TX_HASH,
                START_AN_AUCTION_AT + 1,
                15
            );
            let ctx = &mut ctx;
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let coin = coin::mint_for_testing<SUI>(BIDDING_FEE + 1000 * configuration::mist_per_sui(), ctx);
            let clock = test_scenario::take_shared<Clock>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);

            auction::place_bid(&mut auction, &mut suins, &config, FIRST_SECRET, 1000 * configuration::mist_per_sui(), &mut coin, &clock, ctx);

            coin::burn_for_testing(coin);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
        };
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);

            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);

            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 1000 * configuration::mist_per_sui(), 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);
            assert!(auction::get_balance(&auction) == 1000 * configuration::mist_per_sui(), 0);

            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }
}
