// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module suins::renew_tests {
    use std::string::utf8;

    use sui::test_scenario::{Self, Scenario, ctx};
    use sui::coin;
    use sui::sui::SUI;
    use sui::clock::{Self, Clock};

    use suins::renew::{Self, Renew, renew};
    use suins::register_sample::Register;
    use suins::register_sample_tests::{register_util, assert_balance};
    use suins::constants::{mist_per_sui, year_ms};
    use suins::suins::{Self, SuiNS, AdminCap};
    use suins::suins_registration::{Self, SuinsRegistration};
    use suins::registry;

    const SUINS_ADDRESS: address = @0xA001;
    const DOMAIN_NAME: vector<u8> = b"abc.sui";

    public fun test_init(): Scenario {
        let scenario_val = test_scenario::begin(SUINS_ADDRESS);
        let scenario = &mut scenario_val;
        {
            let suins = suins::init_for_testing(ctx(scenario));
            suins::authorize_app_for_testing<Renew>(&mut suins);
            suins::authorize_app_for_testing<Register>(&mut suins);
            suins::share_for_testing(suins);
            let clock = clock::create_for_testing(ctx(scenario));
            clock::share_for_testing(clock);
        };
        {
            test_scenario::next_tx(scenario, SUINS_ADDRESS);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);

            registry::init_for_testing(&admin_cap, &mut suins, ctx(scenario));

            test_scenario::return_shared(suins);
            test_scenario::return_to_sender(scenario, admin_cap);
        };
        scenario_val
    }

    fun renew_util(scenario: &mut Scenario, nft: &mut SuinsRegistration, no_years: u8, amount: u64, clock_tick: u64) {
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        let suins = test_scenario::take_shared<SuiNS>(scenario);
        let payment = coin::mint_for_testing<SUI>(amount, ctx(scenario));
        let clock = test_scenario::take_shared<Clock>(scenario);

        clock::increment_for_testing(&mut clock, clock_tick);
        renew(&mut suins, nft, no_years, payment, &clock);

        test_scenario::return_shared(clock);
        test_scenario::return_shared(suins);
    }

    fun deauthorize_app_util(scenario: &mut Scenario) {
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
        let suins = test_scenario::take_shared<SuiNS>(scenario);

        suins::deauthorize_app<Renew>(&admin_cap, &mut suins);

        test_scenario::return_shared(suins);
        test_scenario::return_to_sender(scenario, admin_cap);
    }

    #[test]
    fun test_renew() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;

        let nft = register_util(scenario, utf8(b"abcd.sui"), 1, 200 * mist_per_sui(), 0);
        assert!(suins_registration::expiration_timestamp_ms(&nft) == year_ms(), 0);
        renew_util(scenario, &mut nft, 1, 200 * mist_per_sui(), 0);
        assert_balance(scenario, 400 * mist_per_sui());
        suins_registration::burn_for_testing(nft);

        let nft = register_util(scenario, utf8(b"abcde.sui"), 1, 50 * mist_per_sui(), 0);
        assert!(suins_registration::expiration_timestamp_ms(&nft) == year_ms(), 0);
        renew_util(scenario, &mut nft, 1, 50 * mist_per_sui(), 0);
        assert_balance(scenario, 500 * mist_per_sui());
        suins_registration::burn_for_testing(nft);

        let nft = register_util(scenario, utf8(DOMAIN_NAME), 1, 1200 * mist_per_sui(), 10);
        assert!(suins_registration::expiration_timestamp_ms(&nft) == year_ms() + 10, 0);
        renew_util(scenario, &mut nft, 1, 1200 * mist_per_sui(), 0);
        assert_balance(scenario, 2900 * mist_per_sui());
        assert!(suins_registration::expiration_timestamp_ms(&nft) == 2 * year_ms() + 10, 0);
        renew_util(scenario, &mut nft, 2, 2400 * mist_per_sui(), 0);
        assert_balance(scenario, 5300 * mist_per_sui());
        assert!(suins_registration::expiration_timestamp_ms(&nft) == 4 * year_ms() + 10, 0);
        suins_registration::burn_for_testing(nft);


        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = renew::EIncorrectAmount)]
    fun test_renew_aborts_if_incorrect_amount() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;

        let nft = register_util(scenario, utf8(DOMAIN_NAME), 1, 1200 * mist_per_sui(), 10);
        renew_util(scenario, &mut nft, 1, 1210 * mist_per_sui(), 0);
        suins_registration::burn_for_testing(nft);

        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = renew::EIncorrectAmount)]
    fun test_renew_aborts_if_incorrect_amount_2() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;

        let nft = register_util(scenario, utf8(DOMAIN_NAME), 1, 1200 * mist_per_sui(), 10);
        renew_util(scenario, &mut nft, 1, 10 * mist_per_sui(), 0);
        suins_registration::burn_for_testing(nft);

        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = renew::EGracePeriodPassed)]
    fun test_renew_aborts_if_nft_expired() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;

        let nft = register_util(scenario, utf8(DOMAIN_NAME), 1, 1200 * mist_per_sui(), 10);
        renew_util(scenario, &mut nft, 1, 1200 * mist_per_sui(), 2 * year_ms() + 20);
        suins_registration::burn_for_testing(nft);

        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = renew::EInvalidYearsArgument)]
    fun test_renew_aborts_no_years_more_than_5_years() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;

        let nft = register_util(scenario, utf8(DOMAIN_NAME), 1, 1200 * mist_per_sui(), 0);
        renew_util(scenario, &mut nft, 6, 7200 * mist_per_sui(), 0);
        suins_registration::burn_for_testing(nft);

        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = renew::EInvalidNewExpiredAt)]
    fun test_renew_aborts_new_expiry_more_than_5_years() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;

        let nft = register_util(scenario, utf8(DOMAIN_NAME), 1, 1200 * mist_per_sui(), 0);
        renew_util(scenario, &mut nft, 2, 2400 * mist_per_sui(), 0);
        renew_util(scenario, &mut nft, 4, 4800 * mist_per_sui(), 0);
        suins_registration::burn_for_testing(nft);

        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = suins::suins::EAppNotAuthorized)]
    fun test_renew_aborts_if_renew_is_deauthorized() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;

        let nft = register_util(scenario, utf8(DOMAIN_NAME), 1, 1200 * mist_per_sui(), 0);
        deauthorize_app_util(scenario);
        renew_util(scenario, &mut nft, 2, 2400 * mist_per_sui(), 0);
        suins_registration::burn_for_testing(nft);

        test_scenario::end(scenario_val);
    }
}
