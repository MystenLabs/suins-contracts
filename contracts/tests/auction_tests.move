#[test_only]
module suins::auction_tests {
    use sui::test_scenario::{Self, Scenario, ctx};
    use sui::sui::SUI;
    use sui::clock::{Self, Clock};
    use sui::coin::{Self, Coin};

    use suins::auction::{
    place_bid, claim, withdraw_bid, AuctionHouse, start_auction_and_place_bid, total_balance,
    admin_try_finalize_auction, admin_try_finalize_auctions, admin_withdraw_funds, admin_collect_fund
    };
    use suins::registration_nft::{Self, RegistrationNFT};
    use suins::config;
    use suins::domain;
    use suins::constants::{Self, mist_per_sui};
    use suins::suins::{Self, SuiNS, AdminCap};
    use suins::auction::{Self, App as AuctionApp};

    use std::option;
    use std::string::{String, utf8};

    const SUINS_ADDRESS: address = @0xA001;
    const FIRST_ADDRESS: address = @0xB001;
    const SECOND_ADDRESS: address = @0xB002;
    const THIRD_ADDRESS: address = @0xB003;
    const FIRST_DOMAIN_NAME: vector<u8> = b"tes-t2.sui";
    const SECOND_DOMAIN_NAME: vector<u8> = b"tesq.sui";
    const AUCTION_BIDDING_PERIOD_MS: u64 = 2 * 24 * 60 * 60 * 1000;
    const AUCTION_MIN_QUIET_PERIOD_MS: u64 = 10 * 60 * 1000; // 10 minutes of quiet time

    public fun test_init(): Scenario {
        let scenario_val = test_scenario::begin(SUINS_ADDRESS);
        let scenario = &mut scenario_val;
        let suins = suins::init_for_testing(ctx(scenario));
        suins::authorize_app_for_testing<AuctionApp>(&mut suins);
        suins::share_for_testing(suins);
        auction::init_for_testing(ctx(scenario));
        let clock = clock::create_for_testing(ctx(scenario));
        clock::share_for_testing(clock);
        scenario_val
    }

    public fun start_auction_and_place_bid_util(
        scenario: &mut Scenario,
        sender: address,
        domain_name: String,
        amount: u64
    ) {
        test_scenario::next_tx(scenario, sender);
        let auction_house = test_scenario::take_shared<AuctionHouse>(scenario);
        let suins = test_scenario::take_shared<SuiNS>(scenario);
        let payment = coin::mint_for_testing<SUI>(amount, ctx(scenario));
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
    }

    fun place_bid_util(scenario: &mut Scenario, sender: address, domain_name: String, value: u64, clock_tick: u64) {
        test_scenario::next_tx(scenario, sender);
        let auction_house = test_scenario::take_shared<AuctionHouse>(scenario);
        let payment = coin::mint_for_testing<SUI>(value, ctx(scenario));
        let clock = test_scenario::take_shared<Clock>(scenario);

        clock::increment_for_testing(&mut clock, clock_tick);
        place_bid(&mut auction_house, domain_name, payment, &clock, ctx(scenario));

        test_scenario::return_shared(clock);
        test_scenario::return_shared(auction_house);
    }

    public fun claim_util(
        scenario: &mut Scenario,
        sender: address,
        domain_name: String,
        clock_tick: u64
    ): RegistrationNFT {
        test_scenario::next_tx(scenario, sender);
        let auction_house = test_scenario::take_shared<AuctionHouse>(scenario);
        let clock = test_scenario::take_shared<Clock>(scenario);

        clock::increment_for_testing(&mut clock, clock_tick);
        let nft = claim(&mut auction_house, domain_name, &clock, ctx(scenario));

        test_scenario::return_shared(clock);
        test_scenario::return_shared(auction_house);
        nft
    }

    fun withdraw_util(scenario: &mut Scenario, sender: address, domain_name: String): Coin<SUI> {
        test_scenario::next_tx(scenario, sender);
        let auction_house = test_scenario::take_shared<AuctionHouse>(scenario);

        let returned_payment = withdraw_bid(&mut auction_house, domain_name, ctx(scenario));

        test_scenario::return_shared(auction_house);
        returned_payment
    }

    fun admin_collect_fund_util(scenario: &mut Scenario, domain_name: String, clock_tick: u64) {
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
        let auction_house = test_scenario::take_shared<AuctionHouse>(scenario);
        let clock = test_scenario::take_shared<Clock>(scenario);

        clock::increment_for_testing(&mut clock, clock_tick);
        admin_collect_fund(&admin_cap, &mut auction_house, domain_name, &clock, ctx(scenario));

        test_scenario::return_shared(clock);
        test_scenario::return_shared(auction_house);
        test_scenario::return_to_sender(scenario, admin_cap);
    }

    fun admin_try_finalize_auction_util(
        scenario: &mut Scenario,
        domain: String,
        operation_limit: u64,
        clock_tick: u64
    ) {
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
        let auction_house = test_scenario::take_shared<AuctionHouse>(scenario);
        let clock = test_scenario::take_shared<Clock>(scenario);

        clock::increment_for_testing(&mut clock, clock_tick);
        admin_try_finalize_auction(&admin_cap, &mut auction_house, domain, operation_limit, &clock);

        test_scenario::return_shared(clock);
        test_scenario::return_shared(auction_house);
        test_scenario::return_to_sender(scenario, admin_cap);
    }

    fun admin_try_finalize_auctions_util(scenario: &mut Scenario, operation_limit: u64, clock_tick: u64) {
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
        let auction_house = test_scenario::take_shared<AuctionHouse>(scenario);
        let clock = test_scenario::take_shared<Clock>(scenario);

        clock::increment_for_testing(&mut clock, clock_tick);
        admin_try_finalize_auctions(&admin_cap, &mut auction_house, operation_limit, &clock);

        test_scenario::return_shared(clock);
        test_scenario::return_shared(auction_house);
        test_scenario::return_to_sender(scenario, admin_cap);
    }

    fun admin_withdraw_funds_util(scenario: &mut Scenario): Coin<SUI> {
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
        let auction_house = test_scenario::take_shared<AuctionHouse>(scenario);

        let funds = admin_withdraw_funds(&admin_cap, &mut auction_house, ctx(scenario));

        test_scenario::return_shared(auction_house);
        test_scenario::return_to_sender(scenario, admin_cap);
        funds
    }

    fun deauthorize_app_util(scenario: &mut Scenario) {
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
        let suins = test_scenario::take_shared<SuiNS>(scenario);

        suins::deauthorize_app<AuctionApp>(&admin_cap, &mut suins);

        test_scenario::return_shared(suins);
        test_scenario::return_to_sender(scenario, admin_cap);
    }

    fun assert_balance(scenario: &mut Scenario, amount: u64) {
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        let auction_house = test_scenario::take_shared<AuctionHouse>(scenario);
        assert!(total_balance(&auction_house) == amount, 0);
        test_scenario::return_shared(auction_house);
    }

    fun assert_auction(
        scenario: &mut Scenario,
        domain_name: String,
        expected_start_ms: u64,
        expected_end_ms: u64,
        expected_winner: address,
        expected_highest_amount: u64
    ) {
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        let auction_house = test_scenario::take_shared<AuctionHouse>(scenario);
        let (start_ms, end_ms, winner, highest_amount) = auction::get_auction_metadata(&auction_house, domain_name);
        assert!(option::extract(&mut start_ms) == expected_start_ms, 0);
        assert!(option::extract(&mut end_ms) == expected_end_ms, 0);
        assert!(option::extract(&mut winner) == expected_winner, 0);
        assert!(option::extract(&mut highest_amount) == expected_highest_amount, 0);
        test_scenario::return_shared(auction_house);
    }

    public fun normal_auction_flow(scenario: &mut Scenario) {
        start_auction_and_place_bid_util(
            scenario,
            FIRST_ADDRESS,
            utf8(FIRST_DOMAIN_NAME),
            1200 * mist_per_sui()
        );
        assert_auction(
            scenario,
            utf8(FIRST_DOMAIN_NAME),
            0,
            AUCTION_BIDDING_PERIOD_MS,
            FIRST_ADDRESS,
            1200 * mist_per_sui()
        );
        place_bid_util(scenario, SECOND_ADDRESS, utf8(FIRST_DOMAIN_NAME), 1210 * mist_per_sui(), 10);
        assert_auction(
            scenario,
            utf8(FIRST_DOMAIN_NAME),
            0,
            AUCTION_BIDDING_PERIOD_MS,
            SECOND_ADDRESS,
            1210 * mist_per_sui()
        );

        let nft = claim_util(scenario, SECOND_ADDRESS, utf8(FIRST_DOMAIN_NAME), AUCTION_BIDDING_PERIOD_MS + 1);
        assert!(registration_nft::domain(&nft) == domain::new(utf8(FIRST_DOMAIN_NAME)), 0);
        assert!(registration_nft::expiration_timestamp_ms(&nft) == constants::year_ms(), 0);
        registration_nft::burn_for_testing(nft);

        let payment = withdraw_util(scenario, FIRST_ADDRESS, utf8(FIRST_DOMAIN_NAME));
        assert!(coin::value(&payment) == 1200 * mist_per_sui(), 0);
        coin::burn_for_testing(payment);
        assert_balance(scenario, 1210 * mist_per_sui());

        let funds = admin_withdraw_funds_util(scenario);
        assert!(coin::value(&funds) == 1210 * mist_per_sui(), 0);
        assert_balance(scenario, 0);
        coin::burn_for_testing(funds);
    }

    #[test]
    fun test_normal_auction_flow() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        normal_auction_flow(scenario);
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = option::EOPTION_NOT_SET)]
    fun test_claim_aborts_if_winner_claims_twice() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_auction_and_place_bid_util(
            scenario,
            FIRST_ADDRESS,
            utf8(FIRST_DOMAIN_NAME),
            1200 * mist_per_sui()
        );
        place_bid_util(scenario, SECOND_ADDRESS, utf8(FIRST_DOMAIN_NAME), 1210 * mist_per_sui(), 0);

        let nft = claim_util(scenario, SECOND_ADDRESS, utf8(FIRST_DOMAIN_NAME), AUCTION_BIDDING_PERIOD_MS + 1);
        registration_nft::burn_for_testing(nft);
        let nft = claim_util(scenario, SECOND_ADDRESS, utf8(FIRST_DOMAIN_NAME), AUCTION_BIDDING_PERIOD_MS + 1);
        registration_nft::burn_for_testing(nft);
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::ENotWinner)]
    fun test_winner_cannot_withdraw_bid() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_auction_and_place_bid_util(
            scenario,
            FIRST_ADDRESS,
            utf8(FIRST_DOMAIN_NAME),
            1200 * mist_per_sui()
        );
        place_bid_util(scenario, SECOND_ADDRESS, utf8(FIRST_DOMAIN_NAME), 1210 * mist_per_sui(), 0);

        let payment = withdraw_util(scenario, SECOND_ADDRESS, utf8(FIRST_DOMAIN_NAME));
        coin::burn_for_testing(payment);

        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EWinnerCannotPlaceBid)]
    fun test_winner_cannot_place_bid() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_auction_and_place_bid_util(
            scenario,
            FIRST_ADDRESS,
            utf8(FIRST_DOMAIN_NAME),
            1200 * mist_per_sui()
        );
        place_bid_util(scenario, SECOND_ADDRESS, utf8(FIRST_DOMAIN_NAME), 1210 * mist_per_sui(), 0);
        place_bid_util(scenario, SECOND_ADDRESS, utf8(FIRST_DOMAIN_NAME), 1210 * mist_per_sui(), 0);

        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EBidAmountTooLow)]
    fun test_place_bid_aborts_if_value_is_too_low() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_auction_and_place_bid_util(
            scenario,
            FIRST_ADDRESS,
            utf8(FIRST_DOMAIN_NAME),
            1210 * mist_per_sui()
        );
        place_bid_util(scenario, SECOND_ADDRESS, utf8(FIRST_DOMAIN_NAME), 1200 * mist_per_sui(), 0);

        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::ENotWinner)]
    fun test_non_winner_cannot_claim() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_auction_and_place_bid_util(
            scenario,
            FIRST_ADDRESS,
            utf8(FIRST_DOMAIN_NAME),
            1200 * mist_per_sui()
        );
        place_bid_util(scenario, SECOND_ADDRESS, utf8(FIRST_DOMAIN_NAME), 1210 * mist_per_sui(), 0);

        let nft = claim_util(scenario, FIRST_ADDRESS, utf8(FIRST_DOMAIN_NAME), AUCTION_BIDDING_PERIOD_MS + 1);
        registration_nft::burn_for_testing(nft);
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_admin_try_finalize_auction() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_auction_and_place_bid_util(
            scenario,
            FIRST_ADDRESS,
            utf8(FIRST_DOMAIN_NAME),
            1200 * mist_per_sui()
        );
        place_bid_util(scenario, SECOND_ADDRESS, utf8(FIRST_DOMAIN_NAME), 1210 * mist_per_sui(), 0);
        place_bid_util(scenario, THIRD_ADDRESS, utf8(FIRST_DOMAIN_NAME), 1220 * mist_per_sui(), 1);

        admin_try_finalize_auction_util(scenario, utf8(FIRST_DOMAIN_NAME), 3, AUCTION_BIDDING_PERIOD_MS + 1);
        assert_balance(scenario, 1220 * mist_per_sui());

        let nft = test_scenario::take_from_address<RegistrationNFT>(scenario, THIRD_ADDRESS);
        assert!(registration_nft::domain(&nft) == domain::new(utf8(FIRST_DOMAIN_NAME)), 0);
        assert!(registration_nft::expiration_timestamp_ms(&nft) == constants::year_ms(), 0);
        registration_nft::burn_for_testing(nft);

        let payment = test_scenario::take_from_address<Coin<SUI>>(scenario, SECOND_ADDRESS);
        assert!(coin::value(&payment) == 1210 * mist_per_sui(), 0);
        coin::burn_for_testing(payment);

        let payment = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_ADDRESS);
        assert!(coin::value(&payment) == 1200 * mist_per_sui(), 0);
        coin::burn_for_testing(payment);
        assert_balance(scenario, 1220 * mist_per_sui());

        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_admin_try_finalize_auction_with_operation_limit_less_than_no_bids() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_auction_and_place_bid_util(
            scenario,
            FIRST_ADDRESS,
            utf8(FIRST_DOMAIN_NAME),
            1200 * mist_per_sui()
        );
        place_bid_util(scenario, SECOND_ADDRESS, utf8(FIRST_DOMAIN_NAME), 1210 * mist_per_sui(), 0);
        place_bid_util(scenario, THIRD_ADDRESS, utf8(FIRST_DOMAIN_NAME), 1220 * mist_per_sui(), 1);

        admin_try_finalize_auction_util(scenario, utf8(FIRST_DOMAIN_NAME), 2, AUCTION_BIDDING_PERIOD_MS + 1);
        assert_balance(scenario, 0);
        assert!(!test_scenario::has_most_recent_for_address<RegistrationNFT>(THIRD_ADDRESS), 0);

        let payment = test_scenario::take_from_address<Coin<SUI>>(scenario, SECOND_ADDRESS);
        assert!(coin::value(&payment) == 1210 * mist_per_sui(), 0);
        coin::burn_for_testing(payment);

        let payment = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_ADDRESS);
        assert!(coin::value(&payment) == 1200 * mist_per_sui(), 0);
        coin::burn_for_testing(payment);
        assert_balance(scenario, 0);

        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_admin_try_finalize_auction_2_auctions() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_auction_and_place_bid_util(
            scenario,
            FIRST_ADDRESS,
            utf8(FIRST_DOMAIN_NAME),
            1200 * mist_per_sui()
        );
        start_auction_and_place_bid_util(
            scenario,
            SECOND_ADDRESS,
            utf8(SECOND_DOMAIN_NAME),
            1210 * mist_per_sui()
        );

        admin_try_finalize_auctions_util(scenario, 4, AUCTION_BIDDING_PERIOD_MS + 1);
        assert_balance(scenario, 2410 * mist_per_sui());

        let nft = test_scenario::take_from_address<RegistrationNFT>(scenario, SECOND_ADDRESS);
        assert!(registration_nft::domain(&nft) == domain::new(utf8(SECOND_DOMAIN_NAME)), 0);
        assert!(registration_nft::expiration_timestamp_ms(&nft) == constants::year_ms(), 0);
        registration_nft::burn_for_testing(nft);

        let nft = test_scenario::take_from_address<RegistrationNFT>(scenario, FIRST_ADDRESS);
        assert!(registration_nft::domain(&nft) == domain::new(utf8(FIRST_DOMAIN_NAME)), 0);
        assert!(registration_nft::expiration_timestamp_ms(&nft) == constants::year_ms(), 0);
        registration_nft::burn_for_testing(nft);

        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EAuctionNotEndedYet)]
    fun test_admin_try_finalize_auction_too_early() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_auction_and_place_bid_util(
            scenario,
            FIRST_ADDRESS,
            utf8(FIRST_DOMAIN_NAME),
            1200 * mist_per_sui()
        );

        admin_try_finalize_auction_util(scenario, utf8(FIRST_DOMAIN_NAME), 1, 0);
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_admin_try_finalize_auctions_too_early() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_auction_and_place_bid_util(
            scenario,
            FIRST_ADDRESS,
            utf8(FIRST_DOMAIN_NAME),
            1200 * mist_per_sui()
        );
        admin_try_finalize_auctions_util(scenario, 3, 0);
        assert_balance(scenario, 0);

        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EAuctionEnded)]
    fun test_place_bid_aborts_if_too_late() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_auction_and_place_bid_util(
            scenario,
            FIRST_ADDRESS,
            utf8(FIRST_DOMAIN_NAME),
            1200 * mist_per_sui()
        );
        place_bid_util(
            scenario,
            SECOND_ADDRESS,
            utf8(FIRST_DOMAIN_NAME),
            1210 * mist_per_sui(),
            AUCTION_BIDDING_PERIOD_MS + 1
        );
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::ENoProfits)]
    fun test_admin_withdraw_funds_aborts_if_no_profits() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        let funds = admin_withdraw_funds_util(scenario);
        coin::burn_for_testing(funds);
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = config::EInvalidTld)]
    fun test_start_auction_aborts_with_wrong_tld() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_auction_and_place_bid_util(
            scenario,
            FIRST_ADDRESS,
            utf8(b"test.move"),
            1200 * mist_per_sui()
        );
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = domain::EInvalidDomain)]
    fun test_start_auction_aborts_if_domain_name_too_short() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_auction_and_place_bid_util(
            scenario,
            FIRST_ADDRESS,
            utf8(b"tt.sui"),
            1200 * mist_per_sui()
        );
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = domain::EInvalidDomain)]
    fun test_start_auction_aborts_if_domain_name_too_long() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_auction_and_place_bid_util(
            scenario,
            FIRST_ADDRESS,
            utf8(b"g2bst97onsyl8gwo5brfglcb-obh8i7p01lz5ccscd6zxx4qn7wnv8b1in5sectj8s.sui"),
            1200 * mist_per_sui()
        );
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = domain::EInvalidDomain)]
    fun test_start_auction_aborts_if_domain_name_starts_with_dash() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_auction_and_place_bid_util(
            scenario,
            FIRST_ADDRESS,
            utf8(b"-test.sui"),
            1200 * mist_per_sui()
        );
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = domain::EInvalidDomain)]
    fun test_start_auction_aborts_if_domain_name_ends_with_dash() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_auction_and_place_bid_util(
            scenario,
            FIRST_ADDRESS,
            utf8(b"test-.sui"),
            1200 * mist_per_sui()
        );
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = domain::EInvalidDomain)]
    fun test_start_auction_aborts_if_domain_name_contains_uppercase_characters() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_auction_and_place_bid_util(
            scenario,
            FIRST_ADDRESS,
            utf8(b"ttABC.sui"),
            1200 * mist_per_sui()
        );
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EAuctionNotStarted)]
    fun test_place_bid_aborts_if_auction_not_started() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        place_bid_util(scenario, SECOND_ADDRESS, utf8(FIRST_DOMAIN_NAME), 1210 * mist_per_sui(), 0);
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EInvalidBidValue)]
    fun test_start_auction_aborts_if_not_enough_fee() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_auction_and_place_bid_util(
            scenario,
            FIRST_ADDRESS,
            utf8(b"test.sui"),
            10 * mist_per_sui()
        );
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_admin_collect_fund() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_auction_and_place_bid_util(
            scenario,
            FIRST_ADDRESS,
            utf8(FIRST_DOMAIN_NAME),
            1200 * mist_per_sui()
        );
        place_bid_util(
            scenario,
            SECOND_ADDRESS,
            utf8(FIRST_DOMAIN_NAME),
            1210 * mist_per_sui(),
            AUCTION_BIDDING_PERIOD_MS
        );
        assert_balance(scenario, 0);
        admin_collect_fund_util(scenario, utf8(FIRST_DOMAIN_NAME), AUCTION_BIDDING_PERIOD_MS + 1);
        assert_balance(scenario, 1210 * mist_per_sui());

        let nft = claim_util(scenario, SECOND_ADDRESS, utf8(FIRST_DOMAIN_NAME), AUCTION_BIDDING_PERIOD_MS + 1);
        assert!(registration_nft::domain(&nft) == domain::new(utf8(FIRST_DOMAIN_NAME)), 0);
        assert!(registration_nft::expiration_timestamp_ms(&nft) == constants::year_ms(), 0);
        registration_nft::burn_for_testing(nft);

        let payment = withdraw_util(scenario, FIRST_ADDRESS, utf8(FIRST_DOMAIN_NAME));
        assert!(coin::value(&payment) == 1200 * mist_per_sui(), 0);
        coin::burn_for_testing(payment);
        assert_balance(scenario, 1210 * mist_per_sui());

        let funds = admin_withdraw_funds_util(scenario);
        assert!(coin::value(&funds) == 1210 * mist_per_sui(), 0);
        assert_balance(scenario, 0);
        coin::burn_for_testing(funds);

        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EAuctionNotEndedYet)]
    fun test_admin_collect_fund_aborts_if_too_early() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_auction_and_place_bid_util(
            scenario,
            FIRST_ADDRESS,
            utf8(FIRST_DOMAIN_NAME),
            1200 * mist_per_sui()
        );
        admin_collect_fund_util(scenario, utf8(FIRST_DOMAIN_NAME), 0);
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = suins::suins::EAppNotAuthorized)]
    fun test_start_auction_and_place_bid_aborts_if_auction_is_deauthorized() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        deauthorize_app_util(scenario);
        start_auction_and_place_bid_util(
            scenario,
            FIRST_ADDRESS,
            utf8(FIRST_DOMAIN_NAME),
            1200 * mist_per_sui()
        );
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_place_bid_and_claim_and_withdraw_works_even_if_auction_is_deauthorized() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_auction_and_place_bid_util(
            scenario,
            FIRST_ADDRESS,
            utf8(FIRST_DOMAIN_NAME),
            1200 * mist_per_sui()
        );
        deauthorize_app_util(scenario);
        place_bid_util(scenario, SECOND_ADDRESS, utf8(FIRST_DOMAIN_NAME), 1210 * mist_per_sui(), 10);
        assert_auction(
            scenario,
            utf8(FIRST_DOMAIN_NAME),
            0,
            AUCTION_BIDDING_PERIOD_MS,
            SECOND_ADDRESS,
            1210 * mist_per_sui()
        );

        let nft = claim_util(scenario, SECOND_ADDRESS, utf8(FIRST_DOMAIN_NAME), AUCTION_BIDDING_PERIOD_MS + 1);
        assert!(registration_nft::domain(&nft) == domain::new(utf8(FIRST_DOMAIN_NAME)), 0);
        assert!(registration_nft::expiration_timestamp_ms(&nft) == constants::year_ms(), 0);
        registration_nft::burn_for_testing(nft);

        let payment = withdraw_util(scenario, FIRST_ADDRESS, utf8(FIRST_DOMAIN_NAME));
        assert!(coin::value(&payment) == 1200 * mist_per_sui(), 0);
        coin::burn_for_testing(payment);
        assert_balance(scenario, 1210 * mist_per_sui());

        let funds = admin_withdraw_funds_util(scenario);
        assert!(coin::value(&funds) == 1210 * mist_per_sui(), 0);
        assert_balance(scenario, 0);
        coin::burn_for_testing(funds);

        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_admin_try_finalize_auction_works_even_if_auction_is_deauthorized() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_auction_and_place_bid_util(
            scenario,
            FIRST_ADDRESS,
            utf8(FIRST_DOMAIN_NAME),
            1200 * mist_per_sui()
        );
        place_bid_util(scenario, SECOND_ADDRESS, utf8(FIRST_DOMAIN_NAME), 1210 * mist_per_sui(), 0);
        place_bid_util(scenario, THIRD_ADDRESS, utf8(FIRST_DOMAIN_NAME), 1220 * mist_per_sui(), 1);

        deauthorize_app_util(scenario);
        admin_try_finalize_auction_util(scenario, utf8(FIRST_DOMAIN_NAME), 3, AUCTION_BIDDING_PERIOD_MS + 1);
        assert_balance(scenario, 1220 * mist_per_sui());

        let nft = test_scenario::take_from_address<RegistrationNFT>(scenario, THIRD_ADDRESS);
        assert!(registration_nft::domain(&nft) == domain::new(utf8(FIRST_DOMAIN_NAME)), 0);
        assert!(registration_nft::expiration_timestamp_ms(&nft) == constants::year_ms(), 0);
        registration_nft::burn_for_testing(nft);

        let payment = test_scenario::take_from_address<Coin<SUI>>(scenario, SECOND_ADDRESS);
        assert!(coin::value(&payment) == 1210 * mist_per_sui(), 0);
        coin::burn_for_testing(payment);

        let payment = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_ADDRESS);
        assert!(coin::value(&payment) == 1200 * mist_per_sui(), 0);
        coin::burn_for_testing(payment);
        assert_balance(scenario, 1220 * mist_per_sui());

        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_admin_collect_fund_even_if_auction_is_deauthorized() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        start_auction_and_place_bid_util(
            scenario,
            FIRST_ADDRESS,
            utf8(FIRST_DOMAIN_NAME),
            1200 * mist_per_sui()
        );
        place_bid_util(
            scenario,
            SECOND_ADDRESS,
            utf8(FIRST_DOMAIN_NAME),
            1210 * mist_per_sui(),
            AUCTION_BIDDING_PERIOD_MS
        );
        assert_balance(scenario, 0);
        deauthorize_app_util(scenario);
        admin_collect_fund_util(scenario, utf8(FIRST_DOMAIN_NAME), AUCTION_BIDDING_PERIOD_MS + 1);
        assert_balance(scenario, 1210 * mist_per_sui());

        let nft = claim_util(scenario, SECOND_ADDRESS, utf8(FIRST_DOMAIN_NAME), AUCTION_BIDDING_PERIOD_MS + 1);
        assert!(registration_nft::domain(&nft) == domain::new(utf8(FIRST_DOMAIN_NAME)), 0);
        assert!(registration_nft::expiration_timestamp_ms(&nft) == constants::year_ms(), 0);
        registration_nft::burn_for_testing(nft);

        let payment = withdraw_util(scenario, FIRST_ADDRESS, utf8(FIRST_DOMAIN_NAME));
        assert!(coin::value(&payment) == 1200 * mist_per_sui(), 0);
        coin::burn_for_testing(payment);
        assert_balance(scenario, 1210 * mist_per_sui());

        let funds = admin_withdraw_funds_util(scenario);
        assert!(coin::value(&funds) == 1210 * mist_per_sui(), 0);
        assert_balance(scenario, 0);
        coin::burn_for_testing(funds);

        test_scenario::end(scenario_val);
    }
}
