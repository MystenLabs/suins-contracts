#[test_only]
module suins::auction_tests_2 {
    use std::vector;
    use std::option;
    use std::string::utf8;

    use sui::test_scenario;
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::tx_context::epoch;
    use sui::dynamic_field;

    use suins::auction::{Self, make_seal_bid, get_bids_by_bidder, get_bid_detail_fields, withdraw, state, AuctionHouse, finalize_all_auctions_by_admin};
    use suins::auction_tests::{test_init, start_an_auction_util, place_bid_util, reveal_bid_util, get_entry_util, finalize_auction_util, ctx_new, ctx_util, get_bid_util, state_util};
    use suins::suins::SuiNS;
    use suins::suins::{Self, AdminCap};
    use suins::registrar;
    use suins::registrar::RegistrationNFT;

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
    const BIDDING_FEE: u64 = 1000000000;
    const START_AN_AUCTION_FEE: u64 = 10_000_000_000;
    const EXTRA_PERIOD_END_AT: u64 = 232;

    #[test, expected_failure(abort_code = auction::EInvalidPhase)]
    fun test_finalize_bid_abort_if_too_early() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, FIRST_USER_ADDRESS, 1000 * suins::constants::mist_per_sui(), FIRST_SECRET);
        start_an_auction_util(scenario, FIRST_DOMAIN_NAME);
        place_bid_util(scenario, seal_bid, 1100 * suins::constants::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            reveal_bid_util(
                &mut auction,
                &suins,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                FIRST_DOMAIN_NAME,
                1000 * suins::constants::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                0
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_entry_util(&mut auction, FIRST_DOMAIN_NAME, START_AN_AUCTION_AT + 1, 1000 * suins::constants::mist_per_sui(), 0, FIRST_USER_ADDRESS, false);
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

        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, FIRST_USER_ADDRESS, 1000 * suins::constants::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1100 * suins::constants::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            reveal_bid_util(
                &mut auction,
                &suins,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                FIRST_DOMAIN_NAME,
                1000 * suins::constants::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                0
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_entry_util(&mut auction, FIRST_DOMAIN_NAME, START_AN_AUCTION_AT + 1, 1000 * suins::constants::mist_per_sui(), 0, FIRST_USER_ADDRESS, false);
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
            assert!(coin::value(&coin) == 100 * suins::constants::mist_per_sui(), 0);
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
    fun test_not_yet_finalized_bid_cannot_be_withdrawed() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, FIRST_DOMAIN_NAME);

        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, FIRST_USER_ADDRESS, 1000 * suins::constants::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1100 * suins::constants::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            reveal_bid_util(
                &mut auction,
                &suins,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                FIRST_DOMAIN_NAME,
                1000 * suins::constants::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                5
            );
            test_scenario::return_shared(suins);
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
    fun test_not_yet_finalized_bid_cannot_withdraw_2() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, FIRST_DOMAIN_NAME);

        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, FIRST_USER_ADDRESS, 1000 * suins::constants::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1100 * suins::constants::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            reveal_bid_util(
                &mut auction,
                &suins,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                FIRST_DOMAIN_NAME,
                1000 * suins::constants::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                5
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };

        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, FIRST_USER_ADDRESS, 2000 * suins::constants::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 4100 * suins::constants::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::some(FIRST_TX_HASH), 10);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            reveal_bid_util(
                &mut auction,
                &suins,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                FIRST_DOMAIN_NAME,
                2000 * suins::constants::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                5
            );
            test_scenario::return_shared(suins);
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
            assert!(coin::value(&coin) == 1100 * suins::constants::mist_per_sui(), 0);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);
            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);

            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 4100 * suins::constants::mist_per_sui(), 0);
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
        start_an_auction_util(scenario, FIRST_DOMAIN_NAME);

        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, FIRST_USER_ADDRESS, 1000 * suins::constants::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1100 * suins::constants::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            reveal_bid_util(
                &mut auction,
                &suins,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                FIRST_DOMAIN_NAME,
                1000 * suins::constants::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                5
            );
            test_scenario::return_shared(suins);
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
        start_an_auction_util(scenario, FIRST_DOMAIN_NAME);

        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, FIRST_USER_ADDRESS, 1000 * suins::constants::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1100 * suins::constants::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            reveal_bid_util(
                &mut auction,
                &suins,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                FIRST_DOMAIN_NAME,
                1000 * suins::constants::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                5
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };

        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, SECOND_USER_ADDRESS, 2000 * suins::constants::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 3100 * suins::constants::mist_per_sui(), SECOND_USER_ADDRESS, 0, option::some(FIRST_TX_HASH), 10);
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            reveal_bid_util(
                &mut auction,
                &suins,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                FIRST_DOMAIN_NAME,
                2000 * suins::constants::mist_per_sui(),
                FIRST_SECRET,
                SECOND_USER_ADDRESS,
                10
            );
            test_scenario::return_shared(suins);
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
            assert!(coin::value(&coin) == 1100 * suins::constants::mist_per_sui(), 0);

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

        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, FIRST_USER_ADDRESS, 1000 * suins::constants::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1100 * suins::constants::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            reveal_bid_util(
                &mut auction,
                &suins,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                FIRST_DOMAIN_NAME,
                1000 * suins::constants::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                5
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };

        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, SECOND_USER_ADDRESS, 2000 * suins::constants::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 3100 * suins::constants::mist_per_sui(), SECOND_USER_ADDRESS, 0, option::some(FIRST_TX_HASH), 10);
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            reveal_bid_util(
                &mut auction,
                &suins,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                FIRST_DOMAIN_NAME,
                2000 * suins::constants::mist_per_sui(),
                FIRST_SECRET,
                SECOND_USER_ADDRESS,
                10
            );
            test_scenario::return_shared(suins);
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
            assert!(coin::value(&coin) == 1100 * suins::constants::mist_per_sui(), 0);
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
            assert!(state(&auction, utf8(FIRST_DOMAIN_NAME), epoch(&ctx)) == AUCTION_STATE_OPEN, 0);

            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AUCTION_END_AT + BIDDING_PERIOD,
                10
            );
            assert!(state(&auction, utf8(FIRST_DOMAIN_NAME), epoch(&ctx)) == AUCTION_STATE_OPEN, 0);


            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AUCTION_END_AT + BIDDING_PERIOD + REVEAL_PERIOD,
                10
            );
            assert!(state(&auction, utf8(FIRST_DOMAIN_NAME), epoch(&ctx)) == AUCTION_STATE_OPEN, 0);

            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AUCTION_END_AT + BIDDING_PERIOD + REVEAL_PERIOD + 1,
                10
            );
            assert!(state(&auction, utf8(FIRST_DOMAIN_NAME), epoch(&ctx)) == AUCTION_STATE_NOT_AVAILABLE, 0);

            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AUCTION_END_AT,
                10
            );
            let coin = coin::mint_for_testing<SUI>(3 * START_AN_AUCTION_FEE, &mut ctx);

            auction::start_an_auction(&mut auction, &mut suins, utf8(FIRST_DOMAIN_NAME), &mut coin, &mut ctx);

            test_scenario::return_shared(auction);
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
            assert!(state(&auction, utf8(FIRST_DOMAIN_NAME), epoch(&ctx)) == AUCTION_STATE_PENDING, 0);

            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AUCTION_END_AT + 1,
                10
            );
            assert!(state(&auction, utf8(FIRST_DOMAIN_NAME), epoch(&ctx)) == AUCTION_STATE_BIDDING, 0);

            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AUCTION_END_AT + BIDDING_PERIOD,
                10
            );
            assert!(state(&auction, utf8(FIRST_DOMAIN_NAME), epoch(&ctx)) == AUCTION_STATE_BIDDING, 0);

            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AUCTION_END_AT + BIDDING_PERIOD + 1,
                10
            );
            assert!(state(&auction, utf8(FIRST_DOMAIN_NAME), epoch(&ctx)) == AUCTION_STATE_REVEAL, 0);

            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AUCTION_END_AT + BIDDING_PERIOD + REVEAL_PERIOD + 1,
                10
            );
            assert!(state(&auction, utf8(FIRST_DOMAIN_NAME), epoch(&ctx)) == AUCTION_STATE_NOT_AVAILABLE, 0);

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
        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, FIRST_USER_ADDRESS, 1000 * suins::constants::mist_per_sui(), FIRST_SECRET);
        start_an_auction_util(scenario, FIRST_DOMAIN_NAME);
        place_bid_util(scenario, seal_bid, 1000 * suins::constants::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            reveal_bid_util(
                &mut auction,
                &suins,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                FIRST_DOMAIN_NAME,
                1000 * suins::constants::mist_per_sui(),
                FIRST_SECRET,
                SECOND_USER_ADDRESS,
                2
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_not_yet_finalized_bid_cannot_be_withdrawed_2() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, FIRST_DOMAIN_NAME);

        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, FIRST_USER_ADDRESS, 1000 * suins::constants::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1100 * suins::constants::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            reveal_bid_util(
                &mut auction,
                &suins,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                FIRST_DOMAIN_NAME,
                1000 * suins::constants::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                5
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };

        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, FIRST_USER_ADDRESS, 2000 * suins::constants::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 4100 * suins::constants::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::some(FIRST_TX_HASH), 10);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            reveal_bid_util(
                &mut auction,
                &suins,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                FIRST_DOMAIN_NAME,
                2000 * suins::constants::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                5
            );
            test_scenario::return_shared(suins);
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
            assert!(coin::value(&coin) == 1100 * suins::constants::mist_per_sui(), 0);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);
            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);

            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 4100 * suins::constants::mist_per_sui(), 0);
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

        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, FIRST_USER_ADDRESS, 1000 * suins::constants::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1100 * suins::constants::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            reveal_bid_util(
                &mut auction,
                &suins,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                FIRST_DOMAIN_NAME,
                1000 * suins::constants::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                5
            );
            test_scenario::return_shared(suins);
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

        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, FIRST_USER_ADDRESS, 1000 * suins::constants::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1100 * suins::constants::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            reveal_bid_util(
                &mut auction,
                &suins,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                FIRST_DOMAIN_NAME,
                1000 * suins::constants::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                5
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, FIRST_USER_ADDRESS, 2000 * suins::constants::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 2100 * suins::constants::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::some(FIRST_TX_HASH), 10);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            reveal_bid_util(
                &mut auction,
                &suins,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                FIRST_DOMAIN_NAME,
                2000 * suins::constants::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                5
            );
            test_scenario::return_shared(suins);
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
            assert!(coin::value(&coin) == 1100 * suins::constants::mist_per_sui(), 0);

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
        start_an_auction_util(scenario, FIRST_DOMAIN_NAME);
        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, FIRST_USER_ADDRESS, 1000 * suins::constants::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 10230 * suins::constants::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);

            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);

            assert!(auction::get_balance(&auction) == 10230 * suins::constants::mist_per_sui(), 0);
            assert!(suins::balance(&suins) == START_AN_AUCTION_FEE + BIDDING_FEE, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);

            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);

            let (start_at, highest_bid, second_highest_bid, winner, is_finalized) = auction::get_entry(&auction,
                utf8(FIRST_DOMAIN_NAME)
            );
            assert!(option::extract(&mut start_at) == START_AN_AUCTION_AT + 1, 0);
            assert!(option::extract(&mut highest_bid) == 0, 0);
            assert!(option::extract(&mut second_highest_bid) == 0, 0);
            assert!(option::extract(&mut winner) == @0x0, 0);
            assert!(option::extract(&mut is_finalized) == false, 0);

            get_entry_util(&mut auction, FIRST_DOMAIN_NAME, START_AN_AUCTION_AT + 1, 0, 0, @0x0, false);
            finalize_all_auctions_by_admin(
                &admin_cap,
                &mut auction,
                &mut suins,
                &mut ctx_util(FIRST_USER_ADDRESS, EXTRA_PERIOD_START_AT, 20),
            );
            get_entry_util(&mut auction, FIRST_DOMAIN_NAME, START_AN_AUCTION_AT + 1, 0, 0, @0x0, false);

            test_scenario::return_shared(auction);
            test_scenario::return_to_sender(scenario, admin_cap);
            test_scenario::return_shared(suins);

        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);

            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);

            assert!(auction::get_balance(&auction) == 10230 * suins::constants::mist_per_sui(), 0);
            assert!(suins::balance(&suins) == START_AN_AUCTION_FEE + BIDDING_FEE, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EInvalidPhase)]
    fun test_finalize_all_auctions_by_admin_aborts_if_too_early() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, FIRST_DOMAIN_NAME);

        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);

            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);

            finalize_all_auctions_by_admin(
                &admin_cap,
                &mut auction,
                &mut suins,
                &mut ctx_util(FIRST_USER_ADDRESS, START_AN_AUCTION_AT + 1, 20),
            );

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_to_sender(scenario, admin_cap);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_finalize_all_auctions_by_admin_after_extra_period_with_no_bid() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, FIRST_DOMAIN_NAME);
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);

            get_entry_util(&mut auction, FIRST_DOMAIN_NAME, START_AN_AUCTION_AT + 1, 0, 0, @0x0, false);
            auction::finalize_all_auctions_by_admin(
                &admin_cap,
                &mut auction,
                &mut suins,
                &mut ctx_util(FIRST_USER_ADDRESS, EXTRA_PERIOD_END_AT + 1, 20),
            );
            get_entry_util(&mut auction, FIRST_DOMAIN_NAME, START_AN_AUCTION_AT + 1, 0, 0, @0x0, false);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);

            test_scenario::return_to_sender(scenario, admin_cap);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);
            assert!(!test_scenario::has_most_recent_for_address<RegistrationNFT>(FIRST_USER_ADDRESS), 0);

            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);

            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_DOMAIN_NAME), 0);
            assert!(!suins::has_name_record(&suins, utf8(FIRST_DOMAIN_NAME_SUI)), 0);

            assert!(suins::balance(&suins) == START_AN_AUCTION_FEE, 0);
            assert!(auction::get_balance(&auction) == 0, 0);

            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_finalize_all_auctions_by_admin_after_extra_period_with_1_unrealved_bid() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, FIRST_DOMAIN_NAME);
        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, FIRST_USER_ADDRESS, 1000 * suins::constants::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 10230 * suins::constants::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);

            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);

            get_entry_util(&mut auction, FIRST_DOMAIN_NAME, START_AN_AUCTION_AT + 1, 0, 0, @0x0, false);
            auction::finalize_all_auctions_by_admin(
                &admin_cap,
                &mut auction,
                &mut suins,
                &mut ctx_util(FIRST_USER_ADDRESS, EXTRA_PERIOD_END_AT + 1, 20),
            );
            get_entry_util(&mut auction, FIRST_DOMAIN_NAME, START_AN_AUCTION_AT + 1, 0, 0, @0x0, false);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);

            test_scenario::return_to_sender(scenario, admin_cap);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);
            assert!(!test_scenario::has_most_recent_for_address<RegistrationNFT>(FIRST_USER_ADDRESS), 0);

            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_DOMAIN_NAME), 0);
            assert!(!suins::has_name_record(&suins, utf8(FIRST_DOMAIN_NAME_SUI)), 0);

            assert!(suins::balance(&suins) == START_AN_AUCTION_FEE + BIDDING_FEE, 0);
            assert!(auction::get_balance(&auction) == 10230 * suins::constants::mist_per_sui(), 0);

            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_finalize_all_auctions_by_admin_after_extra_period_with_2_winning_auction() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, FIRST_DOMAIN_NAME);
        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, FIRST_USER_ADDRESS, 1000 * suins::constants::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 10230 * suins::constants::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);

            get_bid_util(&auction, seal_bid, FIRST_USER_ADDRESS, option::some(10230 * suins::constants::mist_per_sui()));
            reveal_bid_util(
                &mut auction,
                &suins,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                FIRST_DOMAIN_NAME,
                1000 * suins::constants::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );
            assert!(auction::get_balance(&auction) == 10230 * suins::constants::mist_per_sui(), 0);
            assert!(suins::balance(&suins) == BIDDING_FEE + START_AN_AUCTION_FEE, 0);

            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let ctx = ctx_new(
                SECOND_USER_ADDRESS,
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
        let seal_bid = make_seal_bid(SECOND_DOMAIN_NAME, SECOND_USER_ADDRESS, 2000 * suins::constants::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 3000 * suins::constants::mist_per_sui(), SECOND_USER_ADDRESS, 0, option::none(), 15);
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);

            get_bid_util(&auction, seal_bid, SECOND_USER_ADDRESS, option::some(3000 * suins::constants::mist_per_sui()));
            reveal_bid_util(
                &mut auction,
                &suins,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                SECOND_DOMAIN_NAME,
                2000 * suins::constants::mist_per_sui(),
                FIRST_SECRET,
                SECOND_USER_ADDRESS,
                2
            );
            assert!(auction::get_balance(&auction) == 13230 * suins::constants::mist_per_sui(), 0);
            assert!(suins::balance(&suins) == BIDDING_FEE * 2 + START_AN_AUCTION_FEE * 2, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);

        };
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(SECOND_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);

            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);

            get_entry_util(&mut auction, FIRST_DOMAIN_NAME, START_AN_AUCTION_AT + 1, 1000 * suins::constants::mist_per_sui(), 0, FIRST_USER_ADDRESS, false);
            get_entry_util(&mut auction, SECOND_DOMAIN_NAME, START_AN_AUCTION_AT + 1, 2000 * suins::constants::mist_per_sui(), 0, SECOND_USER_ADDRESS, false);
            auction::finalize_all_auctions_by_admin(
                &admin_cap,
                &mut auction,
                &mut suins,
                &mut ctx_util(FIRST_USER_ADDRESS, EXTRA_PERIOD_END_AT + 1, 20),
            );
            get_entry_util(&mut auction, FIRST_DOMAIN_NAME, START_AN_AUCTION_AT + 1, 1000 * suins::constants::mist_per_sui(), 0, FIRST_USER_ADDRESS, true);
            get_entry_util(&mut auction, SECOND_DOMAIN_NAME, START_AN_AUCTION_AT + 1, 2000 * suins::constants::mist_per_sui(), 0, SECOND_USER_ADDRESS, true);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);

            test_scenario::return_to_sender(scenario, admin_cap);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);
            let coin = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin) == 9230 * suins::constants::mist_per_sui(), 0);
            assert!(!test_scenario::has_most_recent_for_address<RegistrationNFT>(FIRST_USER_ADDRESS), 0);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin);

            let ids = test_scenario::ids_for_address<Coin<SUI>>(SECOND_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);
            let coin = test_scenario::take_from_address<Coin<SUI>>(scenario, SECOND_USER_ADDRESS);
            assert!(coin::value(&coin) == 1000 * suins::constants::mist_per_sui(), 0);
            assert!(!test_scenario::has_most_recent_for_address<RegistrationNFT>(FIRST_USER_ADDRESS), 0);
            test_scenario::return_to_address(SECOND_USER_ADDRESS, coin);

            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);

            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_DOMAIN_NAME), 0);
            assert!(!suins::has_name_record(&suins, utf8(FIRST_DOMAIN_NAME_SUI)), 0);
            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, SECOND_DOMAIN_NAME), 0);
            assert!(!suins::has_name_record(&suins, utf8(SECOND_DOMAIN_NAME_SUI)), 0);

            assert!(suins::balance(&suins) == BIDDING_FEE * 2 + START_AN_AUCTION_FEE * 2 + 3000 * suins::constants::mist_per_sui(), 0);
            assert!(auction::get_balance(&auction) == 0, 0);

            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_finalize_all_auctions_by_admin_after_extra_period_with_no_auction() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            auction::finalize_all_auctions_by_admin(
                &admin_cap,
                &mut auction,
                &mut suins,
                &mut ctx_util(FIRST_USER_ADDRESS, EXTRA_PERIOD_END_AT, 20),
            );
            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);

            test_scenario::return_to_sender(scenario, admin_cap);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);

            assert!(suins::balance(&suins) == 0, 0);
            assert!(auction::get_balance(&auction) == 0, 0);

            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);

            assert!(suins::balance(&suins) == 0, 0);
            assert!(auction::get_balance(&auction) == 0, 0);

            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_reveal_bid_handle_invalid_bid_if_actual_value_less_than_min_allowed_value() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, FIRST_DOMAIN_NAME);

        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, FIRST_USER_ADDRESS, suins::constants::mist_per_sui() - 1, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1300 * suins::constants::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let coin = test_scenario::most_recent_id_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            let suins = test_scenario::take_shared<SuiNS>(scenario);

            assert!(option::is_none(&coin), 0);
            assert!(auction::get_balance(&auction) == 1300 * suins::constants::mist_per_sui(), 0);
            reveal_bid_util(
                &mut auction,
                &suins,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                FIRST_DOMAIN_NAME,
                suins::constants::mist_per_sui() - 1,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);

            assert!(vector::length(&ids) == 0, 0);
            get_entry_util(&mut auction, FIRST_DOMAIN_NAME, START_AN_AUCTION_AT + 1, 0, 0, @0x0, false);

            test_scenario::return_shared(auction);
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
            assert!(coin::value(&coin) == 1300 * suins::constants::mist_per_sui(), 0);

            let suins = test_scenario::take_shared<SuiNS>(scenario);
            assert!(suins::balance(&suins) == START_AN_AUCTION_FEE + BIDDING_FEE, 0);

            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin);
        };
        test_scenario::end(scenario_val);
    }


    #[test]
    fun test_finalized_entry_has_state_of_owned() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, FIRST_DOMAIN_NAME);
        let seal_bid = make_seal_bid(FIRST_DOMAIN_NAME, FIRST_USER_ADDRESS, 1000 * suins::constants::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1300 * suins::constants::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);

            assert!(auction::get_balance(&auction) == 1300 * suins::constants::mist_per_sui(), 0);
            reveal_bid_util(
                &mut auction,
                &suins,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                FIRST_DOMAIN_NAME,
                1000 * suins::constants::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );

            test_scenario::return_shared(suins);
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
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);

            assert!(
                state_util(
                    &auction,
                    FIRST_DOMAIN_NAME,
                    START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD
                ) == AUCTION_STATE_OWNED,
                0
            );
            assert!(auction::get_balance(&auction) == 0, 0);
            assert!(
                suins::balance(&suins) == START_AN_AUCTION_FEE + 1000 * suins::constants::mist_per_sui() + BIDDING_FEE,
                0
            );

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario_val);
    }
}
