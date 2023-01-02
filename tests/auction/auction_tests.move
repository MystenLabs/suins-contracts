#[test_only]
module suins::auction_tests {

    use sui::test_scenario::{Scenario, ctx};
    use sui::test_scenario;
    use suins::auction;
    use suins::auction::Auction;
    use std::option;
    use sui::coin;
    use sui::sui::SUI;

    const SUINS_ADDRESS: address = @0xA001;
    const FIRST_USER_ADDRESS: address = @0xB001;
    const SECOND_USER_ADDRESS: address = @0xB002;
    const SEAL_BID: vector<u8> = b"vUAgEwNmPr";

    fun test_init(): Scenario {
        let scenario = test_scenario::begin(SUINS_ADDRESS);
        {
            let ctx = ctx(&mut scenario);
            auction::test_init(ctx);
        };
        scenario
    }

    #[test]
    fun test_new_bid() {
        let scenario = test_init();

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(1000, ctx(&mut scenario));
            let (owner, amount) = auction::get_bid(&auction, SEAL_BID);
            assert!(option::is_none(&owner), 0);
            assert!(option::is_none(&amount), 0);

            auction::new_bid(&mut auction, SEAL_BID, 100, &mut coin, ctx(&mut scenario));
            let (owner, amount) = auction::get_bid(&auction, SEAL_BID);
            assert!(option::extract(&mut owner) == FIRST_USER_ADDRESS, 0);
            assert!(option::extract(&mut amount) == 100, 0);
            assert!(coin::value(&coin) == 900, 0);

            auction::new_bid(&mut auction, SEAL_BID, 20, &mut coin, ctx(&mut scenario));
            let (owner, amount) = auction::get_bid(&auction, SEAL_BID);
            assert!(option::extract(&mut owner) == FIRST_USER_ADDRESS, 0);
            assert!(option::extract(&mut amount) == 120, 0);
            assert!(coin::value(&coin) == 880, 0);

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = auction::EUnauthorized)]
    fun test_new_bid_abort_if_unauthorized() {
        let scenario = test_init();

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(1000, ctx(&mut scenario));
            auction::new_bid(&mut auction, SEAL_BID, 100, &mut coin, ctx(&mut scenario));
            coin::destroy_for_testing(coin);
            test_scenario::return_shared(auction);
        };

        test_scenario::next_tx(&mut scenario, SECOND_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(1000, ctx(&mut scenario));
            auction::new_bid(&mut auction, SEAL_BID, 100, &mut coin, ctx(&mut scenario));
            coin::destroy_for_testing(coin);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario);
    }
}
