// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module suins::renew_tests {
    use std::string::utf8;

    use sui::{
        test_scenario::{Self, Scenario, ctx},
        coin,
        sui::SUI,
        clock::{Self, Clock}
    };

    use suins::{
        renew::{Self, Renew, renew},
        register_sample::Register,
        register_sample_tests::{register_util, assert_balance},
        constants::{mist_per_sui, year_ms},
        suins::{Self, SuiNS, AdminCap},
        suins_registration::SuinsRegistration,
        registry,
    };

    const SUINS_ADDRESS: address = @0xA001;
    const DOMAIN_NAME: vector<u8> = b"abc.sui";

    public fun test_init(): Scenario {
        let mut scenario_val = test_scenario::begin(SUINS_ADDRESS);
        let scenario = &mut scenario_val;
        {
            let mut suins = suins::init_for_testing(ctx(scenario));
            suins.authorize_app_for_testing<Renew>();
            suins.authorize_app_for_testing<Register>();
            suins.share_for_testing();
            let clock = clock::create_for_testing(ctx(scenario));
            clock::share_for_testing(clock);
        };
        {
            scenario.next_tx(SUINS_ADDRESS);
            let admin_cap = scenario.take_from_sender<AdminCap>();
            let mut suins = scenario.take_shared<SuiNS>();

            registry::init_for_testing(&admin_cap, &mut suins, ctx(scenario));

            test_scenario::return_shared(suins);
            test_scenario::return_to_sender(scenario, admin_cap);
        };
        scenario_val
    }

    fun renew_util(scenario: &mut Scenario, nft: &mut SuinsRegistration, no_years: u8, amount: u64, clock_tick: u64) {
        scenario.next_tx(SUINS_ADDRESS);
        let mut suins = scenario.take_shared<SuiNS>();
        let payment = coin::mint_for_testing<SUI>(amount, ctx(scenario));
        let mut clock = test_scenario::take_shared<Clock>(scenario);

        clock.increment_for_testing(clock_tick);
        renew(&mut suins, nft, no_years, payment, &clock);

        test_scenario::return_shared(clock);
        test_scenario::return_shared(suins);
    }

    fun deauthorize_app_util(scenario: &mut Scenario) {
        scenario.next_tx(SUINS_ADDRESS);
        let admin_cap = scenario.take_from_sender<AdminCap>();
        let mut suins = scenario.take_shared<SuiNS>();

        suins::deauthorize_app<Renew>(&admin_cap, &mut suins);

        test_scenario::return_shared(suins);
        test_scenario::return_to_sender(scenario, admin_cap);
    }

    #[test]
    fun test_renew() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;

        let mut nft = register_util(scenario, utf8(b"abcd.sui"), 1, 200 * mist_per_sui(), 0);
        assert!(nft.expiration_timestamp_ms() == year_ms(), 0);
        renew_util(scenario, &mut nft, 1, 200 * mist_per_sui(), 0);
        assert_balance(scenario, 400 * mist_per_sui());
        nft.burn_for_testing();

        let mut nft = register_util(scenario, utf8(b"abcde.sui"), 1, 50 * mist_per_sui(), 0);
        assert!(nft.expiration_timestamp_ms() == year_ms(), 0);
        renew_util(scenario, &mut nft, 1, 50 * mist_per_sui(), 0);
        assert_balance(scenario, 500 * mist_per_sui());
        nft.burn_for_testing();

        let mut nft = register_util(scenario, utf8(DOMAIN_NAME), 1, 1200 * mist_per_sui(), 10);
        assert!(nft.expiration_timestamp_ms() == year_ms() + 10, 0);
        renew_util(scenario, &mut nft, 1, 1200 * mist_per_sui(), 0);
        assert_balance(scenario, 2900 * mist_per_sui());
        assert!(nft.expiration_timestamp_ms() == 2 * year_ms() + 10, 0);
        renew_util(scenario, &mut nft, 2, 2400 * mist_per_sui(), 0);
        assert_balance(scenario, 5300 * mist_per_sui());
        assert!(nft.expiration_timestamp_ms() == 4 * year_ms() + 10, 0);
        nft.burn_for_testing();


        scenario_val.end();
    }

    #[test, expected_failure(abort_code = renew::EIncorrectAmount)]
    fun test_renew_aborts_if_incorrect_amount() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;

        let mut nft = register_util(scenario, utf8(DOMAIN_NAME), 1, 1200 * mist_per_sui(), 10);
        renew_util(scenario, &mut nft, 1, 1210 * mist_per_sui(), 0);
        nft.burn_for_testing();

        scenario_val.end();
    }

    #[test, expected_failure(abort_code = renew::EIncorrectAmount)]
    fun test_renew_aborts_if_incorrect_amount_2() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;

        let mut nft = register_util(scenario, utf8(DOMAIN_NAME), 1, 1200 * mist_per_sui(), 10);
        renew_util(scenario, &mut nft, 1, 10 * mist_per_sui(), 0);
        nft.burn_for_testing();

        scenario_val.end();
    }

    #[test, expected_failure(abort_code = renew::EGracePeriodPassed)]
    fun test_renew_aborts_if_nft_expired() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;

        let mut nft = register_util(scenario, utf8(DOMAIN_NAME), 1, 1200 * mist_per_sui(), 10);
        renew_util(scenario, &mut nft, 1, 1200 * mist_per_sui(), 2 * year_ms() + 20);
        nft.burn_for_testing();

        scenario_val.end();
    }

    #[test, expected_failure(abort_code = renew::EInvalidYearsArgument)]
    fun test_renew_aborts_no_years_more_than_5_years() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;

        let mut nft = register_util(scenario, utf8(DOMAIN_NAME), 1, 1200 * mist_per_sui(), 0);
        renew_util(scenario, &mut nft, 6, 7200 * mist_per_sui(), 0);
        nft.burn_for_testing();

        scenario_val.end();
    }

    #[test, expected_failure(abort_code = renew::EInvalidNewExpiredAt)]
    fun test_renew_aborts_new_expiry_more_than_5_years() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;

        let mut nft = register_util(scenario, utf8(DOMAIN_NAME), 1, 1200 * mist_per_sui(), 0);
        renew_util(scenario, &mut nft, 2, 2400 * mist_per_sui(), 0);
        renew_util(scenario, &mut nft, 4, 4800 * mist_per_sui(), 0);
        nft.burn_for_testing();

        scenario_val.end();
    }

    #[test, expected_failure(abort_code = ::suins::suins::EAppNotAuthorized)]
    fun test_renew_aborts_if_renew_is_deauthorized() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;

        let mut nft = register_util(scenario, utf8(DOMAIN_NAME), 1, 1200 * mist_per_sui(), 0);
        deauthorize_app_util(scenario);
        renew_util(scenario, &mut nft, 2, 2400 * mist_per_sui(), 0);
        nft.burn_for_testing();

        scenario_val.end();
    }
}
