#[test_only]
module suins::auction_tests_2 {

    use sui::test_scenario;
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::tx_context::epoch;
    use sui::dynamic_field;
    use suins::auction::{Self, make_seal_bid, get_bids_by_bidder, get_bid_detail_fields, withdraw, state, AuctionHouse, finalize_all_auctions_by_admin};
    use suins::configuration::Configuration;
    use std::vector;
    use std::option;
    use suins::auction_tests::{test_init, start_an_auction_util, place_bid_util, reveal_bid_util, get_entry_util, finalize_auction_util, ctx_new, ctx_util};
    use suins::entity::SuiNS;
    use suins::controller;
    use suins::registry::AdminCap;

    const SUINS_ADDRESS: address = @0xA001;
    const FIRST_USER_ADDRESS: address = @0xB001;
    const SECOND_USER_ADDRESS: address = @0xB002;
    const THIRD_USER_ADDRESS: address = @0xB003;
    const RESOLVER_ADDRESS: address = @0xC001;
    const HASH: vector<u8> = b"vUAgEwNmPr";
    const NODE: vector<u8> = vector[
        97, // 'a'
        98, // 'b'
        99, // 'c'
        240, 159, 146, 150, // 1f496
        240, 159, 145, 168, // 1f468_200d_2764_fe0f_200d_1f48b_200d_1f468
        226, 128, 141,
        226, 157, 164,
        239, 184, 143,
        226, 128, 141,
        240, 159, 146, 139,
        226, 128, 141,
        240, 159, 145, 168,
    ];
    const SECOND_NODE: vector<u8> = b"suins2";
    const THIRD_NODE: vector<u8> = b"suins3";
    const NODE_SUI: vector<u8> = vector[
        97, // 'a'
        98, // 'b'
        99, // 'c'
        240, 159, 146, 150, // 1f496
        240, 159, 145, 168, // 1f468_200d_2764_fe0f_200d_1f48b_200d_1f468
        226, 128, 141,
        226, 157, 164,
        239, 184, 143,
        226, 128, 141,
        240, 159, 146, 139,
        226, 128, 141,
        240, 159, 145, 168,
        46, // .
        115, // s
        117, // u
        105, // i
    ];
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
    const EXTRA_PERIOD: u64 = 30;
    const MOVE_REGISTRAR: vector<u8> = b"move";
    const SUI_REGISTRAR: vector<u8> = b"sui";
    const DEFAULT_TX_HASH: vector<u8> = x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532";
    const FIRST_TX_HASH: vector<u8> = x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431533";
    const SECOND_TX_HASH: vector<u8> = x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431534";
    const BIDDING_FEE: u64 = 1000000000;
    const START_AN_AUCTION_FEE: u64 = 10_000_000_000;

    #[test, expected_failure(abort_code = auction::EInvalidPhase)]
    fun test_finalize_bid_abort_if_too_early() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, FIRST_SECRET);
        start_an_auction_util(scenario, NODE);
        place_bid_util(scenario, seal_bid, 1100, FIRST_USER_ADDRESS, 0, option::none());
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                1000,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                0
            );
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_entry_util(&mut auction, NODE, START_AN_AUCTION_AT + 1, 1000, 0, FIRST_USER_ADDRESS, false);
            finalize_auction_util(
                scenario,
                &mut auction,
                NODE,
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
        start_an_auction_util(scenario, NODE);

        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1100, FIRST_USER_ADDRESS, 0, option::none());
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                1000,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                0
            );
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_entry_util(&mut auction, NODE, START_AN_AUCTION_AT + 1, 1000, 0, FIRST_USER_ADDRESS, false);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);

            finalize_auction_util(
                scenario,
                &mut auction,
                NODE,
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
            assert!(coin::value(&coin) == 100, 0);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            finalize_auction_util(
                scenario,
                &mut auction,
                NODE,
                FIRST_USER_ADDRESS,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
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
        start_an_auction_util(scenario, NODE);

        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1100, FIRST_USER_ADDRESS, 0, option::none());
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                1000,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                5
            );
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
                NODE,
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
    fun test_not_yet_finalized_bid_cannot_withdraw_2() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, NODE);

        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1100, FIRST_USER_ADDRESS, 0, option::none());
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                1000,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                5
            );
            test_scenario::return_shared(auction);
        };

        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 2000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 4100, FIRST_USER_ADDRESS, 0, option::some(FIRST_TX_HASH));
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                2000,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                5
            );
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
            assert!(coin::value(&coin) == 1100, 0);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);
            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);

            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 4100, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(is_unsealed, 0);

            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_not_yet_finalized_winning_bid_cannt_be_withdrawed_after_extra_time() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, NODE);

        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1100, FIRST_USER_ADDRESS, 0, option::none());
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                1000,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                5
            );
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                EXTRA_PERIOD_START_AT + EXTRA_PERIOD + 1,
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
    fun test_not_yet_finalized_bid_can_be_withdrawed_by_non_winner() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, NODE);

        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1100, FIRST_USER_ADDRESS, 0, option::none());
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                1000,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                5
            );
            test_scenario::return_shared(auction);
        };

        let seal_bid = make_seal_bid(NODE, SECOND_USER_ADDRESS, 2000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 3100, SECOND_USER_ADDRESS, 0, option::some(FIRST_TX_HASH));
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                2000,
                FIRST_SECRET,
                SECOND_USER_ADDRESS,
                10
            );
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
            assert!(coin::value(&coin) == 1100, 0);

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
        start_an_auction_util(scenario, NODE);

        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1100, FIRST_USER_ADDRESS, 0, option::none());
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                1000,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                5
            );
            test_scenario::return_shared(auction);
        };

        let seal_bid = make_seal_bid(NODE, SECOND_USER_ADDRESS, 2000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 3100, SECOND_USER_ADDRESS, 0, option::some(FIRST_TX_HASH));
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                2000,
                FIRST_SECRET,
                SECOND_USER_ADDRESS,
                10
            );
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
            assert!(coin::value(&coin) == 1100, 0);
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
    fun test_state() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);

            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AUCTION_END_AT,
                10
            );
            assert!(state(&auction, NODE, epoch(&ctx)) == AUCTION_STATE_OPEN, 0);

            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AUCTION_END_AT + BIDDING_PERIOD,
                10
            );
            assert!(state(&auction, NODE, epoch(&ctx)) == AUCTION_STATE_OPEN, 0);


            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AUCTION_END_AT + BIDDING_PERIOD + REVEAL_PERIOD,
                10
            );
            assert!(state(&auction, NODE, epoch(&ctx)) == AUCTION_STATE_OPEN, 0);

            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AUCTION_END_AT + BIDDING_PERIOD + REVEAL_PERIOD + 1,
                10
            );
            assert!(state(&auction, NODE, epoch(&ctx)) == AUCTION_STATE_NOT_AVAILABLE, 0);

            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AUCTION_END_AT,
                10
            );
            let coin = coin::mint_for_testing<SUI>(3 * START_AN_AUCTION_FEE, &mut ctx);

            auction::start_an_auction(&mut auction, &mut suins, &config, NODE, &mut coin, &mut ctx);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            coin::burn_for_testing(coin);
        };

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);

            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AUCTION_END_AT,
                10
            );
            assert!(state(&auction, NODE, epoch(&ctx)) == AUCTION_STATE_PENDING, 0);

            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AUCTION_END_AT + 1,
                10
            );
            assert!(state(&auction, NODE, epoch(&ctx)) == AUCTION_STATE_BIDDING, 0);

            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AUCTION_END_AT + BIDDING_PERIOD,
                10
            );
            assert!(state(&auction, NODE, epoch(&ctx)) == AUCTION_STATE_BIDDING, 0);

            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AUCTION_END_AT + BIDDING_PERIOD + 1,
                10
            );
            assert!(state(&auction, NODE, epoch(&ctx)) == AUCTION_STATE_REVEAL, 0);

            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AUCTION_END_AT + BIDDING_PERIOD + REVEAL_PERIOD + 1,
                10
            );
            assert!(state(&auction, NODE, epoch(&ctx)) == AUCTION_STATE_NOT_AVAILABLE, 0);

            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = dynamic_field::EFieldDoesNotExist)]
    fun test_withdraw_abort_if_no_bid() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                300,
                2
            );
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            withdraw(&mut auction, &mut ctx);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = dynamic_field::EFieldDoesNotExist)]
    fun test_reveal_bid_abort_if_use_seal_bid_of_other_people() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, FIRST_SECRET);
        start_an_auction_util(scenario, NODE);
        place_bid_util(scenario, seal_bid, 1000, FIRST_USER_ADDRESS, 0, option::none());
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                1000,
                FIRST_SECRET,
                SECOND_USER_ADDRESS,
                2
            );
            test_scenario::return_shared(auction);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_reveal_bid_handle_second_highest_bid() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 3000, FIRST_SECRET);
        start_an_auction_util(scenario, NODE);
        place_bid_util(scenario, seal_bid, 4100, FIRST_USER_ADDRESS, 0, option::none());
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
            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                3000,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );
            test_scenario::return_shared(auction);
        };
        let seal_bid = make_seal_bid(NODE, SECOND_USER_ADDRESS, 1500, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 2000, SECOND_USER_ADDRESS, 0, option::some(FIRST_TX_HASH));
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                1500,
                FIRST_SECRET,
                SECOND_USER_ADDRESS,
                10
            );
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
                NODE,
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
            assert!(coin::value(&coin) == 2000, 0);

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
                NODE,
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
            assert!(coin::value(&coin) == 2600, 0);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin);
        };

        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_entry_util(&mut auction, NODE, START_AN_AUCTION_AT + 1, 3000, 1500, FIRST_USER_ADDRESS, true);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_not_yet_finalized_bid_cannot_be_withdrawed_2() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, NODE);

        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1100, FIRST_USER_ADDRESS, 0, option::none());
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                1000,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                5
            );
            test_scenario::return_shared(auction);
        };

        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 2000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 4100, FIRST_USER_ADDRESS, 0, option::some(FIRST_TX_HASH));
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                2000,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                5
            );
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
            assert!(coin::value(&coin) == 1100, 0);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);
            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);

            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 4100, 0);
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
        start_an_auction_util(scenario, NODE);

        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1100, FIRST_USER_ADDRESS, 0, option::none());
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                1000,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                5
            );
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
        start_an_auction_util(scenario, NODE);

        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1100, FIRST_USER_ADDRESS, 0, option::none());
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                1000,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                5
            );
            test_scenario::return_shared(auction);
        };
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 2000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 2100, FIRST_USER_ADDRESS, 0, option::some(FIRST_TX_HASH));
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                2000,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                5
            );
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
            assert!(coin::value(&coin) == 1100, 0);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);

            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_finalize_all_auctions_by_admin_works_if_not_has_winner() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, NODE);
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 10230, FIRST_USER_ADDRESS, 0, option::none());
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);

            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);

            assert!(auction::get_balance(&auction) == 10230, 0);
            assert!(controller::get_balance(&suins) == START_AN_AUCTION_FEE + BIDDING_FEE, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);

            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);

            let (start_at, highest_bid, second_highest_bid, winner, is_finalized) = auction::get_entry(&auction, NODE);
            assert!(option::extract(&mut start_at) == START_AN_AUCTION_AT + 1, 0);
            assert!(option::extract(&mut highest_bid) == 0, 0);
            assert!(option::extract(&mut second_highest_bid) == 0, 0);
            assert!(option::extract(&mut winner) == @0x0, 0);
            assert!(option::extract(&mut is_finalized) == false, 0);

            get_entry_util(&mut auction, NODE, START_AN_AUCTION_AT + 1, 0, 0, @0x0, false);
            finalize_all_auctions_by_admin(
                &admin_cap,
                &mut auction,
                &mut suins,
                &config,
                RESOLVER_ADDRESS,
                &mut ctx_util(FIRST_USER_ADDRESS, EXTRA_PERIOD_START_AT, 20),
            );
            get_entry_util(&mut auction, NODE, START_AN_AUCTION_AT + 1, 0, 0, @0x0, false);

            test_scenario::return_shared(auction);
            test_scenario::return_to_sender(scenario, admin_cap);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);

            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);

            assert!(auction::get_balance(&auction) == 10230, 0);
            assert!(controller::get_balance(&suins) == START_AN_AUCTION_FEE + BIDDING_FEE, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EAuctionNotAvailable)]
    fun test_finalize_all_auctions_by_admin_aborts_if_too_early() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, NODE);

        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);

            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);

            finalize_all_auctions_by_admin(
                &admin_cap,
                &mut auction,
                &mut suins,
                &config,
                RESOLVER_ADDRESS,
                &mut ctx_util(FIRST_USER_ADDRESS, START_AN_AUCTION_AT + 1, 20),
            );

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_to_sender(scenario, admin_cap);
            test_scenario::return_shared(config);
        };
        test_scenario::end(scenario_val);
    }
}
