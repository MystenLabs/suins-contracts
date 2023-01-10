#[test_only]
module suins::auction_tests {

    use sui::test_scenario::{Scenario, ctx};
    use sui::test_scenario;
    use suins::auction::{Self, Auction, make_seal_bid, get_bid};
    use std::option;
    use sui::coin;
    use sui::sui::SUI;
    use sui::tx_context;
    use sui::dynamic_field;

    const SUINS_ADDRESS: address = @0xA001;
    const FIRST_USER_ADDRESS: address = @0xB001;
    const SECOND_USER_ADDRESS: address = @0xB002;
    const HASH: vector<u8> = b"vUAgEwNmPr";
    const NODE: vector<u8> = b"suinns";
    const SALT: vector<u8> = b"CnRGhPvfCu";

    fun test_init(): Scenario {
        let scenario = test_scenario::begin(SUINS_ADDRESS);
        {
            let ctx = ctx(&mut scenario);
            auction::test_init(ctx);
        };
        scenario
    }

    fun start_auction_util(scenario: &mut Scenario, node: vector<u8>) {
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
            let (start_at, highest_bid, second_highest_bid, winner) = auction::get_entry(&auction, node);
            assert!(option::is_none(&start_at), 0);
            assert!(option::is_none(&highest_bid), 0);
            assert!(option::is_none(&second_highest_bid), 0);
            assert!(option::is_none(&winner), 0);

            auction::start_auction(&mut auction, node, ctx);
            let (start_at, highest_bid, second_highest_bid, winner) = auction::get_entry(&auction, node);
            assert!(option::extract(&mut start_at) == 111, 0);
            assert!(option::extract(&mut highest_bid) == 0, 0);
            assert!(option::extract(&mut second_highest_bid) == 0, 0);
            assert!(option::extract(&mut winner) == @0x0, 0);
            test_scenario::return_shared(auction);
        };
    }

    fun new_bid_util(scenario: &mut Scenario, seal_bid: vector<u8>, value: u64, bidder: address) {
        test_scenario::next_tx(scenario, bidder);
        {
            let ctx = tx_context::new(
                bidder,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                111,
                0
            );
            let ctx = &mut ctx;
            let auction = test_scenario::take_shared<Auction>(scenario);
            let coin = coin::mint_for_testing<SUI>(10000, ctx);
            let (owner, amount) = auction::get_bid(&auction, seal_bid);
            assert!(option::is_none(&owner), 0);
            assert!(option::is_none(&amount), 0);

            auction::new_bid(&mut auction, seal_bid, value, &mut coin, ctx);
            let (owner, amount) = auction::get_bid(&auction, seal_bid);
            assert!(option::extract(&mut owner) == bidder, 0);
            assert!(option::extract(&mut amount) == value, 0);
            assert!(coin::value(&coin) == 10000 - value, 0);
            coin::destroy_for_testing(coin);
            test_scenario::return_shared(auction);
        };
    }
    #[test]
    fun test_new_bid() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        new_bid_util(scenario, HASH, 1000, FIRST_USER_ADDRESS);
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
            auction::start_auction(&mut auction, HASH, ctx);
            test_scenario::return_shared(auction);
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
            auction::start_auction(&mut auction, HASH, ctx);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EInvalidPhase)]
    fun test_start_bidding_auction_abort() {
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
            auction::start_auction(&mut auction, HASH, ctx);
            auction::start_auction(&mut auction, HASH, ctx);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EInvalidPhase)]
    fun test_start_bidding_auction_abort2() {
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
            auction::start_auction(&mut auction, HASH, &mut ctx);
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                112,
                0
            );
            auction::start_auction(&mut auction, HASH, &mut ctx);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EInvalidPhase)]
    fun test_start_reveal_auction_abort() {
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
            auction::start_auction(&mut auction, HASH, &mut ctx);
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                115,
                0
            );
            auction::start_auction(&mut auction, HASH, &mut ctx);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = dynamic_field::EFieldDoesNotExist)]
    fun test_unseal_bid_abort_if_auction_not_start() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                115,
                0
            );
            let auction = test_scenario::take_shared<Auction>(scenario);
            auction::unseal_bid(&mut auction, NODE, 1000, SALT, &mut ctx);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_unseal_bid() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, SALT);
        start_auction_util(scenario, NODE);
        new_bid_util(scenario, seal_bid, 1000, FIRST_USER_ADDRESS);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                114,
                0
            );
            let auction = test_scenario::take_shared<Auction>(scenario);
            let (bidder, value) = get_bid(&auction, seal_bid);
            assert!(option::extract(&mut bidder) == FIRST_USER_ADDRESS, 0);
            assert!(option::extract(&mut value) == 1000, 0);
            auction::unseal_bid(&mut auction, NODE, 1000, SALT, &mut ctx);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
            let (start_at, highest_bid, second_highest_bid, winner) =
                auction::get_entry(&auction, NODE);
            assert!(option::extract(&mut start_at) == 111, 0);
            assert!(option::extract(&mut highest_bid) == 1000, 0);
            assert!(option::extract(&mut second_highest_bid) == 0, 0);
            assert!(option::extract(&mut winner) == FIRST_USER_ADDRESS, 0);
            let (bidder, value) = get_bid(&auction, seal_bid);
            assert!(option::is_none(&bidder), 0);
            assert!(option::is_none(&value), 0);
            test_scenario::return_shared(auction);
        };
        let seal_bid = make_seal_bid(NODE, SECOND_USER_ADDRESS, 1500, SALT);
        new_bid_util(scenario, seal_bid, 2000, SECOND_USER_ADDRESS);
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let ctx = tx_context::new(
                SECOND_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                114,
                0
            );
            let auction = test_scenario::take_shared<Auction>(scenario);
            let (bidder, value) = get_bid(&auction, seal_bid);
            assert!(option::extract(&mut bidder) == SECOND_USER_ADDRESS, 0);
            assert!(option::extract(&mut value) == 2000, 0);
            auction::unseal_bid(&mut auction, NODE, 1500, SALT, &mut ctx);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
            let (start_at, highest_bid, second_highest_bid, winner) =
                auction::get_entry(&auction, NODE);
            assert!(option::extract(&mut start_at) == 111, 0);
            assert!(option::extract(&mut highest_bid) == 1500, 0);
            assert!(option::extract(&mut second_highest_bid) == 1000, 0);
            assert!(option::extract(&mut winner) == SECOND_USER_ADDRESS, 0);
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
        new_bid_util(scenario, seal_bid, 1000, FIRST_USER_ADDRESS);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                114,
                0
            );
            let auction = test_scenario::take_shared<Auction>(scenario);
            auction::unseal_bid(&mut auction, NODE, 1000, SALT, &mut ctx);
            test_scenario::return_shared(auction);
        };
        let seal_bid = make_seal_bid(NODE, SECOND_USER_ADDRESS, 1500, SALT);
        new_bid_util(scenario, seal_bid, 2000, SECOND_USER_ADDRESS);
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let ctx = tx_context::new(
                SECOND_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                120,
                0
            );
            let auction = test_scenario::take_shared<Auction>(scenario);
            auction::unseal_bid(&mut auction, NODE, 1500, SALT, &mut ctx);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
            let (start_at, highest_bid, second_highest_bid, winner) =
                auction::get_entry(&auction, NODE);
            assert!(option::extract(&mut start_at) == 111, 0);
            assert!(option::extract(&mut highest_bid) == 1000, 0);
            assert!(option::extract(&mut second_highest_bid) == 0, 0);
            assert!(option::extract(&mut winner) == FIRST_USER_ADDRESS, 0);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_unseal_bid_invalud_bid() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, SALT);
        start_auction_util(scenario, NODE);
        new_bid_util(scenario, seal_bid, 1000, FIRST_USER_ADDRESS);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                114,
                0
            );
            let auction = test_scenario::take_shared<Auction>(scenario);
            auction::unseal_bid(&mut auction, NODE, 1000, SALT, &mut ctx);
            test_scenario::return_shared(auction);
        };
        let seal_bid = make_seal_bid(NODE, SECOND_USER_ADDRESS, 500, SALT);
        new_bid_util(scenario, seal_bid, 2000, SECOND_USER_ADDRESS);
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let ctx = tx_context::new(
                SECOND_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                114,
                0
            );
            let auction = test_scenario::take_shared<Auction>(scenario);
            auction::unseal_bid(&mut auction, NODE, 500, SALT, &mut ctx);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
            let (start_at, highest_bid, second_highest_bid, winner) =
                auction::get_entry(&auction, NODE);
            assert!(option::extract(&mut start_at) == 111, 0);
            assert!(option::extract(&mut highest_bid) == 1000, 0);
            assert!(option::extract(&mut second_highest_bid) == 0, 0);
            assert!(option::extract(&mut winner) == FIRST_USER_ADDRESS, 0);
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
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                114,
                0
            );
            let auction = test_scenario::take_shared<Auction>(scenario);
            auction::unseal_bid(&mut auction, NODE, 1000, SALT, &mut ctx);
            test_scenario::return_shared(auction);
        };

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                114,
                0
            );
            let auction = test_scenario::take_shared<Auction>(scenario);
            auction::unseal_bid(&mut auction, NODE, 1000, SALT, &mut ctx);
            test_scenario::return_shared(auction);
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
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                114,
                0
            );
            let auction = test_scenario::take_shared<Auction>(scenario);
            auction::unseal_bid(&mut auction, NODE, 1200, SALT, &mut ctx);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = dynamic_field::EFieldDoesNotExist)]
    fun test_unseal_bid_abort_with_wrong_parameter2() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, SALT);
        start_auction_util(scenario, NODE);
        new_bid_util(scenario, seal_bid, 1000, FIRST_USER_ADDRESS);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                114,
                0
            );
            let auction = test_scenario::take_shared<Auction>(scenario);
            auction::unseal_bid(&mut auction, NODE, 1000, b"wrong_salt", &mut ctx);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = dynamic_field::EFieldDoesNotExist)]
    fun test_unseal_bid_abort_with_wrong_parameter3() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 1000, SALT);
        start_auction_util(scenario, NODE);
        new_bid_util(scenario, seal_bid, 1000, FIRST_USER_ADDRESS);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                114,
                0
            );
            let auction = test_scenario::take_shared<Auction>(scenario);
            auction::unseal_bid(&mut auction, b"wrong_node", 1000, SALT, &mut ctx);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_unseal_bid_changes_nothing_if_mask_bid_less_than_actual_value() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        let seal_bid = make_seal_bid(NODE, FIRST_USER_ADDRESS, 3000, SALT);
        start_auction_util(scenario, NODE);
        new_bid_util(scenario, seal_bid, 2000, FIRST_USER_ADDRESS);
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                114,
                0
            );
            let auction = test_scenario::take_shared<Auction>(scenario);
            auction::unseal_bid(&mut auction, NODE, 3000, SALT, &mut ctx);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(scenario);
            let (start_at, highest_bid, second_highest_bid, winner) =
                auction::get_entry(&auction, NODE);
            assert!(option::extract(&mut start_at) == 111, 0);
            assert!(option::extract(&mut highest_bid) == 0, 0);
            assert!(option::extract(&mut second_highest_bid) == 0, 0);
            assert!(option::extract(&mut winner) == @0x0, 0);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario_val);
    }
}
