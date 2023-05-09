#[test_only]
module suins::register_tests {

    use std::string::{utf8, String};

    use sui::test_scenario::{Self, Scenario, ctx};
    use sui::clock::{Self, Clock};
    use sui::coin;
    use sui::sui::SUI;

    use suins::register::{Self, App as RegisterApp, register};
    use suins::constants::{mist_per_sui, grace_period_ms, year_ms};
    use suins::suins::{Self, SuiNS, total_balance, AdminCap};
    use suins::registration_nft::RegistrationNFT;
    use suins::registration_nft;
    use suins::domain;
    use suins::controller;
    use suins::registry ;
    use suins::auction_tests;
    use suins::auction::{Self, App as AuctionApp};

    const SUINS_ADDRESS: address = @0xA001;
    const AUCTIONED_DOMAIN_NAME: vector<u8> = b"tes-t2.sui";
    const DOMAIN_NAME: vector<u8> = b"abc.sui";

    public fun test_init(): Scenario {
        let scenario_val = test_scenario::begin(SUINS_ADDRESS);
        let scenario = &mut scenario_val;
        {
            let suins = suins::init_for_testing(ctx(scenario));
            suins::authorize_app_for_testing<RegisterApp>(&mut suins);
            suins::authorize_app_for_testing<AuctionApp>(&mut suins);
            suins::share_for_testing(suins);
            let clock = clock::create_for_testing(ctx(scenario));
            clock::share_for_testing(clock);
        };
        scenario_val
    }

    public fun register_util(
        scenario: &mut Scenario,
        domain_name: String,
        no_years: u8,
        amount: u64,
        clock_tick: u64
    ): RegistrationNFT {
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        let suins = test_scenario::take_shared<SuiNS>(scenario);
        let payment = coin::mint_for_testing<SUI>(amount, ctx(scenario));
        let clock = test_scenario::take_shared<Clock>(scenario);

        clock::increment_for_testing(&mut clock, clock_tick);
        let nft = register(&mut suins, domain_name, no_years, payment, &clock, ctx(scenario));

        test_scenario::return_shared(clock);
        test_scenario::return_shared(suins);

        nft
    }

    fun deauthorize_app_util(scenario: &mut Scenario) {
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
        let suins = test_scenario::take_shared<SuiNS>(scenario);

        suins::deauthorize_app<RegisterApp>(&admin_cap, &mut suins);

        test_scenario::return_shared(suins);
        test_scenario::return_to_sender(scenario, admin_cap);
    }

    public fun assert_balance(scenario: &mut Scenario, amount: u64) {
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        let auction_house = test_scenario::take_shared<SuiNS>(scenario);
        assert!(total_balance(&auction_house) == amount, 0);
        test_scenario::return_shared(auction_house);
    }

    #[test]
    fun test_register() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;

        let nft = register_util(scenario, utf8(DOMAIN_NAME), 1, 1200 * mist_per_sui(), 10);
        assert_balance(scenario, 1200 * mist_per_sui());
        assert!(registration_nft::domain(&nft) == domain::new(utf8(DOMAIN_NAME)), 0);
        assert!(registration_nft::expiration_timestamp_ms(&nft) == year_ms() + 10, 0);
        registration_nft::burn_for_testing(nft);

        let nft = register_util(scenario, utf8(b"abcd.sui"), 2, 400 * mist_per_sui(), 20);
        assert_balance(scenario, 1600 * mist_per_sui());
        assert!(registration_nft::domain(&nft) == domain::new(utf8(b"abcd.sui")), 0);
        assert!(registration_nft::expiration_timestamp_ms(&nft) == 2 * year_ms() + 30, 0);
        registration_nft::burn_for_testing(nft);

        let nft = register_util(scenario, utf8(b"abce-f12.sui"), 3, 150 * mist_per_sui(), 30);
        assert_balance(scenario, 1750 * mist_per_sui());
        assert!(registration_nft::domain(&nft) == domain::new(utf8(b"abce-f12.sui")), 0);
        assert!(registration_nft::expiration_timestamp_ms(&nft) == 3 * year_ms() + 60, 0);
        registration_nft::burn_for_testing(nft);

        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = controller::EInvalidTld)]
    fun test_register_if_not_sui_tld() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;

        let nft = register_util(scenario, utf8(b"abc.move"), 1, 1200 * mist_per_sui(), 10);
        registration_nft::burn_for_testing(nft);

        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = register::EIncorrectAmount)]
    fun test_register_if_incorrect_amount() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;

        let nft = register_util(scenario, utf8(DOMAIN_NAME), 1, 1210 * mist_per_sui(), 10);
        registration_nft::burn_for_testing(nft);

        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = register::EIncorrectAmount)]
    fun test_register_if_incorrect_amount_2() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;

        let nft = register_util(scenario, utf8(DOMAIN_NAME), 1, 90 * mist_per_sui(), 10);
        registration_nft::burn_for_testing(nft);

        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = register::EInvalidYearsArgument)]
    fun test_register_if_no_years_more_than_5_years() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;

        let nft = register_util(scenario, utf8(DOMAIN_NAME), 6, 6 * 1200 * mist_per_sui(), 10);
        registration_nft::burn_for_testing(nft);

        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = register::EInvalidYearsArgument)]
    fun test_register_if_no_years_is_zero() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;

        let nft = register_util(scenario, utf8(DOMAIN_NAME), 0, 1200 * mist_per_sui(), 10);
        registration_nft::burn_for_testing(nft);

        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_register_if_expired() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;

        let nft = register_util(scenario, utf8(DOMAIN_NAME), 1, 1200 * mist_per_sui(), 10);
        assert_balance(scenario, 1200 * mist_per_sui());
        assert!(registration_nft::domain(&nft) == domain::new(utf8(DOMAIN_NAME)), 0);
        assert!(registration_nft::expiration_timestamp_ms(&nft) == year_ms() + 10, 0);
        registration_nft::burn_for_testing(nft);

        let nft = register_util(
            scenario,
            utf8(DOMAIN_NAME),
            1,
            1200 * mist_per_sui(),
            year_ms() + grace_period_ms() + 20,
        );
        assert_balance(scenario, 2400 * mist_per_sui());
        assert!(registration_nft::domain(&nft) == domain::new(utf8(DOMAIN_NAME)), 0);
        assert!(
            registration_nft::expiration_timestamp_ms(&nft) == 2 * year_ms() + grace_period_ms() + 30,
            0
        );
        registration_nft::burn_for_testing(nft);

        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = registry::ERecordNotExpired)]
    fun test_register_if_not_expired() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;

        let nft = register_util(scenario, utf8(DOMAIN_NAME), 1, 1200 * mist_per_sui(), 10);
        assert_balance(scenario, 1200 * mist_per_sui());
        assert!(registration_nft::domain(&nft) == domain::new(utf8(DOMAIN_NAME)), 0);
        assert!(registration_nft::expiration_timestamp_ms(&nft) == year_ms() + 10, 0);
        registration_nft::burn_for_testing(nft);

        let nft = register_util(scenario, utf8(DOMAIN_NAME), 1, 1200 * mist_per_sui(), 20);
        registration_nft::burn_for_testing(nft);

        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = domain::EInvalidDomain)]
    fun test_register_if_domain_name_starts_with_dash() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;

        let nft = register_util(scenario, utf8(b"-ab.sui"), 1, 1200 * mist_per_sui(), 10);
        registration_nft::burn_for_testing(nft);

        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = domain::EInvalidDomain)]
    fun test_register_if_domain_name_ends_with_dash() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;

        let nft = register_util(scenario, utf8(b"ab-.sui"), 1, 1200 * mist_per_sui(), 10);
        registration_nft::burn_for_testing(nft);

        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = domain::EInvalidDomain)]
    fun test_register_if_domain_name_contains_uppercase_character() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;

        let nft = register_util(scenario, utf8(b"Abc.com"), 1, 1200 * mist_per_sui(), 10);
        registration_nft::burn_for_testing(nft);

        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = domain::EInvalidDomain)]
    fun test_register_if_domain_name_too_short() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;

        let nft = register_util(scenario, utf8(b"ab.sui"), 1, 1200 * mist_per_sui(), 10);
        registration_nft::burn_for_testing(nft);

        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = controller::EInvalidDomain)]
    fun test_register_if_domain_name_contains_subdomain() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;

        let nft = register_util(scenario, utf8(b"abc.xyz.sui"), 1, 1200 * mist_per_sui(), 10);
        registration_nft::burn_for_testing(nft);

        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = registry::ERecordNotExpired)]
    fun test_register_aborts_if_domain_name_went_through_auction() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        auction::init_for_testing(ctx(scenario));

        auction_tests::normal_auction_flow(scenario);
        let nft = register_util(scenario, utf8(AUCTIONED_DOMAIN_NAME), 1, 50 * mist_per_sui(), 10);
        registration_nft::burn_for_testing(nft);

        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_register_works_if_auctioned_domain_name_expired() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        auction::init_for_testing(ctx(scenario));

        auction_tests::normal_auction_flow(scenario);
        let nft = register_util(
            scenario,
            utf8(AUCTIONED_DOMAIN_NAME),
            1,
            50 * mist_per_sui(),
            year_ms() + grace_period_ms() + 20,
        );
        assert_balance(scenario, 50 * mist_per_sui());
        assert!(registration_nft::domain(&nft) == domain::new(utf8(AUCTIONED_DOMAIN_NAME)), 0);
        registration_nft::burn_for_testing(nft);

        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = suins::suins::EAppNotAuthorized)]
    fun test_register_aborts_if_register_is_deauthorized() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;

        deauthorize_app_util(scenario);
        let nft = register_util(scenario, utf8(DOMAIN_NAME), 1, 1200 * mist_per_sui(), 10);
        registration_nft::burn_for_testing(nft);

        test_scenario::end(scenario_val);
    }
}
