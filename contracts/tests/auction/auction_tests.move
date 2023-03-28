#[test_only]
module suins::auction_tests {

    use sui::test_scenario::{Self, Scenario, ctx};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::tx_context::{Self, TxContext};
    use suins::auction::{
        Self,
        make_seal_bid,
        get_seal_bid_by_bidder,
        finalize_auction,
        get_bids_by_bidder,
        get_bid_detail_fields,
        withdraw,
        state,
        AuctionHouse,
    };
    use suins::registry::{Self, AdminCap};
    use suins::registrar;
    use suins::configuration::{Self, Configuration};
    use suins::entity::{Self, SuiNS};
    use suins::emoji;
    use std::vector;
    use std::option::{Self, Option, some, is_some};
    use suins::controller;

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

    public fun test_init(): Scenario {
        let scenario = test_scenario::begin(SUINS_ADDRESS);
        {
            let ctx = ctx(&mut scenario);
            auction::test_init(ctx);
            registry::test_init(ctx);
            configuration::test_init(ctx);
            entity::test_init(ctx);
        };
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let auction = test_scenario::take_shared<AuctionHouse>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            registrar::new_tld(&admin_cap, &mut suins, MOVE_REGISTRAR, test_scenario::ctx(&mut scenario));
            registrar::new_tld(&admin_cap, &mut suins, SUI_REGISTRAR, test_scenario::ctx(&mut scenario));

            auction::configure_auction(
                &admin_cap,
                &mut auction,
                &mut suins,
                START_AUCTION_START_AT,
                START_AUCTION_END_AT,
                ctx(&mut scenario)
            );

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_to_sender(&mut scenario, admin_cap);
        };
        scenario
    }

    public fun start_an_auction_util(scenario: &mut Scenario, node: vector<u8>) {
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
            let (start_at, highest_bid, second_highest_bid, winner, is_finalized) = auction::get_entry(&auction, node);
            assert!(option::is_none(&start_at), 0);
            assert!(option::is_none(&highest_bid), 0);
            assert!(option::is_none(&second_highest_bid), 0);
            assert!(option::is_none(&winner), 0);
            assert!(option::is_none(&is_finalized), 0);
            assert!(state_util(&auction, node, 10) == AUCTION_STATE_NOT_AVAILABLE, 0);
            assert!(state_util(&auction, node, START_AN_AUCTION_AT) == AUCTION_STATE_OPEN, 0);

            let coin = coin::mint_for_testing<SUI>(30000, ctx);
            auction::start_an_auction(&mut auction, &mut suins, &config, node, &mut coin, ctx);

            assert!(controller::get_balance(&suins) == 10000, 0);
            assert!(coin::value(&coin) == 20000, 0);
            assert!(state_util(&auction, node, START_AN_AUCTION_AT) == AUCTION_STATE_PENDING, 0);
            assert!(state_util(&auction, node, START_AN_AUCTION_AT + 1) == AUCTION_STATE_BIDDING, 0);
            assert!(state_util(&auction, node, START_AN_AUCTION_AT + 1 + BIDDING_PERIOD) == AUCTION_STATE_REVEAL, 0);

            // receive no bid
            let state = state_util(
                &auction,
                node,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD
            );
            assert!(state == AUCTION_STATE_REOPENED || state == AUCTION_STATE_NOT_AVAILABLE, 0);
            let (start_at, highest_bid, second_highest_bid, winner, is_finalized) = auction::get_entry(&auction, node);
            assert!(option::extract(&mut start_at) == START_AN_AUCTION_AT + 1, 0);
            assert!(option::extract(&mut highest_bid) == 0, 0);
            assert!(option::extract(&mut second_highest_bid) == 0, 0);
            assert!(option::extract(&mut winner) == @0x0, 0);
            assert!(option::extract(&mut is_finalized) == false, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            coin::destroy_for_testing(coin);
        };
    }

    public fun reveal_bid_util(
        auction: &mut AuctionHouse,
        epoch: u64,
        node: vector<u8>,
        value: u64,
        salt: vector<u8>,
        sender: address,
        ids_created: u64
    ) {
        let ctx = ctx_new(
            sender,
            x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
            epoch,
            ids_created
        );
        auction::reveal_bid(auction, node, value, salt, &mut ctx);
    }

    public fun get_bid_util(auction: &AuctionHouse, seal_bid: vector<u8>, bidder: address, expected_value: Option<u64>) {
        let value = get_seal_bid_by_bidder(auction, seal_bid, bidder);
        if (is_some(&expected_value))
            assert!(option::extract(&mut value) == option::extract(&mut expected_value), 0)
        else
            assert!(option::is_none(&value), 0);
    }

    public fun ctx_new(
        sender: address,
        tx_hash: vector<u8>,
        epoch: u64,
        ids_created: u64,
    ): TxContext {
        tx_context::new(sender, tx_hash, epoch, 0, ids_created)
    }

    public fun get_entry_util(
        auction: &AuctionHouse,
        node: vector<u8>,
        expected_start_at: u64,
        expected_highest_bid: u64,
        expected_second_highest_bid: u64,
        expected_winner: address,
        expected_is_finalized: bool,
    ) {
        let (start_at, highest_bid, second_highest_bid, winner, is_finalized) = auction::get_entry(auction, node);
        assert!(option::extract(&mut start_at) == expected_start_at, 0);
        assert!(option::extract(&mut highest_bid) == expected_highest_bid, 0);
        assert!(option::extract(&mut second_highest_bid) == expected_second_highest_bid, 0);
        assert!(option::extract(&mut winner) == expected_winner, 0);
        assert!(option::extract(&mut is_finalized) == expected_is_finalized, 0);
    }

    public fun finalize_auction_util(
        scenario: &mut Scenario,
        auction: &mut AuctionHouse,
        node: vector<u8>,
        sender: address,
        epoch: u64,
        ids: u64,
    ) {
        let ctx = ctx_new(
            sender,
            x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
            epoch,
            ids
        );
        let suins = test_scenario::take_shared<SuiNS>(scenario);
        let config = test_scenario::take_shared<Configuration>(scenario);
        finalize_auction(auction, &mut suins, &config, node, RESOLVER_ADDRESS, &mut ctx);
        test_scenario::return_shared(suins);
        test_scenario::return_shared(config);
    }

    public fun state_util(auction: &AuctionHouse, node: vector<u8>, epoch: u64): u8 {
        let ctx = ctx_new(
            SUINS_ADDRESS,
            x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
            epoch,
            10
        );
        state(auction, node, tx_context::epoch(&ctx))
    }

    public fun place_bid_util(
        scenario: &mut Scenario,
        seal_bid: vector<u8>,
        value: u64,
        bidder: address,
        tx_hash: Option<vector<u8>>,
    ) {
        test_scenario::next_tx(scenario, bidder);
        {
            let hash;
            if (option::is_some(&tx_hash)) hash = option::extract(&mut tx_hash)
            else hash = DEFAULT_TX_HASH;

            let ctx = ctx_new(
                bidder,
                hash,
                START_AN_AUCTION_AT + 1,
                15
            );
            let ctx = &mut ctx;
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let coin = coin::mint_for_testing<SUI>(30000, ctx);
            let amount = auction::get_seal_bid_by_bidder(&auction, seal_bid, bidder);
            assert!(option::is_none(&amount), 0);

            auction::place_bid(&mut auction, seal_bid, value, &mut coin, ctx);

            let amount = auction::get_seal_bid_by_bidder(&auction, seal_bid, bidder);
            assert!(option::extract(&mut amount) == value, 0);
            assert!(coin::value(&coin) == 30000 - value, 0);
            coin::burn_for_testing(coin);
            test_scenario::return_shared(auction);
        };
    }

    public fun ctx_util(sender: address, epoch: u64, ids_created: u64): TxContext {
        ctx_new(
            sender,
            x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
            epoch,
            ids_created,
        )
    }

    #[test]
    fun test_place_bid() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            place_bid_util(scenario, HASH, 1000, FIRST_USER_ADDRESS, option::none());
        };
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);

            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);

            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 1000, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);
            assert!(auction::get_balance(&auction) == 1000, 0);

            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            place_bid_util(scenario, NODE, 1200, FIRST_USER_ADDRESS, option::none());
        };
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 2, 0);

            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 1000, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 1);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 1200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);
            assert!(auction::get_balance(&auction) == 2200, 0);

            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            place_bid_util(scenario, b"bidbid", 12200, FIRST_USER_ADDRESS, option::none());
        };
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 3, 0);

            let bid_detail = vector::borrow(&bids, 1);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 1200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 2);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 12200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);
            assert!(auction::get_balance(&auction) == 14400, 0);

            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EInvalidBid)]
    fun test_place_bid_abort_if_value_less_than_min_allowed_value() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                100,
                0
            );
            let ctx = &mut ctx;
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let coin = coin::mint_for_testing<SUI>(1000, ctx);
            auction::place_bid(&mut auction, HASH, 100, &mut coin, ctx);
            place_bid_util(scenario, HASH, 100, FIRST_USER_ADDRESS, option::none());
            coin::burn_for_testing(coin);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EBidExisted)]
    fun test_place_bid_abort_if_submit_same_hash_again() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        let ctx = ctx_new(
            FIRST_USER_ADDRESS,
            x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
            100,
            0
        );
        let ctx = &mut ctx;
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let coin = coin::mint_for_testing<SUI>(10000, ctx);
            auction::place_bid(&mut auction, HASH, 1000, &mut coin, ctx);
            coin::burn_for_testing(coin);
            test_scenario::return_shared(auction);
        };

        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let coin = coin::mint_for_testing<SUI>(10000, ctx(scenario));
            assert!(auction::get_balance(&auction) == 1000, 0);

            auction::place_bid(&mut auction, HASH, 1000, &mut coin, ctx);
            coin::burn_for_testing(coin);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EAuctionNotAvailable)]
    fun test_place_bid_abort_if_too_early() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                1,
                0
            );
            let ctx = &mut ctx;
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let coin = coin::mint_for_testing<SUI>(10000, ctx);
            auction::place_bid(&mut auction, HASH, 1000, &mut coin, ctx);
            coin::burn_for_testing(coin);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EAuctionNotAvailable)]
    fun test_place_bid_aborts_if_too_late() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                300,
                0
            );
            let ctx = &mut ctx;
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let coin = coin::mint_for_testing<SUI>(10000, ctx);
            auction::place_bid(&mut auction, HASH, 1000, &mut coin, ctx);
            coin::burn_for_testing(coin);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EAuctionNotAvailable)]
    fun test_place_bid_abort_if_too_late_2() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AUCTION_END_AT + BIDDING_PERIOD + 1,
                0
            );
            let ctx = &mut ctx;
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let coin = coin::mint_for_testing<SUI>(10000, ctx);
            auction::place_bid(&mut auction, HASH, 1000, &mut coin, ctx);
            coin::burn_for_testing(coin);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_place_bid_works_if_on_time() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AUCTION_END_AT,
                10
            );
            let ctx = &mut ctx;
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let coin = coin::mint_for_testing<SUI>(30000, ctx);

            assert!(auction::get_balance(&auction) == 0, 0);
            auction::start_an_auction(&mut auction, &mut suins, &config, NODE, &mut coin, ctx);
            assert!(auction::get_balance(&auction) == 0, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            coin::destroy_for_testing(coin);
        };

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AUCTION_END_AT + BIDDING_PERIOD,
                0
            );
            let ctx = &mut ctx;
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let coin = coin::mint_for_testing<SUI>(10000, ctx);

            assert!(auction::get_balance(&auction) == 0, 0);

            auction::place_bid(&mut auction, HASH, 1000, &mut coin, ctx);
            coin::burn_for_testing(coin);
            test_scenario::return_shared(auction);
        };

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);

            assert!(controller::get_balance(&suins) == 10000, 0);
            assert!(auction::get_balance(&auction) == 1000, 0);

            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_start_an_auction() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);

            assert!(auction::get_balance(&auction) == 0, 0);
            assert!(controller::get_balance(&suins) == 0, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
        };
        start_an_auction_util(scenario, NODE);

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);

            assert!(auction::get_balance(&auction) == 0, 0);
            assert!(controller::get_balance(&suins) == 10000, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EAuctionNotAvailable)]
    fun test_start_an_auction_aborts_if_too_early() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AUCTION_START_AT - 1,
                0
            );
            let ctx = &mut ctx;
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let coin = coin::mint_for_testing<SUI>(30000, ctx);

            auction::start_an_auction(&mut auction, &mut suins, &config, NODE, &mut coin, ctx);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            coin::destroy_for_testing(coin);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EAuctionNotAvailable)]
    fun test_start_an_auction_aborts_if_too_late() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AUCTION_END_AT + 1,
                0
            );
            let ctx = &mut ctx;
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let coin = coin::mint_for_testing<SUI>(30000, ctx);

            auction::start_an_auction(&mut auction, &mut suins, &config, NODE, &mut coin, ctx);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            coin::destroy_for_testing(coin);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = emoji::EInvalidLabel)]
    fun test_start_an_auction_aborts_if_node_too_short() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AUCTION_START_AT,
                0
            );
            let ctx = &mut ctx;
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let coin = coin::mint_for_testing<SUI>(30000, ctx);

            auction::start_an_auction(&mut auction, &mut suins, &config, b"su", &mut coin, ctx);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            coin::destroy_for_testing(coin);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = emoji::EInvalidLabel)]
    fun test_start_an_auction_aborts_if_node_too_long() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AUCTION_START_AT,
                0
            );
            let ctx = &mut ctx;
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let coin = coin::mint_for_testing<SUI>(30000, ctx);

            auction::start_an_auction(&mut auction, &mut suins, &config, b"suinssu", &mut coin, ctx);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            coin::destroy_for_testing(coin);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EInvalidPhase)]
    fun test_start_an_auction_in_pending_phase_abort() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                110,
                0
            );
            let ctx = &mut ctx;
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let test_coin = coin::mint_for_testing<SUI>(30000, ctx);

            auction::start_an_auction(&mut auction, &mut suins, &config, NODE, &mut test_coin, ctx);
            assert!(coin::value(&test_coin) == 20000, 0);

            auction::start_an_auction(&mut auction, &mut suins, &config, NODE, &mut test_coin, ctx);

            coin::burn_for_testing(test_coin);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EInvalidPhase)]
    fun test_start_bidding_auction_in_bidding_phase_abort() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                110,
                0
            );
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let coin = coin::mint_for_testing<SUI>(30000, &mut ctx);
            let config = test_scenario::take_shared<Configuration>(scenario);

            auction::start_an_auction(&mut auction, &mut suins, &config, NODE, &mut coin, &mut ctx);

            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                111,
                0
            );
            auction::start_an_auction(&mut auction, &mut suins, &config, NODE, &mut coin, &mut ctx);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            coin::destroy_for_testing(coin);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EInvalidPhase)]
    fun test_start_an_auction_in_reveal_phase_abort() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                110,
                0
            );
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let coin = coin::mint_for_testing<SUI>(30000, &mut ctx);

            auction::start_an_auction(&mut auction, &mut suins, &config, NODE, &mut coin, &mut ctx);

            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                111 + BIDDING_PERIOD,
                0
            );
            auction::start_an_auction(&mut auction, &mut suins, &config, NODE, &mut coin, &mut ctx);

            coin::burn_for_testing(coin);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_start_an_auction_in_reopened_phase_work() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                110,
                0
            );
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let coin = coin::mint_for_testing<SUI>(30000, &mut ctx);

            assert!(auction::get_balance(&auction) == 0, 0);
            assert!(controller::get_balance(&suins) == 0, 0);

            auction::start_an_auction(&mut auction, &mut suins, &config, NODE, &mut coin, &mut ctx);

            assert!(coin::value(&coin) == 20000, 0);
            assert!(auction::get_balance(&auction) == 0, 0);
            assert!(controller::get_balance(&suins) == 10000, 0);

            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                111 + BIDDING_PERIOD + REVEAL_PERIOD,
                0
            );
            auction::start_an_auction(&mut auction, &mut suins, &config, NODE, &mut coin, &mut ctx);

            assert!(auction::get_balance(&auction) == 0, 0);
            assert!(controller::get_balance(&suins) == 20000, 0);
            assert!(coin::value(&coin) == 10000, 0);

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EInvalidPhase)]
    fun test_start_an_auction_in_finalizing_phase_abort() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, NODE);

        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1000, FIRST_USER_ADDRESS, option::none());
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_bid_util(&auction, seal_bid, FIRST_USER_ADDRESS, some(1000));
            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                1000,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );
            test_scenario::return_shared(auction);
        };

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD,
                0
            );
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let coin = coin::mint_for_testing<SUI>(30000, &mut ctx);

            auction::start_an_auction(&mut auction, &mut suins, &config, NODE, &mut coin, &mut ctx);

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EInvalidPhase)]
    fun test_start_an_auction_in_owned_phase_abort() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, NODE);

        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1000, FIRST_USER_ADDRESS, option::none());
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            assert!(auction::get_balance(&auction) == 1000, 0);
            get_bid_util(&auction, seal_bid, FIRST_USER_ADDRESS, some(1000));
            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                1000,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );
            test_scenario::return_shared(auction);
        };

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_entry_util(&auction, NODE, START_AN_AUCTION_AT + 1, 1000, 0, FIRST_USER_ADDRESS, false);
            finalize_auction_util(
                scenario,
                &mut auction,
                NODE,
                FIRST_USER_ADDRESS,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD,
                10
            );
            get_entry_util(&auction, NODE, START_AN_AUCTION_AT + 1, 1000, 0, FIRST_USER_ADDRESS, true);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD,
                0
            );
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let coin = coin::mint_for_testing<SUI>(30000, &mut ctx);

            assert!(auction::get_balance(&auction) == 0, 0);
            assert!(controller::get_balance(&suins) == 11000, 0);

            auction::start_an_auction(&mut auction, &mut suins, &config, NODE, &mut coin, &mut ctx);

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EInvalidPhase)]
    fun test_reveal_bid_handle_invalid_if_auction_not_start() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;

        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1100, FIRST_USER_ADDRESS, option::none());
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                115,
                10
            );
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let coin = test_scenario::most_recent_id_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(option::is_none(&coin), 0);

            auction::reveal_bid(&mut auction, NODE, 1000, FIRST_SECRET, &mut ctx);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_reveal_bid() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, NODE);

        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1100, FIRST_USER_ADDRESS, option::none());
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_bid_util(&auction, seal_bid, FIRST_USER_ADDRESS, some(1100));
            let coin = test_scenario::most_recent_id_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(option::is_none(&coin), 0);
            assert!(auction::get_balance(&auction) == 1100, 0);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);

            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 1100, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            assert!(
                state_util(
                    &auction,
                    NODE,
                    START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD
                ) == AUCTION_STATE_REOPENED,
                0
            );
            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                1000,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );

            assert!(
                state_util(
                    &auction,
                    NODE,
                    START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD
                ) == AUCTION_STATE_FINALIZING,
                0
            );

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);

            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 1100, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(is_unsealed, 0);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            assert!(auction::get_balance(&auction) == 1100, 0);
            assert!(!test_scenario::has_most_recent_for_address<Coin<SUI>>(FIRST_USER_ADDRESS), 0);
            test_scenario::return_shared(auction);
        };

        let seal_bid = make_seal_bid(NODE, SECOND_USER_ADDRESS, 1500, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 2000, SECOND_USER_ADDRESS, option::some(FIRST_TX_HASH));
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);

            assert!(auction::get_balance(&auction) == 3100, 0);
            get_bid_util(&auction, seal_bid, SECOND_USER_ADDRESS, some(2000));

            let coin = test_scenario::most_recent_id_for_address<Coin<SUI>>(SECOND_USER_ADDRESS);
            assert!(option::is_none(&coin), 0);

            let bids = get_bids_by_bidder(&auction, SECOND_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);

            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == SECOND_USER_ADDRESS, 0);
            assert!(mask == 2000, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                1500,
                FIRST_SECRET,
                SECOND_USER_ADDRESS,
                10
            );

            let bids = get_bids_by_bidder(&auction, SECOND_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);
            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == SECOND_USER_ADDRESS, 0);
            assert!(mask == 2000, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(is_unsealed, 0);

            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, NODE), 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            assert!(!test_scenario::has_most_recent_for_address<Coin<SUI>>(FIRST_USER_ADDRESS), 0);
            assert!(!test_scenario::has_most_recent_for_address<Coin<SUI>>(SECOND_USER_ADDRESS), 0);
        };
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let bids = get_bids_by_bidder(&auction, SECOND_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);
            assert!(auction::get_balance(&auction) == 3100, 0);

            get_entry_util(&mut auction, NODE, START_AN_AUCTION_AT + 1, 1500, 1000, SECOND_USER_ADDRESS, false);
            finalize_auction_util(
                scenario,
                &mut auction,
                NODE,
                SECOND_USER_ADDRESS,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD,
                20
            );
            get_entry_util(&mut auction, NODE, START_AN_AUCTION_AT + 1, 1500, 1000, SECOND_USER_ADDRESS, true);

            let bids = get_bids_by_bidder(&auction, SECOND_USER_ADDRESS);
            assert!(vector::length(&bids) == 0, 0);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(SECOND_USER_ADDRESS);

            assert!(vector::length(&ids) == 1, 0);
            let coin = test_scenario::take_from_address<Coin<SUI>>(scenario, SECOND_USER_ADDRESS);
            assert!(coin::value(&coin) == 1000, 0);
            assert!(auction::get_balance(&auction) == 1100, 0);
            assert!(controller::get_balance(&suins) == 11000, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_to_address(SECOND_USER_ADDRESS, coin);
        };
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            get_entry_util(&mut auction, NODE, START_AN_AUCTION_AT + 1, 1500, 1000, SECOND_USER_ADDRESS, true);
            assert!(registrar::record_exists(&suins, SUI_REGISTRAR, NODE), 0);
            assert!(
                registrar::name_expires_at(&suins, SUI_REGISTRAR, NODE)
                    == START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD + 365,
                0
            );
            assert!(registry::owner(&suins, NODE_SUI) == SECOND_USER_ADDRESS, 0);
            assert!(registry::ttl(&suins, NODE_SUI) == 0, 0);
            assert!(registry::resolver(&suins, NODE_SUI) == RESOLVER_ADDRESS, 0);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);

            get_entry_util(&mut auction, NODE, START_AN_AUCTION_AT + 1, 1500, 1000, SECOND_USER_ADDRESS, true);
            finalize_auction_util(
                scenario,
                &mut auction,
                NODE,
                FIRST_USER_ADDRESS,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD,
                10
            );
            get_entry_util(&mut auction, NODE, START_AN_AUCTION_AT + 1, 1500, 1000, SECOND_USER_ADDRESS, true);
            assert!(auction::get_balance(&auction) == 0, 0);
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 0, 0);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);

            let coin1 = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin1) == 1100, 0);

            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            assert!(auction::get_balance(&auction) == 0, 0);
            assert!(controller::get_balance(&suins) == 11000, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin1);
        };
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            get_entry_util(&mut auction, NODE, START_AN_AUCTION_AT + 1, 1500, 1000, SECOND_USER_ADDRESS, true);
            assert!(registrar::record_exists(&suins, SUI_REGISTRAR, NODE), 0);
            assert!(
                registrar::name_expires_at(&suins, SUI_REGISTRAR, NODE)
                    == START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD + 365,
                0
            );
            assert!(registry::owner(&suins, NODE_SUI) == SECOND_USER_ADDRESS, 0);
            assert!(registry::ttl(&suins, NODE_SUI) == 0, 0);
            assert!(registry::resolver(&suins, NODE_SUI) == RESOLVER_ADDRESS, 0);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_reveal_bid_choose_the_one_who_bids_first_as_winner_if_same_value() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, NODE);

        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, FIRST_SECRET);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AN_AUCTION_AT + 1,
                10
            );
            let ctx = &mut ctx;
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let coin = coin::mint_for_testing<SUI>(30000, ctx);
            assert!(auction::get_balance(&auction) == 0, 0);

            auction::place_bid(&mut auction, seal_bid, 1100, &mut coin, ctx);

            assert!(auction::get_balance(&auction) == 1100, 0);
            coin::destroy_for_testing(coin);
            test_scenario::return_shared(auction);
        };
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
                2
            );
            test_scenario::return_shared(auction);
        };
        let seal_bid = make_seal_bid(NODE, SECOND_USER_ADDRESS, 1000, FIRST_SECRET);
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let ctx = ctx_new(
                SECOND_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AN_AUCTION_AT + 2,
                10
            );
            let ctx = &mut ctx;
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let coin = coin::mint_for_testing<SUI>(30000, ctx);
            assert!(auction::get_balance(&auction) == 1100, 0);

            auction::place_bid(&mut auction, seal_bid, 1100, &mut coin, ctx);

            let suins = test_scenario::take_shared<SuiNS>(scenario);
            assert!(controller::get_balance(&suins) == 10000, 0);
            assert!(auction::get_balance(&auction) == 2200, 0);

            test_scenario::return_shared(suins);
            coin::destroy_for_testing(coin);
            test_scenario::return_shared(auction);
        };
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
                10
            );
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_entry_util(
                &mut auction,
                NODE,
                START_AN_AUCTION_AT + 1,
                1000,
                1000,
                FIRST_USER_ADDRESS,
                false
            );
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_reveal_bid_choose_the_one_who_bids_first_as_winner_if_same_value_2() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, NODE);

        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, FIRST_SECRET);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AN_AUCTION_AT + 2,
                10
            );
            let ctx = &mut ctx;
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let coin = coin::mint_for_testing<SUI>(30000, ctx);

            assert!(auction::get_balance(&auction) == 0, 0);
            auction::place_bid(&mut auction, seal_bid, 1100, &mut coin, ctx);
            assert!(auction::get_balance(&auction) == 1100, 0);

            coin::burn_for_testing(coin);
            test_scenario::return_shared(auction);
        };
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
                2
            );
            test_scenario::return_shared(auction);
        };
        let seal_bid = make_seal_bid(NODE, SECOND_USER_ADDRESS, 1000, FIRST_SECRET);
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let ctx = ctx_new(
                SECOND_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AN_AUCTION_AT + 1,
                10
            );
            let ctx = &mut ctx;
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let coin = coin::mint_for_testing<SUI>(30000, ctx);

            assert!(auction::get_balance(&auction) == 1100, 0);
            auction::place_bid(&mut auction, seal_bid, 1100, &mut coin, ctx);
            assert!(auction::get_balance(&auction) == 2200, 0);

            coin::burn_for_testing(coin);
            test_scenario::return_shared(auction);
        };
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
                10
            );
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            assert!(controller::get_balance(&suins) == 10000, 0);

            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_entry_util(
                &mut auction,
                NODE,
                START_AN_AUCTION_AT + 1,
                1000,
                1000,
                SECOND_USER_ADDRESS,
                false
            );
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_reveal_bid_choose_the_one_who_reveals_first_as_winner_if_same_value_and_same_created_at() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, NODE);

        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1100, FIRST_USER_ADDRESS, option::none());
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
                2
            );
            assert!(auction::get_balance(&auction) == 1100, 0);
            test_scenario::return_shared(auction);
        };
        let seal_bid = make_seal_bid(NODE, SECOND_USER_ADDRESS, 1000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1100, SECOND_USER_ADDRESS, option::none());
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
                10
            );

            let suins = test_scenario::take_shared<SuiNS>(scenario);
            assert!(controller::get_balance(&suins) == 10000, 0);
            assert!(auction::get_balance(&auction) == 2200, 0);

            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_entry_util(
                &mut auction,
                NODE,
                START_AN_AUCTION_AT + 1,
                1000,
                1000,
                FIRST_USER_ADDRESS,
                false
            );
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_reveal_bid_choose_the_one_who_reveals_first_as_winner_if_same_value_and_same_created_at_2() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, NODE);

        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1100, FIRST_USER_ADDRESS, option::none());
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
                2
            );
            assert!(auction::get_balance(&auction) == 1100, 0);
            test_scenario::return_shared(auction);
        };
        let seal_bid = make_seal_bid(NODE, SECOND_USER_ADDRESS, 1000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1100, SECOND_USER_ADDRESS, option::none());
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + 1,
                NODE,
                1000,
                FIRST_SECRET,
                SECOND_USER_ADDRESS,
                10
            );
            assert!(auction::get_balance(&auction) == 2200, 0);

            let suins = test_scenario::take_shared<SuiNS>(scenario);
            assert!(controller::get_balance(&suins) == 10000, 0);

            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_entry_util(
                &mut auction,
                NODE,
                START_AN_AUCTION_AT + 1,
                1000,
                1000,
                FIRST_USER_ADDRESS,
                false
            );
            test_scenario::return_shared(auction);
        };


        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_non_winner_can_call_finalize_auction() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, NODE);

        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1000, FIRST_USER_ADDRESS, option::none());
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_bid_util(&auction, seal_bid, FIRST_USER_ADDRESS, some(1000));
            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                1000,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );
            assert!(auction::get_balance(&auction) == 1000, 0);
            test_scenario::return_shared(auction);
        };

        let seal_bid = make_seal_bid(NODE, SECOND_USER_ADDRESS, 1500, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 2100, SECOND_USER_ADDRESS, option::some(FIRST_TX_HASH));
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_bid_util(&auction, seal_bid, SECOND_USER_ADDRESS, some(2100));

            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                1500,
                FIRST_SECRET,
                SECOND_USER_ADDRESS,
                10
            );
            assert!(auction::get_balance(&auction) == 3100, 0);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_entry_util(&mut auction, NODE, START_AN_AUCTION_AT + 1, 1500, 1000, SECOND_USER_ADDRESS, false);

            finalize_auction_util(
                scenario,
                &mut auction,
                NODE,
                FIRST_USER_ADDRESS,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD,
                10
            );
            assert!(auction::get_balance(&auction) == 2100, 0);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);
            let coin = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin) == 1000, 0);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin);

            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(SECOND_USER_ADDRESS);

            assert!(vector::length(&ids) == 0, 0);
            get_entry_util(&mut auction, NODE, START_AN_AUCTION_AT + 1, 1500, 1000, SECOND_USER_ADDRESS, false);

            let suins = test_scenario::take_shared<SuiNS>(scenario);
            assert!(controller::get_balance(&suins) == 10000, 0);

            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_finalize_auction() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, NODE);

        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1000, FIRST_USER_ADDRESS, option::none());
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_bid_util(&auction, seal_bid, FIRST_USER_ADDRESS, some(1000));
            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                1000,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );
            assert!(auction::get_balance(&auction) == 11000, 0);
            test_scenario::return_shared(auction);
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
            assert!(vector::length(&ids) == 0, 0);
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);

            get_entry_util(&mut auction, NODE, START_AN_AUCTION_AT + 1, 1000, 0, FIRST_USER_ADDRESS, true);
            assert!(registrar::record_exists(&suins, SUI_REGISTRAR, NODE), 0);
            assert!(
                registrar::name_expires_at(&suins, SUI_REGISTRAR, NODE)
                    == START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD + 365,
                0
            );
            assert!(registry::owner(&suins, NODE_SUI) == FIRST_USER_ADDRESS, 0);
            assert!(registry::ttl(&suins, NODE_SUI) == 0, 0);
            assert!(registry::resolver(&suins, NODE_SUI) == RESOLVER_ADDRESS, 0);
            assert!(auction::get_balance(&auction) == 10000, 0);
            assert!(controller::get_balance(&suins) == 1000, 0);

            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_finalize_auction_if_winning_bid_has_mask_equals_actual_value() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, NODE);

        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1000, FIRST_USER_ADDRESS, option::none());
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_bid_util(&auction, seal_bid, FIRST_USER_ADDRESS, some(1000));
            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                1000,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );
            assert!(auction::get_balance(&auction) == 1000, 0);
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
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD,
                10
            );
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);

            get_entry_util(&mut auction, NODE, START_AN_AUCTION_AT + 1, 1000, 0, FIRST_USER_ADDRESS, true);
            assert!(registrar::record_exists(&suins, SUI_REGISTRAR, NODE), 0);
            assert!(
                registrar::name_expires_at(&suins, SUI_REGISTRAR, NODE)
                    == START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD + 365,
                0
            );
            assert!(registry::owner(&suins, NODE_SUI) == FIRST_USER_ADDRESS, 0);
            assert!(registry::ttl(&suins, NODE_SUI) == 0, 0);
            assert!(registry::resolver(&suins, NODE_SUI) == RESOLVER_ADDRESS, 0);

            assert!(auction::get_balance(&auction) == 0, 0);
            assert!(controller::get_balance(&suins) == 11000, 0);

            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_finalize_auction_if_winning_bid_has_mask_equals_actual_value_2() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, NODE);

        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1000, FIRST_USER_ADDRESS, option::none());
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_bid_util(&auction, seal_bid, FIRST_USER_ADDRESS, some(1000));
            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                1000,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );
            assert!(auction::get_balance(&auction) == 1000, 0);
            test_scenario::return_shared(auction);
        };

        let seal_bid = make_seal_bid(NODE, SECOND_USER_ADDRESS, 1500, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1500, SECOND_USER_ADDRESS, option::some(FIRST_TX_HASH));
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_bid_util(&auction, seal_bid, SECOND_USER_ADDRESS, some(1500));

            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                1500,
                FIRST_SECRET,
                SECOND_USER_ADDRESS,
                10
            );
            assert!(auction::get_balance(&auction) == 2500, 0);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_entry_util(&mut auction, NODE, START_AN_AUCTION_AT + 1, 1500, 1000, SECOND_USER_ADDRESS, false);

            finalize_auction_util(
                scenario,
                &mut auction,
                NODE,
                SECOND_USER_ADDRESS,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD,
                20
            );
            assert!(auction::get_balance(&auction) == 11000, 0);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(SECOND_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);

            let coin = test_scenario::take_from_address<Coin<SUI>>(scenario, SECOND_USER_ADDRESS);
            assert!(coin::value(&coin) == 500, 0);

            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            get_entry_util(&mut auction, NODE, START_AN_AUCTION_AT + 1, 1500, 1000, SECOND_USER_ADDRESS, true);

            assert!(auction::get_balance(&auction) == 1000, 0);
            assert!(controller::get_balance(&suins) == 11000, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_to_address(SECOND_USER_ADDRESS, coin);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            finalize_auction_util(
                scenario,
                &mut auction,
                NODE,
                FIRST_USER_ADDRESS,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD,
                30
            );
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);
            let coin1 = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin1) == 1000, 0);

            let ids = test_scenario::ids_for_address<Coin<SUI>>(SECOND_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);

            let coin2 = test_scenario::take_from_address<Coin<SUI>>(scenario, SECOND_USER_ADDRESS);
            assert!(coin::value(&coin2) == 500, 0);

            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            get_entry_util(&mut auction, NODE, START_AN_AUCTION_AT + 1, 1500, 1000, SECOND_USER_ADDRESS, true);

            assert!(auction::get_balance(&auction) == 0, 0);
            assert!(controller::get_balance(&suins) == 11000, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin1);
            test_scenario::return_to_address(SECOND_USER_ADDRESS, coin2);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_finalize_auction_if_winning_bid_has_mask_equals_actual_value_3() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, NODE);

        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1000, FIRST_USER_ADDRESS, option::none());
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_bid_util(&auction, seal_bid, FIRST_USER_ADDRESS, some(1000));
            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                1000,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );
            test_scenario::return_shared(auction);
        };

        let seal_bid = make_seal_bid(NODE, SECOND_USER_ADDRESS, 1500, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1500, SECOND_USER_ADDRESS, option::some(FIRST_TX_HASH));
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_bid_util(&auction, seal_bid, SECOND_USER_ADDRESS, some(1500));

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
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_entry_util(&mut auction, NODE, START_AN_AUCTION_AT + 1, 1500, 1000, SECOND_USER_ADDRESS, false);

            finalize_auction_util(
                scenario,
                &mut auction,
                NODE,
                SECOND_USER_ADDRESS,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD,
                20
            );
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(SECOND_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);

            let coin = test_scenario::take_from_address<Coin<SUI>>(scenario, SECOND_USER_ADDRESS);
            assert!(coin::value(&coin) == 500, 0);

            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_entry_util(&mut auction, NODE, START_AN_AUCTION_AT + 1, 1500, 1000, SECOND_USER_ADDRESS, true);
            test_scenario::return_shared(auction);
            test_scenario::return_to_address(SECOND_USER_ADDRESS, coin);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            finalize_auction_util(
                scenario,
                &mut auction,
                NODE,
                FIRST_USER_ADDRESS,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD,
                30
            );
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);
            let coin1 = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin1) == 1000, 0);

            let ids = test_scenario::ids_for_address<Coin<SUI>>(SECOND_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);

            let coin2 = test_scenario::take_from_address<Coin<SUI>>(scenario, SECOND_USER_ADDRESS);
            assert!(coin::value(&coin2) == 500, 0);

            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_entry_util(&mut auction, NODE, START_AN_AUCTION_AT + 1, 1500, 1000, SECOND_USER_ADDRESS, true);
            test_scenario::return_shared(auction);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin1);
            test_scenario::return_to_address(SECOND_USER_ADDRESS, coin2);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_finalize_auction_has_extra_period() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, NODE);

        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1000, FIRST_USER_ADDRESS, option::none());
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_bid_util(&auction, seal_bid, FIRST_USER_ADDRESS, some(1000));
            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                1000,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );
            assert!(auction::get_balance(&auction) == 1000, 0);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);
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
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);

            get_entry_util(&mut auction, NODE, START_AN_AUCTION_AT + 1, 1000, 0, FIRST_USER_ADDRESS, true);
            assert!(registrar::record_exists(&suins, SUI_REGISTRAR, NODE), 0);
            assert!(
                registrar::name_expires_at(&suins, SUI_REGISTRAR, NODE)
                    == START_AUCTION_END_AT + 10 + 365,
                0
            );
            assert!(registry::owner(&suins, NODE_SUI) == FIRST_USER_ADDRESS, 0);
            assert!(registry::ttl(&suins, NODE_SUI) == 0, 0);
            assert!(registry::resolver(&suins, NODE_SUI) == RESOLVER_ADDRESS, 0);
            assert!(auction::get_balance(&auction) == 0, 0);
            assert!(controller::get_balance(&suins) == 11000, 0);

            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EInvalidPhase)]
    fun test_reveal_bid_late() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        let seal_bid = make_seal_bid(NODE, SECOND_USER_ADDRESS, 1500, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 2000, SECOND_USER_ADDRESS, option::none());
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD,
                NODE,
                1500,
                FIRST_SECRET,
                SECOND_USER_ADDRESS,
                10
            );
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EAuctionNotAvailable)]
    fun test_reveal_bid_late_2() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;

        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            reveal_bid_util(
                &mut auction,
                START_AUCTION_END_AT + BIDDING_PERIOD + REVEAL_PERIOD + 1,
                NODE,
                1500,
                FIRST_SECRET,
                SECOND_USER_ADDRESS,
                10
            );
            test_scenario::return_shared(auction);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_reveal_bid_on_time() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AUCTION_END_AT,
                10
            );
            let ctx = &mut ctx;
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let coin = coin::mint_for_testing<SUI>(30000, ctx);

            assert!(auction::get_balance(&auction) == 0, 0);

            auction::start_an_auction(&mut auction, &mut suins, &config, NODE, &mut coin, &mut ctx);

            assert!(auction::get_balance(&auction) == 0, 0);
            assert!(controller::get_balance(&suins) == 10000, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            coin::burn_for_testing(coin);
        };

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1500, FIRST_SECRET);
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AUCTION_END_AT + BIDDING_PERIOD,
                20
            );
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let coin = coin::mint_for_testing<SUI>(30000, &mut ctx);

            auction::place_bid(&mut auction, seal_bid, 2000, &mut coin, &mut ctx);
            assert!(auction::get_balance(&auction) == 2000, 0);

            coin::burn_for_testing(coin);
            test_scenario::return_shared(auction);
        };

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            reveal_bid_util(
                &mut auction,
                START_AUCTION_END_AT + BIDDING_PERIOD + REVEAL_PERIOD,
                NODE,
                1500,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                10
            );
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EAuctionNotAvailable)]
    fun test_finalize_auction_late() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            finalize_auction_util(
                scenario,
                &mut auction,
                NODE,
                FIRST_USER_ADDRESS,
                START_AUCTION_END_AT + BIDDING_PERIOD + REVEAL_PERIOD + EXTRA_PERIOD + 1,
                10
            );
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_finalize_auction_on_time() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AUCTION_END_AT,
                10
            );
            let ctx = &mut ctx;
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let coin = coin::mint_for_testing<SUI>(30000, ctx);

            auction::start_an_auction(&mut auction, &mut suins, &config, NODE, &mut coin, ctx);
            assert!(auction::get_balance(&auction) == 0, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            coin::burn_for_testing(coin);
        };

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1500, FIRST_SECRET);
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AUCTION_END_AT + BIDDING_PERIOD,
                20
            );
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let coin = coin::mint_for_testing<SUI>(30000, &mut ctx);

            auction::place_bid(&mut auction, seal_bid, 2000, &mut coin, &mut ctx);
            assert!(auction::get_balance(&auction) == 2000, 0);

            coin::burn_for_testing(coin);
            test_scenario::return_shared(auction);
        };

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            reveal_bid_util(
                &mut auction,
                START_AUCTION_END_AT + BIDDING_PERIOD + REVEAL_PERIOD,
                NODE,
                1500,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                5
            );
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
                START_AUCTION_END_AT + BIDDING_PERIOD + REVEAL_PERIOD + EXTRA_PERIOD - 1,
                10
            );
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let coin = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin) == 500, 0);

            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);

            get_entry_util(&mut auction, NODE, START_AUCTION_END_AT + 1, 1500, 0, FIRST_USER_ADDRESS, true);
            assert!(registrar::record_exists(&suins, SUI_REGISTRAR, NODE), 0);
            assert!(
                registrar::name_expires_at(&suins, SUI_REGISTRAR, NODE)
                    == START_AUCTION_END_AT + BIDDING_PERIOD + REVEAL_PERIOD + EXTRA_PERIOD - 1 + 365,
                0
            );
            assert!(registry::owner(&suins, NODE_SUI) == FIRST_USER_ADDRESS, 0);
            assert!(registry::ttl(&suins, NODE_SUI) == 0, 0);
            assert!(registry::resolver(&suins, NODE_SUI) == RESOLVER_ADDRESS, 0);

            assert!(auction::get_balance(&auction) == 0, 0);
            assert!(controller::get_balance(&suins) == 11500, 0);

            test_scenario::return_shared(suins);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_withdraw_bid_that_remains_sealed() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1500, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 2000, FIRST_USER_ADDRESS, option::none());

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AN_AUCTION_AT + 200,
                0
            );
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);
            assert!(auction::get_balance(&auction) == 2000, 0);

            withdraw(&mut auction, &mut ctx);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 0, 0);
            assert!(auction::get_balance(&auction) == 0, 0);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);

            let coin = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin) == 2000, 0);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_withdraw_bids() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1500, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 2000, FIRST_USER_ADDRESS, option::none());

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
            let coin = coin::mint_for_testing<SUI>(30000, ctx);
            let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1100, FIRST_SECRET);

            assert!(auction::get_balance(&auction) == 2000, 0);
            auction::place_bid(&mut auction, seal_bid, 1300, &mut coin, ctx);
            assert!(auction::get_balance(&auction) == 3300, 0);

            coin::burn_for_testing(coin);
            test_scenario::return_shared(auction);
        };

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AN_AUCTION_AT + 200,
                0
            );
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 2, 0);

            withdraw(&mut auction, &mut ctx);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 0, 0);
            assert!(auction::get_balance(&auction) == 0, 0);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 2, 0);

            let first_coin = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&first_coin) == 1300, 0);
            let second_coin = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&second_coin) == 2000, 0);

            test_scenario::return_to_address(FIRST_USER_ADDRESS, first_coin);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, second_coin);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_cannt_withdraw_winning_bid() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, NODE);
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1500, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 2000, FIRST_USER_ADDRESS, option::none());

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                1500,
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
                START_AUCTION_END_AT + BIDDING_PERIOD + REVEAL_PERIOD + 1,
                0
            );
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);
            assert!(auction::get_balance(&auction) == 12000, 0);

            withdraw(&mut auction, &mut ctx);
            // it is the winning bid, cannot be withdrawed at this point
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);
            assert!(auction::get_balance(&auction) == 12000, 0);
            test_scenario::return_shared(auction);
        };

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AUCTION_END_AT + BIDDING_PERIOD + REVEAL_PERIOD + EXTRA_PERIOD + 1,
                0
            );
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);

            withdraw(&mut auction, &mut ctx);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);
            assert!(auction::get_balance(&auction) == 12000, 0);
            test_scenario::return_shared(auction);
        };

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_reveal_invalid_bid_that_is_less_than_minimum_amount_and_not_have_a_winner() {
        // auction receives only 1 bid and it is invalid
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, NODE);

        let seal_bid = make_seal_bid(NODE, SECOND_USER_ADDRESS, 500, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 2000, SECOND_USER_ADDRESS, option::none());
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            assert!(
                state_util(
                    &auction,
                    NODE,
                    START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD
                ) == AUCTION_STATE_REOPENED,
                0
            );
            assert!(auction::get_balance(&auction) == 2000, 0);
            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                500,
                FIRST_SECRET,
                SECOND_USER_ADDRESS,
                2
            );
            assert!(auction::get_balance(&auction) == 2000, 0);
            assert!(
                state_util(
                    &auction,
                    NODE,
                    START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD
                ) == AUCTION_STATE_REOPENED,
                0
            );
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            finalize_auction_util(
                scenario,
                &mut auction,
                NODE,
                SECOND_USER_ADDRESS,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD,
                10
            );
            assert!(auction::get_balance(&auction) == 0, 0);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(SECOND_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);
            let coin = test_scenario::take_from_address<Coin<SUI>>(scenario, SECOND_USER_ADDRESS);
            assert!(coin::value(&coin) == 2000, 0);

            let suins = test_scenario::take_shared<SuiNS>(scenario);
            assert!(controller::get_balance(&suins) == 10000, 0);

            test_scenario::return_shared(suins);
            test_scenario::return_to_address(SECOND_USER_ADDRESS, coin);
        };
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_entry_util(&auction, NODE, START_AN_AUCTION_AT + 1, 0, 0, @0x0, false);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_reveal_multiple_invalid_bids_that_are_less_than_minimum_amount_and_not_have_a_winner() {
        // auction receives 2 bids and they are invalid
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, NODE);

        let seal_bid = make_seal_bid(NODE, SECOND_USER_ADDRESS, 500, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 2000, SECOND_USER_ADDRESS, option::none());
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            assert!(
                state_util(
                    &auction,
                    NODE,
                    START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD
                ) == AUCTION_STATE_REOPENED,
                0
            );

            assert!(auction::get_balance(&auction) == 2000, 0);
            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                500,
                FIRST_SECRET,
                SECOND_USER_ADDRESS,
                2
            );
            assert!(auction::get_balance(&auction) == 2000, 0);
            assert!(
                state_util(
                    &auction,
                    NODE,
                    START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD
                ) == AUCTION_STATE_REOPENED,
                0
            );
            test_scenario::return_shared(auction);
        };

        let seal_bid = make_seal_bid(NODE, SECOND_USER_ADDRESS, 400, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 3000, SECOND_USER_ADDRESS, option::none());
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            assert!(auction::get_balance(&auction) == 5000, 0);
            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                400,
                FIRST_SECRET,
                SECOND_USER_ADDRESS,
                5
            );
            assert!(auction::get_balance(&auction) == 5000, 0);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            finalize_auction_util(
                scenario,
                &mut auction,
                NODE,
                SECOND_USER_ADDRESS,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD,
                10
            );
            assert!(auction::get_balance(&auction) == 0, 0);

            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(SECOND_USER_ADDRESS);
            assert!(vector::length(&ids) == 2, 0);

            let first_coin = test_scenario::take_from_address<Coin<SUI>>(scenario, SECOND_USER_ADDRESS);
            let second_coin = test_scenario::take_from_address<Coin<SUI>>(scenario, SECOND_USER_ADDRESS);

            assert!(coin::value(&first_coin) == 3000, 0);
            assert!(coin::value(&second_coin) == 2000, 0);

            let suins = test_scenario::take_shared<SuiNS>(scenario);
            assert!(controller::get_balance(&suins) == 10000, 0);

            test_scenario::return_shared(suins);
            test_scenario::return_to_address(SECOND_USER_ADDRESS, second_coin);
            test_scenario::return_to_address(SECOND_USER_ADDRESS, first_coin);
        };
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_entry_util(&auction, NODE, START_AN_AUCTION_AT + 1, 0, 0, @0x0, false);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_reveal_invalid_bid_that_is_less_than_minimum_amount_and_has_a_winner() {
        // auction receives only 1 bid and it is invalid
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, NODE);

        // mock a winner
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1500, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 2000, FIRST_USER_ADDRESS, option::none());
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            assert!(auction::get_balance(&auction) == 2000, 0);
            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                1500,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );
            test_scenario::return_shared(auction);
        };

        let seal_bid = make_seal_bid(NODE, SECOND_USER_ADDRESS, 500, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 2200, SECOND_USER_ADDRESS, option::some(FIRST_TX_HASH));
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            assert!(
                state_util(
                    &auction,
                    NODE,
                    START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD
                ) == AUCTION_STATE_FINALIZING,
                0
            );
            assert!(auction::get_balance(&auction) == 4200, 0);
            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                500,
                FIRST_SECRET,
                SECOND_USER_ADDRESS,
                2
            );
            assert!(auction::get_balance(&auction) == 4200, 0);
            assert!(
                state_util(
                    &auction,
                    NODE,
                    START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD
                ) == AUCTION_STATE_FINALIZING,
                0
            );
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            finalize_auction_util(
                scenario,
                &mut auction,
                NODE,
                SECOND_USER_ADDRESS,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD,
                10
            );
            assert!(auction::get_balance(&auction) == 2000, 0);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(SECOND_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);
            let coin = test_scenario::take_from_address<Coin<SUI>>(scenario, SECOND_USER_ADDRESS);
            assert!(coin::value(&coin) == 2200, 0);

            let suins = test_scenario::take_shared<SuiNS>(scenario);
            assert!(controller::get_balance(&suins) == 10000, 0);

            test_scenario::return_shared(suins);
            test_scenario::return_to_address(SECOND_USER_ADDRESS, coin);
        };
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_entry_util(&auction, NODE, START_AN_AUCTION_AT + 1, 1500, 0, FIRST_USER_ADDRESS, false);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_reveal_multiple_invalid_bids_that_are_less_than_minimum_amount_and_has_a_winner() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, NODE);

        // mock a winner
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1500, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 2000, FIRST_USER_ADDRESS, option::none());
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            assert!(
                state_util(
                    &auction,
                    NODE,
                    START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD
                ) == AUCTION_STATE_REOPENED,
                0
            );
            assert!(auction::get_balance(&auction) == 2000, 0);

            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                1500,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );

            assert!(
                state_util(
                    &auction,
                    NODE,
                    START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD
                ) == AUCTION_STATE_FINALIZING,
                0
            );
            test_scenario::return_shared(auction);
        };

        let seal_bid = make_seal_bid(NODE, SECOND_USER_ADDRESS, 500, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 2200, SECOND_USER_ADDRESS, option::some(FIRST_TX_HASH));
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            assert!(
                state_util(
                    &auction,
                    NODE,
                    START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD
                ) == AUCTION_STATE_FINALIZING,
                0
            );
            assert!(auction::get_balance(&auction) == 4200, 0);
            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                500,
                FIRST_SECRET,
                SECOND_USER_ADDRESS,
                2
            );
            assert!(
                state_util(
                    &auction,
                    NODE,
                    START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD
                ) == AUCTION_STATE_FINALIZING,
                0
            );
            test_scenario::return_shared(auction);
        };

        let seal_bid = make_seal_bid(NODE, SECOND_USER_ADDRESS, 900, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1200, SECOND_USER_ADDRESS, option::some(SECOND_TX_HASH));
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            assert!(auction::get_balance(&auction) == 5400, 0);
            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                900,
                FIRST_SECRET,
                SECOND_USER_ADDRESS,
                2
            );
            test_scenario::return_shared(auction);
        };

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            finalize_auction_util(
                scenario,
                &mut auction,
                NODE,
                SECOND_USER_ADDRESS,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD,
                10
            );
            assert!(auction::get_balance(&auction) == 2000, 0);

            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(SECOND_USER_ADDRESS);
            assert!(vector::length(&ids) == 2, 0);

            let first_coin = test_scenario::take_from_address<Coin<SUI>>(scenario, SECOND_USER_ADDRESS);
            let second_coin = test_scenario::take_from_address<Coin<SUI>>(scenario, SECOND_USER_ADDRESS);

            assert!(coin::value(&first_coin) == 1200, 0);
            assert!(coin::value(&second_coin) == 2200, 0);

            let suins = test_scenario::take_shared<SuiNS>(scenario);
            assert!(controller::get_balance(&suins) == 10000, 0);

            test_scenario::return_shared(suins);
            test_scenario::return_to_address(SECOND_USER_ADDRESS, first_coin);
            test_scenario::return_to_address(SECOND_USER_ADDRESS, second_coin);
        };
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_entry_util(&auction, NODE, START_AN_AUCTION_AT + 1, 1500, 0, FIRST_USER_ADDRESS, false);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EInvalidPhase)]
    fun test_reveal_invalid_bids_that_are_less_than_minimum_amount_and_has_no_winner_and_auction_is_restarted_abort() {
        // auction receives only 1 bid and it is invalid
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, NODE);

        let seal_bid = make_seal_bid(NODE, SECOND_USER_ADDRESS, 500, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 2200, SECOND_USER_ADDRESS, option::none());
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            assert!(
                state_util(
                    &auction,
                    NODE,
                    START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD
                ) == AUCTION_STATE_REOPENED,
                0
            );
            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                500,
                FIRST_SECRET,
                SECOND_USER_ADDRESS,
                2
            );
            assert!(
                state_util(
                    &auction,
                    NODE,
                    START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD
                ) == AUCTION_STATE_REOPENED,
                0
            );
            test_scenario::return_shared(auction);
        };

        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let ctx = ctx_new(
                SECOND_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD,
                10
            );
            let coin = coin::mint_for_testing<SUI>(30000, &mut ctx);

            auction::start_an_auction(&mut auction, &mut suins, &config, NODE, &mut coin, &mut ctx);

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
        };

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
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
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_reveal_invalid_bids_that_bid_less_than_minimum_amount_and_has_no_winner_and_auction_is_restarted() {
        // auction receives only 1 bid and it is invalid
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, NODE);

        let seal_bid = make_seal_bid(NODE, SECOND_USER_ADDRESS, 500, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 2200, SECOND_USER_ADDRESS, option::none());
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            assert!(
                state_util(
                    &auction,
                    NODE,
                    START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD
                ) == AUCTION_STATE_REOPENED,
                0
            );
            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                500,
                FIRST_SECRET,
                SECOND_USER_ADDRESS,
                2
            );
            assert!(auction::get_balance(&auction) == 2200, 0);
            assert!(
                state_util(
                    &auction,
                    NODE,
                    START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD
                ) == AUCTION_STATE_REOPENED,
                0
            );
            test_scenario::return_shared(auction);
        };

        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let ctx = ctx_new(
                SECOND_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD,
                10
            );
            let coin = coin::mint_for_testing<SUI>(30000, &mut ctx);

            auction::start_an_auction(&mut auction, &mut suins, &config, NODE, &mut coin, &mut ctx);

            assert!(auction::get_balance(&auction) == 2200, 0);
            assert!(controller::get_balance(&suins) == 20000, 0);

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
        };

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            finalize_auction_util(
                scenario,
                &mut auction,
                NODE,
                SECOND_USER_ADDRESS,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD + 1 + BIDDING_PERIOD + REVEAL_PERIOD,
                10
            );
            assert!(auction::get_balance(&auction) == 0, 0);
            test_scenario::return_shared(auction);
        };

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(SECOND_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);

            let first_coin = test_scenario::take_from_address<Coin<SUI>>(scenario, SECOND_USER_ADDRESS);
            assert!(coin::value(&first_coin) == 2200, 0);

            let suins = test_scenario::take_shared<SuiNS>(scenario);
            assert!(controller::get_balance(&suins) == 20000, 0);

            test_scenario::return_shared(suins);
            test_scenario::return_to_address(SECOND_USER_ADDRESS, first_coin);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_winner_finalize_auction_get_the_extra_payment() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, NODE);

        let seal_bid = make_seal_bid(NODE, SECOND_USER_ADDRESS, 1500, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 2200, SECOND_USER_ADDRESS, option::none());
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            assert!(
                state_util(
                    &auction,
                    NODE,
                    START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD
                ) == AUCTION_STATE_REOPENED,
                0
            );
            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                1500,
                FIRST_SECRET,
                SECOND_USER_ADDRESS,
                2
            );
            assert!(auction::get_balance(&auction) == 2200, 0);
            assert!(
                state_util(
                    &auction,
                    NODE,
                    START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD
                ) == AUCTION_STATE_FINALIZING,
                0
            );
            test_scenario::return_shared(auction);
        };

        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1600, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 3000, FIRST_USER_ADDRESS, option::some(FIRST_TX_HASH));
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_entry_util(&auction, NODE, START_AN_AUCTION_AT + 1, 1500, 0, SECOND_USER_ADDRESS, false);

            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                1600,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                5
            );
            assert!(auction::get_balance(&auction) == 5200, 0);
            test_scenario::return_shared(auction);
        };

        let seal_bid = make_seal_bid(NODE, SECOND_USER_ADDRESS, 1700, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 2000, SECOND_USER_ADDRESS, option::some(SECOND_TX_HASH));
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_entry_util(&auction, NODE, START_AN_AUCTION_AT + 1, 1600, 1500, FIRST_USER_ADDRESS, false);

            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                1700,
                FIRST_SECRET,
                SECOND_USER_ADDRESS,
                5
            );
            assert!(auction::get_balance(&auction) == 7200, 0);
            test_scenario::return_shared(auction);
        };

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_entry_util(&auction, NODE, START_AN_AUCTION_AT + 1, 1700, 1600, SECOND_USER_ADDRESS, false);

            finalize_auction_util(
                scenario,
                &mut auction,
                NODE,
                FIRST_USER_ADDRESS,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD,
                10
            );
            assert!(auction::get_balance(&auction) == 4200, 0);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);
            let coin = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin) == 3000, 0);

            let ids = test_scenario::ids_for_address<Coin<SUI>>(SECOND_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);

            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin);
        };
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_entry_util(&auction, NODE, START_AN_AUCTION_AT + 1, 1700, 1600, SECOND_USER_ADDRESS, false);

            finalize_auction_util(
                scenario,
                &mut auction,
                NODE,
                SECOND_USER_ADDRESS,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD,
                15
            );
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(SECOND_USER_ADDRESS);
            assert!(vector::length(&ids) == 2, 0);

            let first_coin = test_scenario::take_from_address<Coin<SUI>>(scenario, SECOND_USER_ADDRESS);
            let second_coin = test_scenario::take_from_address<Coin<SUI>>(scenario, SECOND_USER_ADDRESS);

            assert!(coin::value(&first_coin) == 400, 0);
            assert!(coin::value(&second_coin) == 2200, 0);

            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            assert!(auction::get_balance(&auction) == 0, 0);
            assert!(controller::get_balance(&suins) == 11600, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_to_address(SECOND_USER_ADDRESS, first_coin);
            test_scenario::return_to_address(SECOND_USER_ADDRESS, second_coin);
        };

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            // call again and no problem
            finalize_auction_util(
                scenario,
                &mut auction,
                NODE,
                FIRST_USER_ADDRESS,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD,
                15
            );
            test_scenario::return_shared(auction);
        };

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);

            let first_coin = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&first_coin) == 3000, 0);

            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            assert!(auction::get_balance(&auction) == 0, 0);
            assert!(controller::get_balance(&suins) == 11600, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, first_coin);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EAlreadyUnsealed)]
    fun test_reveal_bid_abort_if_unseal_twice() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, NODE);

        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1000, FIRST_USER_ADDRESS, option::none());
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
                2
            );
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);
        };
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
                10
            );
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::ESealBidNotExists)]
    fun test_reveal_bid_abort_with_wrong_parameter() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, FIRST_SECRET);
        start_an_auction_util(scenario, NODE);
        place_bid_util(scenario, seal_bid, 1000, FIRST_USER_ADDRESS, option::none());
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                1200,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::ESealBidNotExists)]
    fun test_reveal_bid_abort_with_wrong_parameter_2() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, FIRST_SECRET);
        start_an_auction_util(scenario, NODE);
        place_bid_util(scenario, seal_bid, 1400, FIRST_USER_ADDRESS, option::none());
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                1000,
                b"wrong_salt",
                FIRST_USER_ADDRESS,
                2
            );
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EInvalidPhase)]
    fun test_reveal_bid_abort_with_wrong_parameter_3() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;

        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, FIRST_SECRET);
        start_an_auction_util(scenario, NODE);
        place_bid_util(scenario, seal_bid, 10000, FIRST_USER_ADDRESS, option::none());
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                b"wrongn",
                1000,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_reveal_bid_handle_invalid_if_mask_bid_less_than_actual_value() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 3000, FIRST_SECRET);
        start_an_auction_util(scenario, NODE);
        place_bid_util(scenario, seal_bid, 2000, FIRST_USER_ADDRESS, option::none());
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let coin = test_scenario::most_recent_id_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(option::is_none(&coin), 0);

            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                3000,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );
            assert!(auction::get_balance(&auction) == 2000, 0);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);

            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_entry_util(&mut auction, NODE, START_AN_AUCTION_AT + 1, 0, 0, @0x0, false);
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
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD,
                10
            );
            assert!(auction::get_balance(&auction) == 0, 0);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);
            let coin = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin) == 2000, 0);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            assert!(controller::get_balance(&suins) == 10000, 0);

            test_scenario::return_shared(suins);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_config_auction() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                114,
                0
            );
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            auction::configure_auction(&admin_cap, &mut auction, &mut suins, 3000, 3001, &mut ctx);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_to_sender(scenario, admin_cap);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EInvalidConfigParam)]
    fun test_config_auction_aborts_if_start_greater_than_end() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                114,
                0
            );
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            auction::configure_auction(&admin_cap, &mut auction, &mut suins,3001, 3000, &mut ctx);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_to_sender(scenario, admin_cap);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EInvalidConfigParam)]
    fun test_config_auction_aborts_if_start_same_as_end() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                114,
                0
            );
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            auction::configure_auction(&admin_cap, &mut auction, &mut suins, 3000, 3000, &mut ctx);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_to_sender(scenario, admin_cap);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EInvalidConfigParam)]
    fun test_config_auction_aborts_if_start_less_than_current_epoch() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                114,
                0
            );
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            auction::configure_auction(&admin_cap, &mut auction, &mut suins, 100, 300, &mut ctx);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
            test_scenario::return_to_sender(scenario, admin_cap);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EInvalidPhase)]
    fun test_withdraw_abort_if_too_early() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                114,
                2
            );
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            withdraw(&mut auction, &mut ctx);
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
            let ctx = tx_context::new(
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

    #[test]
    fun test_bids_multiple_domains_and_reveal_only_one() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, NODE);
        start_an_auction_util(scenario, SECOND_NODE);
        start_an_auction_util(scenario, THIRD_NODE);

        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1300, FIRST_USER_ADDRESS, option::none());
        let seal_bid = make_seal_bid(SECOND_NODE, FIRST_USER_ADDRESS, 2000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 2200, FIRST_USER_ADDRESS, option::none());
        let seal_bid = make_seal_bid(THIRD_NODE, FIRST_USER_ADDRESS, 3000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 12200, FIRST_USER_ADDRESS, option::none());

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            assert!(auction::get_balance(&auction) == 45700, 0);

            let coin = test_scenario::most_recent_id_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(option::is_none(&coin), 0);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 3, 0);

            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 1300, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 1);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 2200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 2);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 12200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                SECOND_NODE,
                2000,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );
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
                SECOND_NODE,
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
            assert!(coin::value(&first_coin) == 200, 0);
            assert!(auction::get_balance(&auction) == 43500, 0);
            assert!(controller::get_balance(&suins) == 2000, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, first_coin);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AN_AUCTION_AT + 200,
                0
            );
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 2, 0);

            withdraw(&mut auction, &mut ctx);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 0, 0);
            assert!(auction::get_balance(&auction) == 30000, 0);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 3, 0);

            let coin1 = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin1) == 12200, 0);
            let coin2 = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin2) == 1300, 0);
            let coin3 = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin3) == 200, 0);
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
        start_an_auction_util(scenario, NODE);

        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1300, FIRST_USER_ADDRESS, option::none());
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 2000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 12200, FIRST_USER_ADDRESS, option::none());
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 3000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 10200, FIRST_USER_ADDRESS, option::none());

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            assert!(auction::get_balance(&auction) == 33700, 0);

            let coin = test_scenario::most_recent_id_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(option::is_none(&coin), 0);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 3, 0);

            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 1300, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 1);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 12200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 2);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 10200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                3000,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 3, 0);
            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 1300, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 1);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 12200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 2);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 10200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(is_unsealed, 0);
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
            assert!(mask == 1300, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 1);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 12200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 2);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 10200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(is_unsealed, 0);

            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AUCTION_END_AT + 200,
                10
            );
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 3, 0);

            withdraw(&mut auction, &mut ctx);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);
            assert!(auction::get_balance(&auction) == 20200, 0);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 2, 0);
            let coin1 = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin1) == 12200, 0);
            let coin2 = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin2) == 1300, 0);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin1);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin2);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);
            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 10200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(is_unsealed, 0);

            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_bids_multiple_times_same_domain_and_finalize() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, NODE);

        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1300, FIRST_USER_ADDRESS, option::none());
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 2000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 12200, FIRST_USER_ADDRESS, option::none());
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 3000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 10200, FIRST_USER_ADDRESS, option::none());

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            assert!(auction::get_balance(&auction) == 33700, 0);
            let coin = test_scenario::most_recent_id_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(option::is_none(&coin), 0);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 3, 0);

            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 1300, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 1);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 12200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 2);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 10200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                3000,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 3, 0);
            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 1300, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 1);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 12200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 2);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 10200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(is_unsealed, 0);
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
            assert!(mask == 1300, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 1);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 12200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 2);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 10200, 0);
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
                NODE,
                FIRST_USER_ADDRESS,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD,
                10
            );
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 2, 0);

            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 1300, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 1);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 12200, 0);
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
            assert!(coin::value(&coin1) == 7200, 0);

            assert!(auction::get_balance(&auction) == 23500, 0);
            assert!(controller::get_balance(&suins) == 3000, 0);

            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin1);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AN_AUCTION_AT + 200,
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
            assert!(coin::value(&coin1) == 12200, 0);
            let coin2 = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin2) == 1300, 0);
            let coin3 = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin3) == 7200, 0);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 0, 0);

            assert!(auction::get_balance(&auction) == 10000, 0);
            assert!(controller::get_balance(&suins) == 3000, 0);

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
        start_an_auction_util(scenario, NODE);

        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 2000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 3300, FIRST_USER_ADDRESS, option::none());
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 2000, SECOND_SECRET);
        place_bid_util(scenario, seal_bid, 12200, FIRST_USER_ADDRESS, option::some(FIRST_TX_HASH));

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            assert!(auction::get_balance(&auction) == 15500, 0);
            let coin = test_scenario::most_recent_id_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(option::is_none(&coin), 0);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 2, 0);

            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 3300, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 1);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 12200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                2000,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );

            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                2000,
                SECOND_SECRET,
                FIRST_USER_ADDRESS,
                2
            );

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 2, 0);
            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 3300, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 1);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 12200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(is_unsealed, 0);

            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 2, 0);

            finalize_auction_util(
                scenario,
                &mut auction,
                NODE,
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
            assert!(vector::length(&ids) == 2, 0);

            let coin1 = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin1) == 12200, 0);

            let coin2 = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin2) == 1300, 0);

            assert!(auction::get_balance(&auction) == 0, 0);
            assert!(controller::get_balance(&suins) == 12000, 0);

            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin1);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin2);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_finalized_entry_has_state_of_owned() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, NODE);
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1300, FIRST_USER_ADDRESS, option::none());
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            assert!(auction::get_balance(&auction) == 1300, 0);

            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                1000,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );
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
                    NODE,
                    START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD
                ) == AUCTION_STATE_OWNED,
                0
            );
            assert!(auction::get_balance(&auction) == 0, 0);
            assert!(controller::get_balance(&suins) == 11000, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_reveal_bid_handle_invalid_bid_if_actual_value_less_than_min_allowed_value() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, NODE);

        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 999, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1300, FIRST_USER_ADDRESS, option::none());
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let coin = test_scenario::most_recent_id_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(option::is_none(&coin), 0);
            assert!(auction::get_balance(&auction) == 1300, 0);
            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                999,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);

            assert!(vector::length(&ids) == 0, 0);
            get_entry_util(&mut auction, NODE, START_AN_AUCTION_AT + 1, 0, 0, @0x0, false);

            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ctx = tx_context::new(
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
            assert!(coin::value(&coin) == 1300, 0);

            let suins = test_scenario::take_shared<SuiNS>(scenario);
            assert!(controller::get_balance(&suins) == 10000, 0);

            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_reveal_bid_handle_invalid_bid_if_place_bid_too_early() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;

        start_an_auction_util(scenario, NODE);
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1100, FIRST_SECRET);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AN_AUCTION_AT - 1,
                2
            );
            let ctx = &mut ctx;
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let coin = coin::mint_for_testing<SUI>(30000, ctx);
            assert!(auction::get_balance(&auction) == 0, 0);

            auction::place_bid(&mut auction, seal_bid, 1300, &mut coin, ctx);

            assert!(auction::get_balance(&auction) == 1300, 0);
            coin::destroy_for_testing(coin);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let coin = test_scenario::most_recent_id_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(option::is_none(&coin), 0);

            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                1100,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                5
            );

            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ctx = tx_context::new(
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
            assert!(coin::value(&coin) == 1300, 0);
            let (start_at, highest_bid, second_highest_bid, winner, is_finalized) =
                auction::get_entry(&auction, NODE);
            assert!(option::extract(&mut start_at) == START_AN_AUCTION_AT + 1, 0);
            assert!(option::extract(&mut highest_bid) == 0, 0);
            assert!(option::extract(&mut second_highest_bid) == 0, 0);
            assert!(option::extract(&mut winner) == @0x0, 0);
            assert!(option::extract(&mut is_finalized) == false, 0);

            let suins = test_scenario::take_shared<SuiNS>(scenario);
            assert!(controller::get_balance(&suins) == 10000, 0);

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
        start_an_auction_util(scenario, NODE);

        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 11100, FIRST_SECRET);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                2
            );
            let ctx = &mut ctx;
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let coin = coin::mint_for_testing<SUI>(30000, ctx);
            assert!(auction::get_balance(&auction) == 0, 0);

            auction::place_bid(&mut auction, seal_bid, 30000, &mut coin, ctx);

            assert!(auction::get_balance(&auction) == 30000, 0);
            coin::destroy_for_testing(coin);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let coin = test_scenario::most_recent_id_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(option::is_none(&coin), 0);

            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                11100,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                5
            );
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);
        };
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let ctx = tx_context::new(
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
            assert!(controller::get_balance(&suins) == 10000, 0);

            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);

            let coin = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin) == 30000, 0);
            let (start_at, highest_bid, second_highest_bid, winner, is_finalized) =
                auction::get_entry(&auction, NODE);
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
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, FIRST_SECRET);
        start_an_auction_util(scenario, NODE);
        place_bid_util(scenario, seal_bid, 1000, FIRST_USER_ADDRESS, option::none());
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
        place_bid_util(scenario, seal_bid, 4100, FIRST_USER_ADDRESS, option::none());
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
        place_bid_util(scenario, seal_bid, 2000, SECOND_USER_ADDRESS, option::some(FIRST_TX_HASH));
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
    fun test_reveal_bid_handle_low_value_bid() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 3000, FIRST_SECRET);
        start_an_auction_util(scenario, NODE);
        place_bid_util(scenario, seal_bid, 4100, FIRST_USER_ADDRESS, option::none());
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
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);
        };
        let seal_bid = make_seal_bid(NODE, SECOND_USER_ADDRESS, 1500, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 2000, SECOND_USER_ADDRESS, option::some(FIRST_TX_HASH));
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
                5
            );
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(SECOND_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);
        };
        let seal_bid = make_seal_bid(NODE, THIRD_USER_ADDRESS, 1200, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 2000, THIRD_USER_ADDRESS, option::some(SECOND_TX_HASH));
        test_scenario::next_tx(scenario, THIRD_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                1200,
                FIRST_SECRET,
                THIRD_USER_ADDRESS,
                10
            );
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
            get_entry_util(&mut auction, NODE, START_AN_AUCTION_AT + 1, 3000, 1500, FIRST_USER_ADDRESS, false);
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
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(SECOND_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);
            let coin = test_scenario::take_from_address<Coin<SUI>>(scenario, SECOND_USER_ADDRESS);
            assert!(coin::value(&coin) == 2000, 0);
            test_scenario::return_to_address(SECOND_USER_ADDRESS, coin);
        };
        test_scenario::next_tx(scenario, THIRD_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            finalize_auction_util(
                scenario,
                &mut auction,
                NODE,
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
            assert!(coin::value(&coin) == 2000, 0);
            test_scenario::return_to_address(THIRD_USER_ADDRESS, coin);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EInvalidPhase)]
    fun test_finalize_bid_abort_if_too_early() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, FIRST_SECRET);
        start_an_auction_util(scenario, NODE);
        place_bid_util(scenario, seal_bid, 1100, FIRST_USER_ADDRESS, option::none());
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
        place_bid_util(scenario, seal_bid, 1100, FIRST_USER_ADDRESS, option::none());
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
    fun test_finalize_bid_handle_being_called_twice_by_non_winner() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, NODE);

        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1100, FIRST_USER_ADDRESS, option::none());
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

        let seal_bid = make_seal_bid(NODE, SECOND_USER_ADDRESS, 2000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 3300, SECOND_USER_ADDRESS, option::some(FIRST_TX_HASH));
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_entry_util(&mut auction, NODE, START_AN_AUCTION_AT + 1, 1000, 0, FIRST_USER_ADDRESS, false);
            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                2000,
                FIRST_SECRET,
                SECOND_USER_ADDRESS,
                0
            );
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_entry_util(&mut auction, NODE, START_AN_AUCTION_AT + 1, 2000, 1000, SECOND_USER_ADDRESS, false);
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
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_entry_util(&mut auction, NODE, START_AN_AUCTION_AT + 1, 2000, 1000, SECOND_USER_ADDRESS, false);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(SECOND_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);

            finalize_auction_util(
                scenario,
                &mut auction,
                NODE,
                SECOND_USER_ADDRESS,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD,
                20
            );
            test_scenario::return_shared(auction);
        };

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);

            let coin = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin) == 1100, 0);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin);

            let ids = test_scenario::ids_for_address<Coin<SUI>>(SECOND_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);

            let coin = test_scenario::take_from_address<Coin<SUI>>(scenario, SECOND_USER_ADDRESS);
            assert!(coin::value(&coin) == 2300, 0);
            test_scenario::return_to_address(SECOND_USER_ADDRESS, coin);
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
                30
            );
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);

            let coin = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin) == 1100, 0);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin);

            let ids = test_scenario::ids_for_address<Coin<SUI>>(SECOND_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);

            let coin = test_scenario::take_from_address<Coin<SUI>>(scenario, SECOND_USER_ADDRESS);
            assert!(coin::value(&coin) == 2300, 0);
            test_scenario::return_to_address(SECOND_USER_ADDRESS, coin);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_not_yet_finalized_bid_cannot_be_withdrawed() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, NODE);

        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1100, FIRST_USER_ADDRESS, option::none());
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
            let ctx = tx_context::new(
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
    fun test_not_yet_finalized_bid_cannot_be_withdrawed_2() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, NODE);

        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1100, FIRST_USER_ADDRESS, option::none());
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
        place_bid_util(scenario, seal_bid, 4100, FIRST_USER_ADDRESS, option::some(FIRST_TX_HASH));
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
            let ctx = tx_context::new(
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
        place_bid_util(scenario, seal_bid, 1100, FIRST_USER_ADDRESS, option::none());
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
            let ctx = tx_context::new(
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
        place_bid_util(scenario, seal_bid, 1100, FIRST_USER_ADDRESS, option::none());
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
        place_bid_util(scenario, seal_bid, 2100, FIRST_USER_ADDRESS, option::some(FIRST_TX_HASH));
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
            let ctx = tx_context::new(
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
    fun test_not_yet_finalized_bid_can_be_withdrawed_by_non_winner() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, NODE);

        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1100, FIRST_USER_ADDRESS, option::none());
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
        place_bid_util(scenario, seal_bid, 3100, SECOND_USER_ADDRESS, option::some(FIRST_TX_HASH));
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
            let ctx = tx_context::new(
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
        place_bid_util(scenario, seal_bid, 1100, FIRST_USER_ADDRESS, option::none());
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
        place_bid_util(scenario, seal_bid, 3100, SECOND_USER_ADDRESS, option::some(FIRST_TX_HASH));
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
            let ctx = tx_context::new(
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

            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AUCTION_END_AT,
                10
            );
            assert!(state(&auction, NODE, epoch(&ctx)) == AUCTION_STATE_OPEN, 0);

            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AUCTION_END_AT + BIDDING_PERIOD,
                10
            );
            assert!(state(&auction, NODE, epoch(&ctx)) == AUCTION_STATE_OPEN, 0);


            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AUCTION_END_AT + BIDDING_PERIOD + REVEAL_PERIOD,
                10
            );
            assert!(state(&auction, NODE, epoch(&ctx)) == AUCTION_STATE_OPEN, 0);

            let ctx = tx_context::new(
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
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AUCTION_END_AT,
                10
            );
            let coin = coin::mint_for_testing<SUI>(30000, &mut ctx);

            auction::start_an_auction(&mut auction, &mut suins, &config, NODE, &mut coin, &mut ctx);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            coin::destroy_for_testing(coin);
        };

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);

            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AUCTION_END_AT,
                10
            );
            assert!(state(&auction, NODE, epoch(&ctx)) == AUCTION_STATE_PENDING, 0);

            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AUCTION_END_AT + 1,
                10
            );
            assert!(state(&auction, NODE, epoch(&ctx)) == AUCTION_STATE_BIDDING, 0);

            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AUCTION_END_AT + BIDDING_PERIOD,
                10
            );
            assert!(state(&auction, NODE, epoch(&ctx)) == AUCTION_STATE_BIDDING, 0);

            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AUCTION_END_AT + BIDDING_PERIOD + 1,
                10
            );
            assert!(state(&auction, NODE, epoch(&ctx)) == AUCTION_STATE_REVEAL, 0);

            let ctx = tx_context::new(
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

    #[test]
    fun test_finalize_auction_by_admin() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, NODE);

        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 10230, FIRST_USER_ADDRESS, option::none());
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_bid_util(&auction, seal_bid, FIRST_USER_ADDRESS, some(10230));
            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                1000,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );
            assert!(auction::get_balance(&auction) == 20230, 0);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);

            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);

            finalize_auction_by_admin(
                &admin_cap,
                &mut auction,
                &mut suins,
                &config,
                NODE,
                RESOLVER_ADDRESS,
                &mut ctx_util(FIRST_USER_ADDRESS, START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD, 20),
            );

            test_scenario::return_to_sender(scenario, admin_cap);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);

            get_entry_util(&mut auction, NODE, START_AN_AUCTION_AT + 1, 1000, 0, FIRST_USER_ADDRESS, true);
            assert!(registrar::record_exists(&suins, SUI_REGISTRAR, NODE), 0);
            assert!(
                registrar::name_expires_at(&suins, SUI_REGISTRAR, NODE)
                    == START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD + 365,
                0
            );
            assert!(registry::owner(&suins, NODE_SUI) == FIRST_USER_ADDRESS, 0);
            assert!(registry::ttl(&suins, NODE_SUI) == 0, 0);
            assert!(registry::resolver(&suins, NODE_SUI) == RESOLVER_ADDRESS, 0);
            assert!(auction::get_balance(&auction) == 10000, 0);
            assert!(controller::get_balance(&suins) == 1000, 0);

            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EAlreadyFinalized)]
    fun test_finalize_auction_by_admin_aborts_if_the_winner_calls_finalize_later() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, NODE);

        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 10230, FIRST_USER_ADDRESS, option::none());
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_bid_util(&auction, seal_bid, FIRST_USER_ADDRESS, some(10230));
            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                1000,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );
            assert!(auction::get_balance(&auction) == 20230, 0);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);

            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);

            finalize_auction_by_admin(
                &admin_cap,
                &mut auction,
                &mut suins,
                &config,
                NODE,
                RESOLVER_ADDRESS,
                &mut ctx_util(FIRST_USER_ADDRESS, START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD, 20),
            );

            test_scenario::return_to_sender(scenario, admin_cap);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
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
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EInvalidPhase)]
    fun test_finalize_auction_by_admin_aborts_if_admin_calls_finalize_later() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, NODE);

        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 10230, FIRST_USER_ADDRESS, option::none());
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_bid_util(&auction, seal_bid, FIRST_USER_ADDRESS, some(10230));
            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                1000,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );
            assert!(auction::get_balance(&auction) == 20230, 0);
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
            finalize_auction_by_admin(
                &admin_cap,
                &mut auction,
                &mut suins,
                &config,
                NODE,
                RESOLVER_ADDRESS,
                &mut ctx_util(FIRST_USER_ADDRESS, START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD, 20),
            );

            test_scenario::return_to_sender(scenario, admin_cap);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
        };
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            finalize_auction_by_admin(
                &admin_cap,
                &mut auction,
                &mut suins,
                &config,
                NODE,
                RESOLVER_ADDRESS,
                &mut ctx_util(FIRST_USER_ADDRESS, START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD, 20),
            );

            test_scenario::return_to_sender(scenario, admin_cap);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_finalize_auction_by_admin_has_extra_period() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, NODE);

        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 10230, FIRST_USER_ADDRESS, option::none());
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_bid_util(&auction, seal_bid, FIRST_USER_ADDRESS, some(10230));
            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                1000,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );
            assert!(auction::get_balance(&auction) == 20230, 0);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);

            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            finalize_auction_by_admin(
                &admin_cap,
                &mut auction,
                &mut suins,
                &config,
                NODE,
                RESOLVER_ADDRESS,
                &mut ctx_util(FIRST_USER_ADDRESS, START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD + 20, 20),
            );

            test_scenario::return_to_sender(scenario, admin_cap);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);

            get_entry_util(&mut auction, NODE, START_AN_AUCTION_AT + 1, 1000, 0, FIRST_USER_ADDRESS, true);
            assert!(registrar::record_exists(&suins, SUI_REGISTRAR, NODE), 0);
            assert!(
                registrar::name_expires_at(&suins, SUI_REGISTRAR, NODE)
                    == START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD + 20 + 365,
                0
            );
            assert!(registry::owner(&suins, NODE_SUI) == FIRST_USER_ADDRESS, 0);
            assert!(registry::ttl(&suins, NODE_SUI) == 0, 0);
            assert!(registry::resolver(&suins, NODE_SUI) == RESOLVER_ADDRESS, 0);
            assert!(auction::get_balance(&auction) == 10000, 0);
            assert!(controller::get_balance(&suins) == 1000, 0);

            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EInvalidPhase)]
    fun test_finalize_auction_by_admin_aborts_if_not_has_winner() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, NODE);
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 10230, FIRST_USER_ADDRESS, option::none());

        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);

            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);

            finalize_auction_by_admin(
                &admin_cap,
                &mut auction,
                &mut suins,
                &config,
                NODE,
                RESOLVER_ADDRESS,
                &mut ctx_util(FIRST_USER_ADDRESS, START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD + 20, 20),
            );

            test_scenario::return_to_sender(scenario, admin_cap);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EAuctionNotAvailable)]
    fun test_finalize_auction_by_admin_aborts_if_too_late() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, NODE);

        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 10230, FIRST_USER_ADDRESS, option::none());
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_bid_util(&auction, seal_bid, FIRST_USER_ADDRESS, some(10230));
            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                1000,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );
            assert!(auction::get_balance(&auction) == 20230, 0);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);

            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            finalize_auction_by_admin(
                &admin_cap,
                &mut auction,
                &mut suins,
                &config,
                NODE,
                RESOLVER_ADDRESS,
                &mut ctx_util(FIRST_USER_ADDRESS, START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD + 200, 20),
            );

            test_scenario::return_to_sender(scenario, admin_cap);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EInvalidPhase)]
    fun test_finalize_auction_by_admin_aborts_if_too_early() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, NODE);

        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 10230, FIRST_USER_ADDRESS, option::none());
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_bid_util(&auction, seal_bid, FIRST_USER_ADDRESS, some(10230));
            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                1000,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );
            assert!(auction::get_balance(&auction) == 20230, 0);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);

            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            finalize_auction_by_admin(
                &admin_cap,
                &mut auction,
                &mut suins,
                &config,
                NODE,
                RESOLVER_ADDRESS,
                &mut ctx_util(FIRST_USER_ADDRESS, START_AN_AUCTION_AT + 1 + BIDDING_PERIOD, 20),
            );

            test_scenario::return_to_sender(scenario, admin_cap);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_finalized_by_admin_entry_has_state_of_owned() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, NODE);
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1300, FIRST_USER_ADDRESS, option::none());
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            assert!(auction::get_balance(&auction) == 1300, 0);

            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                1000,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            finalize_auction_by_admin(
                &admin_cap,
                &mut auction,
                &mut suins,
                &config,
                NODE,
                RESOLVER_ADDRESS,
                &mut ctx_util(FIRST_USER_ADDRESS, START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD, 20),
            );

            test_scenario::return_to_sender(scenario, admin_cap);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);

            assert!(
                state_util(
                    &auction,
                    NODE,
                    START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD
                ) == AUCTION_STATE_OWNED,
                0
            );
            assert!(auction::get_balance(&auction) == 0, 0);
            assert!(controller::get_balance(&suins) == 11000, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_finalize_auction_by_admin_not_affect_non_revealed_bids() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, NODE);
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1300, FIRST_USER_ADDRESS, option::none());
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 2000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 12200, FIRST_USER_ADDRESS, option::none());
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 3000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 10200, FIRST_USER_ADDRESS, option::none());

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            assert!(auction::get_balance(&auction) == 33700, 0);
            let coin = test_scenario::most_recent_id_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(option::is_none(&coin), 0);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 3, 0);

            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 1300, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 1);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 12200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 2);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 10200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                3000,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 3, 0);
            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 1300, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 1);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 12200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 2);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 10200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(is_unsealed, 0);
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
            assert!(mask == 1300, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 1);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 12200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 2);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 10200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(is_unsealed, 0);

            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 3, 0);

            finalize_auction_by_admin(
                &admin_cap,
                &mut auction,
                &mut suins,
                &config,
                NODE,
                RESOLVER_ADDRESS,
                &mut ctx_util(FIRST_USER_ADDRESS, START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD, 10),
            );
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 2, 0);

            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 1300, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 1);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 12200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(scenario, admin_cap);
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);

            let coin1 = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin1) == 7200, 0);

            assert!(auction::get_balance(&auction) == 23500, 0);
            assert!(controller::get_balance(&suins) == 3000, 0);

            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin1);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AN_AUCTION_AT + 200,
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
            assert!(coin::value(&coin1) == 12200, 0);
            let coin2 = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin2) == 1300, 0);
            let coin3 = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin3) == 7200, 0);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 0, 0);

            assert!(auction::get_balance(&auction) == 10000, 0);
            assert!(controller::get_balance(&suins) == 3000, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin1);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin2);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin3);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_finalize_auction_by_admin_not_affect_non_revealed_bids_2() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, NODE);
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1300, FIRST_USER_ADDRESS, option::none());
        let seal_bid = make_seal_bid(NODE, SECOND_USER_ADDRESS, 2000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 12200, SECOND_USER_ADDRESS, option::none());

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            assert!(auction::get_balance(&auction) == 23500, 0);
            let coin = test_scenario::most_recent_id_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(option::is_none(&coin), 0);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);
            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 1300, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            let bids = get_bids_by_bidder(&auction, SECOND_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);
            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == SECOND_USER_ADDRESS, 0);
            assert!(mask == 12200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                1000,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);
            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 1300, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(is_unsealed, 0);

            let bids = get_bids_by_bidder(&auction, SECOND_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);
            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == SECOND_USER_ADDRESS, 0);
            assert!(mask == 12200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);

            finalize_auction_by_admin(
                &admin_cap,
                &mut auction,
                &mut suins,
                &config,
                NODE,
                RESOLVER_ADDRESS,
                &mut ctx_util(FIRST_USER_ADDRESS, START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD, 10),
            );
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 0, 0);

            let bids = get_bids_by_bidder(&auction, SECOND_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);
            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == SECOND_USER_ADDRESS, 0);
            assert!(mask == 12200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_to_sender(scenario, admin_cap);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);

            let coin1 = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin1) == 300, 0);

            assert!(auction::get_balance(&auction) == 22200, 0);
            assert!(controller::get_balance(&suins) == 1000, 0);

            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin1);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let ctx = tx_context::new(
                SECOND_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AN_AUCTION_AT + 200,
                20
            );
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 0, 0);
            let bids = get_bids_by_bidder(&auction, SECOND_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);
            withdraw(&mut auction, &mut ctx);

            let bids = get_bids_by_bidder(&auction, SECOND_USER_ADDRESS);
            assert!(vector::length(&bids) == 0, 0);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(SECOND_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);

            let coin = test_scenario::take_from_address<Coin<SUI>>(scenario, SECOND_USER_ADDRESS);
            assert!(coin::value(&coin) == 12200, 0);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 0, 0);
            let bids = get_bids_by_bidder(&auction, SECOND_USER_ADDRESS);
            assert!(vector::length(&bids) == 0, 0);

            assert!(auction::get_balance(&auction) == 10000, 0);
            assert!(controller::get_balance(&suins) == 1000, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_to_address(SECOND_USER_ADDRESS, coin);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_finalize_auction_by_admin_not_affect_non_winning_bids() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, NODE);
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1300, FIRST_USER_ADDRESS, option::none());
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 2000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 12200, FIRST_USER_ADDRESS, option::some(FIRST_TX_HASH));

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            assert!(auction::get_balance(&auction) == 13500, 0);
            let coin = test_scenario::most_recent_id_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(option::is_none(&coin), 0);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 2, 0);

            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 1300, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 1);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 12200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                1000,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );

            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                2000,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 2, 0);
            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 1300, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 1);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 12200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(is_unsealed, 0);

            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 2, 0);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 2, 0);

            finalize_auction_by_admin(
                &admin_cap,
                &mut auction,
                &mut suins,
                &config,
                NODE,
                RESOLVER_ADDRESS,
                &mut ctx_util(FIRST_USER_ADDRESS, START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD, 10),
            );
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);

            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 1300, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(is_unsealed, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(scenario, admin_cap);
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);

            let coin1 = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin1) == 11200, 0);

            assert!(auction::get_balance(&auction) == 1300, 0);
            assert!(controller::get_balance(&suins) == 11000, 0);

            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin1);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AN_AUCTION_AT + 200,
                20
            );
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);
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
            assert!(coin::value(&coin1) == 1300, 0);
            let coin2 = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin2) == 11200, 0);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 0, 0);

            assert!(auction::get_balance(&auction) == 0, 0);
            assert!(controller::get_balance(&suins) == 11000, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin1);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin2);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_finalize_auction_by_admin_not_affect_non_winning_bids_2() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, NODE);
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1300, FIRST_USER_ADDRESS, option::none());
        let seal_bid = make_seal_bid(NODE, SECOND_USER_ADDRESS, 2000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 12200, SECOND_USER_ADDRESS, option::some(FIRST_TX_HASH));

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            assert!(auction::get_balance(&auction) == 13500, 0);
            let coin = test_scenario::most_recent_id_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(option::is_none(&coin), 0);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);

            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 1300, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            let bids = get_bids_by_bidder(&auction, SECOND_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);
            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == SECOND_USER_ADDRESS, 0);
            assert!(mask == 12200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                1000,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );

            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                2000,
                FIRST_SECRET,
                SECOND_USER_ADDRESS,
                2
            );

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);
            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 1300, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(is_unsealed, 0);

            let bids = get_bids_by_bidder(&auction, SECOND_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);
            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == SECOND_USER_ADDRESS, 0);
            assert!(mask == 12200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(is_unsealed, 0);

            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);

            let ids = test_scenario::ids_for_address<Coin<SUI>>(SECOND_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);
            let bids = get_bids_by_bidder(&auction, SECOND_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);

            finalize_auction_by_admin(
                &admin_cap,
                &mut auction,
                &mut suins,
                &config,
                NODE,
                RESOLVER_ADDRESS,
                &mut ctx_util(FIRST_USER_ADDRESS, START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD, 10),
            );
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);
            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 1300, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(is_unsealed, 0);

            let bids = get_bids_by_bidder(&auction, SECOND_USER_ADDRESS);
            assert!(vector::length(&bids) == 0, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(scenario, admin_cap);
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);

            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);

            let ids = test_scenario::ids_for_address<Coin<SUI>>(SECOND_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);
            let coin = test_scenario::take_from_address<Coin<SUI>>(scenario, SECOND_USER_ADDRESS);
            assert!(coin::value(&coin) == 11200, 0);

            assert!(auction::get_balance(&auction) == 1300, 0);
            assert!(controller::get_balance(&suins) == 11000, 0);

            test_scenario::return_to_address(SECOND_USER_ADDRESS, coin);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                SECOND_TX_HASH,
                START_AN_AUCTION_AT + 200,
                20
            );
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);
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
            assert!(vector::length(&ids) == 1, 0);

            let coin1 = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin1) == 1300, 0);
            let coin2 = test_scenario::take_from_address<Coin<SUI>>(scenario, SECOND_USER_ADDRESS);
            assert!(coin::value(&coin2) == 11200, 0);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 0, 0);
            let bids = get_bids_by_bidder(&auction, SECOND_USER_ADDRESS);
            assert!(vector::length(&bids) == 0, 0);

            assert!(auction::get_balance(&auction) == 0, 0);
            assert!(controller::get_balance(&suins) == 11000, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin1);
            test_scenario::return_to_address(SECOND_USER_ADDRESS, coin2);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_place_bid_aborts_if_exists() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, NODE);

        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 2000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 3300, FIRST_USER_ADDRESS, option::none());
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 2000, SECOND_SECRET);
        place_bid_util(scenario, seal_bid, 12200, FIRST_USER_ADDRESS, option::none());
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_bids_multiple_times_same_domain_and_same_highest_value_then_finalize_by_admin() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, NODE);

        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 2000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 3300, FIRST_USER_ADDRESS, option::none());
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 2000, SECOND_SECRET);
        place_bid_util(scenario, seal_bid, 12200, FIRST_USER_ADDRESS, option::some(FIRST_TX_HASH));

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            assert!(auction::get_balance(&auction) == 25500, 0);
            let coin = test_scenario::most_recent_id_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(option::is_none(&coin), 0);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 2, 0);

            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 3300, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 1);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 12200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                2000,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );

            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                2000,
                SECOND_SECRET,
                FIRST_USER_ADDRESS,
                2
            );

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 2, 0);
            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 3300, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 1);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 12200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(is_unsealed, 0);

            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 2, 0);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);

            finalize_auction_by_admin(
                &admin_cap,
                &mut auction,
                &mut suins,
                &config,
                NODE,
                RESOLVER_ADDRESS,
                &mut ctx_util(FIRST_USER_ADDRESS, START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD, 10),
            );
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);

            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 12200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(is_unsealed, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_to_sender(scenario, admin_cap);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);

            let coin1 = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin1) == 1300, 0);

            assert!(auction::get_balance(&auction) == 22200, 0);
            assert!(controller::get_balance(&suins) == 2000, 0);

            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin1);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AN_AUCTION_AT + 200,
                20
            );
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);
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
            assert!(coin::value(&coin1) == 12200, 0);
            let coin2 = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin2) == 1300, 0);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 0, 0);

            assert!(auction::get_balance(&auction) == 10000, 0);
            assert!(controller::get_balance(&suins) == 2000, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin1);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin2);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_bids_multiple_times_same_domain_and_same_highest_value_then_finalize_by_admin_2() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, NODE);

        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 2000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 3300, FIRST_USER_ADDRESS, option::none());
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 2000, SECOND_SECRET);
        place_bid_util(scenario, seal_bid, 12200, FIRST_USER_ADDRESS, option::some(FIRST_TX_HASH));

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            assert!(auction::get_balance(&auction) == 25500, 0);
            let coin = test_scenario::most_recent_id_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(option::is_none(&coin), 0);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 2, 0);

            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 3300, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 1);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 12200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                2000,
                SECOND_SECRET,
                FIRST_USER_ADDRESS,
                2
            );

            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                2000,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 2, 0);
            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 3300, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 1);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 12200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(is_unsealed, 0);

            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 2, 0);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);

            finalize_auction_by_admin(
                &admin_cap,
                &mut auction,
                &mut suins,
                &config,
                NODE,
                RESOLVER_ADDRESS,
                &mut ctx_util(FIRST_USER_ADDRESS, START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD, 10),
            );
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);

            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 3300, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(is_unsealed, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_to_sender(scenario, admin_cap);
            test_scenario::return_shared(config);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);

            let coin1 = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin1) == 10200, 0);

            assert!(auction::get_balance(&auction) == 13300, 0);
            assert!(controller::get_balance(&suins) == 2000, 0);

            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin1);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AN_AUCTION_AT + 200,
                25
            );
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);
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
            assert!(coin::value(&coin1) == 3300, 0);
            let coin2 = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin2) == 10200, 0);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 0, 0);

            assert!(auction::get_balance(&auction) == 10000, 0);
            assert!(controller::get_balance(&suins) == 2000, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin1);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin2);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_bids_multiple_times_same_domain_and_same_highest_value_then_withdraw() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, NODE);

        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 2000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 3300, FIRST_USER_ADDRESS, option::none());
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 2000, SECOND_SECRET);
        place_bid_util(scenario, seal_bid, 12200, FIRST_USER_ADDRESS, option::some(FIRST_TX_HASH));

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            assert!(auction::get_balance(&auction) == 25500, 0);
            let coin = test_scenario::most_recent_id_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(option::is_none(&coin), 0);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 2, 0);

            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 3300, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 1);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 12200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                2000,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );

            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                2000,
                SECOND_SECRET,
                FIRST_USER_ADDRESS,
                2
            );

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 2, 0);
            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 3300, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 1);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 12200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(is_unsealed, 0);

            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                SECOND_TX_HASH,
                START_AN_AUCTION_AT + 200,
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
            assert!(coin::value(&coin1) == 12200, 0);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);

            assert!(auction::get_balance(&auction) == 13300, 0);
            assert!(controller::get_balance(&suins) == 0, 0);

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
        start_an_auction_util(scenario, NODE);

        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 2000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 3300, FIRST_USER_ADDRESS, option::none());
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 2000, SECOND_SECRET);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                FIRST_TX_HASH,
                START_AN_AUCTION_AT + 2,
                15,
            );
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let coin = coin::mint_for_testing<SUI>(30000, &mut ctx);
            auction::place_bid(&mut auction, seal_bid, 12200, &mut coin, &mut ctx);
            coin::destroy_for_testing(coin);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            assert!(auction::get_balance(&auction) == 25500, 0);
            let coin = test_scenario::most_recent_id_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(option::is_none(&coin), 0);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 2, 0);

            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 3300, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 1);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 12200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 2, 0);
            assert!(!is_unsealed, 0);

            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                2000,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );

            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                2000,
                SECOND_SECRET,
                FIRST_USER_ADDRESS,
                2
            );

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 2, 0);
            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 3300, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 1);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 12200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 2, 0);
            assert!(is_unsealed, 0);

            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                SECOND_TX_HASH,
                START_AN_AUCTION_AT + 200,
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
            assert!(coin::value(&coin1) == 12200, 0);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);

            assert!(auction::get_balance(&auction) == 13300, 0);
            assert!(controller::get_balance(&suins) == 0, 0);

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
        start_an_auction_util(scenario, NODE);

        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 2000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 12200, FIRST_USER_ADDRESS, option::none());
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 2000, SECOND_SECRET);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                FIRST_TX_HASH,
                START_AN_AUCTION_AT + 2,
                15,
            );
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let coin = coin::mint_for_testing<SUI>(30000, &mut ctx);
            auction::place_bid(&mut auction, seal_bid, 3300, &mut coin, &mut ctx);
            coin::destroy_for_testing(coin);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            assert!(auction::get_balance(&auction) == 25500, 0);
            let coin = test_scenario::most_recent_id_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(option::is_none(&coin), 0);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 2, 0);

            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 12200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 1);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 3300, 0);
            assert!(created_at == START_AN_AUCTION_AT + 2, 0);
            assert!(!is_unsealed, 0);

            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                2000,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );

            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                2000,
                SECOND_SECRET,
                FIRST_USER_ADDRESS,
                2
            );

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 2, 0);
            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 12200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 1);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 3300, 0);
            assert!(created_at == START_AN_AUCTION_AT + 2, 0);
            assert!(is_unsealed, 0);

            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                SECOND_TX_HASH,
                START_AN_AUCTION_AT + 200,
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
            assert!(coin::value(&coin1) == 3300, 0);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);

            assert!(auction::get_balance(&auction) == 22200, 0);
            assert!(controller::get_balance(&suins) == 0, 0);

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
        start_an_auction_util(scenario, NODE);

        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 2000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 3300, FIRST_USER_ADDRESS, option::none());
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 2000, SECOND_SECRET);
        place_bid_util(scenario, seal_bid, 12200, FIRST_USER_ADDRESS, option::none());

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            assert!(auction::get_balance(&auction) == 25500, 0);
            let coin = test_scenario::most_recent_id_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(option::is_none(&coin), 0);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 2, 0);

            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 3300, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 1);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 12200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AN_AUCTION_AT + 200,
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
            assert!(coin::value(&coin1) == 12200, 0);
            let coin2 = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin2) == 3300, 0);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 0, 0);

            assert!(auction::get_balance(&auction) == 10000, 0);
            assert!(controller::get_balance(&suins) == 0, 0);

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
        start_an_auction_util(scenario, NODE);

        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 2000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 3300, FIRST_USER_ADDRESS, option::none());
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 2000, SECOND_SECRET);
        place_bid_util(scenario, seal_bid, 12200, FIRST_USER_ADDRESS, option::none());

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            assert!(auction::get_balance(&auction) == 25500, 0);
            let coin = test_scenario::most_recent_id_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(option::is_none(&coin), 0);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 2, 0);

            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 3300, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 1);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 12200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            finalize_auction_util(
                scenario,
                &mut auction,
                NODE,
                FIRST_USER_ADDRESS,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD,
                10
            );

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 2, 0);
            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 3300, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 1);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 12200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AN_AUCTION_AT + 200,
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
            assert!(coin::value(&coin1) == 12200, 0);
            let coin2 = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin2) == 3300, 0);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 0, 0);

            assert!(auction::get_balance(&auction) == 10000, 0);
            assert!(controller::get_balance(&suins) == 0, 0);

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
        start_an_auction_util(scenario, NODE);

        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 10230, FIRST_USER_ADDRESS, option::none());
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_bid_util(&auction, seal_bid, FIRST_USER_ADDRESS, some(10230));
            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                1000,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );
            assert!(auction::get_balance(&auction) == 20230, 0);
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

            get_entry_util(&mut auction, NODE, START_AN_AUCTION_AT + 1, 1000, 0, FIRST_USER_ADDRESS, false);
            finalize_all_auctions_by_admin(
                &admin_cap,
                &mut auction,
                &mut suins,
                &config,
                RESOLVER_ADDRESS,
                &mut ctx_util(FIRST_USER_ADDRESS, EXTRA_PERIOD_START_AT, 20),
            );
            get_entry_util(&mut auction, NODE, START_AN_AUCTION_AT + 1, 1000, 0, FIRST_USER_ADDRESS, true);

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

            get_entry_util(&mut auction, NODE, START_AN_AUCTION_AT + 1, 1000, 0, FIRST_USER_ADDRESS, true);
            assert!(registrar::record_exists(&suins, SUI_REGISTRAR, NODE), 0);
            assert!(
                registrar::name_expires_at(&suins, SUI_REGISTRAR, NODE)
                    == EXTRA_PERIOD_START_AT + 365,
                0
            );
            assert!(registry::owner(&suins, NODE_SUI) == FIRST_USER_ADDRESS, 0);
            assert!(registry::ttl(&suins, NODE_SUI) == 0, 0);
            assert!(registry::resolver(&suins, NODE_SUI) == RESOLVER_ADDRESS, 0);
            assert!(auction::get_balance(&auction) == 10000, 0);
            assert!(controller::get_balance(&suins) == 1000, 0);

            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EAlreadyFinalized)]
    fun test_finalize_all_auctions_by_admin_aborts_if_the_winner_calls_finalize_later() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, NODE);

        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 10230, FIRST_USER_ADDRESS, option::none());
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_bid_util(&auction, seal_bid, FIRST_USER_ADDRESS, some(10230));
            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                1000,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );
            assert!(auction::get_balance(&auction) == 20230, 0);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);

            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);

            get_entry_util(&mut auction, NODE, START_AN_AUCTION_AT + 1, 1000, 0, FIRST_USER_ADDRESS, false);
            finalize_all_auctions_by_admin(
                &admin_cap,
                &mut auction,
                &mut suins,
                &config,
                RESOLVER_ADDRESS,
                &mut ctx_util(FIRST_USER_ADDRESS, EXTRA_PERIOD_START_AT, 20),
            );
            get_entry_util(&mut auction, NODE, START_AN_AUCTION_AT + 1, 1000, 0, FIRST_USER_ADDRESS, true);

            test_scenario::return_to_sender(scenario, admin_cap);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
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
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EInvalidPhase)]
    fun test_finalize_all_auctions_by_admin_aborts_if_admin_calls_finalize_later() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, NODE);

        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 10230, FIRST_USER_ADDRESS, option::none());
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_bid_util(&auction, seal_bid, FIRST_USER_ADDRESS, some(10230));
            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                1000,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );
            assert!(auction::get_balance(&auction) == 20230, 0);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);

            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);

            get_entry_util(&mut auction, NODE, START_AN_AUCTION_AT + 1, 1000, 0, FIRST_USER_ADDRESS, false);
            finalize_all_auctions_by_admin(
                &admin_cap,
                &mut auction,
                &mut suins,
                &config,
                RESOLVER_ADDRESS,
                &mut ctx_util(FIRST_USER_ADDRESS, EXTRA_PERIOD_START_AT, 20),
            );
            get_entry_util(&mut auction, NODE, START_AN_AUCTION_AT + 1, 1000, 0, FIRST_USER_ADDRESS, true);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_to_sender(scenario, admin_cap);
            test_scenario::return_shared(config);
        };
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);

            finalize_auction_by_admin(
                &admin_cap,
                &mut auction,
                &mut suins,
                &config,
                NODE,
                RESOLVER_ADDRESS,
                &mut ctx_util(FIRST_USER_ADDRESS, START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD, 20),
            );
            get_entry_util(&mut auction, NODE, START_AN_AUCTION_AT + 1, 1000, 0, FIRST_USER_ADDRESS, true);

            test_scenario::return_shared(auction);
            test_scenario::return_to_sender(scenario, admin_cap);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_finalize_all_auctions_by_admin_has_extra_period() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, NODE);

        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 10230, FIRST_USER_ADDRESS, option::none());
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_bid_util(&auction, seal_bid, FIRST_USER_ADDRESS, some(10230));
            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                1000,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );
            assert!(auction::get_balance(&auction) == 20230, 0);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);

            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);

            get_entry_util(&mut auction, NODE, START_AN_AUCTION_AT + 1, 1000, 0, FIRST_USER_ADDRESS, false);
            finalize_all_auctions_by_admin(
                &admin_cap,
                &mut auction,
                &mut suins,
                &config,
                RESOLVER_ADDRESS,
                &mut ctx_util(FIRST_USER_ADDRESS, EXTRA_PERIOD_START_AT + 1, 20),
            );
            get_entry_util(&mut auction, NODE, START_AN_AUCTION_AT + 1, 1000, 0, FIRST_USER_ADDRESS, true);

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

            get_entry_util(&mut auction, NODE, START_AN_AUCTION_AT + 1, 1000, 0, FIRST_USER_ADDRESS, true);
            assert!(registrar::record_exists(&suins, SUI_REGISTRAR, NODE), 0);
            assert!(
                registrar::name_expires_at(&suins, SUI_REGISTRAR, NODE)
                    == EXTRA_PERIOD_START_AT + 1 + 365,
                0
            );
            assert!(registry::owner(&suins, NODE_SUI) == FIRST_USER_ADDRESS, 0);
            assert!(registry::ttl(&suins, NODE_SUI) == 0, 0);
            assert!(registry::resolver(&suins, NODE_SUI) == RESOLVER_ADDRESS, 0);
            assert!(auction::get_balance(&auction) == 10000, 0);
            assert!(controller::get_balance(&suins) == 1000, 0);

            test_scenario::return_shared(suins);
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
        place_bid_util(scenario, seal_bid, 10230, FIRST_USER_ADDRESS, option::none());
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);

            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);

            assert!(auction::get_balance(&auction) == 20230, 0);
            assert!(controller::get_balance(&suins) == 0, 0);

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

            assert!(auction::get_balance(&auction) == 20230, 0);
            assert!(controller::get_balance(&suins) == 0, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EAuctionNotAvailable)]
    fun test_finalize_all_auctions_by_admin_aborts_if_too_late() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, NODE);

        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 10230, FIRST_USER_ADDRESS, option::none());
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_bid_util(&auction, seal_bid, FIRST_USER_ADDRESS, some(10230));
            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                1000,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );
            assert!(auction::get_balance(&auction) == 20230, 0);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);

            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);

            get_entry_util(&mut auction, NODE, START_AN_AUCTION_AT + 1, 1000, 0, FIRST_USER_ADDRESS, false);
            finalize_all_auctions_by_admin(
                &admin_cap,
                &mut auction,
                &mut suins,
                &config,
                RESOLVER_ADDRESS,
                &mut ctx_util(FIRST_USER_ADDRESS, START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD + 200, 20),
            );
            get_entry_util(&mut auction, NODE, START_AN_AUCTION_AT + 1, 1000, 0, FIRST_USER_ADDRESS, true);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_to_sender(scenario, admin_cap);
            test_scenario::return_shared(config);
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

    #[test]
    fun test_finalize_all_auctions_by_admin_not_affect_non_revealed_bids() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, NODE);
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1300, FIRST_USER_ADDRESS, option::none());
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 2000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 12200, FIRST_USER_ADDRESS, option::none());
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 3000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 10200, FIRST_USER_ADDRESS, option::none());

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            assert!(auction::get_balance(&auction) == 33700, 0);
            let coin = test_scenario::most_recent_id_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(option::is_none(&coin), 0);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 3, 0);

            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 1300, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 1);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 12200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 2);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 10200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                3000,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 3, 0);
            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 1300, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 1);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 12200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 2);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 10200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(is_unsealed, 0);
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
            assert!(mask == 1300, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 1);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 12200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 2);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 10200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(is_unsealed, 0);

            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 3, 0);

            get_entry_util(&mut auction, NODE, START_AN_AUCTION_AT + 1, 3000, 0, FIRST_USER_ADDRESS, false);
            finalize_all_auctions_by_admin(
                &admin_cap,
                &mut auction,
                &mut suins,
                &config,
                RESOLVER_ADDRESS,
                &mut ctx_util(FIRST_USER_ADDRESS, EXTRA_PERIOD_START_AT, 10),
            );
            get_entry_util(&mut auction, NODE, START_AN_AUCTION_AT + 1, 3000, 0, FIRST_USER_ADDRESS, true);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 2, 0);

            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 1300, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 1);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 12200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(scenario, admin_cap);
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);

            let coin1 = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin1) == 7200, 0);

            assert!(auction::get_balance(&auction) == 23500, 0);
            assert!(controller::get_balance(&suins) == 3000, 0);

            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin1);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AN_AUCTION_AT + 200,
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
            assert!(coin::value(&coin1) == 12200, 0);
            let coin2 = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin2) == 1300, 0);
            let coin3 = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin3) == 7200, 0);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 0, 0);

            assert!(auction::get_balance(&auction) == 10000, 0);
            assert!(controller::get_balance(&suins) == 3000, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin1);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin2);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin3);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_finalize_all_auctions_by_admin_not_affect_non_revealed_bids_2() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, NODE);
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1300, FIRST_USER_ADDRESS, option::none());
        let seal_bid = make_seal_bid(NODE, SECOND_USER_ADDRESS, 2000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 12200, SECOND_USER_ADDRESS, option::none());

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            assert!(auction::get_balance(&auction) == 23500, 0);
            let coin = test_scenario::most_recent_id_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(option::is_none(&coin), 0);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);
            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 1300, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            let bids = get_bids_by_bidder(&auction, SECOND_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);
            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == SECOND_USER_ADDRESS, 0);
            assert!(mask == 12200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                1000,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);
            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 1300, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(is_unsealed, 0);

            let bids = get_bids_by_bidder(&auction, SECOND_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);
            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == SECOND_USER_ADDRESS, 0);
            assert!(mask == 12200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);

            get_entry_util(&mut auction, NODE, START_AN_AUCTION_AT + 1, 1000, 0, FIRST_USER_ADDRESS, false);
            finalize_all_auctions_by_admin(
                &admin_cap,
                &mut auction,
                &mut suins,
                &config,
                RESOLVER_ADDRESS,
                &mut ctx_util(FIRST_USER_ADDRESS, EXTRA_PERIOD_START_AT, 10),
            );
            get_entry_util(&mut auction, NODE, START_AN_AUCTION_AT + 1, 1000, 0, FIRST_USER_ADDRESS, true);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 0, 0);

            let bids = get_bids_by_bidder(&auction, SECOND_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);
            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == SECOND_USER_ADDRESS, 0);
            assert!(mask == 12200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_to_sender(scenario, admin_cap);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);

            let coin1 = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin1) == 300, 0);

            assert!(auction::get_balance(&auction) == 22200, 0);
            assert!(controller::get_balance(&suins) == 1000, 0);

            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin1);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let ctx = tx_context::new(
                SECOND_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AN_AUCTION_AT + 200,
                20
            );
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 0, 0);
            let bids = get_bids_by_bidder(&auction, SECOND_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);
            withdraw(&mut auction, &mut ctx);

            let bids = get_bids_by_bidder(&auction, SECOND_USER_ADDRESS);
            assert!(vector::length(&bids) == 0, 0);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(SECOND_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);

            let coin = test_scenario::take_from_address<Coin<SUI>>(scenario, SECOND_USER_ADDRESS);
            assert!(coin::value(&coin) == 12200, 0);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 0, 0);
            let bids = get_bids_by_bidder(&auction, SECOND_USER_ADDRESS);
            assert!(vector::length(&bids) == 0, 0);

            assert!(auction::get_balance(&auction) == 10000, 0);
            assert!(controller::get_balance(&suins) == 1000, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_to_address(SECOND_USER_ADDRESS, coin);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_finalize_all_auctions_by_admin_not_affect_non_winning_bids() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, NODE);
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1300, FIRST_USER_ADDRESS, option::none());
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 2000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 12200, FIRST_USER_ADDRESS, option::some(FIRST_TX_HASH));

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            assert!(auction::get_balance(&auction) == 23500, 0);
            let coin = test_scenario::most_recent_id_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(option::is_none(&coin), 0);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 2, 0);

            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 1300, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 1);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 12200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                1000,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );

            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                2000,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 2, 0);
            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 1300, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 1);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 12200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(is_unsealed, 0);

            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 2, 0);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 2, 0);

            get_entry_util(&mut auction, NODE, START_AN_AUCTION_AT + 1, 2000, 1000, FIRST_USER_ADDRESS, false);
            finalize_all_auctions_by_admin(
                &admin_cap,
                &mut auction,
                &mut suins,
                &config,
                RESOLVER_ADDRESS,
                &mut ctx_util(FIRST_USER_ADDRESS, EXTRA_PERIOD_START_AT + 1, 10),
            );
            get_entry_util(&mut auction, NODE, START_AN_AUCTION_AT + 1, 2000, 1000, FIRST_USER_ADDRESS, true);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);

            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 1300, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(is_unsealed, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_to_sender(scenario, admin_cap);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);

            let coin1 = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin1) == 11200, 0);

            assert!(auction::get_balance(&auction) == 11300, 0);
            assert!(controller::get_balance(&suins) == 1000, 0);

            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin1);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AN_AUCTION_AT + 200,
                20
            );
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);
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
            assert!(coin::value(&coin1) == 1300, 0);
            let coin2 = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin2) == 11200, 0);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 0, 0);

            assert!(auction::get_balance(&auction) == 10000, 0);
            assert!(controller::get_balance(&suins) == 1000, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin1);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin2);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_finalize_all_auctions_by_admin_not_affect_non_winning_bids_2() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, NODE);
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1300, FIRST_USER_ADDRESS, option::none());
        let seal_bid = make_seal_bid(NODE, SECOND_USER_ADDRESS, 2000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 12200, SECOND_USER_ADDRESS, option::some(FIRST_TX_HASH));

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            assert!(auction::get_balance(&auction) == 23500, 0);
            let coin = test_scenario::most_recent_id_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(option::is_none(&coin), 0);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);

            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 1300, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            let bids = get_bids_by_bidder(&auction, SECOND_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);
            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == SECOND_USER_ADDRESS, 0);
            assert!(mask == 12200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                1000,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );

            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                2000,
                FIRST_SECRET,
                SECOND_USER_ADDRESS,
                2
            );

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);
            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 1300, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(is_unsealed, 0);

            let bids = get_bids_by_bidder(&auction, SECOND_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);
            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == SECOND_USER_ADDRESS, 0);
            assert!(mask == 12200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(is_unsealed, 0);

            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);

            let ids = test_scenario::ids_for_address<Coin<SUI>>(SECOND_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);
            let bids = get_bids_by_bidder(&auction, SECOND_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);

            get_entry_util(&mut auction, NODE, START_AN_AUCTION_AT + 1, 2000, 1000, SECOND_USER_ADDRESS, false);
            finalize_all_auctions_by_admin(
                &admin_cap,
                &mut auction,
                &mut suins,
                &config,
                RESOLVER_ADDRESS,
                &mut ctx_util(FIRST_USER_ADDRESS, EXTRA_PERIOD_START_AT, 10),
            );
            get_entry_util(&mut auction, NODE, START_AN_AUCTION_AT + 1, 2000, 1000, SECOND_USER_ADDRESS, true);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);
            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 1300, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(is_unsealed, 0);

            let bids = get_bids_by_bidder(&auction, SECOND_USER_ADDRESS);
            assert!(vector::length(&bids) == 0, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_to_sender(scenario, admin_cap);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);

            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);

            let ids = test_scenario::ids_for_address<Coin<SUI>>(SECOND_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);
            let coin = test_scenario::take_from_address<Coin<SUI>>(scenario, SECOND_USER_ADDRESS);
            assert!(coin::value(&coin) == 11200, 0);

            assert!(auction::get_balance(&auction) == 11300, 0);
            assert!(controller::get_balance(&suins) == 1000, 0);

            test_scenario::return_to_address(SECOND_USER_ADDRESS, coin);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AN_AUCTION_AT + 200,
                20
            );
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);
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
            assert!(vector::length(&ids) == 1, 0);

            let coin1 = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin1) == 1300, 0);
            let coin2 = test_scenario::take_from_address<Coin<SUI>>(scenario, SECOND_USER_ADDRESS);
            assert!(coin::value(&coin2) == 11200, 0);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 0, 0);
            let bids = get_bids_by_bidder(&auction, SECOND_USER_ADDRESS);
            assert!(vector::length(&bids) == 0, 0);

            assert!(auction::get_balance(&auction) == 10000, 0);
            assert!(controller::get_balance(&suins) == 1000, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin1);
            test_scenario::return_to_address(SECOND_USER_ADDRESS, coin2);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_bids_multiple_times_same_domain_and_same_highest_value_then_finalize_all_auctions_by_admin() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, NODE);

        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 2000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 3300, FIRST_USER_ADDRESS, option::none());
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 2000, SECOND_SECRET);
        place_bid_util(scenario, seal_bid, 12200, FIRST_USER_ADDRESS, option::some(FIRST_TX_HASH));

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            assert!(auction::get_balance(&auction) == 25500, 0);
            let coin = test_scenario::most_recent_id_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(option::is_none(&coin), 0);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 2, 0);

            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 3300, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 1);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 12200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                2000,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );

            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                2000,
                SECOND_SECRET,
                FIRST_USER_ADDRESS,
                2
            );

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 2, 0);
            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 3300, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 1);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 12200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(is_unsealed, 0);

            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 2, 0);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);

            finalize_all_auctions_by_admin(
                &admin_cap,
                &mut auction,
                &mut suins,
                &config,
                RESOLVER_ADDRESS,
                &mut ctx_util(FIRST_USER_ADDRESS, EXTRA_PERIOD_START_AT, 10),
            );
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);

            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 12200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(is_unsealed, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_to_sender(scenario, admin_cap);
            test_scenario::return_shared(config);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);

            let coin1 = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin1) == 1300, 0);

            assert!(auction::get_balance(&auction) == 22200, 0);
            assert!(controller::get_balance(&suins) == 2000, 0);

            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin1);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AN_AUCTION_AT + 200,
                25
            );
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);
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
            assert!(coin::value(&coin1) == 12200, 0);
            let coin2 = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin2) == 1300, 0);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 0, 0);

            assert!(auction::get_balance(&auction) == 10000, 0);
            assert!(controller::get_balance(&suins) == 2000, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin1);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin2);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_bids_multiple_times_same_domain_and_same_highest_value_then_finalize_all_auctions_by_admin_2() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, NODE);

        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 2000, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 3300, FIRST_USER_ADDRESS, option::none());
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 2000, SECOND_SECRET);
        place_bid_util(scenario, seal_bid, 12200, FIRST_USER_ADDRESS, option::some(FIRST_TX_HASH));

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            assert!(auction::get_balance(&auction) == 25500, 0);
            let coin = test_scenario::most_recent_id_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(option::is_none(&coin), 0);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 2, 0);

            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 3300, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 1);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 12200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                2000,
                SECOND_SECRET,
                FIRST_USER_ADDRESS,
                2
            );

            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                NODE,
                2000,
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 2, 0);
            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 3300, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 1);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 12200, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(is_unsealed, 0);

            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 2, 0);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);

            finalize_all_auctions_by_admin(
                &admin_cap,
                &mut auction,
                &mut suins,
                &config,
                RESOLVER_ADDRESS,
                &mut ctx_util(FIRST_USER_ADDRESS, EXTRA_PERIOD_START_AT, 10),
            );
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);

            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 3300, 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(is_unsealed, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_to_sender(scenario, admin_cap);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);

            let coin1 = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin1) == 10200, 0);

            assert!(auction::get_balance(&auction) == 13300, 0);
            assert!(controller::get_balance(&suins) == 2000, 0);

            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin1);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AN_AUCTION_AT + 200,
                25
            );
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);
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
            assert!(coin::value(&coin1) == 3300, 0);
            let coin2 = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin2) == 10200, 0);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 0, 0);

            assert!(auction::get_balance(&auction) == 10000, 0);
            assert!(controller::get_balance(&suins) == 2000, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin1);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin2);
        };
        test_scenario::end(scenario_val);
    }
}
