#[test_only]
module suins::auction_tests {
    use suins::auction::{place_bid, claim, withdraw_bid, admin_withdraw, AuctionHouse, start_auction_and_place_bid, total_balance};
    use sui::test_scenario;
    use sui::test_scenario::{Scenario, ctx};
    use suins::suins::{SuiNS, AdminCap};
    use sui::coin;
    use sui::sui::SUI;
    use std::string::{String, utf8};
    use sui::clock::Clock;
    use suins::suins;
    use suins::auction::App as AuctionApp;
    use sui::coin::Coin;
    use suins::registration_nft::RegistrationNFT;
    use suins::registration_nft;
    use suins::domain;
    use suins::constants;
    use sui::clock;
    use suins::auction;

    const SUINS_ADDRESS: address = @0xA001;
    const FIRST_ADDRESS: address = @0xB001;
    const SECOND_ADDRESS: address = @0xB002;
    const THIRD_ADDRESS: address = @0xB003;
    const FIRST_DOMAIN_NAME: vector<u8> = b"test.sui";
    const SECOND_DOMAIN_NAME: vector<u8> = b"tesq.sui";
    const AUCTION_BIDDING_PERIOD_MS: u64 = 2 * 24 * 60 * 60 * 1000;

    public fun test_init(): Scenario {
        let scenario_val = test_scenario::begin(SUINS_ADDRESS);
        let scenario = &mut scenario_val;
        {
            let suins = suins::init_for_testing(ctx(scenario));
            suins::authorize_app_for_testing<AuctionApp>(&mut suins);
            suins::share_for_testing(suins);
            auction::init_for_testing(ctx(scenario));
            let clock = clock::create_for_testing(ctx(scenario));
            clock::share_for_testing(clock);
        };
        scenario_val
    }

    fun start_auction_and_place_bid_util(scenario: &mut Scenario, sender: address, domain_name: String, value: u64) {
        test_scenario::next_tx(scenario, sender);
        {
            let auction_house = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let payment = coin::mint_for_testing<SUI>(value, ctx(scenario));
            let clock = test_scenario::take_shared<Clock>(scenario);

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
        };
    }

    fun place_bid_util(scenario: &mut Scenario, sender: address, domain_name: String, value: u64) {
        test_scenario::next_tx(scenario, sender);
        {
            let auction_house = test_scenario::take_shared<AuctionHouse>(scenario);
            let payment = coin::mint_for_testing<SUI>(value, ctx(scenario));
            let clock = test_scenario::take_shared<Clock>(scenario);

            place_bid(&mut auction_house, domain_name, payment, &clock, ctx(scenario));

            test_scenario::return_shared(clock);
            test_scenario::return_shared(auction_house);
        };
    }

    fun claim_util(scenario: &mut Scenario, sender: address, domain_name: String, clock_tick: u64): RegistrationNFT {
        test_scenario::next_tx(scenario, sender);
        let nft;
        {
            let auction_house = test_scenario::take_shared<AuctionHouse>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);

            clock::increment_for_testing(&mut clock, clock_tick);
            nft = claim(&mut auction_house, domain_name, &clock, ctx(scenario));

            test_scenario::return_shared(clock);
            test_scenario::return_shared(auction_house);
        };
        nft
    }

    fun withdraw_util(scenario: &mut Scenario, sender: address, domain_name: String): Coin<SUI> {
        test_scenario::next_tx(scenario, sender);
        let returned_payment;
        {
            let auction_house = test_scenario::take_shared<AuctionHouse>(scenario);

            returned_payment = withdraw_bid(&mut auction_house, domain_name, ctx(scenario));

            test_scenario::return_shared(auction_house);
        };
        returned_payment
    }

    fun admin_withdraw_util(scenario: &mut Scenario, clock_tick: u64) {
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let auction_house = test_scenario::take_shared<AuctionHouse>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);

            clock::increment_for_testing(&mut clock, clock_tick);
            admin_withdraw(&admin_cap, &mut auction_house, &clock);

            test_scenario::return_shared(clock);
            test_scenario::return_shared(auction_house);
            test_scenario::return_to_sender(scenario, admin_cap);
        };
    }

    #[test]
    fun test_normal_auction_flow() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_auction_and_place_bid_util(scenario, FIRST_ADDRESS, utf8(FIRST_DOMAIN_NAME), 1200 * suins::constants::mist_per_sui());
        place_bid_util(scenario, SECOND_ADDRESS, utf8(FIRST_DOMAIN_NAME), 1210 * suins::constants::mist_per_sui());

        let nft = claim_util(scenario, SECOND_ADDRESS, utf8(FIRST_DOMAIN_NAME), AUCTION_BIDDING_PERIOD_MS + 1);
        assert!(registration_nft::domain(&nft) == domain::new(utf8(FIRST_DOMAIN_NAME)), 0);
        assert!(registration_nft::expiration_timestamp_ms(&nft) == constants::year_ms(), 0);
        let payment = withdraw_util(scenario, FIRST_ADDRESS, utf8(FIRST_DOMAIN_NAME));
        assert!(coin::value(&payment) == 1200 * suins::constants::mist_per_sui(), 0);
        {
            test_scenario::next_tx(scenario, SUINS_ADDRESS);
            let auction_house = test_scenario::take_shared<AuctionHouse>(scenario);
            assert!(total_balance(&auction_house) == 1210 * suins::constants::mist_per_sui(), 0);
            test_scenario::return_shared(auction_house);
        };

        coin::burn_for_testing(payment);
        registration_nft::burn_for_testing(nft);
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_admin_pulls_winning_bid() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_auction_and_place_bid_util(scenario, FIRST_ADDRESS, utf8(FIRST_DOMAIN_NAME), 1200 * suins::constants::mist_per_sui());
        place_bid_util(scenario, SECOND_ADDRESS, utf8(FIRST_DOMAIN_NAME), 1210 * suins::constants::mist_per_sui());
        place_bid_util(scenario, THIRD_ADDRESS, utf8(FIRST_DOMAIN_NAME), 1220 * suins::constants::mist_per_sui());

        admin_withdraw_util(scenario, AUCTION_BIDDING_PERIOD_MS + 1);
        {
            test_scenario::next_tx(scenario, SUINS_ADDRESS);
            let auction_house = test_scenario::take_shared<AuctionHouse>(scenario);
            assert!(total_balance(&auction_house) == 1220 * suins::constants::mist_per_sui(), 0);
            test_scenario::return_shared(auction_house);
        };
        let nft = claim_util(scenario, THIRD_ADDRESS, utf8(FIRST_DOMAIN_NAME), AUCTION_BIDDING_PERIOD_MS + 1);
        assert!(registration_nft::domain(&nft) == domain::new(utf8(FIRST_DOMAIN_NAME)), 0);
        assert!(registration_nft::expiration_timestamp_ms(&nft) == constants::year_ms(), 0);

        let payment = withdraw_util(scenario, SECOND_ADDRESS, utf8(FIRST_DOMAIN_NAME));
        assert!(coin::value(&payment) == 1210 * suins::constants::mist_per_sui(), 0);
        coin::burn_for_testing(payment);

        let payment = withdraw_util(scenario, FIRST_ADDRESS, utf8(FIRST_DOMAIN_NAME));
        assert!(coin::value(&payment) == 1200 * suins::constants::mist_per_sui(), 0);
        coin::burn_for_testing(payment);
        {
            test_scenario::next_tx(scenario, SUINS_ADDRESS);
            let auction_house = test_scenario::take_shared<AuctionHouse>(scenario);
            assert!(total_balance(&auction_house) == 1220 * suins::constants::mist_per_sui(), 0);
            test_scenario::return_shared(auction_house);
        };

        registration_nft::burn_for_testing(nft);
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_admin_pulls_two_winning_bids() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_auction_and_place_bid_util(scenario, FIRST_ADDRESS, utf8(FIRST_DOMAIN_NAME), 1200 * suins::constants::mist_per_sui());
        start_auction_and_place_bid_util(scenario, SECOND_ADDRESS, utf8(SECOND_DOMAIN_NAME), 1210 * suins::constants::mist_per_sui());

        admin_withdraw_util(scenario, AUCTION_BIDDING_PERIOD_MS + 1);
        {
            test_scenario::next_tx(scenario, SUINS_ADDRESS);
            let auction_house = test_scenario::take_shared<AuctionHouse>(scenario);
            assert!(total_balance(&auction_house) == 2410 * suins::constants::mist_per_sui(), 0);
            test_scenario::return_shared(auction_house);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_admin_pulls_two_winning_bids_too_early() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_auction_and_place_bid_util(scenario, FIRST_ADDRESS, utf8(FIRST_DOMAIN_NAME), 1200 * suins::constants::mist_per_sui());

        admin_withdraw_util(scenario, AUCTION_BIDDING_PERIOD_MS);
        {
            test_scenario::next_tx(scenario, SUINS_ADDRESS);
            let auction_house = test_scenario::take_shared<AuctionHouse>(scenario);
            assert!(total_balance(&auction_house) == 0 * suins::constants::mist_per_sui(), 0);
            test_scenario::return_shared(auction_house);
        };
        test_scenario::end(scenario_val);
    }
}
