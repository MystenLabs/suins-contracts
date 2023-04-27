#[test_only]
module suins::auction_tests_3 {

    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::dynamic_field;
    use suins::auction::{Self, make_seal_bid, get_bids_by_bidder, get_bid_detail_fields, withdraw, AuctionHouse, finalize_all_auctions_by_admin};
    use suins::configuration::Configuration;
    use std::vector;
    use std::option;
    use suins::auction_tests::{test_init, start_an_auction_util, place_bid_util, reveal_bid_util, ctx_new, get_bid_util, ctx_util, finalize_auction_util, get_entry_util};
    use suins::suins::SuiNS;
    use suins::registry;
    use suins::suins::{Self, AdminCap};
    use sui::test_scenario;
    use sui::clock::Clock;
    use suins::registrar;
    use suins::configuration;
    use std::string::utf8;

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
    const BIDDING_PERIOD: u64 = 3;
    const REVEAL_PERIOD: u64 = 3;
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
    const EXTRA_PERIOD_END_AT: u64 = 236;
    const EXTRA_PERIOD: u64 = 30;
    const MOVE_REGISTRAR: vector<u8> = b"move";
    const SUI_REGISTRAR: vector<u8> = b"sui";
    const DEFAULT_TX_HASH: vector<u8> = x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532";
    const FIRST_TX_HASH: vector<u8> = x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431533";
    const SECOND_TX_HASH: vector<u8> = x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431534";
    const BIDDING_FEE: u64 = 1_000_000_000;
    const START_AN_AUCTION_FEE: u64 = 10_000_000_000;

    #[test]
    fun test_place_bid_aborts_if_exists() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, FIRST_DOMAIN_NAME);

        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, FIRST_USER_ADDRESS, 2000 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 3300 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);
        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, FIRST_USER_ADDRESS, 2000 * configuration::mist_per_sui(), SECOND_SECRET);
        place_bid_util(scenario, seal_bid, 12200 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_bids_multiple_times_same_domain_and_same_highest_value_then_withdraw() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, FIRST_DOMAIN_NAME);

        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, FIRST_USER_ADDRESS, 2000 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 3300 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);
        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, FIRST_USER_ADDRESS, 2000 * configuration::mist_per_sui(), SECOND_SECRET);
        place_bid_util(scenario, seal_bid, 12200 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::some(FIRST_TX_HASH), 10);

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

            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                SECOND_TX_HASH,
                START_AN_AUCTION_AT + 200 * configuration::mist_per_sui(),
                20
            );
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 2, 0);
            withdraw(&mut auction, &mut ctx);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);

            let coin1 = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin1) == 12200 * configuration::mist_per_sui(), 0);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);

            assert!(auction::get_balance(&auction) == 3300 * configuration::mist_per_sui(), 0);
            assert!(suins::balance(&suins) == START_AN_AUCTION_FEE + BIDDING_FEE * 2, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin1);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_bids_multiple_times_same_domain_and_same_highest_value_then_withdraw_2() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, FIRST_DOMAIN_NAME);

        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, FIRST_USER_ADDRESS, 2000 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 3300 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);
        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, FIRST_USER_ADDRESS, 2000 * configuration::mist_per_sui(), SECOND_SECRET);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                FIRST_TX_HASH,
                START_AN_AUCTION_AT + 2,
                15,
            );
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let coin = coin::mint_for_testing<SUI>(12222 * configuration::mist_per_sui() + BIDDING_FEE, &mut ctx);
            auction::place_bid(&mut auction, &mut suins, seal_bid, 12200 * configuration::mist_per_sui(), &mut coin, &clock, &mut ctx);
            assert!(coin::value(&coin) == 22 * configuration::mist_per_sui(), 0);

            coin::burn_for_testing(coin);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
        };
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
            assert!(created_at == START_AN_AUCTION_AT + 2, 0);
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
            assert!(created_at == START_AN_AUCTION_AT + 2, 0);
            assert!(is_unsealed, 0);

            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                SECOND_TX_HASH,
                START_AN_AUCTION_AT + 200 * configuration::mist_per_sui(),
                20
            );
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 2, 0);
            withdraw(&mut auction, &mut ctx);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);

            let coin1 = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin1) == 12200 * configuration::mist_per_sui(), 0);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);

            assert!(auction::get_balance(&auction) == 3300 * configuration::mist_per_sui(), 0);
            assert!(suins::balance(&suins) == START_AN_AUCTION_FEE + BIDDING_FEE * 2, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin1);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_bids_multiple_times_same_domain_and_same_highest_value_then_withdraw_3() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, FIRST_DOMAIN_NAME);

        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, FIRST_USER_ADDRESS, 2000 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 12200 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);
        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, FIRST_USER_ADDRESS, 2000 * configuration::mist_per_sui(), SECOND_SECRET);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                FIRST_TX_HASH,
                START_AN_AUCTION_AT + 2,
                15,
            );
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            let coin = coin::mint_for_testing<SUI>(3301 * configuration::mist_per_sui() + BIDDING_FEE, &mut ctx);
            let config = test_scenario::take_shared<Configuration>(scenario);
            auction::place_bid(&mut auction, &mut suins, seal_bid, 3300 * configuration::mist_per_sui(), &mut coin, &clock, &mut ctx);
            assert!(coin::value(&coin) == configuration::mist_per_sui(), 0);
            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
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
            assert!(mask == 12200 * configuration::mist_per_sui(), 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 1);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 3300 * configuration::mist_per_sui(), 0);
            assert!(created_at == START_AN_AUCTION_AT + 2, 0);
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
            assert!(mask == 12200 * configuration::mist_per_sui(), 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 1);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 3300 * configuration::mist_per_sui(), 0);
            assert!(created_at == START_AN_AUCTION_AT + 2, 0);
            assert!(is_unsealed, 0);

            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                SECOND_TX_HASH,
                START_AN_AUCTION_AT + 200 * configuration::mist_per_sui(),
                20
            );
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 2, 0);
            withdraw(&mut auction, &mut ctx);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);

            let coin1 = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin1) == 3300 * configuration::mist_per_sui(), 0);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);

            assert!(auction::get_balance(&auction) == 12200 * configuration::mist_per_sui(), 0);
            assert!(suins::balance(&suins) == START_AN_AUCTION_FEE + BIDDING_FEE * 2, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin1);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_bids_multiple_times_same_domain_and_same_highest_value_but_not_yet_reveal_then_withdraw() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, FIRST_DOMAIN_NAME);

        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, FIRST_USER_ADDRESS, 2000 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 3300 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 15);
        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, FIRST_USER_ADDRESS, 2000 * configuration::mist_per_sui(), SECOND_SECRET);
        place_bid_util(scenario, seal_bid, 12200 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 20);

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
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

            test_scenario::return_shared(auction);
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
            assert!(vector::length(&ids) == 2, 0);

            let coin1 = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin1) == 12200 * configuration::mist_per_sui(), 0);
            let coin2 = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin2) == 3300 * configuration::mist_per_sui(), 0);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 0, 0);

            assert!(auction::get_balance(&auction) == 0, 0);
            assert!(suins::balance(&suins) == START_AN_AUCTION_FEE + BIDDING_FEE * 2, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin1);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin2);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_bids_multiple_times_same_domain_and_same_highest_value_but_not_yet_reveal_then_finalize() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, FIRST_DOMAIN_NAME);

        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, FIRST_USER_ADDRESS, 2000 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 3300 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 15);
        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, FIRST_USER_ADDRESS, 2000 * configuration::mist_per_sui(), SECOND_SECRET);
        place_bid_util(scenario, seal_bid, 12200 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 20);

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
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
            assert!(mask == 3300 * configuration::mist_per_sui(), 0);
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
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AN_AUCTION_AT + 200 * configuration::mist_per_sui(),
                20
            );
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 2, 0);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);

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
            assert!(vector::length(&ids) == 2, 0);

            let coin1 = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin1) == 12200 * configuration::mist_per_sui(), 0);
            let coin2 = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin2) == 3300 * configuration::mist_per_sui(), 0);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 0, 0);

            assert!(auction::get_balance(&auction) == 0, 0);
            assert!(suins::balance(&suins) == START_AN_AUCTION_FEE + BIDDING_FEE * 2, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin1);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin2);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_finalize_all_auctions_by_admin() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, FIRST_DOMAIN_NAME);

        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, FIRST_USER_ADDRESS, 1000 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 10230 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            get_bid_util(&auction, seal_bid, FIRST_USER_ADDRESS, option::some(10230 * configuration::mist_per_sui()));
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                FIRST_DOMAIN_NAME,
                1000 * configuration::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );
            assert!(auction::get_balance(&auction) == 10230 * configuration::mist_per_sui(), 0);
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);

            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);

            get_entry_util(&mut auction, FIRST_DOMAIN_NAME, START_AN_AUCTION_AT + 1, 1000 * configuration::mist_per_sui(), 0, FIRST_USER_ADDRESS, false);
            finalize_all_auctions_by_admin(
                &admin_cap,
                &mut auction,
                &mut suins,
                &config,
                &mut ctx_util(FIRST_USER_ADDRESS, EXTRA_PERIOD_START_AT, 20),
            );
            get_entry_util(&mut auction, FIRST_DOMAIN_NAME, START_AN_AUCTION_AT + 1, 1000 * configuration::mist_per_sui(), 0, FIRST_USER_ADDRESS, true);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_to_sender(scenario, admin_cap);
            test_scenario::return_shared(config);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);

            get_entry_util(&mut auction, FIRST_DOMAIN_NAME, START_AN_AUCTION_AT + 1, 1000 * configuration::mist_per_sui(), 0, FIRST_USER_ADDRESS, true);
            assert!(registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_DOMAIN_NAME), 0);
            assert!(
                registrar::name_expires_at(&suins, utf8(SUI_REGISTRAR), utf8(FIRST_DOMAIN_NAME))
                    == EXTRA_PERIOD_START_AT + 365,
                0
            );
            assert!(registry::owner(&suins, utf8(FIRST_DOMAIN_NAME_SUI)) == FIRST_USER_ADDRESS, 0);
            assert!(registry::target_address(&suins, utf8(FIRST_DOMAIN_NAME_SUI)) == FIRST_USER_ADDRESS, 0);
            assert!(auction::get_balance(&auction) == 0, 0);
            assert!(
                suins::balance(&suins) == START_AN_AUCTION_FEE + 1000 * configuration::mist_per_sui() + BIDDING_FEE,
                0,
            );

            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EAlreadyFinalized)]
    fun test_finalize_all_auctions_by_admin_aborts_if_the_winner_calls_finalize_later() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, FIRST_DOMAIN_NAME);

        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, FIRST_USER_ADDRESS, 1000 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 10230 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);

            get_bid_util(&auction, seal_bid, FIRST_USER_ADDRESS, option::some(10230 * configuration::mist_per_sui()));
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                FIRST_DOMAIN_NAME,
                1000 * configuration::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );
            assert!(auction::get_balance(&auction) == 10230 * configuration::mist_per_sui(), 0);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
        };
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);

            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);

            get_entry_util(&mut auction, FIRST_DOMAIN_NAME, START_AN_AUCTION_AT + 1, 1000 * configuration::mist_per_sui(), 0, FIRST_USER_ADDRESS, false);
            finalize_all_auctions_by_admin(
                &admin_cap,
                &mut auction,
                &mut suins,
                &config,
                &mut ctx_util(FIRST_USER_ADDRESS, EXTRA_PERIOD_START_AT, 20),
            );
            get_entry_util(&mut auction, FIRST_DOMAIN_NAME, START_AN_AUCTION_AT + 1, 1000 * configuration::mist_per_sui(), 0, FIRST_USER_ADDRESS, true);

            test_scenario::return_to_sender(scenario, admin_cap);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            finalize_auction_util(
                scenario,
                &mut auction,
                FIRST_DOMAIN_NAME,
                FIRST_USER_ADDRESS,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD,
                10
            );
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_not_yet_finalized_bid_cannot_be_withdrawed() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, FIRST_DOMAIN_NAME);

        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, FIRST_USER_ADDRESS, 1000 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1100 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);

            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                FIRST_DOMAIN_NAME,
                1000 * configuration::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                5
            );
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                200 + 20,
                10
            );
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);

            withdraw(&mut auction, &mut ctx);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);

            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            finalize_auction_util(
                scenario,
                &mut auction,
                FIRST_DOMAIN_NAME,
                FIRST_USER_ADDRESS,
                START_AUCTION_END_AT + 10,
                10
            );
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 0, 0);

            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_not_yet_finalized_bid_cannot_be_withdrawed_2() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, FIRST_DOMAIN_NAME);

        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, FIRST_USER_ADDRESS, 1000 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1100 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);

            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                FIRST_DOMAIN_NAME,
                1000 * configuration::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                5
            );
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
        };

        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, FIRST_USER_ADDRESS, 2000 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 4100 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::some(FIRST_TX_HASH), 10);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                FIRST_DOMAIN_NAME,
                2000 * configuration::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                5
            );
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                200 + 20,
                10
            );
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 2, 0);

            withdraw(&mut auction, &mut ctx);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);

            let coin = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin) == 1100 * configuration::mist_per_sui(), 0);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);
            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);

            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 4100 * configuration::mist_per_sui(), 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(is_unsealed, 0);

            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_not_yet_finalized_bid_cannt_be_withdrawed_after_extra_time_if_it_is_the_winning() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, FIRST_DOMAIN_NAME);

        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, FIRST_USER_ADDRESS, 1000 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1100 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                FIRST_DOMAIN_NAME,
                1000 * configuration::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                5
            );
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AUCTION_END_AT + BIDDING_PERIOD + REVEAL_PERIOD + 30 + 1,
                10
            );
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);
            withdraw(&mut auction, &mut ctx);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_not_yet_finalized_bid_cannt_be_withdrawed_after_extra_time_if_it_isnt_the_winning() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, FIRST_DOMAIN_NAME);

        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, FIRST_USER_ADDRESS, 1000 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1100 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                FIRST_DOMAIN_NAME,
                1000 * configuration::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                5
            );
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
        };
        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, FIRST_USER_ADDRESS, 2000 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 2100 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::some(FIRST_TX_HASH), 10);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                FIRST_DOMAIN_NAME,
                2000 * configuration::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                5
            );
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AUCTION_END_AT + BIDDING_PERIOD + REVEAL_PERIOD + 30 + 1,
                10
            );
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 2, 0);
            withdraw(&mut auction, &mut ctx);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);
            let coin = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin) == 1100 * configuration::mist_per_sui(), 0);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);

            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_not_yet_finalized_bid_can_be_withdrawed_by_non_winner() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, FIRST_DOMAIN_NAME);

        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, FIRST_USER_ADDRESS, 1000 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1100 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                FIRST_DOMAIN_NAME,
                1000 * configuration::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                5
            );
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
        };

        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, SECOND_USER_ADDRESS, 2000 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 3100 * configuration::mist_per_sui(), SECOND_USER_ADDRESS, 0, option::some(FIRST_TX_HASH), 10);
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                FIRST_DOMAIN_NAME,
                2000 * configuration::mist_per_sui(),
                FIRST_SECRET,
                SECOND_USER_ADDRESS,
                10
            );
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
        };

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                200 + 20,
                10
            );
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(SECOND_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);

            withdraw(&mut auction, &mut ctx);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);

            let coin = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin) == 1100 * configuration::mist_per_sui(), 0);

            let ids = test_scenario::ids_for_address<Coin<SUI>>(SECOND_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 0, 0);

            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_not_yet_finalized_bid_can_be_withdrawed_by_non_winner_2() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, FIRST_DOMAIN_NAME);

        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, FIRST_USER_ADDRESS, 1000 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1100 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                FIRST_DOMAIN_NAME,
                1000 * configuration::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                5
            );
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
        };

        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, SECOND_USER_ADDRESS, 2000 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 3100 * configuration::mist_per_sui(), SECOND_USER_ADDRESS, 0, option::some(FIRST_TX_HASH), 10);
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                FIRST_DOMAIN_NAME,
                2000 * configuration::mist_per_sui(),
                FIRST_SECRET,
                SECOND_USER_ADDRESS,
                10
            );
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
        };

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                200 + 40,
                10
            );
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(SECOND_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);

            withdraw(&mut auction, &mut ctx);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);

            let coin = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin) == 1100 * configuration::mist_per_sui(), 0);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin);

            let ids = test_scenario::ids_for_address<Coin<SUI>>(SECOND_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 0, 0);

            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_reveal_bid_handle_invalid_bid_if_place_bid_too_early() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;

        start_an_auction_util(scenario, FIRST_DOMAIN_NAME);
        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, FIRST_USER_ADDRESS, 1100 * configuration::mist_per_sui(), FIRST_SECRET);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AN_AUCTION_AT - 1,
                2
            );
            let ctx = &mut ctx;
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let coin = coin::mint_for_testing<SUI>(1300 * configuration::mist_per_sui() + BIDDING_FEE, ctx);
            let config = test_scenario::take_shared<Configuration>(scenario);

            assert!(auction::get_balance(&auction) == 0, 0);
            auction::place_bid(&mut auction, &mut suins, seal_bid, 1300 * configuration::mist_per_sui(), &mut coin, &clock, ctx);
            assert!(auction::get_balance(&auction) == 1300 * configuration::mist_per_sui(), 0);
            assert!(coin::value(&coin) == 0, 0);

            coin::burn_for_testing(coin);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let coin = test_scenario::most_recent_id_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            let config = test_scenario::take_shared<Configuration>(scenario);

            assert!(option::is_none(&coin), 0);
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                FIRST_DOMAIN_NAME,
                1100 * configuration::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                5
            );

            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                300,
                2
            );
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);

            withdraw(&mut auction, &mut ctx);

            assert!(auction::get_balance(&auction) == 0, 0);
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 0, 0);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);

            let coin = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin) == 1300 * configuration::mist_per_sui(), 0);
            let (start_at, highest_bid, second_highest_bid, winner, is_finalized) =
                auction::get_entry(&auction, utf8(FIRST_DOMAIN_NAME));
            assert!(option::extract(&mut start_at) == START_AN_AUCTION_AT + 1, 0);
            assert!(option::extract(&mut highest_bid) == 0, 0);
            assert!(option::extract(&mut second_highest_bid) == 0, 0);
            assert!(option::extract(&mut winner) == @0x0, 0);
            assert!(option::extract(&mut is_finalized) == false, 0);

            let suins = test_scenario::take_shared<SuiNS>(scenario);
            assert!(suins::balance(&suins) == START_AN_AUCTION_FEE + BIDDING_FEE, 0);

            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_reveal_bid_handle_invalid_bid_if_place_bid_too_late() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, FIRST_DOMAIN_NAME);

        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, FIRST_USER_ADDRESS, 11100 * configuration::mist_per_sui(), FIRST_SECRET);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                2
            );
            let ctx = &mut ctx;
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            let coin = coin::mint_for_testing<SUI>(30000 * configuration::mist_per_sui() + BIDDING_FEE, ctx);
            let config = test_scenario::take_shared<Configuration>(scenario);

            assert!(auction::get_balance(&auction) == 0, 0);
            auction::place_bid(&mut auction, &mut suins, seal_bid, 30000 * configuration::mist_per_sui(), &mut coin, &clock, ctx);
            assert!(auction::get_balance(&auction) == 30000 * configuration::mist_per_sui(), 0);
            assert!(coin::value(&coin) == 0, 0);

            coin::burn_for_testing(coin);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let coin = test_scenario::most_recent_id_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            let config = test_scenario::take_shared<Configuration>(scenario);

            assert!(option::is_none(&coin), 0);
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                FIRST_DOMAIN_NAME,
                11100 * configuration::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                5
            );

            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);
        };
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                300,
                2
            );
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);

            withdraw(&mut auction, &mut ctx);

            assert!(auction::get_balance(&auction) == 0, 0);
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 0, 0);

            let suins = test_scenario::take_shared<SuiNS>(scenario);
            assert!(suins::balance(&suins) == START_AN_AUCTION_FEE + BIDDING_FEE, 0);

            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);

            let coin = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin) == 30000 * configuration::mist_per_sui(), 0);
            let (start_at, highest_bid, second_highest_bid, winner, is_finalized) =
                auction::get_entry(&auction, utf8(FIRST_DOMAIN_NAME));
            assert!(option::extract(&mut start_at) == START_AN_AUCTION_AT + 1, 0);
            assert!(option::extract(&mut highest_bid) == 0, 0);
            assert!(option::extract(&mut second_highest_bid) == 0, 0);
            assert!(option::extract(&mut winner) == @0x0, 0);
            assert!(option::extract(&mut is_finalized) == false, 0);
            test_scenario::return_shared(auction);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = dynamic_field::EFieldDoesNotExist)]
    fun test_reveal_bid_abort_if_use_seal_bid_of_other_people() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, FIRST_USER_ADDRESS, 1000 * configuration::mist_per_sui(), FIRST_SECRET);
        start_an_auction_util(scenario, FIRST_DOMAIN_NAME);
        place_bid_util(scenario, seal_bid, 1000 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                FIRST_DOMAIN_NAME,
                1000 * configuration::mist_per_sui(),
                FIRST_SECRET,
                SECOND_USER_ADDRESS,
                2
            );
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_reveal_bid_handle_second_highest_bid() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, FIRST_USER_ADDRESS, 3000 * configuration::mist_per_sui(), FIRST_SECRET);
        start_an_auction_util(scenario, FIRST_DOMAIN_NAME);
        place_bid_util(scenario, seal_bid, 4100 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let coin = test_scenario::most_recent_id_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(option::is_none(&coin), 0);
            let coin = test_scenario::most_recent_id_for_address<Coin<SUI>>(SECOND_USER_ADDRESS);
            assert!(option::is_none(&coin), 0);
            test_scenario::return_shared(auction);
        };

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
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
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
        };
        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, SECOND_USER_ADDRESS, 1500 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 2000 * configuration::mist_per_sui(), SECOND_USER_ADDRESS, 0, option::some(FIRST_TX_HASH), 10);
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                FIRST_DOMAIN_NAME,
                1500 * configuration::mist_per_sui(),
                FIRST_SECRET,
                SECOND_USER_ADDRESS,
                10
            );
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
        };

        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(SECOND_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);

            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            finalize_auction_util(
                scenario,
                &mut auction,
                FIRST_DOMAIN_NAME,
                SECOND_USER_ADDRESS,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD,
                10
            );
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(SECOND_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);
            let coin = test_scenario::take_from_address<Coin<SUI>>(scenario, SECOND_USER_ADDRESS);
            assert!(coin::value(&coin) == 2000 * configuration::mist_per_sui(), 0);

            test_scenario::return_to_address(SECOND_USER_ADDRESS, coin);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);

            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            finalize_auction_util(
                scenario,
                &mut auction,
                FIRST_DOMAIN_NAME,
                FIRST_USER_ADDRESS,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD,
                10
            );
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);
            let coin = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin) == 2600 * configuration::mist_per_sui(), 0);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin);
        };

        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_entry_util(&mut auction,
                FIRST_DOMAIN_NAME, START_AN_AUCTION_AT + 1, 3000 * configuration::mist_per_sui(), 1500 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, true);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_reveal_bid_handle_low_value_bid() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, FIRST_USER_ADDRESS, 3000 * configuration::mist_per_sui(), FIRST_SECRET);
        start_an_auction_util(scenario, FIRST_DOMAIN_NAME);
        place_bid_util(scenario, seal_bid, 4100 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 15);
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let coin = test_scenario::most_recent_id_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(option::is_none(&coin), 0);
            let coin = test_scenario::most_recent_id_for_address<Coin<SUI>>(SECOND_USER_ADDRESS);
            assert!(option::is_none(&coin), 0);
            test_scenario::return_shared(auction);
        };

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
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
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);
        };
        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, SECOND_USER_ADDRESS, 1500 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 2000 * configuration::mist_per_sui(), SECOND_USER_ADDRESS, 0, option::some(FIRST_TX_HASH), 10);
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                FIRST_DOMAIN_NAME,
                1500 * configuration::mist_per_sui(),
                FIRST_SECRET,
                SECOND_USER_ADDRESS,
                5
            );
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(SECOND_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);
        };
        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, THIRD_USER_ADDRESS, 1200 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 2000 * configuration::mist_per_sui(), THIRD_USER_ADDRESS, 0, option::some(SECOND_TX_HASH), 10);
        test_scenario::next_tx(scenario, THIRD_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                FIRST_DOMAIN_NAME,
                1200 * configuration::mist_per_sui(),
                FIRST_SECRET,
                THIRD_USER_ADDRESS,
                10
            );
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(THIRD_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);
        };
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_entry_util(&mut auction,
                FIRST_DOMAIN_NAME, START_AN_AUCTION_AT + 1, 3000 * configuration::mist_per_sui(), 1500 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, false);
            test_scenario::return_shared(auction);
        };

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            finalize_auction_util(
                scenario,
                &mut auction,
                FIRST_DOMAIN_NAME,
                FIRST_USER_ADDRESS,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD,
                10
            );
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);
            let coin = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin) == 2600 * configuration::mist_per_sui(), 0);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin);
        };

        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            finalize_auction_util(
                scenario,
                &mut auction,
                FIRST_DOMAIN_NAME,
                SECOND_USER_ADDRESS,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD,
                10
            );
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(SECOND_USER_ADDRESS);
            assert!(vector::length(&ids) == 2, 0);

            let first_coin = test_scenario::take_from_address<Coin<SUI>>(scenario, SECOND_USER_ADDRESS);
            assert!(coin::value(&first_coin) == 2000 * configuration::mist_per_sui(), 0);
            let second_coin = test_scenario::take_from_address<Coin<SUI>>(scenario, SECOND_USER_ADDRESS);
            assert!(coin::value(&second_coin) == 75 * configuration::mist_per_sui(), 0);

            test_scenario::return_to_address(SECOND_USER_ADDRESS, first_coin);
            test_scenario::return_to_address(SECOND_USER_ADDRESS, second_coin);
        };
        test_scenario::next_tx(scenario, THIRD_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            finalize_auction_util(
                scenario,
                &mut auction,
                FIRST_DOMAIN_NAME,
                THIRD_USER_ADDRESS,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD,
                10
            );
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, THIRD_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(THIRD_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);
            let coin = test_scenario::take_from_address<Coin<SUI>>(scenario, THIRD_USER_ADDRESS);
            assert!(coin::value(&coin) == 2000 * configuration::mist_per_sui(), 0);
            test_scenario::return_to_address(THIRD_USER_ADDRESS, coin);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_reveal_bid_handle_low_value_bid_2() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, FIRST_USER_ADDRESS, 3000 * configuration::mist_per_sui(), FIRST_SECRET);
        start_an_auction_util(scenario, FIRST_DOMAIN_NAME);
        place_bid_util(scenario, seal_bid, 4100 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 15);
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let coin = test_scenario::most_recent_id_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(option::is_none(&coin), 0);
            let coin = test_scenario::most_recent_id_for_address<Coin<SUI>>(SECOND_USER_ADDRESS);
            assert!(option::is_none(&coin), 0);
            test_scenario::return_shared(auction);
        };

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
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
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);
        };
        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, SECOND_USER_ADDRESS, 1500 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 2000 * configuration::mist_per_sui(), SECOND_USER_ADDRESS, 0, option::some(FIRST_TX_HASH), 10);
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                FIRST_DOMAIN_NAME,
                1500 * configuration::mist_per_sui(),
                FIRST_SECRET,
                SECOND_USER_ADDRESS,
                5
            );
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(SECOND_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);
        };
        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, THIRD_USER_ADDRESS, 1200 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 2000 * configuration::mist_per_sui(), THIRD_USER_ADDRESS, 0, option::some(SECOND_TX_HASH), 10);
        test_scenario::next_tx(scenario, THIRD_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                FIRST_DOMAIN_NAME,
                1200 * configuration::mist_per_sui(),
                FIRST_SECRET,
                THIRD_USER_ADDRESS,
                10
            );
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_entry_util(&mut auction,
                FIRST_DOMAIN_NAME, START_AN_AUCTION_AT + 1, 3000 * configuration::mist_per_sui(), 1500 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, false);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            finalize_auction_util(
                scenario,
                &mut auction,
                FIRST_DOMAIN_NAME,
                FIRST_USER_ADDRESS,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD,
                10
            );
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);
            let coin = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin) == 2600 * configuration::mist_per_sui(), 0);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin);
        };
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            finalize_auction_util(
                scenario,
                &mut auction,
                FIRST_DOMAIN_NAME,
                SECOND_USER_ADDRESS,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD,
                10
            );
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(SECOND_USER_ADDRESS);
            assert!(vector::length(&ids) == 2, 0);
            let first_coin = test_scenario::take_from_address<Coin<SUI>>(scenario, SECOND_USER_ADDRESS);
            assert!(coin::value(&first_coin) == 2000 * configuration::mist_per_sui(), 0);
            let second_coin = test_scenario::take_from_address<Coin<SUI>>(scenario, SECOND_USER_ADDRESS);
            assert!(coin::value(&second_coin) == 75 * configuration::mist_per_sui(), 0);
            test_scenario::return_to_address(SECOND_USER_ADDRESS, first_coin);
            test_scenario::return_to_address(SECOND_USER_ADDRESS, second_coin);
        };
        test_scenario::next_tx(scenario, THIRD_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            finalize_auction_util(
                scenario,
                &mut auction,
                FIRST_DOMAIN_NAME,
                THIRD_USER_ADDRESS,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD,
                10
            );
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, THIRD_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(THIRD_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);
            let coin = test_scenario::take_from_address<Coin<SUI>>(scenario, THIRD_USER_ADDRESS);
            assert!(coin::value(&coin) == 2000 * configuration::mist_per_sui(), 0);
            test_scenario::return_to_address(THIRD_USER_ADDRESS, coin);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EInvalidPhase)]
    fun test_finalize_bid_abort_if_too_early() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, FIRST_USER_ADDRESS, 1000 * configuration::mist_per_sui(), FIRST_SECRET);
        start_an_auction_util(scenario, FIRST_DOMAIN_NAME);
        place_bid_util(scenario, seal_bid, 1100 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                FIRST_DOMAIN_NAME,
                1000 * configuration::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                0
            );
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_entry_util(&mut auction, FIRST_DOMAIN_NAME, START_AN_AUCTION_AT + 1, 1000 * configuration::mist_per_sui(), 0, FIRST_USER_ADDRESS, false);
            finalize_auction_util(
                scenario,
                &mut auction,
                FIRST_DOMAIN_NAME,
                FIRST_USER_ADDRESS,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                10
            );
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EAlreadyFinalized)]
    fun test_finalize_bid_abort_if_being_called_twice_by_winner() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, FIRST_DOMAIN_NAME);

        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, FIRST_USER_ADDRESS, 1000 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1100 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                FIRST_DOMAIN_NAME,
                1000 * configuration::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                0
            );
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_entry_util(&mut auction, FIRST_DOMAIN_NAME, START_AN_AUCTION_AT + 1, 1000 * configuration::mist_per_sui(), 0, FIRST_USER_ADDRESS, false);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);

            finalize_auction_util(
                scenario,
                &mut auction,
                FIRST_DOMAIN_NAME,
                FIRST_USER_ADDRESS,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD,
                10
            );
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);

            let coin = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin) == 100 * configuration::mist_per_sui(), 0);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            finalize_auction_util(
                scenario,
                &mut auction,
                FIRST_DOMAIN_NAME,
                FIRST_USER_ADDRESS,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                10
            );
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_finalize_bid_handle_being_called_twice_by_non_winner() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, FIRST_DOMAIN_NAME);

        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, FIRST_USER_ADDRESS, 1000 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1100 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                FIRST_DOMAIN_NAME,
                1000 * configuration::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                0
            );
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
        };

        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, SECOND_USER_ADDRESS, 2000 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 3300 * configuration::mist_per_sui(), SECOND_USER_ADDRESS, 0, option::some(FIRST_TX_HASH), 10);
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            get_entry_util(&mut auction, FIRST_DOMAIN_NAME, START_AN_AUCTION_AT + 1, 1000 * configuration::mist_per_sui(), 0, FIRST_USER_ADDRESS, false);
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                FIRST_DOMAIN_NAME,
                2000 * configuration::mist_per_sui(),
                FIRST_SECRET,
                SECOND_USER_ADDRESS,
                0
            );
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_entry_util(&mut auction,
                FIRST_DOMAIN_NAME, START_AN_AUCTION_AT + 1, 2000 * configuration::mist_per_sui(), 1000 * configuration::mist_per_sui(), SECOND_USER_ADDRESS, false);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);

            finalize_auction_util(
                scenario,
                &mut auction,
                FIRST_DOMAIN_NAME,
                FIRST_USER_ADDRESS,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD,
                10
            );
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_entry_util(&mut auction,
                FIRST_DOMAIN_NAME, START_AN_AUCTION_AT + 1, 2000 * configuration::mist_per_sui(), 1000 * configuration::mist_per_sui(), SECOND_USER_ADDRESS, false);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(SECOND_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);

            finalize_auction_util(
                scenario,
                &mut auction,
                FIRST_DOMAIN_NAME,
                SECOND_USER_ADDRESS,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD,
                20
            );
            test_scenario::return_shared(auction);
        };

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 2, 0);

            let first_coin = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&first_coin) == 50 * configuration::mist_per_sui(), 0);
            let second_coin = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&second_coin) == 1100 * configuration::mist_per_sui(), 0);

            let ids = test_scenario::ids_for_address<Coin<SUI>>(SECOND_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);

            let coin = test_scenario::take_from_address<Coin<SUI>>(scenario, SECOND_USER_ADDRESS);
            assert!(coin::value(&coin) == 2300 * configuration::mist_per_sui(), 0);
            test_scenario::return_to_address(SECOND_USER_ADDRESS, coin);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, first_coin);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, second_coin);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            finalize_auction_util(
                scenario,
                &mut auction,
                FIRST_DOMAIN_NAME,
                FIRST_USER_ADDRESS,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                30
            );
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 2, 0);

            let first_coin = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&first_coin) == 1100 * configuration::mist_per_sui(), 0);
            let second_coin = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&second_coin) == 50 * configuration::mist_per_sui(), 0);

            let ids = test_scenario::ids_for_address<Coin<SUI>>(SECOND_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);

            let coin = test_scenario::take_from_address<Coin<SUI>>(scenario, SECOND_USER_ADDRESS);
            assert!(coin::value(&coin) == 2300 * configuration::mist_per_sui(), 0);
            test_scenario::return_to_address(SECOND_USER_ADDRESS, coin);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, first_coin);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, second_coin);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_bids_multiple_domains_and_reveal_only_one() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, FIRST_DOMAIN_NAME);
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
            assert!(suins::balance(&suins) == 2 * START_AN_AUCTION_FEE, 0);
            assert!(coin::value(&coin) == 2 * START_AN_AUCTION_FEE, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            coin::burn_for_testing(coin);
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
            let config = test_scenario::take_shared<Configuration>(scenario);
            let coin = coin::mint_for_testing<SUI>(3 * START_AN_AUCTION_FEE, ctx);

            auction::start_an_auction(&mut auction, &mut suins, utf8(THIRD_DOMAIN_NAME), &mut coin, ctx);
            assert!(suins::balance(&suins) == 3 * START_AN_AUCTION_FEE, 0);
            assert!(coin::value(&coin) == 2 * START_AN_AUCTION_FEE, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            coin::burn_for_testing(coin);
        };

        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, FIRST_USER_ADDRESS, 1000 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1300 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);
        let seal_bid = make_seal_bid(SECOND_DOMAIN_NAME, FIRST_USER_ADDRESS, 2000 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 2200 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);
        let seal_bid = make_seal_bid(THIRD_DOMAIN_NAME, FIRST_USER_ADDRESS, 3000 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 12200 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            assert!(auction::get_balance(&auction) == 15700 * configuration::mist_per_sui(), 0);

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
            assert!(mask == 2200 * configuration::mist_per_sui(), 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 2);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 12200 * configuration::mist_per_sui(), 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                SECOND_DOMAIN_NAME,
                2000 * configuration::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);

            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 3, 0);

            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            finalize_auction_util(
                scenario,
                &mut auction,
                SECOND_DOMAIN_NAME,
                FIRST_USER_ADDRESS,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD,
                10
            );
            test_scenario::return_shared(auction);
        };

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);

            let first_coin = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&first_coin) == 200 * configuration::mist_per_sui(), 0);
            assert!(auction::get_balance(&auction) == 13500 * configuration::mist_per_sui(), 0);
            assert!(
                suins::balance(&suins) == 3 * START_AN_AUCTION_FEE + 2000 * configuration::mist_per_sui() + BIDDING_FEE * 3,
                0,
            );

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, first_coin);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AN_AUCTION_AT + 200 * configuration::mist_per_sui(),
                0
            );
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 2, 0);

            withdraw(&mut auction, &mut ctx);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 0, 0);
            assert!(auction::get_balance(&auction) == 0, 0);
            assert!(
                suins::balance(&suins) == 3 * START_AN_AUCTION_FEE + 2000 * configuration::mist_per_sui() + BIDDING_FEE * 3,
                0,
            );

            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 3, 0);

            let coin1 = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin1) == 12200 * configuration::mist_per_sui(), 0);
            let coin2 = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin2) == 1300 * configuration::mist_per_sui(), 0);
            let coin3 = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin3) == 200 * configuration::mist_per_sui(), 0);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin1);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin2);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin3);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 0, 0);

            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_bids_multiple_times_same_domain_and_reveal_only_one_bid() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, FIRST_DOMAIN_NAME);

        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, FIRST_USER_ADDRESS, 1000 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1300 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 15);
        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, FIRST_USER_ADDRESS, 2000 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 12200 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 20);
        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, FIRST_USER_ADDRESS, 3000 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 10200 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 25);

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

            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
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
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AUCTION_END_AT + 200 * configuration::mist_per_sui(),
                10
            );
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 3, 0);

            withdraw(&mut auction, &mut ctx);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);
            assert!(auction::get_balance(&auction) == 10200 * configuration::mist_per_sui(), 0);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 2, 0);
            let coin1 = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin1) == 12200 * configuration::mist_per_sui(), 0);
            let coin2 = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin2) == 1300 * configuration::mist_per_sui(), 0);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin1);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin2);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);
            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 10200 * configuration::mist_per_sui(), 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(is_unsealed, 0);
            assert!(suins::balance(&suins) == START_AN_AUCTION_FEE + BIDDING_FEE * 3, 0);

            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }
}
