#[test_only]
module suins::auction_tests {

    use sui::test_scenario::{Self, Scenario, ctx};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::dynamic_field;
    use sui::tx_context::{Self, TxContext};
    use suins::auction::{Self, make_seal_bid, get_seal_bid_by_bidder, finalize_auction, get_bids_by_bidder, get_bid_detail_fields, withdraw, state, AuctionHouse};
    use suins::registry;
    use suins::registrar;
    use suins::string_utils;
    use suins::configuration::{Self, Configuration};
    use suins::suins::{Self, SuiNS, AdminCap};
    use std::vector;
    use std::option::{Self, Option, some, is_some};
    use suins::controller;
    use sui::clock::Clock;
    use sui::clock;
    use std::string::utf8;

    const SUINS_ADDRESS: address = @0xA001;
    const FIRST_USER_ADDRESS: address = @0xB001;
    const SECOND_USER_ADDRESS: address = @0xB002;
    const THIRD_USER_ADDRESS: address = @0xB003;
    const HASH: vector<u8> = b"vUAgEwNmPr";
    const DOMAIN_NAME: vector<u8> = vector[
        97, // 'a'
        98, // 'b'
        99, // 'c'
        102,
        105,
    ];
    const SECOND_DOMAIN_NAME: vector<u8> = b"suins2";
    const THIRD_DOMAIN_NAME: vector<u8> = b"suins3";
    const DOMAIN_NAME_SUI: vector<u8> = vector[
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

    public fun test_init(): Scenario {
        let scenario = test_scenario::begin(SUINS_ADDRESS);
        {
            let ctx = ctx(&mut scenario);
            auction::test_init(ctx);
            configuration::test_init(ctx);
            suins::test_init(ctx);
            clock::share_for_testing(clock::create_for_testing(ctx));
        };
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let auction = test_scenario::take_shared<AuctionHouse>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            registrar::new_tld(&admin_cap, &mut suins, utf8(MOVE_REGISTRAR), test_scenario::ctx(&mut scenario));
            registrar::new_tld(&admin_cap, &mut suins, utf8(SUI_REGISTRAR), test_scenario::ctx(&mut scenario));

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

    public fun start_an_auction_util(scenario: &mut Scenario, domain_name: vector<u8>) {
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
            let (start_at, highest_bid, second_highest_bid, winner, is_finalized) = auction::get_entry(&auction, utf8(domain_name));
            assert!(option::is_none(&start_at), 0);
            assert!(option::is_none(&highest_bid), 0);
            assert!(option::is_none(&second_highest_bid), 0);
            assert!(option::is_none(&winner), 0);
            assert!(option::is_none(&is_finalized), 0);
            assert!(state_util(&auction, domain_name, 10) == AUCTION_STATE_NOT_AVAILABLE, 0);
            assert!(state_util(&auction, domain_name, START_AN_AUCTION_AT) == AUCTION_STATE_OPEN, 0);

            let coin = coin::mint_for_testing<SUI>(3 * START_AN_AUCTION_FEE, ctx);

            auction::start_an_auction(&mut auction, &mut suins, utf8(domain_name), &mut coin, ctx);
            assert!(controller::get_balance(&suins) == START_AN_AUCTION_FEE, 0);
            assert!(coin::value(&coin) == 2 * START_AN_AUCTION_FEE, 0);
            assert!(state_util(&auction, domain_name, START_AN_AUCTION_AT) == AUCTION_STATE_PENDING, 0);
            assert!(state_util(&auction, domain_name, START_AN_AUCTION_AT + 1) == AUCTION_STATE_BIDDING, 0);
            assert!(state_util(&auction, domain_name, START_AN_AUCTION_AT + 1 + BIDDING_PERIOD) == AUCTION_STATE_REVEAL, 0);

            // receive no bid
            let state = state_util(
                &auction,
                domain_name,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD
            );
            assert!(state == AUCTION_STATE_REOPENED || state == AUCTION_STATE_NOT_AVAILABLE, 0);
            let (start_at, highest_bid, second_highest_bid, winner, is_finalized) = auction::get_entry(&auction, utf8(domain_name));
            assert!(option::extract(&mut start_at) == START_AN_AUCTION_AT + 1, 0);
            assert!(option::extract(&mut highest_bid) == 0, 0);
            assert!(option::extract(&mut second_highest_bid) == 0, 0);
            assert!(option::extract(&mut winner) == @0x0, 0);
            assert!(option::extract(&mut is_finalized) == false, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            coin::burn_for_testing(coin);
        };
    }

    public fun reveal_bid_util(
        auction: &mut AuctionHouse,
        config: &Configuration,
        epoch: u64,
        domain_name: vector<u8>,
        value: u64,
        secret: vector<u8>,
        sender: address,
        ids_created: u64
    ) {
        let ctx = ctx_new(
            sender,
            x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
            epoch,
            ids_created
        );
        auction::reveal_bid(auction, config, utf8(domain_name), value, secret, &mut ctx);
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
        domain_name: vector<u8>,
        expected_start_at: u64,
        expected_highest_bid: u64,
        expected_second_highest_bid: u64,
        expected_winner: address,
        expected_is_finalized: bool,
    ) {
        let (start_at, highest_bid, second_highest_bid, winner, is_finalized) = auction::get_entry(auction, utf8(domain_name));
        assert!(option::extract(&mut start_at) == expected_start_at, 0);
        assert!(option::extract(&mut highest_bid) == expected_highest_bid, 0);
        assert!(option::extract(&mut second_highest_bid) == expected_second_highest_bid, 0);
        assert!(option::extract(&mut winner) == expected_winner, 0);
        assert!(option::extract(&mut is_finalized) == expected_is_finalized, 0);
    }

    public fun finalize_auction_util(
        scenario: &mut Scenario,
        auction: &mut AuctionHouse,
        domain_name: vector<u8>,
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
        finalize_auction(auction, &mut suins, &config, utf8(domain_name), &mut ctx);
        test_scenario::return_shared(suins);
        test_scenario::return_shared(config);
    }

    public fun state_util(auction: &AuctionHouse, domain_name: vector<u8>, epoch: u64): u8 {
        let ctx = ctx_new(
            SUINS_ADDRESS,
            x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
            epoch,
            10
        );
        state(auction, utf8(domain_name), tx_context::epoch(&ctx))
    }

    public fun place_bid_util(
        scenario: &mut Scenario,
        seal_bid: vector<u8>,
        bid_value_mask: u64,
        bidder: address,
        clock_tick: u64,
        tx_hash: Option<vector<u8>>,
        ids_created: u64,
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
                ids_created,
            );
            let ctx = &mut ctx;
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let coin = coin::mint_for_testing<SUI>(BIDDING_FEE * 3 + bid_value_mask, ctx);
            let amount = auction::get_seal_bid_by_bidder(&auction, seal_bid, bidder);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            clock::increment_for_testing(&mut clock, clock_tick);

            assert!(option::is_none(&amount), 0);
            auction::place_bid(&mut auction, &mut suins, &config, seal_bid, bid_value_mask, &mut coin, &clock, ctx);

            let amount = auction::get_seal_bid_by_bidder(&auction, seal_bid, bidder);
            assert!(option::extract(&mut amount) == bid_value_mask, 0);
            assert!(coin::value(&coin) == BIDDING_FEE * 2, 0);

            coin::burn_for_testing(coin);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
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
            place_bid_util(scenario, HASH, 1000 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);
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
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            place_bid_util(scenario, DOMAIN_NAME, 1200 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);
        };
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 2, 0);

            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 1000 * configuration::mist_per_sui(), 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 1);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 1200 * configuration::mist_per_sui(), 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);
            assert!(auction::get_balance(&auction) == 2200 * configuration::mist_per_sui(), 0);

            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            place_bid_util(scenario, b"bidbid", 12200 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);
        };
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 3, 0);

            let bid_detail = vector::borrow(&bids, 1);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 1200 * configuration::mist_per_sui(), 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            let bid_detail = vector::borrow(&bids, 2);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 12200 * configuration::mist_per_sui(), 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);
            assert!(auction::get_balance(&auction) == 14400 * configuration::mist_per_sui(), 0);

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
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            let coin = coin::mint_for_testing<SUI>(1000 * configuration::mist_per_sui(), ctx);
            let config = test_scenario::take_shared<Configuration>(scenario);
            auction::place_bid(&mut auction, &mut suins, &config, HASH, 100, &mut coin, &clock, ctx);
            place_bid_util(scenario, HASH, 100, FIRST_USER_ADDRESS, 0, option::none(), 10);
            coin::burn_for_testing(coin);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
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
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let coin = coin::mint_for_testing<SUI>(1000 * configuration::mist_per_sui() + BIDDING_FEE, ctx);
            let clock = test_scenario::take_shared<Clock>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);

            auction::place_bid(&mut auction, &mut suins, &config, HASH, 1000 * configuration::mist_per_sui(), &mut coin, &clock, ctx);
            assert!(coin::value(&coin) == 0, 0);

            coin::burn_for_testing(coin);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            let coin = coin::mint_for_testing<SUI>(10000 * configuration::mist_per_sui(), ctx(scenario));
            let config = test_scenario::take_shared<Configuration>(scenario);

            assert!(auction::get_balance(&auction) == 1000 * configuration::mist_per_sui(), 0);
			auction::place_bid(&mut auction, &mut suins, &config, HASH, 1000 * configuration::mist_per_sui(), &mut coin, &clock, ctx);
            coin::burn_for_testing(coin);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EInvalidPhase)]
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
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            let coin = coin::mint_for_testing<SUI>(10000 * configuration::mist_per_sui(), ctx);
            let config = test_scenario::take_shared<Configuration>(scenario);
            auction::place_bid(&mut auction, &mut suins, &config, HASH, 1000 * configuration::mist_per_sui(), &mut coin, &clock, ctx);
            coin::burn_for_testing(coin);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EInvalidPhase)]
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
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            let coin = coin::mint_for_testing<SUI>(10000 * configuration::mist_per_sui(), ctx);
            let config = test_scenario::take_shared<Configuration>(scenario);
            auction::place_bid(&mut auction, &mut suins, &config, HASH, 1000 * configuration::mist_per_sui(), &mut coin, &clock, ctx);
            coin::burn_for_testing(coin);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EInvalidPhase)]
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
            let clock = test_scenario::take_shared<Clock>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let coin = coin::mint_for_testing<SUI>(10000 * configuration::mist_per_sui(), ctx);
            let config = test_scenario::take_shared<Configuration>(scenario);
            auction::place_bid(&mut auction, &mut suins, &config, HASH, 1000 * configuration::mist_per_sui(), &mut coin, &clock, ctx);
            coin::burn_for_testing(coin);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
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
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let coin = coin::mint_for_testing<SUI>(30 * START_AN_AUCTION_FEE, ctx);

            assert!(auction::get_balance(&auction) == 0, 0);
            auction::start_an_auction(&mut auction, &mut suins, utf8(DOMAIN_NAME), &mut coin, ctx);
            assert!(auction::get_balance(&auction) == 0, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            coin::burn_for_testing(coin);
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
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let coin = coin::mint_for_testing<SUI>(1000 * configuration::mist_per_sui() + BIDDING_FEE, ctx);
            let clock = test_scenario::take_shared<Clock>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);

            assert!(auction::get_balance(&auction) == 0, 0);
            auction::place_bid(&mut auction, &mut suins, &config, HASH, 1000 * configuration::mist_per_sui(), &mut coin, &clock, ctx);

            coin::burn_for_testing(coin);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);

            assert!(controller::get_balance(&suins) == START_AN_AUCTION_FEE + BIDDING_FEE, 0);
            assert!(auction::get_balance(&auction) == 1000 * configuration::mist_per_sui(), 0);

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
        start_an_auction_util(scenario, DOMAIN_NAME);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);

            assert!(auction::get_balance(&auction) == 0, 0);
            assert!(controller::get_balance(&suins) == START_AN_AUCTION_FEE, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EInvalidPhase)]
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
            let coin = coin::mint_for_testing<SUI>(30000, ctx);

            auction::start_an_auction(&mut auction, &mut suins, utf8(DOMAIN_NAME), &mut coin, ctx);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            coin::burn_for_testing(coin);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EInvalidPhase)]
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
            let coin = coin::mint_for_testing<SUI>(30000, ctx);

            auction::start_an_auction(&mut auction, &mut suins, utf8(DOMAIN_NAME), &mut coin, ctx);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            coin::burn_for_testing(coin);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = string_utils::EInvalidLabel)]
    fun test_start_an_auction_aborts_if_domain_name_too_short() {
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
            let coin = coin::mint_for_testing<SUI>(3 * START_AN_AUCTION_FEE, ctx);

            auction::start_an_auction(&mut auction, &mut suins, utf8(b"su"), &mut coin, ctx);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            coin::burn_for_testing(coin);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = string_utils::EInvalidLabel)]
    fun test_start_an_auction_aborts_if_domain_name_too_long() {
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
            let coin = coin::mint_for_testing<SUI>(3 * START_AN_AUCTION_FEE, ctx);

            auction::start_an_auction(
                &mut auction,
                &mut suins,
                utf8(b"suinssusuinssusuinssusuinssusuinssusuinssusuinssusuinssusuinssusuinssusuinssusuinssu"),
                &mut coin,
                ctx,
            );

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            coin::burn_for_testing(coin);
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
            let test_coin = coin::mint_for_testing<SUI>(3 * START_AN_AUCTION_FEE, ctx);

            auction::start_an_auction(&mut auction, &mut suins, utf8(DOMAIN_NAME), &mut test_coin, ctx);
            assert!(coin::value(&test_coin) == 2 * START_AN_AUCTION_FEE, 0);

            auction::start_an_auction(&mut auction, &mut suins, utf8(DOMAIN_NAME), &mut test_coin, ctx);

            coin::burn_for_testing(test_coin);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
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
            let coin = coin::mint_for_testing<SUI>(3 * START_AN_AUCTION_FEE, &mut ctx);

            auction::start_an_auction(&mut auction, &mut suins, utf8(DOMAIN_NAME), &mut coin, &mut ctx);

            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                111,
                0
            );
            auction::start_an_auction(&mut auction, &mut suins, utf8(DOMAIN_NAME), &mut coin, &mut ctx);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            coin::burn_for_testing(coin);
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
            let coin = coin::mint_for_testing<SUI>(3 * START_AN_AUCTION_FEE, &mut ctx);

            auction::start_an_auction(&mut auction, &mut suins, utf8(DOMAIN_NAME), &mut coin, &mut ctx);

            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                111 + BIDDING_PERIOD,
                0
            );
            auction::start_an_auction(&mut auction, &mut suins, utf8(DOMAIN_NAME), &mut coin, &mut ctx);

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
            let coin = coin::mint_for_testing<SUI>(3 * START_AN_AUCTION_FEE, &mut ctx);

            assert!(auction::get_balance(&auction) == 0, 0);
            assert!(controller::get_balance(&suins) == 0, 0);

            auction::start_an_auction(&mut auction, &mut suins, utf8(DOMAIN_NAME), &mut coin, &mut ctx);

            assert!(coin::value(&coin) == 2 * START_AN_AUCTION_FEE, 0);
            assert!(auction::get_balance(&auction) == 0, 0);
            assert!(controller::get_balance(&suins) == START_AN_AUCTION_FEE, 0);

            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                111 + BIDDING_PERIOD + REVEAL_PERIOD,
                0
            );
            auction::start_an_auction(&mut auction, &mut suins, utf8(DOMAIN_NAME), &mut coin, &mut ctx);

            assert!(auction::get_balance(&auction) == 0, 0);
            assert!(controller::get_balance(&suins) == 2 * START_AN_AUCTION_FEE, 0);
            assert!(coin::value(&coin) == START_AN_AUCTION_FEE, 0);

            coin::burn_for_testing(coin);
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
        start_an_auction_util(scenario, DOMAIN_NAME);

        let seal_bid = make_seal_bid(DOMAIN_NAME, FIRST_USER_ADDRESS, 1300 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1300 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            get_bid_util(&auction, seal_bid, FIRST_USER_ADDRESS, some(1300 * configuration::mist_per_sui()));
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                DOMAIN_NAME,
                1300 * configuration::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );
            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
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
            let coin = coin::mint_for_testing<SUI>(10 * configuration::mist_per_sui(), &mut ctx);

            auction::start_an_auction(&mut auction, &mut suins, utf8(DOMAIN_NAME), &mut coin, &mut ctx);

            coin::burn_for_testing(coin);
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
        start_an_auction_util(scenario, DOMAIN_NAME);

        let seal_bid = make_seal_bid(DOMAIN_NAME, FIRST_USER_ADDRESS, 1300 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1300 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);

            assert!(auction::get_balance(&auction) == 1300 * configuration::mist_per_sui(), 0);
            get_bid_util(&auction, seal_bid, FIRST_USER_ADDRESS, some(1300 * configuration::mist_per_sui()));
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                DOMAIN_NAME,
                1300 * configuration::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );

            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
        };

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_entry_util(&auction, DOMAIN_NAME, START_AN_AUCTION_AT + 1, 1300 * configuration::mist_per_sui(), 0, FIRST_USER_ADDRESS, false);
            finalize_auction_util(
                scenario,
                &mut auction,
                DOMAIN_NAME,
                FIRST_USER_ADDRESS,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD,
                10
            );
            get_entry_util(&auction, DOMAIN_NAME, START_AN_AUCTION_AT + 1, 1300 * configuration::mist_per_sui(), 0, FIRST_USER_ADDRESS, true);
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
            assert!(controller::get_balance(&suins) == START_AN_AUCTION_FEE + 1300 * configuration::mist_per_sui() + BIDDING_FEE, 0);

            auction::start_an_auction(&mut auction, &mut suins, utf8(DOMAIN_NAME), &mut coin, &mut ctx);

            coin::burn_for_testing(coin);
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

        let seal_bid = make_seal_bid(DOMAIN_NAME, FIRST_USER_ADDRESS, 1000 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1100 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                115,
                10
            );
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let coin = test_scenario::most_recent_id_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);

            assert!(option::is_none(&coin), 0);
            auction::reveal_bid(&mut auction, &config, utf8(DOMAIN_NAME), 1000 * configuration::mist_per_sui(), FIRST_SECRET, &mut ctx);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_reveal_bid() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, DOMAIN_NAME);

        let seal_bid = make_seal_bid(DOMAIN_NAME, FIRST_USER_ADDRESS, 1200 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1300 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            get_bid_util(&auction, seal_bid, FIRST_USER_ADDRESS, some(1300 * configuration::mist_per_sui()));
            let coin = test_scenario::most_recent_id_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(option::is_none(&coin), 0);
            assert!(auction::get_balance(&auction) == 1300 * configuration::mist_per_sui(), 0);

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);

            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 1300 * configuration::mist_per_sui(), 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            assert!(
                state_util(
                    &auction,
                    DOMAIN_NAME,
                    START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD
                ) == AUCTION_STATE_REOPENED,
                0
            );
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                DOMAIN_NAME,
                1200 * configuration::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );

            assert!(
                state_util(
                    &auction,
                    DOMAIN_NAME,
                    START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD
                ) == AUCTION_STATE_FINALIZING,
                0
            );

            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);

            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 1300 * configuration::mist_per_sui(), 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(is_unsealed, 0);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            assert!(auction::get_balance(&auction) == 1300 * configuration::mist_per_sui(), 0);
            assert!(!test_scenario::has_most_recent_for_address<Coin<SUI>>(FIRST_USER_ADDRESS), 0);
            test_scenario::return_shared(auction);
        };

        let seal_bid = make_seal_bid(DOMAIN_NAME, SECOND_USER_ADDRESS, 1500 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 2000 * configuration::mist_per_sui(), SECOND_USER_ADDRESS, 0, option::some(FIRST_TX_HASH), 10);
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);

            assert!(auction::get_balance(&auction) == 3300 * configuration::mist_per_sui(), 0);
            get_bid_util(&auction, seal_bid, SECOND_USER_ADDRESS, some(2000 * configuration::mist_per_sui()));

            let coin = test_scenario::most_recent_id_for_address<Coin<SUI>>(SECOND_USER_ADDRESS);
            assert!(option::is_none(&coin), 0);

            let bids = get_bids_by_bidder(&auction, SECOND_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);

            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == SECOND_USER_ADDRESS, 0);
            assert!(mask == 2000 * configuration::mist_per_sui(), 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(!is_unsealed, 0);

            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                DOMAIN_NAME,
                1500 * configuration::mist_per_sui(),
                FIRST_SECRET,
                SECOND_USER_ADDRESS,
                10
            );

            let bids = get_bids_by_bidder(&auction, SECOND_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);
            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at, is_unsealed) = get_bid_detail_fields(bid_detail);
            assert!(bidder == SECOND_USER_ADDRESS, 0);
            assert!(mask == 2000 * configuration::mist_per_sui(), 0);
            assert!(created_at == START_AN_AUCTION_AT + 1, 0);
            assert!(is_unsealed, 0);

            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, DOMAIN_NAME), 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
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
            assert!(auction::get_balance(&auction) == 3300 * configuration::mist_per_sui(), 0);

            get_entry_util(&mut auction, DOMAIN_NAME, START_AN_AUCTION_AT + 1, 1500 * configuration::mist_per_sui(), 1200 * configuration::mist_per_sui(), SECOND_USER_ADDRESS, false);
            finalize_auction_util(
                scenario,
                &mut auction,
                DOMAIN_NAME,
                SECOND_USER_ADDRESS,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD,
                20
            );
            get_entry_util(&mut auction, DOMAIN_NAME, START_AN_AUCTION_AT + 1, 1500 * configuration::mist_per_sui(), 1200 * configuration::mist_per_sui(), SECOND_USER_ADDRESS, true);

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
            assert!(coin::value(&coin) == 800 * configuration::mist_per_sui(), 0);
            assert!(auction::get_balance(&auction) == 1300 * configuration::mist_per_sui(), 0);
            assert!(controller::get_balance(&suins) == START_AN_AUCTION_FEE + 1140 * configuration::mist_per_sui() + BIDDING_FEE * 2, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_to_address(SECOND_USER_ADDRESS, coin);
        };
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            get_entry_util(&mut auction, DOMAIN_NAME, START_AN_AUCTION_AT + 1, 1500 * configuration::mist_per_sui(), 1200 * configuration::mist_per_sui(), SECOND_USER_ADDRESS, true);
            assert!(registrar::record_exists(&suins, SUI_REGISTRAR, DOMAIN_NAME), 0);
            assert!(
                registrar::name_expires_at(&suins, utf8(SUI_REGISTRAR), utf8(DOMAIN_NAME))
                    == START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD + 365,
                0
            );
            assert!(registry::owner(&suins, utf8(DOMAIN_NAME_SUI)) == SECOND_USER_ADDRESS, 0);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);

            get_entry_util(&mut auction, DOMAIN_NAME, START_AN_AUCTION_AT + 1, 1500 * configuration::mist_per_sui(), 1200 * configuration::mist_per_sui(), SECOND_USER_ADDRESS, true);
            finalize_auction_util(
                scenario,
                &mut auction,
                DOMAIN_NAME,
                FIRST_USER_ADDRESS,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD,
                10
            );
            get_entry_util(&mut auction, DOMAIN_NAME, START_AN_AUCTION_AT + 1, 1500 * configuration::mist_per_sui(), 1200 * configuration::mist_per_sui(), SECOND_USER_ADDRESS, true);
            assert!(auction::get_balance(&auction) == 0, 0);
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 0, 0);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 2, 0);

            let coin1 = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin1) == 1300 * configuration::mist_per_sui(), 0);
            let coin2 = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin2) == 60 * configuration::mist_per_sui(), 0);

            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            assert!(auction::get_balance(&auction) == 0, 0);
            assert!(controller::get_balance(&suins) == START_AN_AUCTION_FEE + 1140 * configuration::mist_per_sui() + BIDDING_FEE * 2, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin1);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin2);
        };
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            get_entry_util(&mut auction, DOMAIN_NAME, START_AN_AUCTION_AT + 1, 1500 * configuration::mist_per_sui(), 1200 * configuration::mist_per_sui(), SECOND_USER_ADDRESS, true);
            assert!(registrar::record_exists(&suins, SUI_REGISTRAR, DOMAIN_NAME), 0);
            assert!(
                registrar::name_expires_at(&suins, utf8(SUI_REGISTRAR), utf8(DOMAIN_NAME))
                    == START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD + 365,
                0
            );
            assert!(registry::owner(&suins, utf8(DOMAIN_NAME_SUI)) == SECOND_USER_ADDRESS, 0);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_reveal_bid_choose_the_one_who_bids_first_in_epoch_as_winner_if_same_value() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, DOMAIN_NAME);

        let seal_bid = make_seal_bid(DOMAIN_NAME, FIRST_USER_ADDRESS, 1200 * configuration::mist_per_sui(), FIRST_SECRET);
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
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let coin = coin::mint_for_testing<SUI>(1300 * configuration::mist_per_sui() + BIDDING_FEE, ctx);
            let clock = test_scenario::take_shared<Clock>(scenario);

            assert!(auction::get_balance(&auction) == 0, 0);
            auction::place_bid(&mut auction, &mut suins, &config, seal_bid, 1300 * configuration::mist_per_sui(), &mut coin, &clock, ctx);
            assert!(auction::get_balance(&auction) == 1300 * configuration::mist_per_sui(), 0);
            assert!(coin::value(&coin) == 0, 0);

            clock::increment_for_testing(&mut clock, 2);
            coin::burn_for_testing(coin);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
        };
        let seal_bid = make_seal_bid(DOMAIN_NAME, SECOND_USER_ADDRESS, 1200 * configuration::mist_per_sui(), FIRST_SECRET);
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let ctx = ctx_new(
                SECOND_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AN_AUCTION_AT + 2,
                15
            );
            let ctx = &mut ctx;
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let coin = coin::mint_for_testing<SUI>(1300 * configuration::mist_per_sui() + BIDDING_FEE, ctx);
            let clock = test_scenario::take_shared<Clock>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);

            assert!(auction::get_balance(&auction) == 1300 * configuration::mist_per_sui(), 0);
            auction::place_bid(&mut auction, &mut suins, &config, seal_bid, 1300 * configuration::mist_per_sui(), &mut coin, &clock, ctx);
            assert!(controller::get_balance(&suins) == START_AN_AUCTION_FEE + BIDDING_FEE * 2, 0);
            assert!(auction::get_balance(&auction) == 2600 * configuration::mist_per_sui(), 0);

            assert!(auction::get_balance(&auction) == 2600 * configuration::mist_per_sui(), 0);
            assert!(coin::value(&coin) == 0, 0);

            coin::burn_for_testing(coin);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
        };
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                DOMAIN_NAME,
                1200 * configuration::mist_per_sui(),
                FIRST_SECRET,
                SECOND_USER_ADDRESS,
                10
            );
            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                DOMAIN_NAME,
                1200 * configuration::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );
            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
        };
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_entry_util(
                &mut auction,
                DOMAIN_NAME,
                START_AN_AUCTION_AT + 1,
                1200 * configuration::mist_per_sui(),
                1200 * configuration::mist_per_sui(),
                FIRST_USER_ADDRESS,
                false
            );
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_reveal_bid_choose_the_one_who_bids_first_in_epoch_as_winner_if_same_value_2() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, DOMAIN_NAME);

        let seal_bid = make_seal_bid(DOMAIN_NAME, FIRST_USER_ADDRESS, 1200 * configuration::mist_per_sui(), FIRST_SECRET);
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
            let coin = coin::mint_for_testing<SUI>(1300 * configuration::mist_per_sui() + BIDDING_FEE, ctx);
            let clock = test_scenario::take_shared<Clock>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);

            assert!(auction::get_balance(&auction) == 0, 0);
            auction::place_bid(&mut auction, &mut suins, &config, seal_bid, 1300 * configuration::mist_per_sui(), &mut coin, &clock, ctx);
            assert!(auction::get_balance(&auction) == 1300 * configuration::mist_per_sui(), 0);
            assert!(controller::get_balance(&suins) == START_AN_AUCTION_FEE + BIDDING_FEE, 0);

            clock::increment_for_testing(&mut clock, 2);
            coin::burn_for_testing(coin);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
        };
        let seal_bid = make_seal_bid(DOMAIN_NAME, SECOND_USER_ADDRESS, 1200 * configuration::mist_per_sui(), FIRST_SECRET);
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let ctx = ctx_new(
                SECOND_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AN_AUCTION_AT + 2,
                15
            );
            let ctx = &mut ctx;
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let coin = coin::mint_for_testing<SUI>(1300 * configuration::mist_per_sui() + BIDDING_FEE, ctx);
            let config = test_scenario::take_shared<Configuration>(scenario);

            assert!(auction::get_balance(&auction) == 1300 * configuration::mist_per_sui(), 0);
            auction::place_bid(&mut auction, &mut suins, &config, seal_bid, 1300 * configuration::mist_per_sui(), &mut coin, &clock, ctx);
            assert!(auction::get_balance(&auction) == 2600 * configuration::mist_per_sui(), 0);
            assert!(coin::value(&coin) == 0, 0);
            assert!(controller::get_balance(&suins) == START_AN_AUCTION_FEE + BIDDING_FEE * 2, 0);

            coin::burn_for_testing(coin);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
        };
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);

            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                DOMAIN_NAME,
                1200 * configuration::mist_per_sui(),
                FIRST_SECRET,
                SECOND_USER_ADDRESS,
                10
            );

            clock::increment_for_testing(&mut clock, 2);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                DOMAIN_NAME,
                1200 * configuration::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );
            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
        };
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_entry_util(
                &mut auction,
                DOMAIN_NAME,
                START_AN_AUCTION_AT + 1,
                1200 * configuration::mist_per_sui(),
                1200 * configuration::mist_per_sui(),
                FIRST_USER_ADDRESS,
                false
            );
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_reveal_bid_choose_the_one_who_bids_first_in_ms_as_winner_if_same_value() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, DOMAIN_NAME);

        let seal_bid = make_seal_bid(DOMAIN_NAME, FIRST_USER_ADDRESS, 1200 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1300 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 1, option::none(), 10);
        let seal_bid = make_seal_bid(DOMAIN_NAME, SECOND_USER_ADDRESS, 1200 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1300 * configuration::mist_per_sui(), SECOND_USER_ADDRESS, 2, option::none(), 15);
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);

            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                DOMAIN_NAME,
                1200 * configuration::mist_per_sui(),
                FIRST_SECRET,
                SECOND_USER_ADDRESS,
                10
            );
            assert!(controller::get_balance(&suins) == START_AN_AUCTION_FEE + BIDDING_FEE * 2, 0);

            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);

            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                DOMAIN_NAME,
                1200 * configuration::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );
            assert!(controller::get_balance(&suins) == START_AN_AUCTION_FEE + BIDDING_FEE * 2, 0);

            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
             get_entry_util(
                &mut auction,
                 DOMAIN_NAME,
                START_AN_AUCTION_AT + 1,
                 1200 * configuration::mist_per_sui(),
                 1200 * configuration::mist_per_sui(),
                FIRST_USER_ADDRESS,
                false
            );
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_reveal_bid_choose_the_one_who_bids_first_in_ms_as_winner_if_same_value_2() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, DOMAIN_NAME);

        let seal_bid = make_seal_bid(DOMAIN_NAME, FIRST_USER_ADDRESS, 1200 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1300 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 1, option::none(), 10);
        let seal_bid = make_seal_bid(DOMAIN_NAME, SECOND_USER_ADDRESS, 1200 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1300 * configuration::mist_per_sui(), SECOND_USER_ADDRESS, 2, option::none(), 15);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);

            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                DOMAIN_NAME,
                1200 * configuration::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );
            assert!(controller::get_balance(&suins) == START_AN_AUCTION_FEE + BIDDING_FEE * 2, 0);

            clock::increment_for_testing(&mut clock, 2);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);

            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                DOMAIN_NAME,
                1200 * configuration::mist_per_sui(),
                FIRST_SECRET,
                SECOND_USER_ADDRESS,
                10
            );
            assert!(controller::get_balance(&suins) == START_AN_AUCTION_FEE + BIDDING_FEE * 2, 0);

            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_entry_util(
                &mut auction,
                DOMAIN_NAME,
                START_AN_AUCTION_AT + 1,
                1200 * configuration::mist_per_sui(),
                1200 * configuration::mist_per_sui(),
                FIRST_USER_ADDRESS,
                false
            );
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_reveal_bid_choose_the_one_who_reveals_first_as_winner_if_same_value_and_same_created_at_in_epoch_and_same_ms() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, DOMAIN_NAME);

        let seal_bid = make_seal_bid(DOMAIN_NAME, FIRST_USER_ADDRESS, 1200 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1300 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);
        let seal_bid = make_seal_bid(DOMAIN_NAME, SECOND_USER_ADDRESS, 1200 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1300 * configuration::mist_per_sui(), SECOND_USER_ADDRESS, 0, option::none(), 15);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                DOMAIN_NAME,
                1200 * configuration::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );
            assert!(auction::get_balance(&auction) == 2600 * configuration::mist_per_sui(), 0);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
        };
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                DOMAIN_NAME,
                1200 * configuration::mist_per_sui(),
                FIRST_SECRET,
                SECOND_USER_ADDRESS,
                10
            );

            let suins = test_scenario::take_shared<SuiNS>(scenario);
            assert!(controller::get_balance(&suins) == START_AN_AUCTION_FEE + BIDDING_FEE * 2, 0);
            assert!(auction::get_balance(&auction) == 2600 * configuration::mist_per_sui(), 0);

            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_entry_util(
                &mut auction,
                DOMAIN_NAME,
                START_AN_AUCTION_AT + 1,
                1200 * configuration::mist_per_sui(),
                1200 * configuration::mist_per_sui(),
                FIRST_USER_ADDRESS,
                false
            );
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_reveal_bid_choose_the_one_who_reveals_first_as_winner_if_same_value_and_same_created_at_in_epoch_and_different_ms() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, DOMAIN_NAME);

        let seal_bid = make_seal_bid(DOMAIN_NAME, FIRST_USER_ADDRESS, 1200 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1300 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 1, option::none(), 10);
        let seal_bid = make_seal_bid(DOMAIN_NAME, SECOND_USER_ADDRESS, 1200 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1300 * configuration::mist_per_sui(), SECOND_USER_ADDRESS, 0, option::none(), 15);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                DOMAIN_NAME,
                1200 * configuration::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );
            assert!(auction::get_balance(&auction) == 2600 * configuration::mist_per_sui(), 0);

            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                DOMAIN_NAME,
                1200 * configuration::mist_per_sui(),
                FIRST_SECRET,
                SECOND_USER_ADDRESS,
                10
            );

            let suins = test_scenario::take_shared<SuiNS>(scenario);
            assert!(controller::get_balance(&suins) == START_AN_AUCTION_FEE + BIDDING_FEE * 2, 0);
            assert!(auction::get_balance(&auction) == 2600 * configuration::mist_per_sui(), 0);

            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_entry_util(
                &mut auction,
                DOMAIN_NAME,
                START_AN_AUCTION_AT + 1,
                1200 * configuration::mist_per_sui(),
                1200 * configuration::mist_per_sui(),
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
        start_an_auction_util(scenario, DOMAIN_NAME);

        let seal_bid = make_seal_bid(DOMAIN_NAME, FIRST_USER_ADDRESS, 1200 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1300 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                DOMAIN_NAME,
                1200 * configuration::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );
            assert!(auction::get_balance(&auction) == 1300 * configuration::mist_per_sui(), 0);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
        };
        let seal_bid = make_seal_bid(DOMAIN_NAME, SECOND_USER_ADDRESS, 1200 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1300 * configuration::mist_per_sui(), SECOND_USER_ADDRESS, 0,option::none(), 15);
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + 1,
                DOMAIN_NAME,
                1200 * configuration::mist_per_sui(),
                FIRST_SECRET,
                SECOND_USER_ADDRESS,
                10
            );
            assert!(auction::get_balance(&auction) == 2600 * configuration::mist_per_sui(), 0);

            let suins = test_scenario::take_shared<SuiNS>(scenario);
            assert!(controller::get_balance(&suins) == START_AN_AUCTION_FEE + BIDDING_FEE * 2, 0);

            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_entry_util(
                &mut auction,
                DOMAIN_NAME,
                START_AN_AUCTION_AT + 1,
                1200 * configuration::mist_per_sui(),
                1200 * configuration::mist_per_sui(),
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
        start_an_auction_util(scenario, DOMAIN_NAME);

        let seal_bid = make_seal_bid(DOMAIN_NAME, FIRST_USER_ADDRESS, 1200 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1200 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            get_bid_util(&auction, seal_bid, FIRST_USER_ADDRESS, some(1200 * configuration::mist_per_sui()));
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                DOMAIN_NAME,
                1200 * configuration::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );
            assert!(auction::get_balance(&auction) == 1200 * configuration::mist_per_sui(), 0);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
        };

        let seal_bid = make_seal_bid(DOMAIN_NAME, SECOND_USER_ADDRESS, 1500 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 2100 * configuration::mist_per_sui(), SECOND_USER_ADDRESS, 0, option::some(FIRST_TX_HASH), 10);
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            get_bid_util(&auction, seal_bid, SECOND_USER_ADDRESS, some(2100 * configuration::mist_per_sui()));

            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                DOMAIN_NAME,
                1500 * configuration::mist_per_sui(),
                FIRST_SECRET,
                SECOND_USER_ADDRESS,
                10
            );
            assert!(auction::get_balance(&auction) == 3300 * configuration::mist_per_sui(), 0);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_entry_util(&mut auction, DOMAIN_NAME, START_AN_AUCTION_AT + 1, 1500 * configuration::mist_per_sui(), 1200 * configuration::mist_per_sui(), SECOND_USER_ADDRESS, false);

            finalize_auction_util(
                scenario,
                &mut auction,
                DOMAIN_NAME,
                FIRST_USER_ADDRESS,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD,
                10
            );
            assert!(auction::get_balance(&auction) == 2100 * configuration::mist_per_sui(), 0);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);
            let coin = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin) == 1200 * configuration::mist_per_sui(), 0);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin);

            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(SECOND_USER_ADDRESS);

            assert!(vector::length(&ids) == 0, 0);
            get_entry_util(&mut auction, DOMAIN_NAME, START_AN_AUCTION_AT + 1, 1500 * configuration::mist_per_sui(), 1200 * configuration::mist_per_sui(), SECOND_USER_ADDRESS, false);

            let suins = test_scenario::take_shared<SuiNS>(scenario);
            assert!(controller::get_balance(&suins) == START_AN_AUCTION_FEE + BIDDING_FEE * 2, 0);

            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_finalize_auction() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, DOMAIN_NAME);

        let seal_bid = make_seal_bid(DOMAIN_NAME, FIRST_USER_ADDRESS, 1200 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1200 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);

            get_bid_util(&auction, seal_bid, FIRST_USER_ADDRESS, some(1200 * configuration::mist_per_sui()));
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                DOMAIN_NAME,
                1200 * configuration::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );
            assert!(auction::get_balance(&auction) == 1200 * configuration::mist_per_sui(), 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);

            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            finalize_auction_util(
                scenario,
                &mut auction,
                DOMAIN_NAME,
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

            get_entry_util(&mut auction, DOMAIN_NAME, START_AN_AUCTION_AT + 1, 1200 * configuration::mist_per_sui(), 0, FIRST_USER_ADDRESS, true);
            assert!(registrar::record_exists(&suins, SUI_REGISTRAR, DOMAIN_NAME), 0);
            assert!(
                registrar::name_expires_at(&suins, utf8(SUI_REGISTRAR), utf8(DOMAIN_NAME))
                    == START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD + 365,
                0
            );
            assert!(registry::owner(&suins, utf8(DOMAIN_NAME_SUI)) == FIRST_USER_ADDRESS, 0);
            assert!(auction::get_balance(&auction) == 0, 0);
            assert!(controller::get_balance(&suins) == START_AN_AUCTION_FEE + 1200 * configuration::mist_per_sui() + BIDDING_FEE, 0);

            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_finalize_auction_if_winning_bid_has_mask_equals_actual_value() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, DOMAIN_NAME);

        let seal_bid = make_seal_bid(DOMAIN_NAME, FIRST_USER_ADDRESS, 1200 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1200 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);

            get_bid_util(&auction, seal_bid, FIRST_USER_ADDRESS, some(1200 * configuration::mist_per_sui()));
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                DOMAIN_NAME,
                1200 * configuration::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );
            assert!(auction::get_balance(&auction) == 1200 * configuration::mist_per_sui(), 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            finalize_auction_util(
                scenario,
                &mut auction,
                DOMAIN_NAME,
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

            get_entry_util(&mut auction, DOMAIN_NAME, START_AN_AUCTION_AT + 1, 1200 * configuration::mist_per_sui(), 0, FIRST_USER_ADDRESS, true);
            assert!(registrar::record_exists(&suins, SUI_REGISTRAR, DOMAIN_NAME), 0);
            assert!(
                registrar::name_expires_at(&suins, utf8(SUI_REGISTRAR), utf8(DOMAIN_NAME))
                    == START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD + 365,
                0
            );
            assert!(registry::owner(&suins, utf8(DOMAIN_NAME_SUI)) == FIRST_USER_ADDRESS, 0);

            assert!(auction::get_balance(&auction) == 0, 0);
            assert!(controller::get_balance(&suins) == START_AN_AUCTION_FEE + 1200 * configuration::mist_per_sui() + BIDDING_FEE, 0);

            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_finalize_auction_if_winning_bid_has_mask_equals_actual_value_2() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, DOMAIN_NAME);

        let seal_bid = make_seal_bid(DOMAIN_NAME, FIRST_USER_ADDRESS, 1200 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1200 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);

            get_bid_util(&auction, seal_bid, FIRST_USER_ADDRESS, some(1200 * configuration::mist_per_sui()));
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                DOMAIN_NAME,
                1200 * configuration::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );
            assert!(auction::get_balance(&auction) == 1200 * configuration::mist_per_sui(), 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
        };

        let seal_bid = make_seal_bid(DOMAIN_NAME, SECOND_USER_ADDRESS, 1500 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1500 * configuration::mist_per_sui(), SECOND_USER_ADDRESS, 0, option::some(FIRST_TX_HASH), 10);
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);

            get_bid_util(&auction, seal_bid, SECOND_USER_ADDRESS, some(1500 * configuration::mist_per_sui()));
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                DOMAIN_NAME,
                1500 * configuration::mist_per_sui(),
                FIRST_SECRET,
                SECOND_USER_ADDRESS,
                10
            );
            assert!(auction::get_balance(&auction) == 2700 * configuration::mist_per_sui(), 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
        };
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_entry_util(&mut auction, DOMAIN_NAME, START_AN_AUCTION_AT + 1, 1500 * configuration::mist_per_sui(), 1200 * configuration::mist_per_sui(), SECOND_USER_ADDRESS, false);

            finalize_auction_util(
                scenario,
                &mut auction,
                DOMAIN_NAME,
                SECOND_USER_ADDRESS,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD,
                20
            );
            assert!(auction::get_balance(&auction) == 1200 * configuration::mist_per_sui(), 0);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);
            let first_coin = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&first_coin) == 60 * configuration::mist_per_sui(), 0);

            let ids = test_scenario::ids_for_address<Coin<SUI>>(SECOND_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);
            let second_coin = test_scenario::take_from_address<Coin<SUI>>(scenario, SECOND_USER_ADDRESS);
            assert!(coin::value(&second_coin) == 300 * configuration::mist_per_sui(), 0);

            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            get_entry_util(&mut auction, DOMAIN_NAME, START_AN_AUCTION_AT + 1, 1500 * configuration::mist_per_sui(), 1200 * configuration::mist_per_sui(), SECOND_USER_ADDRESS, true);

            assert!(auction::get_balance(&auction) == 1200 * configuration::mist_per_sui(), 0);
            assert!(controller::get_balance(&suins) == START_AN_AUCTION_FEE + 1140 * configuration::mist_per_sui() + BIDDING_FEE * 2, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, first_coin);
            test_scenario::return_to_address(SECOND_USER_ADDRESS, second_coin);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            finalize_auction_util(
                scenario,
                &mut auction,
                DOMAIN_NAME,
                FIRST_USER_ADDRESS,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD,
                30
            );
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 2, 0);
            let coin1 = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin1) == 1200 * configuration::mist_per_sui(), 0);
            let coin2 = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin2) == 60 * configuration::mist_per_sui(), 0);

            let ids = test_scenario::ids_for_address<Coin<SUI>>(SECOND_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);
            let coin3 = test_scenario::take_from_address<Coin<SUI>>(scenario, SECOND_USER_ADDRESS);
            assert!(coin::value(&coin3) == 300 * configuration::mist_per_sui(), 0);

            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            get_entry_util(&mut auction, DOMAIN_NAME, START_AN_AUCTION_AT + 1, 1500 * configuration::mist_per_sui(), 1200 * configuration::mist_per_sui(), SECOND_USER_ADDRESS, true);

            assert!(auction::get_balance(&auction) == 0, 0);
            assert!(controller::get_balance(&suins) == START_AN_AUCTION_FEE + 1140 * configuration::mist_per_sui() + BIDDING_FEE * 2, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin1);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin2);
            test_scenario::return_to_address(SECOND_USER_ADDRESS, coin3);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_finalize_auction_if_winning_bid_has_mask_equals_actual_value_3() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, DOMAIN_NAME);

        let seal_bid = make_seal_bid(DOMAIN_NAME, FIRST_USER_ADDRESS, 1200 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1200 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);

            get_bid_util(&auction, seal_bid, FIRST_USER_ADDRESS, some(1200 * configuration::mist_per_sui()));
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                DOMAIN_NAME,
                1200 * configuration::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );

            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
        };

        let seal_bid = make_seal_bid(DOMAIN_NAME, SECOND_USER_ADDRESS, 1500 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1500 * configuration::mist_per_sui(), SECOND_USER_ADDRESS, 0, option::some(FIRST_TX_HASH), 10);
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);

            get_bid_util(&auction, seal_bid, SECOND_USER_ADDRESS, some(1500 * configuration::mist_per_sui()));
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                DOMAIN_NAME,
                1500 * configuration::mist_per_sui(),
                FIRST_SECRET,
                SECOND_USER_ADDRESS,
                10
            );

            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
        };
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_entry_util(&mut auction, DOMAIN_NAME, START_AN_AUCTION_AT + 1, 1500 * configuration::mist_per_sui(), 1200 * configuration::mist_per_sui(), SECOND_USER_ADDRESS, false);

            finalize_auction_util(
                scenario,
                &mut auction,
                DOMAIN_NAME,
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
            let first_coin = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&first_coin) == 60 * configuration::mist_per_sui(), 0);

            let ids = test_scenario::ids_for_address<Coin<SUI>>(SECOND_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);
            let second_coin = test_scenario::take_from_address<Coin<SUI>>(scenario, SECOND_USER_ADDRESS);
            assert!(coin::value(&second_coin) == 300 * configuration::mist_per_sui(), 0);

            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_entry_util(&mut auction, DOMAIN_NAME, START_AN_AUCTION_AT + 1, 1500 * configuration::mist_per_sui(), 1200 * configuration::mist_per_sui(), SECOND_USER_ADDRESS, true);

            test_scenario::return_shared(auction);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, first_coin);
            test_scenario::return_to_address(SECOND_USER_ADDRESS, second_coin);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            finalize_auction_util(
                scenario,
                &mut auction,
                DOMAIN_NAME,
                FIRST_USER_ADDRESS,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD,
                30
            );
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 2, 0);
            let coin1 = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin1) == 1200 * configuration::mist_per_sui(), 0);
            let coin2 = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin2) == 60 * configuration::mist_per_sui(), 0);

            let ids = test_scenario::ids_for_address<Coin<SUI>>(SECOND_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);
            let coin3 = test_scenario::take_from_address<Coin<SUI>>(scenario, SECOND_USER_ADDRESS);
            assert!(coin::value(&coin3) == 300 * configuration::mist_per_sui(), 0);

            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_entry_util(&mut auction, DOMAIN_NAME, START_AN_AUCTION_AT + 1, 1500 * configuration::mist_per_sui(), 1200 * configuration::mist_per_sui(), SECOND_USER_ADDRESS, true);
            test_scenario::return_shared(auction);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin1);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin2);
            test_scenario::return_to_address(SECOND_USER_ADDRESS, coin3);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_finalize_auction_has_extra_period() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, DOMAIN_NAME);

        let seal_bid = make_seal_bid(DOMAIN_NAME, FIRST_USER_ADDRESS, 1200 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1200 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);

            get_bid_util(&auction, seal_bid, FIRST_USER_ADDRESS, some(1200 * configuration::mist_per_sui()));
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                DOMAIN_NAME,
                1200 * configuration::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );
            assert!(auction::get_balance(&auction) == 1200 * configuration::mist_per_sui(), 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
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
                DOMAIN_NAME,
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

            get_entry_util(&mut auction, DOMAIN_NAME, START_AN_AUCTION_AT + 1, 1200 * configuration::mist_per_sui(), 0, FIRST_USER_ADDRESS, true);
            assert!(registrar::record_exists(&suins, SUI_REGISTRAR, DOMAIN_NAME), 0);
            assert!(
                registrar::name_expires_at(&suins, utf8(SUI_REGISTRAR), utf8(DOMAIN_NAME))
                    == START_AUCTION_END_AT + 10 + 365,
                0
            );
            assert!(registry::owner(&suins, utf8(DOMAIN_NAME_SUI)) == FIRST_USER_ADDRESS, 0);
            assert!(auction::get_balance(&auction) == 0, 0);
            assert!(controller::get_balance(&suins) == START_AN_AUCTION_FEE + 1200 * configuration::mist_per_sui() + BIDDING_FEE, 0);

            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EInvalidPhase)]
    fun test_reveal_bid_late() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        let seal_bid = make_seal_bid(DOMAIN_NAME, SECOND_USER_ADDRESS, 1500 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 2000 * configuration::mist_per_sui(), SECOND_USER_ADDRESS, 0, option::none(), 10);
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);

            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD,
                DOMAIN_NAME,
                1500 * configuration::mist_per_sui(),
                FIRST_SECRET,
                SECOND_USER_ADDRESS,
                10
            );

            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EInvalidPhase)]
    fun test_reveal_bid_late_2() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;

        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            reveal_bid_util(
                &mut auction,
                &config,
                START_AUCTION_END_AT + BIDDING_PERIOD + REVEAL_PERIOD + 1,
                DOMAIN_NAME,
                1500 * configuration::mist_per_sui(),
                FIRST_SECRET,
                SECOND_USER_ADDRESS,
                10
            );
            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
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
            let coin = coin::mint_for_testing<SUI>(3 * START_AN_AUCTION_FEE, ctx);

            assert!(auction::get_balance(&auction) == 0, 0);
            auction::start_an_auction(&mut auction, &mut suins, utf8(DOMAIN_NAME), &mut coin, ctx);
            assert!(auction::get_balance(&auction) == 0, 0);
            assert!(controller::get_balance(&suins) == START_AN_AUCTION_FEE, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            coin::burn_for_testing(coin);
        };

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let seal_bid = make_seal_bid(DOMAIN_NAME, FIRST_USER_ADDRESS, 1500 * configuration::mist_per_sui(), FIRST_SECRET);
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AUCTION_END_AT + BIDDING_PERIOD,
                20
            );
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let coin = coin::mint_for_testing<SUI>(30000 * configuration::mist_per_sui() + BIDDING_FEE, &mut ctx);
            let config = test_scenario::take_shared<Configuration>(scenario);

            auction::place_bid(&mut auction, &mut suins, &config, seal_bid, 2000 * configuration::mist_per_sui(), &mut coin, &clock, &mut ctx);
            assert!(auction::get_balance(&auction) == 2000 * configuration::mist_per_sui(), 0);
            assert!(coin::value(&coin) == 28000 * configuration::mist_per_sui(), 0);

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
            reveal_bid_util(
                &mut auction,
                &config,
                START_AUCTION_END_AT + BIDDING_PERIOD + REVEAL_PERIOD,
                DOMAIN_NAME,
                1500 * configuration::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                10
            );
            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EInvalidPhase)]
    fun test_finalize_auction_late() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            finalize_auction_util(
                scenario,
                &mut auction,
                DOMAIN_NAME,
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
            let coin = coin::mint_for_testing<SUI>(30 * START_AN_AUCTION_FEE, ctx);

            auction::start_an_auction(&mut auction, &mut suins, utf8(DOMAIN_NAME), &mut coin, ctx);
            assert!(auction::get_balance(&auction) == 0, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            coin::burn_for_testing(coin);
        };

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let seal_bid = make_seal_bid(DOMAIN_NAME, FIRST_USER_ADDRESS, 1500 * configuration::mist_per_sui(), FIRST_SECRET);
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AUCTION_END_AT + BIDDING_PERIOD,
                20
            );
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let coin = coin::mint_for_testing<SUI>(2000 * configuration::mist_per_sui() + BIDDING_FEE, &mut ctx);
            let config = test_scenario::take_shared<Configuration>(scenario);

            auction::place_bid(&mut auction, &mut suins, &config, seal_bid, 2000 * configuration::mist_per_sui(), &mut coin, &clock, &mut ctx);
            assert!(auction::get_balance(&auction) == 2000 * configuration::mist_per_sui(), 0);
            assert!(coin::value(&coin) == 0, 0);

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
            reveal_bid_util(
                &mut auction,
                &config,
                START_AUCTION_END_AT + BIDDING_PERIOD + REVEAL_PERIOD,
                DOMAIN_NAME,
                1500 * configuration::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                5
            );
            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            finalize_auction_util(
                scenario,
                &mut auction,
                DOMAIN_NAME,
                FIRST_USER_ADDRESS,
                START_AUCTION_END_AT + BIDDING_PERIOD + REVEAL_PERIOD + EXTRA_PERIOD - 1,
                10
            );
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let coin = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin) == 500 * configuration::mist_per_sui(), 0);

            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);

            get_entry_util(&mut auction, DOMAIN_NAME, START_AUCTION_END_AT + 1, 1500 * configuration::mist_per_sui(), 0, FIRST_USER_ADDRESS, true);
            assert!(registrar::record_exists(&suins, SUI_REGISTRAR, DOMAIN_NAME), 0);
            assert!(
                registrar::name_expires_at(&suins, utf8(SUI_REGISTRAR), utf8(DOMAIN_NAME))
                    == START_AUCTION_END_AT + BIDDING_PERIOD + REVEAL_PERIOD + EXTRA_PERIOD - 1 + 365,
                0
            );
            assert!(registry::owner(&suins, utf8(DOMAIN_NAME_SUI)) == FIRST_USER_ADDRESS, 0);

            assert!(auction::get_balance(&auction) == 0, 0);
            assert!(controller::get_balance(&suins) == START_AN_AUCTION_FEE + 1500 * configuration::mist_per_sui() + BIDDING_FEE, 0);

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
        let seal_bid = make_seal_bid(DOMAIN_NAME, FIRST_USER_ADDRESS, 1500 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 2000 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);

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
            assert!(auction::get_balance(&auction) == 2000 * configuration::mist_per_sui(), 0);

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
            assert!(coin::value(&coin) == 2000 * configuration::mist_per_sui(), 0);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_withdraw_bids() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        let seal_bid = make_seal_bid(DOMAIN_NAME, FIRST_USER_ADDRESS, 1500 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 2000 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);

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
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let coin = coin::mint_for_testing<SUI>(2000 * configuration::mist_per_sui() + BIDDING_FEE, ctx);
            let seal_bid = make_seal_bid(DOMAIN_NAME, FIRST_USER_ADDRESS, 1100 * configuration::mist_per_sui(), FIRST_SECRET);
            let clock = test_scenario::take_shared<Clock>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);

            assert!(auction::get_balance(&auction) == 2000 * configuration::mist_per_sui(), 0);
            auction::place_bid(&mut auction, &mut suins, &config, seal_bid, 1300 * configuration::mist_per_sui(), &mut coin, &clock, ctx);
            assert!(auction::get_balance(&auction) == 3300 * configuration::mist_per_sui(), 0);
            assert!(coin::value(&coin) == 700 * configuration::mist_per_sui(), 0);

            coin::burn_for_testing(coin);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
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
            assert!(coin::value(&first_coin) == 1300 * configuration::mist_per_sui(), 0);
            let second_coin = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&second_coin) == 2000 * configuration::mist_per_sui(), 0);

            test_scenario::return_to_address(FIRST_USER_ADDRESS, first_coin);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, second_coin);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_cannt_withdraw_winning_bid() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, DOMAIN_NAME);
        let seal_bid = make_seal_bid(DOMAIN_NAME, FIRST_USER_ADDRESS, 1500 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 2000 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                DOMAIN_NAME,
                1500 * configuration::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                5
            );
            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
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
            assert!(auction::get_balance(&auction) == 2000 * configuration::mist_per_sui(), 0);

            withdraw(&mut auction, &mut ctx);
            // it is the winning bid, cannot be withdrawed at this point
            let bids = get_bids_by_bidder(&auction, FIRST_USER_ADDRESS);
            assert!(vector::length(&bids) == 1, 0);
            assert!(auction::get_balance(&auction) == 2000 * configuration::mist_per_sui(), 0);
            test_scenario::return_shared(auction);
        };

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
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
            assert!(auction::get_balance(&auction) == 2000 * configuration::mist_per_sui(), 0);
            assert!(controller::get_balance(&suins) == START_AN_AUCTION_FEE + BIDDING_FEE, 0);

            test_scenario::return_shared(suins);

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
        start_an_auction_util(scenario, DOMAIN_NAME);

        let seal_bid = make_seal_bid(DOMAIN_NAME, SECOND_USER_ADDRESS, 500, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 2000 * configuration::mist_per_sui(), SECOND_USER_ADDRESS, 0, option::none(), 10);
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);

            assert!(
                state_util(
                    &auction,
                    DOMAIN_NAME,
                    START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD
                ) == AUCTION_STATE_REOPENED,
                0
            );
            assert!(auction::get_balance(&auction) == 2000 * configuration::mist_per_sui(), 0);
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                DOMAIN_NAME,
                500,
                FIRST_SECRET,
                SECOND_USER_ADDRESS,
                2
            );
            assert!(auction::get_balance(&auction) == 2000 * configuration::mist_per_sui(), 0);
            assert!(
                state_util(
                    &auction,
                    DOMAIN_NAME,
                    START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD
                ) == AUCTION_STATE_REOPENED,
                0
            );
            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            finalize_auction_util(
                scenario,
                &mut auction,
                DOMAIN_NAME,
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
            assert!(coin::value(&coin) == 2000 * configuration::mist_per_sui(), 0);

            let suins = test_scenario::take_shared<SuiNS>(scenario);
            assert!(controller::get_balance(&suins) == START_AN_AUCTION_FEE + BIDDING_FEE, 0);

            test_scenario::return_shared(suins);
            test_scenario::return_to_address(SECOND_USER_ADDRESS, coin);
        };
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_entry_util(&auction, DOMAIN_NAME, START_AN_AUCTION_AT + 1, 0, 0, @0x0, false);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_reveal_multiple_invalid_bids_that_are_less_than_minimum_amount_and_not_have_a_winner() {
        // auction receives 2 bids and they are invalid
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, SECOND_DOMAIN_NAME);

        let seal_bid = make_seal_bid(SECOND_DOMAIN_NAME, SECOND_USER_ADDRESS, 40 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 2000 * configuration::mist_per_sui(), SECOND_USER_ADDRESS, 0, option::none(), 15);
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);

            assert!(
                state_util(
                    &auction,
                    SECOND_DOMAIN_NAME,
                    START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD
                ) == AUCTION_STATE_REOPENED,
                0
            );

            assert!(auction::get_balance(&auction) == 2000 * configuration::mist_per_sui(), 0);
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                SECOND_DOMAIN_NAME,
                40 * configuration::mist_per_sui(),
                FIRST_SECRET,
                SECOND_USER_ADDRESS,
                2
            );
            assert!(auction::get_balance(&auction) == 2000 * configuration::mist_per_sui(), 0);
            assert!(
                state_util(
                    &auction,
                    SECOND_DOMAIN_NAME,
                    START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD
                ) == AUCTION_STATE_REOPENED,
                0
            );
            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
        };

        let seal_bid = make_seal_bid(SECOND_DOMAIN_NAME, SECOND_USER_ADDRESS, 30 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 3000 * configuration::mist_per_sui(), SECOND_USER_ADDRESS, 0, option::none(), 20);
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);

            assert!(auction::get_balance(&auction) == 5000 * configuration::mist_per_sui(), 0);
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                SECOND_DOMAIN_NAME,
                30 * configuration::mist_per_sui(),
                FIRST_SECRET,
                SECOND_USER_ADDRESS,
                5
            );
            assert!(auction::get_balance(&auction) == 5000 * configuration::mist_per_sui(), 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            finalize_auction_util(
                scenario,
                &mut auction,
                SECOND_DOMAIN_NAME,
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

            assert!(coin::value(&first_coin) == 3000 * configuration::mist_per_sui(), 0);
            assert!(coin::value(&second_coin) == 2000 * configuration::mist_per_sui(), 0);

            let suins = test_scenario::take_shared<SuiNS>(scenario);
            assert!(controller::get_balance(&suins) == START_AN_AUCTION_FEE + BIDDING_FEE * 2, 0);

            test_scenario::return_shared(suins);
            test_scenario::return_to_address(SECOND_USER_ADDRESS, second_coin);
            test_scenario::return_to_address(SECOND_USER_ADDRESS, first_coin);
        };
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_entry_util(&auction, SECOND_DOMAIN_NAME, START_AN_AUCTION_AT + 1, 0, 0, @0x0, false);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_reveal_invalid_bid_that_is_less_than_minimum_amount_and_has_a_winner() {
        // auction receives only 1 bid and it is invalid
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, DOMAIN_NAME);

        // mock a winner
        let seal_bid = make_seal_bid(DOMAIN_NAME, FIRST_USER_ADDRESS, 1500 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 2000 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);

            assert!(auction::get_balance(&auction) == 2000 * configuration::mist_per_sui(), 0);
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                DOMAIN_NAME,
                1500 * configuration::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );

            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
        };
        let seal_bid = make_seal_bid(DOMAIN_NAME, SECOND_USER_ADDRESS, 500, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 2200 * configuration::mist_per_sui(), SECOND_USER_ADDRESS, 0, option::some(FIRST_TX_HASH), 10);
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);

            assert!(
                state_util(
                    &auction,
                    DOMAIN_NAME,
                    START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD
                ) == AUCTION_STATE_FINALIZING,
                0
            );
            assert!(auction::get_balance(&auction) == 4200 * configuration::mist_per_sui(), 0);
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                DOMAIN_NAME,
                500,
                FIRST_SECRET,
                SECOND_USER_ADDRESS,
                2
            );
            assert!(auction::get_balance(&auction) == 4200 * configuration::mist_per_sui(), 0);
            assert!(
                state_util(
                    &auction,
                    DOMAIN_NAME,
                    START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD
                ) == AUCTION_STATE_FINALIZING,
                0
            );

            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            finalize_auction_util(
                scenario,
                &mut auction,
                DOMAIN_NAME,
                SECOND_USER_ADDRESS,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD,
                10
            );
            assert!(auction::get_balance(&auction) == 2000 * configuration::mist_per_sui(), 0);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(SECOND_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);
            let coin = test_scenario::take_from_address<Coin<SUI>>(scenario, SECOND_USER_ADDRESS);
            assert!(coin::value(&coin) == 2200 * configuration::mist_per_sui(), 0);

            let suins = test_scenario::take_shared<SuiNS>(scenario);
            assert!(controller::get_balance(&suins) == START_AN_AUCTION_FEE + BIDDING_FEE * 2, 0);

            test_scenario::return_shared(suins);
            test_scenario::return_to_address(SECOND_USER_ADDRESS, coin);
        };
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_entry_util(&auction, DOMAIN_NAME, START_AN_AUCTION_AT + 1, 1500 * configuration::mist_per_sui(), 0, FIRST_USER_ADDRESS, false);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_reveal_multiple_invalid_bids_that_are_less_than_minimum_amount_and_has_a_winner() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, SECOND_DOMAIN_NAME);

        // mock a winner
        let seal_bid = make_seal_bid(SECOND_DOMAIN_NAME, FIRST_USER_ADDRESS, 1500 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 2000 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 15);
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);

            assert!(
                state_util(
                    &auction,
                    SECOND_DOMAIN_NAME,
                    START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD
                ) == AUCTION_STATE_REOPENED,
                0
            );
            assert!(auction::get_balance(&auction) == 2000 * configuration::mist_per_sui(), 0);

            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                SECOND_DOMAIN_NAME,
                1500 * configuration::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );

            assert!(
                state_util(
                    &auction,
                    SECOND_DOMAIN_NAME,
                    START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD
                ) == AUCTION_STATE_FINALIZING,
                0
            );
            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
        };

        let seal_bid = make_seal_bid(SECOND_DOMAIN_NAME, SECOND_USER_ADDRESS, 40, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 2200 * configuration::mist_per_sui(), SECOND_USER_ADDRESS, 0, option::some(FIRST_TX_HASH), 20);
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);

            assert!(
                state_util(
                    &auction,
                    SECOND_DOMAIN_NAME,
                    START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD
                ) == AUCTION_STATE_FINALIZING,
                0
            );
            assert!(auction::get_balance(&auction) == 4200 * configuration::mist_per_sui(), 0);
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                SECOND_DOMAIN_NAME,
                40,
                FIRST_SECRET,
                SECOND_USER_ADDRESS,
                2
            );
            assert!(
                state_util(
                    &auction,
                    SECOND_DOMAIN_NAME,
                    START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD
                ) == AUCTION_STATE_FINALIZING,
                0
            );

            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
        };

        let seal_bid = make_seal_bid(SECOND_DOMAIN_NAME, SECOND_USER_ADDRESS, 45 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1200 * configuration::mist_per_sui(), SECOND_USER_ADDRESS, 0, option::some(SECOND_TX_HASH), 25);
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);

            assert!(auction::get_balance(&auction) == 5400 * configuration::mist_per_sui(), 0);
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                SECOND_DOMAIN_NAME,
                45 * configuration::mist_per_sui(),
                FIRST_SECRET,
                SECOND_USER_ADDRESS,
                2
            );

            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
        };

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            finalize_auction_util(
                scenario,
                &mut auction,
                SECOND_DOMAIN_NAME,
                SECOND_USER_ADDRESS,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD,
                10
            );
            assert!(auction::get_balance(&auction) == 2000 * configuration::mist_per_sui(), 0);

            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(SECOND_USER_ADDRESS);
            assert!(vector::length(&ids) == 2, 0);

            let first_coin = test_scenario::take_from_address<Coin<SUI>>(scenario, SECOND_USER_ADDRESS);
            let second_coin = test_scenario::take_from_address<Coin<SUI>>(scenario, SECOND_USER_ADDRESS);

            assert!(coin::value(&first_coin) == 1200 * configuration::mist_per_sui(), 0);
            assert!(coin::value(&second_coin) == 2200 * configuration::mist_per_sui(), 0);

            let suins = test_scenario::take_shared<SuiNS>(scenario);
            assert!(controller::get_balance(&suins) == START_AN_AUCTION_FEE + BIDDING_FEE * 3, 0);

            test_scenario::return_shared(suins);
            test_scenario::return_to_address(SECOND_USER_ADDRESS, first_coin);
            test_scenario::return_to_address(SECOND_USER_ADDRESS, second_coin);
        };
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_entry_util(&auction, SECOND_DOMAIN_NAME, START_AN_AUCTION_AT + 1, 1500 * configuration::mist_per_sui(), 0, FIRST_USER_ADDRESS, false);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EInvalidPhase)]
    fun test_reveal_invalid_bids_that_are_less_than_minimum_amount_and_has_no_winner_and_auction_is_restarted_abort() {
        // auction receives only 1 bid and it is invalid
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, DOMAIN_NAME);

        let seal_bid = make_seal_bid(DOMAIN_NAME, SECOND_USER_ADDRESS, 500, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 2200 * configuration::mist_per_sui(), SECOND_USER_ADDRESS, 0, option::none(), 10);
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);

            assert!(
                state_util(
                    &auction,
                    DOMAIN_NAME,
                    START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD
                ) == AUCTION_STATE_REOPENED,
                0
            );
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                DOMAIN_NAME,
                500,
                FIRST_SECRET,
                SECOND_USER_ADDRESS,
                2
            );
            assert!(
                state_util(
                    &auction,
                    DOMAIN_NAME,
                    START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD
                ) == AUCTION_STATE_REOPENED,
                0
            );

            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
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
            let coin = coin::mint_for_testing<SUI>(3 * START_AN_AUCTION_FEE, &mut ctx);

            auction::start_an_auction(&mut auction, &mut suins, utf8(DOMAIN_NAME), &mut coin, &mut ctx);

            coin::burn_for_testing(coin);
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
                DOMAIN_NAME,
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
        start_an_auction_util(scenario, DOMAIN_NAME);

        let seal_bid = make_seal_bid(DOMAIN_NAME, SECOND_USER_ADDRESS, 500, FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 2200 * configuration::mist_per_sui(), SECOND_USER_ADDRESS, 0, option::none(), 10);
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);

            assert!(
                state_util(
                    &auction,
                    DOMAIN_NAME,
                    START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD
                ) == AUCTION_STATE_REOPENED,
                0
            );
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                DOMAIN_NAME,
                500,
                FIRST_SECRET,
                SECOND_USER_ADDRESS,
                2
            );
            assert!(auction::get_balance(&auction) == 2200 * configuration::mist_per_sui(), 0);
            assert!(
                state_util(
                    &auction,
                    DOMAIN_NAME,
                    START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD
                ) == AUCTION_STATE_REOPENED,
                0
            );

            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
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
            let coin = coin::mint_for_testing<SUI>(3 * START_AN_AUCTION_FEE, &mut ctx);

            auction::start_an_auction(&mut auction, &mut suins, utf8(DOMAIN_NAME), &mut coin, &mut ctx);

            assert!(auction::get_balance(&auction) == 2200 * configuration::mist_per_sui(), 0);
            assert!(controller::get_balance(&suins) == 2 * START_AN_AUCTION_FEE + BIDDING_FEE, 0);

            coin::burn_for_testing(coin);
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
                DOMAIN_NAME,
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
            assert!(coin::value(&first_coin) == 2200 * configuration::mist_per_sui(), 0);

            let suins = test_scenario::take_shared<SuiNS>(scenario);
            assert!(controller::get_balance(&suins) == START_AN_AUCTION_FEE * 2 + BIDDING_FEE, 0);

            test_scenario::return_shared(suins);
            test_scenario::return_to_address(SECOND_USER_ADDRESS, first_coin);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_winner_finalize_auction_get_the_extra_payment() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, DOMAIN_NAME);

        let seal_bid = make_seal_bid(DOMAIN_NAME, SECOND_USER_ADDRESS, 1500 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 2200 * configuration::mist_per_sui(), SECOND_USER_ADDRESS, 0, option::none(), 10);
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);

            assert!(
                state_util(
                    &auction,
                    DOMAIN_NAME,
                    START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD
                ) == AUCTION_STATE_REOPENED,
                0
            );
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                DOMAIN_NAME,
                1500 * configuration::mist_per_sui(),
                FIRST_SECRET,
                SECOND_USER_ADDRESS,
                2
            );
            assert!(auction::get_balance(&auction) == 2200 * configuration::mist_per_sui(), 0);
            assert!(
                state_util(
                    &auction,
                    DOMAIN_NAME,
                    START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD
                ) == AUCTION_STATE_FINALIZING,
                0
            );

            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
        };

        let seal_bid = make_seal_bid(DOMAIN_NAME, FIRST_USER_ADDRESS, 1600 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 3000 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::some(FIRST_TX_HASH), 10);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);

            get_entry_util(&auction, DOMAIN_NAME, START_AN_AUCTION_AT + 1, 1500 * configuration::mist_per_sui(), 0, SECOND_USER_ADDRESS, false);
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                DOMAIN_NAME,
                1600 * configuration::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                5
            );
            assert!(auction::get_balance(&auction) == 5200 * configuration::mist_per_sui(), 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
        };

        let seal_bid = make_seal_bid(DOMAIN_NAME, SECOND_USER_ADDRESS, 1700 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 2000 * configuration::mist_per_sui(), SECOND_USER_ADDRESS, 0, option::some(SECOND_TX_HASH), 10);
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);

            get_entry_util(&auction, DOMAIN_NAME, START_AN_AUCTION_AT + 1, 1600 * configuration::mist_per_sui(), 1500 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, false);
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                DOMAIN_NAME,
                1700 * configuration::mist_per_sui(),
                FIRST_SECRET,
                SECOND_USER_ADDRESS,
                5
            );
            assert!(auction::get_balance(&auction) == 7200 * configuration::mist_per_sui(), 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
        };

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_entry_util(&auction, DOMAIN_NAME, START_AN_AUCTION_AT + 1, 1700 * configuration::mist_per_sui(), 1600 * configuration::mist_per_sui(), SECOND_USER_ADDRESS, false);

            finalize_auction_util(
                scenario,
                &mut auction,
                DOMAIN_NAME,
                FIRST_USER_ADDRESS,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD,
                10
            );
            assert!(auction::get_balance(&auction) == 4200 * configuration::mist_per_sui(), 0);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);
            let coin = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin) == 3000 * configuration::mist_per_sui(), 0);

            let ids = test_scenario::ids_for_address<Coin<SUI>>(SECOND_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);

            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin);
        };
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            get_entry_util(&auction, DOMAIN_NAME, START_AN_AUCTION_AT + 1, 1700 * configuration::mist_per_sui(), 1600 * configuration::mist_per_sui(), SECOND_USER_ADDRESS, false);

            finalize_auction_util(
                scenario,
                &mut auction,
                DOMAIN_NAME,
                SECOND_USER_ADDRESS,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD,
                15
            );
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 2, 0);

            let first_coin = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&first_coin) == 80 * configuration::mist_per_sui(), 0);
            let second_coin = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&second_coin) == 3000 * configuration::mist_per_sui(), 0);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, first_coin);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, second_coin);

            let ids = test_scenario::ids_for_address<Coin<SUI>>(SECOND_USER_ADDRESS);
            assert!(vector::length(&ids) == 2, 0);

            let first_coin = test_scenario::take_from_address<Coin<SUI>>(scenario, SECOND_USER_ADDRESS);
            assert!(coin::value(&first_coin) == 400 * configuration::mist_per_sui(), 0);
            let second_coin = test_scenario::take_from_address<Coin<SUI>>(scenario, SECOND_USER_ADDRESS);
            assert!(coin::value(&second_coin) == 2200 * configuration::mist_per_sui(), 0);

            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            assert!(auction::get_balance(&auction) == 0, 0);
            assert!(controller::get_balance(&suins) == START_AN_AUCTION_FEE + 1520 * configuration::mist_per_sui() + BIDDING_FEE * 3, 0);

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
                DOMAIN_NAME,
                FIRST_USER_ADDRESS,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD,
                15
            );
            test_scenario::return_shared(auction);
        };

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 2, 0);
            let first_coin = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&first_coin) == 3000 * configuration::mist_per_sui(), 0);
            let second_coin = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&second_coin) == 80 * configuration::mist_per_sui(), 0);

            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            assert!(auction::get_balance(&auction) == 0, 0);
            assert!(controller::get_balance(&suins) == START_AN_AUCTION_FEE + 1520 * configuration::mist_per_sui() + BIDDING_FEE * 3, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, first_coin);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, second_coin);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EAlreadyUnsealed)]
    fun test_reveal_bid_abort_if_unseal_twice() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_an_auction_util(scenario, DOMAIN_NAME);

        let seal_bid = make_seal_bid(DOMAIN_NAME, FIRST_USER_ADDRESS, 1000 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(scenario, seal_bid, 1000 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                DOMAIN_NAME,
                1000 * configuration::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );
            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                DOMAIN_NAME,
                1000 * configuration::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                10
            );
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::ESealBidNotExists)]
    fun test_reveal_bid_abort_with_wrong_parameter() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        let seal_bid = make_seal_bid(DOMAIN_NAME, FIRST_USER_ADDRESS, 1000 * configuration::mist_per_sui(), FIRST_SECRET);
        start_an_auction_util(scenario, DOMAIN_NAME);
        place_bid_util(scenario, seal_bid, 1000 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                DOMAIN_NAME,
                1200 * configuration::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );
            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::ESealBidNotExists)]
    fun test_reveal_bid_abort_with_wrong_parameter_2() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        let seal_bid = make_seal_bid(DOMAIN_NAME, FIRST_USER_ADDRESS, 1000 * configuration::mist_per_sui(), FIRST_SECRET);
        start_an_auction_util(scenario, DOMAIN_NAME);
        place_bid_util(scenario, seal_bid, 1400 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                DOMAIN_NAME,
                1000 * configuration::mist_per_sui(),
                b"wrong_secret",
                FIRST_USER_ADDRESS,
                2
            );
            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EInvalidPhase)]
    fun test_reveal_bid_abort_with_wrong_parameter_3() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;

        let seal_bid = make_seal_bid(DOMAIN_NAME, FIRST_USER_ADDRESS, 1000 * configuration::mist_per_sui(), FIRST_SECRET);
        start_an_auction_util(scenario, DOMAIN_NAME);
        place_bid_util(scenario, seal_bid, 10000 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                b"wrongn",
                1000 * configuration::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );
            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_reveal_bid_handle_invalid_if_mask_bid_less_than_actual_value() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        let seal_bid = make_seal_bid(DOMAIN_NAME, FIRST_USER_ADDRESS, 3000 * configuration::mist_per_sui(), FIRST_SECRET);
        start_an_auction_util(scenario, DOMAIN_NAME);
        place_bid_util(scenario, seal_bid, 2000 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let coin = test_scenario::most_recent_id_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(option::is_none(&coin), 0);

            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                DOMAIN_NAME,
                3000 * configuration::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );
            assert!(auction::get_balance(&auction) == 2000 * configuration::mist_per_sui(), 0);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
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
            get_entry_util(&mut auction, DOMAIN_NAME, START_AN_AUCTION_AT + 1, 0, 0, @0x0, false);
            test_scenario::return_shared(auction);
        };

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            finalize_auction_util(
                scenario,
                &mut auction,
                DOMAIN_NAME,
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
            assert!(coin::value(&coin) == 2000 * configuration::mist_per_sui(), 0);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            assert!(controller::get_balance(&suins) == START_AN_AUCTION_FEE + BIDDING_FEE, 0);

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
            auction::configure_auction(&admin_cap, &mut auction, &mut suins, 3000 * configuration::mist_per_sui(), 3000 * configuration::mist_per_sui(), &mut ctx);
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

    #[test, expected_failure(abort_code = auction::EInvalidPhase)]
    fun test_start_an_auction_aborts_if_set_auction_config_not_called() {
        let scenario = test_scenario::begin(SUINS_ADDRESS);
        {
            let ctx = ctx(&mut scenario);
            auction::test_init(ctx);
            configuration::test_init(ctx);
            suins::test_init(ctx);
            clock::share_for_testing(clock::create_for_testing(ctx));
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AN_AUCTION_AT,
                10
            );
            let ctx = &mut ctx;
            let auction = test_scenario::take_shared<AuctionHouse>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(3 * START_AN_AUCTION_FEE, ctx);

            auction::start_an_auction(&mut auction, &mut suins, utf8(DOMAIN_NAME), &mut coin, ctx);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            coin::burn_for_testing(coin);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = auction::EInvalidPhase)]
    fun test_place_bid_aborts_if_set_auction_config_not_called() {
        let scenario = test_scenario::begin(SUINS_ADDRESS);
        {
            let ctx = ctx(&mut scenario);
            auction::test_init(ctx);
            configuration::test_init(ctx);
            suins::test_init(ctx);
            clock::share_for_testing(clock::create_for_testing(ctx));
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                DEFAULT_TX_HASH,
                START_AN_AUCTION_AT + 1,
                15
            );
            let ctx = &mut ctx;
            let auction = test_scenario::take_shared<AuctionHouse>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(BIDDING_FEE * 3, ctx);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);

            auction::place_bid(&mut auction, &mut suins, &config, FIRST_SECRET, 1000 * configuration::mist_per_sui(), &mut coin, &clock, ctx);

            coin::burn_for_testing(coin);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = auction::EInvalidPhase)]
    fun test_reveal_bid_aborts_if_set_auction_config_not_called() {
        let scenario = test_scenario::begin(SUINS_ADDRESS);
        {
            let ctx = ctx(&mut scenario);
            auction::test_init(ctx);
            configuration::test_init(ctx);
            suins::test_init(ctx);
            clock::share_for_testing(clock::create_for_testing(ctx));
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AN_AUCTION_AT,
                10
            );
            let auction = test_scenario::take_shared<AuctionHouse>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            auction::reveal_bid(&mut auction, &config, utf8(DOMAIN_NAME), 1000 * configuration::mist_per_sui(), FIRST_SECRET, &mut ctx);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = auction::EInvalidPhase)]
    fun test_finalize_auction_aborts_if_set_auction_config_not_called() {
        let scenario = test_scenario::begin(SUINS_ADDRESS);
        {
            let ctx = ctx(&mut scenario);
            auction::test_init(ctx);
            configuration::test_init(ctx);
            suins::test_init(ctx);
            clock::share_for_testing(clock::create_for_testing(ctx));
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AN_AUCTION_AT,
                10
            );
            let auction = test_scenario::take_shared<AuctionHouse>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            auction::finalize_auction(&mut auction, &mut suins, &config, utf8(DOMAIN_NAME), &mut ctx);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = auction::EInvalidPhase)]
    fun test_finalize_auction_by_admin_aborts_if_set_auction_config_not_called() {
        let scenario = test_scenario::begin(SUINS_ADDRESS);
        {
            let ctx = ctx(&mut scenario);
            auction::test_init(ctx);
            configuration::test_init(ctx);
            suins::test_init(ctx);
            clock::share_for_testing(clock::create_for_testing(ctx));
        };
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let ctx = ctx_new(
                SUINS_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AN_AUCTION_AT,
                10
            );
            let auction = test_scenario::take_shared<AuctionHouse>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            auction::finalize_all_auctions_by_admin(&admin_cap, &mut auction, &mut suins, &config, &mut ctx);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(&mut scenario, admin_cap);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = auction::EInvalidPhase)]
    fun test_withdraw_aborts_if_set_auction_config_not_called() {
        let scenario = test_scenario::begin(SUINS_ADDRESS);
        {
            let ctx = ctx(&mut scenario);
            auction::test_init(ctx);
            configuration::test_init(ctx);
            clock::share_for_testing(clock::create_for_testing(ctx));
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AN_AUCTION_AT,
                10
            );
            let auction = test_scenario::take_shared<AuctionHouse>(&mut scenario);
            auction::withdraw(&mut auction, &mut ctx);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = auction::ELabelUnavailable)]
    fun test_start_an_auction_aborts_if_label_is_reserved() {
        let scenario = test_init();
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = &mut ctx_new(
                SUINS_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                50,
                2
            );
            controller::new_reserved_domains(
                &admin_cap,
                &mut suins,
                &config,
                b"abcde.sui",
                @0x0,
                ctx
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(&mut scenario, admin_cap);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AN_AUCTION_AT,
                10
            );
            let ctx = &mut ctx;
            let auction = test_scenario::take_shared<AuctionHouse>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(3 * START_AN_AUCTION_FEE, ctx);

            auction::start_an_auction(&mut auction, &mut suins, utf8(b"abcde"), &mut coin, ctx);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            coin::burn_for_testing(coin);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_start_an_auction_works_if_label_is_not_reserved() {
        let scenario = test_init();
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AN_AUCTION_AT,
                10
            );
            let ctx = &mut ctx;
            let auction = test_scenario::take_shared<AuctionHouse>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(3 * START_AN_AUCTION_FEE, ctx);

            auction::start_an_auction(&mut auction, &mut suins, utf8(b"abcde"), &mut coin, ctx);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            coin::burn_for_testing(coin);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(&mut scenario);

            let state = state_util(
                &auction,
                b"abcde",
                START_AN_AUCTION_AT,
            );
            assert!(state == AUCTION_STATE_PENDING, 0);
            let (start_at, highest_bid, second_highest_bid, winner, is_finalized) =
                auction::get_entry(&auction, utf8(b"abcde"));
            assert!(option::extract(&mut start_at) == START_AN_AUCTION_AT + 1, 0);
            assert!(option::extract(&mut highest_bid) == 0, 0);
            assert!(option::extract(&mut second_highest_bid) == 0, 0);
            assert!(option::extract(&mut winner) == @0x0, 0);
            assert!(option::extract(&mut is_finalized) == false, 0);

            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = auction::EPaymentNotEnough)]
    fun test_place_bid_aborts_if_payment_is_not_enough() {
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
            let coin = coin::mint_for_testing<SUI>(BIDDING_FEE + 999, ctx);
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
}
