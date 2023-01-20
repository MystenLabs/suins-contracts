#[test_only]
module suins::auction_tests {

    use sui::test_scenario::{Scenario, ctx};
    use sui::test_scenario;
    use suins::auction::{Self, Auction, make_seal_bid, get_bid, finalize_auction, get_bids_by_addr, get_bid_detail_fields, withdraw, state};
    use std::option;
    use sui::coin;
    use sui::sui::SUI;
    use sui::tx_context;
    use sui::dynamic_field;
    use std::option::{Option, some, none};
    use suins::base_registry::{Registry, AdminCap};
    use suins::base_registrar::{BaseRegistrar, TLDsList};
    use suins::base_registry;
    use suins::base_registrar;
    use suins::configuration::{Self, Configuration};
    use std::string::utf8;
    use std::vector;
    use sui::coin::Coin;
    use sui::vec_set;

    const SUINS_ADDRESS: address = @0xA001;
    const FIRST_USER_ADDRESS: address = @0xB001;
    const SECOND_USER_ADDRESS: address = @0xB002;
    const THIRD_USER_ADDRESS: address = @0xB003;
    const RESOLVER_ADDRESS: address = @0xC001;
    const HASH: vector<u8> = b"vUAgEwNmPr";
    const NODE: vector<u8> = b"suinns";
    const SECOND_NODE: vector<u8> = b"suinns2";
    const THIRD_NODE: vector<u8> = b"suinns3";
    const NODE_SUI: vector<u8> = b"suinns.sui";
    const SALT: vector<u8> = b"CnRGhPvfCu";
    // epoch at which user calls start_auction, next epoch. e.g START_AUCTION_AT + 1, is starting epoch
    const START_AUCTION_AT: u64 = 110;
    const BIDDING_PERIOD: u64 = 3;
    const REVEAL_PERIOD: u64 = 3;
    const AUCTION_STATE_NOT_AVAILABLE: u8 = 0;
    const AUCTION_STATE_OPEN: u8 = 1;
    const AUCTION_STATE_PENDING: u8 = 2;
    const AUCTION_STATE_BIDDING: u8 = 3;
    const AUCTION_STATE_REVEAL: u8 = 4;
    const AUCTION_STATE_FINALIZING: u8 = 5;
    const AUCTION_STATE_OWNED: u8 = 6;
    const AUCTION_STATE_REOPEN: u8 = 7;


    fun test_init(): Scenario {
        let scenario = test_scenario::begin(SUINS_ADDRESS);
        {
            let ctx = ctx(&mut scenario);
            auction::test_init(ctx);
            base_registry::test_init(ctx);
            base_registrar::test_init(ctx);
            configuration::test_init(ctx);
        };
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let tlds_list = test_scenario::take_shared<TLDsList>(&mut scenario);
            base_registrar::new_tld(&admin_cap, &mut tlds_list, b"move", test_scenario::ctx(&mut scenario));
            base_registrar::new_tld(&admin_cap, &mut tlds_list, b"sui", test_scenario::ctx(&mut scenario));
            test_scenario::return_shared(tlds_list);
            test_scenario::return_to_sender(&mut scenario, admin_cap);
        };
        scenario
    }

    fun start_auction_util(scenario: &mut Scenario, node: vector<u8>) {
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AUCTION_AT,
                10
            );
            let ctx = &mut ctx;
            let auction = test_scenario::take_shared<Auction>(scenario);
            let (start_at, highest_bid, second_highest_bid, winner, is_finalized) = auction::get_entry(&auction, node);
            assert!(option::is_none(&start_at), 0);
            assert!(option::is_none(&highest_bid), 0);
            assert!(option::is_none(&second_highest_bid), 0);
            assert!(option::is_none(&winner), 0);
            assert!(option::is_none(&is_finalized), 0);
            assert!(state_util(&auction, node, 10) == AUCTION_STATE_NOT_AVAILABLE, 0);
            assert!(state_util(&auction, node, START_AUCTION_AT) == AUCTION_STATE_OPEN, 0);

            let coin = coin::mint_for_testing<SUI>(30000, ctx);
            auction::start_auction(&mut auction, node, &mut coin, ctx);
            assert!(coin::value(&coin) == 20000, 0);
            assert!(state_util(&auction, node, START_AUCTION_AT) == AUCTION_STATE_PENDING, 0);
            assert!(state_util(&auction, node, START_AUCTION_AT + 1) == AUCTION_STATE_BIDDING, 0);
            assert!(state_util(&auction, node, START_AUCTION_AT + 1 + BIDDING_PERIOD) == AUCTION_STATE_REVEAL, 0);
            // receive no bid
            assert!(state_util(&auction, node, START_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD) == AUCTION_STATE_REOPEN, 0);
            let (start_at, highest_bid, second_highest_bid, winner, is_finalized) = auction::get_entry(&auction, node);
            assert!(option::extract(&mut start_at) == START_AUCTION_AT + 1, 0);
            assert!(option::extract(&mut highest_bid) == 0, 0);
            assert!(option::extract(&mut second_highest_bid) == 0, 0);
            assert!(option::extract(&mut winner) == @0x0, 0);
            assert!(option::extract(&mut is_finalized) == false, 0);
            test_scenario::return_shared(auction);
            coin::destroy_for_testing(coin);
        };
    }

    fun unseal_bid_util(auction: &mut Auction, epoch: u64, node: vector<u8>, value: u64, salt: vector<u8>, sender: address, ids_created: u64) {
        let ctx = tx_context::new(
            sender,
            x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
            epoch,
            ids_created
        );
        auction::unseal_bid(auction, node, value, salt, &mut ctx);
    }

    fun get_bid_util(auction: &Auction, seal_bid: vector<u8>, expected_bidder: Option<address>, expected_value: Option<u64>) {
        let (bidder, value) = get_bid(auction, seal_bid);
        if (option::is_some(&expected_bidder)) {
            assert!(option::extract(&mut bidder) == option::extract(&mut expected_bidder), 0);
            assert!(option::extract(&mut value) == option::extract(&mut expected_value), 0);
        } else {
            assert!(option::is_none(&bidder), 0);
            assert!(option::is_none(&value), 0);
        };
    }

    fun get_entry_util(
        auction: &Auction,
        node: vector<u8>,
        expected_start_at: u64,
        expected_highest_bid: u64,
        expected_second_highest_bid: u64,
        expected_winner: address,
        expected_is_finalized: bool,
    ) {
        let (start_at, highest_bid, second_highest_bid, winner, is_finalized) =
            auction::get_entry(auction, node);
        assert!(option::extract(&mut start_at) == expected_start_at, 0);
        assert!(option::extract(&mut highest_bid) == expected_highest_bid, 0);
        assert!(option::extract(&mut second_highest_bid) == expected_second_highest_bid, 0);
        assert!(option::extract(&mut winner) == expected_winner, 0);
        assert!(option::extract(&mut is_finalized) == expected_is_finalized, 0);
    }

    fun finalize_auction_util(
        scenario: &mut Scenario,
        auction: &mut Auction,
        node: vector<u8>,
        sender: address,
        epoch: u64,
    ) {
        let ctx = tx_context::new(
            sender,
            x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
            epoch,
            10
        );
        let registry = test_scenario::take_shared<Registry>(scenario);
        let registrar = test_scenario::take_shared<BaseRegistrar>(scenario);
        let config = test_scenario::take_shared<Configuration>(scenario);
        finalize_auction(auction, &mut registrar, &mut registry, &config, node, RESOLVER_ADDRESS, &mut ctx);
        test_scenario::return_shared(registry);
        test_scenario::return_shared(config);
        test_scenario::return_shared(registrar);
    }

    fun state_util(auction: &Auction, node: vector<u8>, epoch: u64): u8 {
        let ctx = tx_context::new(
            SUINS_ADDRESS,
            x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
            epoch,
            10
        );
        state(auction, node, &mut ctx)
    }

    fun new_bid_util(scenario: &mut Scenario, seal_bid: vector<u8>, value: u64, bidder: address) {
        test_scenario::next_tx(scenario, bidder);
        {
            let ctx = tx_context::new(
                bidder,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AUCTION_AT + 1,
                10
            );
            let ctx = &mut ctx;
            let auction = test_scenario::take_shared<Auction>(scenario);
            let coin = coin::mint_for_testing<SUI>(30000, ctx);
            let (owner, amount) = auction::get_bid(&auction, seal_bid);
            assert!(option::is_none(&owner), 0);
            assert!(option::is_none(&amount), 0);

            auction::new_bid(&mut auction, seal_bid, value, &mut coin, ctx);
            let (owner, amount) = auction::get_bid(&auction, seal_bid);
            assert!(option::extract(&mut owner) == bidder, 0);
            assert!(option::extract(&mut amount) == value, 0);
            assert!(coin::value(&coin) == 30000 - value, 0);
            coin::destroy_for_testing(coin);
            test_scenario::return_shared(auction);
        };
    }

    #[test]
    fun test_new_bid() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            new_bid_util(scenario, HASH, 1000, FIRST_USER_ADDRESS);
        };
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
            let bids = get_bids_by_addr(&auction, FIRST_USER_ADDRESS);
            assert!(vec_set::size(&bids) == 1, 0);
            let bids = vec_set::into_keys(bids);
            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 1000, 0);
            assert!(created_at == START_AUCTION_AT + 1, 0);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            new_bid_util(scenario, NODE, 1200, FIRST_USER_ADDRESS);
        };
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
            let bids = get_bids_by_addr(&auction, FIRST_USER_ADDRESS);
            let bids = vec_set::into_keys(bids);
            assert!(vector::length(&bids) == 2, 0);
            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 1000, 0);
            assert!(created_at == START_AUCTION_AT + 1, 0);

            let bid_detail = vector::borrow(&bids, 1);
            let (bidder, mask, created_at) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 1200, 0);
            assert!(created_at == START_AUCTION_AT + 1, 0);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            new_bid_util(scenario, b"bidbid", 12200, FIRST_USER_ADDRESS);
        };
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
            let bids = get_bids_by_addr(&auction, FIRST_USER_ADDRESS);
            let bids = vec_set::into_keys(bids);
            assert!(vector::length(&bids) == 3, 0);

            let bid_detail = vector::borrow(&bids, 1);
            let (bidder, mask, created_at) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 1200, 0);
            assert!(created_at == START_AUCTION_AT + 1, 0);

            let bid_detail = vector::borrow(&bids, 2);
            let (bidder, mask, created_at) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 12200, 0);
            assert!(created_at == START_AUCTION_AT + 1, 0);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EInvalidBid)]
    fun test_new_bid_abort_if_value_less_than_min_allowed_value() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                100,
                0
            );
            let ctx = &mut ctx;
            let auction = test_scenario::take_shared<Auction>(scenario);
            let coin = coin::mint_for_testing<SUI>(1000, ctx);
            auction::new_bid(&mut auction, HASH, 100, &mut coin, ctx);
            new_bid_util(scenario, HASH, 100, FIRST_USER_ADDRESS);
            coin::destroy_for_testing(coin);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EBidExisted)]
    fun test_new_bid_abort_if_submit_again() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        let ctx = tx_context::new(
            FIRST_USER_ADDRESS,
            x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
            100,
            0
        );
        let ctx = &mut ctx;
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {

            let auction = test_scenario::take_shared<Auction>(scenario);
            let coin = coin::mint_for_testing<SUI>(10000, ctx);
            auction::new_bid(&mut auction, HASH, 1000, &mut coin, ctx);
            coin::destroy_for_testing(coin);
            test_scenario::return_shared(auction);
        };

        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
            let coin = coin::mint_for_testing<SUI>(10000, ctx(scenario));
            auction::new_bid(&mut auction, HASH, 1000, &mut coin, ctx);
            coin::destroy_for_testing(coin);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EAuctionNotAvailable)]
    fun test_new_bid_abort_if_too_early() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                1,
                0
            );
            let ctx = &mut ctx;
            let auction = test_scenario::take_shared<Auction>(scenario);
            let coin = coin::mint_for_testing<SUI>(10000, ctx);
            auction::new_bid(&mut auction, HASH, 1000, &mut coin, ctx);
            coin::destroy_for_testing(coin);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EAuctionNotAvailable)]
    fun test_new_bid_abort_if_too_late() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                300,
                0
            );
            let ctx = &mut ctx;
            let auction = test_scenario::take_shared<Auction>(scenario);
            let coin = coin::mint_for_testing<SUI>(10000, ctx);
            auction::new_bid(&mut auction, HASH, 1000, &mut coin, ctx);
            coin::destroy_for_testing(coin);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_start_auction() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_auction_util(scenario, NODE);
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EInvalidPhase)]
    fun test_start_auction_aborts_if_too_early() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                90,
                0
            );
            let ctx = &mut ctx;
            let auction = test_scenario::take_shared<Auction>(scenario);
            let coin = coin::mint_for_testing<SUI>(30000, ctx);
            auction::start_auction(&mut auction, HASH, &mut coin, ctx);
            test_scenario::return_shared(auction);
            coin::destroy_for_testing(coin);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EInvalidPhase)]
    fun test_start_auction_aborts_if_too_late() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                300,
                0
            );
            let ctx = &mut ctx;
            let auction = test_scenario::take_shared<Auction>(scenario);
            let coin = coin::mint_for_testing<SUI>(30000, ctx);
            auction::start_auction(&mut auction, HASH, &mut coin, ctx);
            test_scenario::return_shared(auction);
            coin::destroy_for_testing(coin);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EInvalidPhase)]
    fun test_start_auction_in_pending_phase_abort() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                110,
                0
            );
            let ctx = &mut ctx;
            let auction = test_scenario::take_shared<Auction>(scenario);
            let test_coin = coin::mint_for_testing<SUI>(30000, ctx);
            auction::start_auction(&mut auction, HASH, &mut test_coin, ctx);
            assert!(coin::value(&test_coin) == 20000, 0);
            auction::start_auction(&mut auction, HASH, &mut test_coin, ctx);
            coin::destroy_for_testing(test_coin);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EInvalidPhase)]
    fun test_start_bidding_auction_in_bidding_phase_abort2() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                110,
                0
            );
            let auction = test_scenario::take_shared<Auction>(scenario);
            let coin = coin::mint_for_testing<SUI>(30000, &mut ctx);
            auction::start_auction(&mut auction, HASH, &mut coin, &mut ctx);
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                112,
                0
            );
            auction::start_auction(&mut auction, HASH, &mut coin, &mut ctx);
            test_scenario::return_shared(auction);
            coin::destroy_for_testing(coin);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EInvalidPhase)]
    fun test_start_auction_in_reveal_phase_abort() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                110,
                0
            );
            let auction = test_scenario::take_shared<Auction>(scenario);
            let coin = coin::mint_for_testing<SUI>(30000, &mut ctx);
            auction::start_auction(&mut auction, HASH, &mut coin,&mut ctx);
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                115,
                0
            );
            auction::start_auction(&mut auction, HASH, &mut coin, &mut ctx);
            coin::destroy_for_testing(coin);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_unseal_bid_handle_invalid_if_auction_not_start() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, SALT);
        new_bid_util(scenario, seal_bid, 1100, FIRST_USER_ADDRESS);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                115,
                10
            );
            let auction = test_scenario::take_shared<Auction>(scenario);
            let coin = test_scenario::most_recent_id_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(option::is_none(&coin), 0);

            auction::unseal_bid(&mut auction, NODE, 1000, SALT, &mut ctx);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let coin = test_scenario::take_from_sender<Coin<SUI>>(scenario);
            assert!(coin::value(&coin) == 1100, 0);
            test_scenario::return_to_sender(scenario, coin);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_unseal_bid() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, SALT);
        start_auction_util(scenario, NODE);
        new_bid_util(scenario, seal_bid, 1100, FIRST_USER_ADDRESS);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
            get_bid_util(&auction, seal_bid, some(FIRST_USER_ADDRESS), some(1100));
            let coin = test_scenario::most_recent_id_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(option::is_none(&coin), 0);

            let bids = get_bids_by_addr(&auction, FIRST_USER_ADDRESS);
            let bids = vec_set::into_keys(bids);
            assert!(vector::length(&bids) == 1, 0);
            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 1100, 0);
            assert!(created_at == START_AUCTION_AT + 1, 0);

            assert!(state_util(&auction, NODE, START_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD) == AUCTION_STATE_REOPEN, 0);
            unseal_bid_util(&mut auction, START_AUCTION_AT + 1 + BIDDING_PERIOD, NODE, 1000, SALT, FIRST_USER_ADDRESS, 2);
            assert!(state_util(&auction, NODE, START_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD) == AUCTION_STATE_FINALIZING, 0);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let coin = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin) == 100, 0);

            let auction = test_scenario::take_shared<Auction>(scenario);
            get_entry_util(&mut auction, NODE, START_AUCTION_AT + 1, 1000, 0 , FIRST_USER_ADDRESS, false);
            get_bid_util(&auction, seal_bid, none(), none());

            let bids = get_bids_by_addr(&auction, FIRST_USER_ADDRESS);
            assert!(vec_set::size(&bids) == 0, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin);
        };
        let seal_bid = make_seal_bid(NODE, SECOND_USER_ADDRESS, 1500, SALT);
        new_bid_util(scenario, seal_bid, 2000, SECOND_USER_ADDRESS);
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(scenario);
            get_bid_util(&auction, seal_bid, some(SECOND_USER_ADDRESS), some(2000));
            let coin = test_scenario::most_recent_id_for_address<Coin<SUI>>(SECOND_USER_ADDRESS);
            assert!(option::is_none(&coin), 0);

            let bids = get_bids_by_addr(&auction, SECOND_USER_ADDRESS);
            let bids = vec_set::into_keys(bids);
            assert!(vector::length(&bids) == 1, 0);
            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at) = get_bid_detail_fields(bid_detail);
            assert!(bidder == SECOND_USER_ADDRESS, 0);
            assert!(mask == 2000, 0);
            assert!(created_at == START_AUCTION_AT + 1, 0);

            unseal_bid_util(&mut auction, START_AUCTION_AT + 1 + BIDDING_PERIOD, NODE, 1500, SALT, SECOND_USER_ADDRESS, 10);
            assert!(!base_registrar::record_exists(&registrar, utf8(NODE)), 0);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(registrar);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 2, 0);
            let coin1 = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin1) == 1000, 0);
            let coin2 = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin2) == 100, 0);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin1);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin2);

            let ids = test_scenario::ids_for_address<Coin<SUI>>(SECOND_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);
            let coin = test_scenario::take_from_address<Coin<SUI>>(scenario, SECOND_USER_ADDRESS);
            assert!(coin::value(&coin) == 500, 0);
            test_scenario::return_to_address(SECOND_USER_ADDRESS, coin);
        };
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
            let bids = get_bids_by_addr(&auction, FIRST_USER_ADDRESS);
            assert!(vec_set::size(&bids) == 0, 0);

            get_entry_util(&mut auction, NODE, START_AUCTION_AT + 1, 1500, 1000 , SECOND_USER_ADDRESS, false);
            finalize_auction_util(scenario, &mut auction, NODE, SECOND_USER_ADDRESS, START_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(scenario);
            let registry = test_scenario::take_shared<Registry>(scenario);
            get_entry_util(&mut auction, NODE, START_AUCTION_AT + 1, 1500, 1000 , SECOND_USER_ADDRESS, true);
            assert!(base_registrar::record_exists(&registrar, utf8(NODE)), 0);
            assert!(base_registrar::name_expires(&registrar, utf8(NODE)) == START_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD + 365, 0);
            assert!(base_registry::owner(&registry, NODE_SUI) == SECOND_USER_ADDRESS, 0);
            assert!(base_registry::ttl(&registry, NODE_SUI) == 0, 0);
            assert!(base_registry::resolver(&registry, NODE_SUI) == RESOLVER_ADDRESS, 0);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(registry);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EUnauthorized)]
    fun test_finalize_auction_util_abort_if_unauthorized() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, SALT);
        start_auction_util(scenario, NODE);
        new_bid_util(scenario, seal_bid, 1000, FIRST_USER_ADDRESS);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
            get_bid_util(&auction, seal_bid, some(FIRST_USER_ADDRESS), some(1000));
            unseal_bid_util(&mut auction, START_AUCTION_AT + 1 + BIDDING_PERIOD, NODE, 1000, SALT, FIRST_USER_ADDRESS, 2);
            test_scenario::return_shared(auction);
        };
        let seal_bid = make_seal_bid(NODE, SECOND_USER_ADDRESS, 1500, SALT);
        new_bid_util(scenario, seal_bid, 2100, SECOND_USER_ADDRESS);
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(scenario);
            get_bid_util(&auction, seal_bid, some(SECOND_USER_ADDRESS), some(2100));
            unseal_bid_util(&mut auction, START_AUCTION_AT + 1 + BIDDING_PERIOD, NODE, 1500, SALT, SECOND_USER_ADDRESS, 10);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(registrar);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);
            let coin = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin) == 1000, 0);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin);

            let ids = test_scenario::ids_for_address<Coin<SUI>>(SECOND_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);
            let coin = test_scenario::take_from_address<Coin<SUI>>(scenario, SECOND_USER_ADDRESS);
            assert!(coin::value(&coin) == 600, 0);
            test_scenario::return_to_address(SECOND_USER_ADDRESS, coin);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
            finalize_auction_util(scenario, &mut auction, NODE, FIRST_USER_ADDRESS, START_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_finalize_auction() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, SALT);
        start_auction_util(scenario, NODE);
        new_bid_util(scenario, seal_bid, 1000, FIRST_USER_ADDRESS);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
            get_bid_util(&auction, seal_bid, some(FIRST_USER_ADDRESS), some(1000));
            unseal_bid_util(&mut auction, START_AUCTION_AT + 1 + BIDDING_PERIOD, NODE, 1000, SALT, FIRST_USER_ADDRESS, 2);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
            finalize_auction_util(scenario, &mut auction, NODE, FIRST_USER_ADDRESS, START_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(scenario);
            let registry = test_scenario::take_shared<Registry>(scenario);
            get_entry_util(&mut auction, NODE, START_AUCTION_AT + 1, 1000, 0 , FIRST_USER_ADDRESS, true);
            assert!(base_registrar::record_exists(&registrar, utf8(NODE)), 0);
            assert!(base_registrar::name_expires(&registrar, utf8(NODE)) == START_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD + 365, 0);
            assert!(base_registry::owner(&registry, NODE_SUI) == FIRST_USER_ADDRESS, 0);
            assert!(base_registry::ttl(&registry, NODE_SUI) == 0, 0);
            assert!(base_registry::resolver(&registry, NODE_SUI) == RESOLVER_ADDRESS, 0);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(registry);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EInvalidRegistrar)]
    fun test_finalize_auction_abort_if_using_move_registrar() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, SALT);
        start_auction_util(scenario, NODE);
        new_bid_util(scenario, seal_bid, 1000, FIRST_USER_ADDRESS);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
            get_bid_util(&auction, seal_bid, some(FIRST_USER_ADDRESS), some(1000));
            unseal_bid_util(&mut auction, START_AUCTION_AT + 1 + BIDDING_PERIOD, NODE, 1000, SALT, FIRST_USER_ADDRESS, 2);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                122,
                0
            );
            let registry = test_scenario::take_shared<Registry>(scenario);
            let sui_registrar = test_scenario::take_shared<BaseRegistrar>(scenario);
            let move_registrar = test_scenario::take_shared<BaseRegistrar>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            finalize_auction(&mut auction, &mut move_registrar, &mut registry, &config, NODE, RESOLVER_ADDRESS, &mut ctx);
            test_scenario::return_shared(registry);
            test_scenario::return_shared(config);
            test_scenario::return_shared(sui_registrar);
            test_scenario::return_shared(move_registrar);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_unseal_bid_late() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, SALT);
        start_auction_util(scenario, NODE);
        new_bid_util(scenario, seal_bid, 1001, FIRST_USER_ADDRESS);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
            let coin = test_scenario::most_recent_id_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(option::is_none(&coin), 0);

            unseal_bid_util(&mut auction, START_AUCTION_AT + 1 + BIDDING_PERIOD, NODE, 1000, SALT, FIRST_USER_ADDRESS, 2);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);
            let coin = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin) == 1, 0);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin);
        };
        let seal_bid = make_seal_bid(NODE, SECOND_USER_ADDRESS, 1500, SALT);
        new_bid_util(scenario, seal_bid, 2000, SECOND_USER_ADDRESS);
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
            unseal_bid_util(&mut auction, START_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD, NODE, 1500, SALT, SECOND_USER_ADDRESS, 10);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
            get_entry_util(&auction, NODE, START_AUCTION_AT + 1, 1000, 0, FIRST_USER_ADDRESS, false);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(SECOND_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);

            let coin = test_scenario::take_from_address<Coin<SUI>>(scenario, SECOND_USER_ADDRESS);
            assert!(coin::value(&coin) == 2000, 0);

            test_scenario::return_to_address(SECOND_USER_ADDRESS, coin);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_unseal_invalid_bid() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_auction_util(scenario, NODE);
        let seal_bid = make_seal_bid(NODE, SECOND_USER_ADDRESS, 500, SALT);
        new_bid_util(scenario, seal_bid, 2000, SECOND_USER_ADDRESS);
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
            assert!(state_util(&auction, NODE, START_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD) == AUCTION_STATE_REOPEN, 0);
            unseal_bid_util(&mut auction, START_AUCTION_AT + 1 + BIDDING_PERIOD, NODE, 500, SALT, SECOND_USER_ADDRESS, 2);
            assert!(state_util(&auction, NODE, START_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD) == AUCTION_STATE_REOPEN, 0);
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
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
            get_entry_util(&auction, NODE, START_AUCTION_AT + 1, 0, 0, @0x0, false);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = dynamic_field::EFieldDoesNotExist)]
        fun test_unseal_bid_abort_if_unseal_twice() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, SALT);
        start_auction_util(scenario, NODE);
        new_bid_util(scenario, seal_bid, 1000, FIRST_USER_ADDRESS);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
            unseal_bid_util(&mut auction, START_AUCTION_AT + 1 + BIDDING_PERIOD, NODE, 1000, SALT, FIRST_USER_ADDRESS, 2);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
            unseal_bid_util(&mut auction, START_AUCTION_AT + 1 + BIDDING_PERIOD, NODE, 1000, SALT, FIRST_USER_ADDRESS, 10);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 0, 0);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = dynamic_field::EFieldDoesNotExist)]
    fun test_unseal_bid_abort_with_wrong_parameter() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, SALT);
        start_auction_util(scenario, NODE);
        new_bid_util(scenario, seal_bid, 1000, FIRST_USER_ADDRESS);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
            unseal_bid_util(&mut auction, START_AUCTION_AT + 1 + BIDDING_PERIOD, NODE, 1200, SALT, FIRST_USER_ADDRESS, 2);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);
            let coin = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin) == 1200, 0);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = dynamic_field::EFieldDoesNotExist)]
    fun test_unseal_bid_abort_with_wrong_parameter2() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, SALT);
        start_auction_util(scenario, NODE);
        new_bid_util(scenario, seal_bid, 1400, FIRST_USER_ADDRESS);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
            unseal_bid_util(&mut auction, START_AUCTION_AT + 1 + BIDDING_PERIOD, NODE, 1000, b"wrong_salt", FIRST_USER_ADDRESS, 2);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);
            let coin = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin) == 1400, 0);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = dynamic_field::EFieldDoesNotExist)]
    fun test_unseal_bid_abort_with_wrong_parameter3() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, SALT);
        start_auction_util(scenario, NODE);
        new_bid_util(scenario, seal_bid, 10000, FIRST_USER_ADDRESS);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
            unseal_bid_util(&mut auction, START_AUCTION_AT + 1 + BIDDING_PERIOD, b"wrong_node", 1000, SALT, FIRST_USER_ADDRESS, 2);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);
            let coin = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin) == 10000, 0);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_unseal_bid_handle_invalid_if_mask_bid_less_than_actual_value() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 3000, SALT);
        start_auction_util(scenario, NODE);
        new_bid_util(scenario, seal_bid, 2000, FIRST_USER_ADDRESS);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
            let coin = test_scenario::most_recent_id_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(option::is_none(&coin), 0);

            unseal_bid_util(&mut auction, START_AUCTION_AT + 1 + BIDDING_PERIOD, NODE, 3000, SALT, FIRST_USER_ADDRESS, 2);
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
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
            let coin = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin) == 2000, 0);
            get_entry_util(&mut auction, NODE, START_AUCTION_AT + 1, 0, 0 , @0x0, false);

            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_config_auction() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                114,
                0
            );
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let auction = test_scenario::take_shared<Auction>(scenario);
            auction::config_auction(&admin_cap, &mut auction, 3000, 3001, &mut ctx);
            test_scenario::return_shared(auction);
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
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                114,
                0
            );
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let auction = test_scenario::take_shared<Auction>(scenario);
            auction::config_auction(&admin_cap, &mut auction, 3001, 3000, &mut ctx);
            test_scenario::return_shared(auction);
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
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                114,
                0
            );
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let auction = test_scenario::take_shared<Auction>(scenario);
            auction::config_auction(&admin_cap, &mut auction, 3000, 3000, &mut ctx);
            test_scenario::return_shared(auction);
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
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                114,
                0
            );
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let auction = test_scenario::take_shared<Auction>(scenario);
            auction::config_auction(&admin_cap, &mut auction, 100, 300, &mut ctx);
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
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                114,
                2
            );
            let auction = test_scenario::take_shared<Auction>(scenario);
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
            let auction = test_scenario::take_shared<Auction>(scenario);
            withdraw(&mut auction, &mut ctx);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_bids_multiple_domains_and_unseal_only_one() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_auction_util(scenario, NODE);
        start_auction_util(scenario, SECOND_NODE);
        start_auction_util(scenario, THIRD_NODE);
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, SALT);
        new_bid_util(scenario, seal_bid, 1300, FIRST_USER_ADDRESS);
        let seal_bid = make_seal_bid(SECOND_NODE, FIRST_USER_ADDRESS, 2000, SALT);
        new_bid_util(scenario, seal_bid, 2200, FIRST_USER_ADDRESS);
        let seal_bid = make_seal_bid(THIRD_NODE, FIRST_USER_ADDRESS, 3000, SALT);
        new_bid_util(scenario, seal_bid, 12200, FIRST_USER_ADDRESS);

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
            let coin = test_scenario::most_recent_id_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(option::is_none(&coin), 0);

            let bids = get_bids_by_addr(&auction, FIRST_USER_ADDRESS);
            let bids = vec_set::into_keys(bids);
            assert!(vector::length(&bids) == 3, 0);
            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 1300, 0);
            assert!(created_at == START_AUCTION_AT + 1, 0);

            let bid_detail = vector::borrow(&bids, 1);
            let (bidder, mask, created_at) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 2200, 0);
            assert!(created_at == START_AUCTION_AT + 1, 0);

            let bid_detail = vector::borrow(&bids, 2);
            let (bidder, mask, created_at) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 12200, 0);
            assert!(created_at == START_AUCTION_AT + 1, 0);

            unseal_bid_util(&mut auction, START_AUCTION_AT + 1 + BIDDING_PERIOD, SECOND_NODE, 2000, SALT, FIRST_USER_ADDRESS, 2);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);
            let coin = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin) == 200, 0);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
            let coin = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin) == 200, 0);

            let bids = get_bids_by_addr(&auction, FIRST_USER_ADDRESS);
            let bids = vec_set::into_keys(bids);
            assert!(vector::length(&bids) == 2, 0);

            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 1300, 0);
            assert!(created_at == START_AUCTION_AT + 1, 0);

            let bid_detail = vector::borrow(&bids, 1);
            let (bidder, mask, created_at) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 12200, 0);
            assert!(created_at == START_AUCTION_AT + 1, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AUCTION_AT + 200,
                0
            );
            let bids = get_bids_by_addr(&auction, FIRST_USER_ADDRESS);
            let bids = vec_set::into_keys(bids);
            assert!(vector::length(&bids) == 2, 0);
            withdraw(&mut auction, &mut ctx);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
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

            let bids = get_bids_by_addr(&auction, FIRST_USER_ADDRESS);
            let bids = vec_set::into_keys(bids);
            assert!(vector::length(&bids) == 0, 0);

            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_bids_same_domain_and_unseal_only_one_bid() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_auction_util(scenario, NODE);
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, SALT);
        new_bid_util(scenario, seal_bid, 1300, FIRST_USER_ADDRESS);

        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 2000, SALT);
        new_bid_util(scenario, seal_bid, 2200, FIRST_USER_ADDRESS);

        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 3000, SALT);
        new_bid_util(scenario, seal_bid, 12200, FIRST_USER_ADDRESS);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
            let coin = test_scenario::most_recent_id_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(option::is_none(&coin), 0);

            let bids = get_bids_by_addr(&auction, FIRST_USER_ADDRESS);
            let bids = vec_set::into_keys(bids);
            assert!(vector::length(&bids) == 3, 0);
            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 1300, 0);
            assert!(created_at == START_AUCTION_AT + 1, 0);

            let bid_detail = vector::borrow(&bids, 1);
            let (bidder, mask, created_at) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 2200, 0);
            assert!(created_at == START_AUCTION_AT + 1, 0);

            let bid_detail = vector::borrow(&bids, 2);
            let (bidder, mask, created_at) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 12200, 0);
            assert!(created_at == START_AUCTION_AT + 1, 0);

            unseal_bid_util(&mut auction, START_AUCTION_AT + 1 + BIDDING_PERIOD, NODE, 3000, SALT, FIRST_USER_ADDRESS, 2);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);
            let coin = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin) == 9200, 0);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
            let coin = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin) == 12200 - 3000, 0);

            let bids = get_bids_by_addr(&auction, FIRST_USER_ADDRESS);
            let bids = vec_set::into_keys(bids);
            assert!(vector::length(&bids) == 2, 0);

            let bid_detail = vector::borrow(&bids, 0);
            let (bidder, mask, created_at) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 1300, 0);
            assert!(created_at == START_AUCTION_AT + 1, 0);

            let bid_detail = vector::borrow(&bids, 1);
            let (bidder, mask, created_at) = get_bid_detail_fields(bid_detail);
            assert!(bidder == FIRST_USER_ADDRESS, 0);
            assert!(mask == 2200, 0);
            assert!(created_at == START_AUCTION_AT + 1, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AUCTION_AT + 200,
                10
            );
            let bids = get_bids_by_addr(&auction, FIRST_USER_ADDRESS);
            let bids = vec_set::into_keys(bids);
            assert!(vector::length(&bids) == 2, 0);
            withdraw(&mut auction, &mut ctx);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 3, 0);
            let coin1 = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin1) == 2200, 0);
            let coin2 = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin2) == 1300, 0);
            let coin3 = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin3) == 9200, 0);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin1);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin2);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin3);

            let bids = get_bids_by_addr(&auction, FIRST_USER_ADDRESS);
            let bids = vec_set::into_keys(bids);
            assert!(vector::length(&bids) == 0, 0);

            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_finalized_entry_has_state_of_owned() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_auction_util(scenario, NODE);
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, SALT);
        new_bid_util(scenario, seal_bid, 1300, FIRST_USER_ADDRESS);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
            unseal_bid_util(&mut auction, START_AUCTION_AT + 1 + BIDDING_PERIOD, NODE, 1000, SALT, FIRST_USER_ADDRESS, 2);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
            finalize_auction_util(scenario, &mut auction, NODE, FIRST_USER_ADDRESS, START_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD);
            test_scenario::return_shared(auction);
        };

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
            assert!(state_util(&auction, NODE, START_AUCTION_AT + 1) == AUCTION_STATE_OWNED, 0);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_unseal_bid_handle_invalid_bid_if_actual_value_less_than_min_allowed_value() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_auction_util(scenario, NODE);
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 999, SALT);
        new_bid_util(scenario, seal_bid, 1300, FIRST_USER_ADDRESS);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
            let coin = test_scenario::most_recent_id_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(option::is_none(&coin), 0);
            unseal_bid_util(&mut auction, START_AUCTION_AT + 1 + BIDDING_PERIOD, NODE, 999, SALT, FIRST_USER_ADDRESS, 2);
            test_scenario::return_shared(auction);
        };

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);
            let coin = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin) == 1300, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_unseal_bid_handle_invalid_bid_if_new_bid_too_early() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_auction_util(scenario, NODE);
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1100, SALT);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AUCTION_AT - 1,
                2
            );
            let ctx = &mut ctx;
            let auction = test_scenario::take_shared<Auction>(scenario);
            let coin = coin::mint_for_testing<SUI>(30000, ctx);
            auction::new_bid(&mut auction, seal_bid, 1300, &mut coin, ctx);

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
            let coin = test_scenario::most_recent_id_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(option::is_none(&coin), 0);

            unseal_bid_util(&mut auction, START_AUCTION_AT + 1 + BIDDING_PERIOD, NODE, 1100, SALT, FIRST_USER_ADDRESS, 5);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);
            let coin = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin) == 1300, 0);
            let (start_at, highest_bid, second_highest_bid, winner, is_finalized) =
                auction::get_entry(&auction, NODE);
            assert!(option::extract(&mut start_at) == START_AUCTION_AT + 1, 0);
            assert!(option::extract(&mut highest_bid) == 0, 0);
            assert!(option::extract(&mut second_highest_bid) == 0, 0);
            assert!(option::extract(&mut winner) == @0x0, 0);
            assert!(option::extract(&mut is_finalized) == false, 0);
            test_scenario::return_shared(auction);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_unseal_bid_handle_invalid_bid_if_new_bid_too_late() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_auction_util(scenario, NODE);
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 11100, SALT);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AUCTION_AT + 1 + BIDDING_PERIOD,
                2
            );
            let ctx = &mut ctx;
            let auction = test_scenario::take_shared<Auction>(scenario);
            let coin = coin::mint_for_testing<SUI>(30000, ctx);
            auction::new_bid(&mut auction, seal_bid, 30000, &mut coin, ctx);

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
            let coin = test_scenario::most_recent_id_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(option::is_none(&coin), 0);

            unseal_bid_util(&mut auction, START_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD, NODE, 11100, SALT, FIRST_USER_ADDRESS, 5);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);
            let coin = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin) == 30000, 0);
            let (start_at, highest_bid, second_highest_bid, winner, is_finalized) =
                auction::get_entry(&auction, NODE);
            assert!(option::extract(&mut start_at) == START_AUCTION_AT + 1, 0);
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
    fun test_unseal_bid_abort_if_use_seal_bid_of_other_people() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, SALT);
        start_auction_util(scenario, NODE);
        new_bid_util(scenario, seal_bid, 1000, FIRST_USER_ADDRESS);
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
            unseal_bid_util(&mut auction, START_AUCTION_AT + 1 + BIDDING_PERIOD, NODE, 1000, SALT, SECOND_USER_ADDRESS, 2);
            test_scenario::return_shared(auction);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_unseal_bid_handle_second_highest_bid() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 3000, SALT);
        start_auction_util(scenario, NODE);
        new_bid_util(scenario, seal_bid, 4100, FIRST_USER_ADDRESS);
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
            let coin = test_scenario::most_recent_id_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(option::is_none(&coin), 0);
            let coin = test_scenario::most_recent_id_for_address<Coin<SUI>>(SECOND_USER_ADDRESS);
            assert!(option::is_none(&coin), 0);
            test_scenario::return_shared(auction);
        };

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
            unseal_bid_util(&mut auction, START_AUCTION_AT + 1 + BIDDING_PERIOD, NODE, 3000, SALT, FIRST_USER_ADDRESS, 2);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);
            let coin = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin) == 1100, 0);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin);
        };
        let seal_bid = make_seal_bid(NODE, SECOND_USER_ADDRESS, 1500, SALT);
        new_bid_util(scenario, seal_bid, 2000, SECOND_USER_ADDRESS);
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
            unseal_bid_util(&mut auction, START_AUCTION_AT + 1 + BIDDING_PERIOD, NODE, 1500, SALT, SECOND_USER_ADDRESS, 5);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(SECOND_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);
            let coin = test_scenario::take_from_address<Coin<SUI>>(scenario, SECOND_USER_ADDRESS);
            assert!(coin::value(&coin) == 2000, 0);

            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);
            let coin2 = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin2) == 1100, 0);

            test_scenario::return_to_address(SECOND_USER_ADDRESS, coin);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin2);
        };
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
            get_entry_util(&mut auction, NODE, START_AUCTION_AT + 1, 3000, 1500 , FIRST_USER_ADDRESS, false);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_unseal_bid_handle_low_value_bid() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 3000, SALT);
        start_auction_util(scenario, NODE);
        new_bid_util(scenario, seal_bid, 4100, FIRST_USER_ADDRESS);
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
            let coin = test_scenario::most_recent_id_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(option::is_none(&coin), 0);
            let coin = test_scenario::most_recent_id_for_address<Coin<SUI>>(SECOND_USER_ADDRESS);
            assert!(option::is_none(&coin), 0);
            test_scenario::return_shared(auction);
        };

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
            unseal_bid_util(&mut auction, START_AUCTION_AT + 1 + BIDDING_PERIOD, NODE, 3000, SALT, FIRST_USER_ADDRESS, 2);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(FIRST_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);
            let coin = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_USER_ADDRESS);
            assert!(coin::value(&coin) == 1100, 0);
            test_scenario::return_to_address(FIRST_USER_ADDRESS, coin);
        };
        let seal_bid = make_seal_bid(NODE, SECOND_USER_ADDRESS, 1500, SALT);
        new_bid_util(scenario, seal_bid, 2000, SECOND_USER_ADDRESS);
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
            unseal_bid_util(&mut auction, START_AUCTION_AT + 1 + BIDDING_PERIOD, NODE, 1500, SALT, SECOND_USER_ADDRESS, 5);
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
        let seal_bid = make_seal_bid(NODE, THIRD_USER_ADDRESS, 1200, SALT);
        new_bid_util(scenario, seal_bid, 2000, THIRD_USER_ADDRESS);
        test_scenario::next_tx(scenario, THIRD_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
            unseal_bid_util(&mut auction, START_AUCTION_AT + 1 + BIDDING_PERIOD, NODE, 1200, SALT, THIRD_USER_ADDRESS, 10);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let ids = test_scenario::ids_for_address<Coin<SUI>>(THIRD_USER_ADDRESS);
            assert!(vector::length(&ids) == 1, 0);
            let coin = test_scenario::take_from_address<Coin<SUI>>(scenario, THIRD_USER_ADDRESS);
            assert!(coin::value(&coin) == 2000, 0);
            test_scenario::return_to_address(THIRD_USER_ADDRESS, coin);
        };
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
            get_entry_util(&mut auction, NODE, START_AUCTION_AT + 1, 3000, 1500 , FIRST_USER_ADDRESS, false);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EInvalidPhase)]
    fun test_finalize_bid_abort_if_too_early() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, SALT);
        start_auction_util(scenario, NODE);
        new_bid_util(scenario, seal_bid, 1100, FIRST_USER_ADDRESS);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
            unseal_bid_util(&mut auction, START_AUCTION_AT + 1 + BIDDING_PERIOD, NODE, 1000, SALT, FIRST_USER_ADDRESS, 0);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
            get_entry_util(&mut auction, NODE, START_AUCTION_AT + 1, 1000, 0 , FIRST_USER_ADDRESS, false);
            finalize_auction_util(scenario, &mut auction, NODE, FIRST_USER_ADDRESS, START_AUCTION_AT + 1 + BIDDING_PERIOD);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EInvalidPhase)]
    fun test_finalize_bid_abort_being_called_twice() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, SALT);
        start_auction_util(scenario, NODE);
        new_bid_util(scenario, seal_bid, 1100, FIRST_USER_ADDRESS);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
            unseal_bid_util(&mut auction, START_AUCTION_AT + 1 + BIDDING_PERIOD, NODE, 1000, SALT, FIRST_USER_ADDRESS, 0);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
            get_entry_util(&mut auction, NODE, START_AUCTION_AT + 1, 1000, 0 , FIRST_USER_ADDRESS, false);
            finalize_auction_util(scenario, &mut auction, NODE, FIRST_USER_ADDRESS, START_AUCTION_AT + 1 + BIDDING_PERIOD + REVEAL_PERIOD);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
            finalize_auction_util(scenario, &mut auction, NODE, FIRST_USER_ADDRESS, START_AUCTION_AT + 1 + BIDDING_PERIOD);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }
}
