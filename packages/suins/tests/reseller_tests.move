// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module suins::reseller_tests {
    use std::option::{Self, Option};
    use std::string::{String, utf8};

    use sui::test_scenario::{Self as ts, Scenario, ctx};
    use sui::transfer;
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;

    use suins::suins::{Self, SuiNS, AdminCap};
    use suins::reseller::{Self, ResellerApp, ResellerCap};

    /// A test app to use for using the reseller system.
    struct TestApp has drop {}

    const ADMIN_ADDRESS: address = @0x1;
    const USER: address = @0x2;
    const RESELLER: address = @0x3;
    const SALE_PRICE: u64 = 100_000_000;

    #[test]
    /// Pay a regular amount without reseller code (option::none()) and 
    /// make sure the suins got all the coin balance.
    fun test_no_code_handling_success() {
        let scenario_val = setup();
        let scenario = &mut scenario_val;

        pay_handler<TestApp>(TestApp {}, scenario, 100_000_000, option::none(), USER);

        {
            ts::next_tx(scenario, USER);
            let suins = ts::take_shared<SuiNS>(scenario);
            assert!(suins::total_balance(&suins) == 100_000_000, 0);
            ts::return_shared(suins);
        };

        ts::end(scenario_val);
    }

    #[test]
    /// Tests a full successful flow where:
    /// 1. Authorize a reseller
    /// 2. Process a payment and verify that reseller got the expect amount
    fun test_authorized_reseller_success() {
        let scenario_val = setup();
        let scenario = &mut scenario_val;

        authorize_reseller(scenario, get_reseller_code(), 10_00, RESELLER);

        pay_handler<TestApp>(TestApp {}, scenario, 100_000_000, option::some(get_reseller_code()), USER);
        // validate that the SUINS registry has got 90% of the funds
        assert_suins_balance(scenario, 90_000_000);
        // Validate that the RESELLER can withdraw profits (and that should be 10% so 10_000_000 in our example here)
        assert_reseller_withdraw_balance(scenario, RESELLER, 10_000_000);

        ts::end(scenario_val);
    }

    #[test]
    /// Tests that the rate changes successfully from admin.
    fun test_rate_change_success() {
        let scenario_val = setup();
        let scenario = &mut scenario_val;

        authorize_reseller(scenario, get_reseller_code(), 10_00, RESELLER);
        pay_handler<TestApp>(TestApp {}, scenario, SALE_PRICE, option::some(get_reseller_code()), USER);
        // validate that the SUINS registry has got 90% of the funds
        assert_suins_balance(scenario, 90_000_000); // (90_000_000 -> 90% of SALE_PRICE)
        // Validate that the RESELLER can withdraw profits (and that should be 10% so 10_000_000 in our example here)
        assert_reseller_withdraw_balance(scenario, RESELLER, 10_000_000); // (10_000_000 -> 10% of SALE_PRICE)

        // change commission to 20% now.
        set_reseller_commission(scenario, get_reseller_code(), 20_00);
        pay_handler<TestApp>(TestApp {}, scenario, SALE_PRICE, option::some(get_reseller_code()), USER);
        // validate that the SUINS registry has got 80% of the funds
        assert_suins_balance(scenario, 90_000_000 + 80_000_000);
        // Validate that the RESELLER can withdraw profits (and that should be 10% so 10_000_000 in our example here)
        assert_reseller_withdraw_balance(scenario, RESELLER, 20_000_000);

        ts::end(scenario_val);
    }

    #[test, expected_failure(abort_code = suins::reseller::EAlreadyExists)]
    fun test_double_authorization_failure() {
        let scenario_val = setup();
        let scenario = &mut scenario_val;

        authorize_reseller(scenario, get_reseller_code(), 10_00, RESELLER);
        authorize_reseller(scenario, get_reseller_code(), 15_00, RESELLER);

        abort 1337
    }

    #[test, expected_failure(abort_code = suins::reseller::EInvalidComission)]
    fun test_invalid_percentage_failure() {
        let scenario_val = setup();
        let scenario = &mut scenario_val;

        authorize_reseller(scenario, get_reseller_code(), 10_001, RESELLER);

        abort 1337
    }

    #[test, expected_failure(abort_code = suins::reseller::EResellerNotExists)]
    fun try_to_claim_with_invalid_reseller_failure() {
        let scenario_val = setup();
        let scenario = &mut scenario_val;

       pay_handler<TestApp>(TestApp {}, scenario, SALE_PRICE, option::some(utf8(b"RANDOM_NON_EXISTING_RESELLER")), USER);

        abort 1337
    }

    #[test, expected_failure(abort_code = suins::reseller::EResellerDisabled)]
    fun try_to_pay_with_unauthorized_reseller_failure() {
        let scenario_val = setup();
        let scenario = &mut scenario_val;

        authorize_reseller(scenario, get_reseller_code(), 10_00, RESELLER);
        disable_reseller(scenario, get_reseller_code());
        pay_handler<TestApp>(TestApp {}, scenario, SALE_PRICE, option::some(get_reseller_code()), USER);

        abort 1337
    }

    #[test, expected_failure(abort_code = suins::reseller::EResellerNotExists)]
    fun try_to_disable_non_existing_reseller_failure(){
        let scenario_val = setup();
        let scenario = &mut scenario_val;
        disable_reseller(scenario, get_reseller_code());

        abort 1337
    }

    #[test, expected_failure(abort_code = suins::reseller::EResellerNotExists)]
    fun try_to_change_rate_to_non_existing_reseller_failure(){
        let scenario_val = setup();
        let scenario = &mut scenario_val;
        set_reseller_commission(scenario, get_reseller_code(), 20_00);

        abort 1337
    }


    ///
    /// ===== HELPERS =====
    /// 
    fun get_reseller_code(): String {
        utf8(b"RESELLER")
    }

    fun setup (): Scenario {
        let scenario_val = ts::begin(ADMIN_ADDRESS);
        let scenario = &mut scenario_val;
        {
            ts::next_tx(scenario, ADMIN_ADDRESS);
            let suins = suins::init_for_testing(ctx(scenario));
            suins::share_for_testing(suins);
        };
        {
            ts::next_tx(scenario, ADMIN_ADDRESS);
            let suins = ts::take_shared<SuiNS>(scenario);

            let admin_cap = ts::take_from_sender<AdminCap>(scenario);
            reseller::setup(&mut suins, &admin_cap, ctx(scenario));

            suins::authorize_app_for_testing<TestApp>(&mut suins);
            suins::authorize_app_for_testing<ResellerApp>(&mut suins);

            ts::return_to_sender(scenario, admin_cap);
            ts::return_shared(suins);
        };

        scenario_val
    }

    fun authorize_reseller(scenario: &mut Scenario, reseller: String, commission: u16, user: address) {
        ts::next_tx(scenario, ADMIN_ADDRESS);

        let suins = ts::take_shared<SuiNS>(scenario);
        let admin_cap = suins::create_admin_cap_for_testing(ctx(scenario));

        let cap = reseller::authorize(&mut suins, &admin_cap, reseller, commission, ctx(scenario));
        transfer::public_transfer(cap, user);

        suins::burn_admin_cap_for_testing(admin_cap);
        ts::return_shared(suins);
    }

    fun disable_reseller(scenario: &mut Scenario, reseller: String) {
        ts::next_tx(scenario, ADMIN_ADDRESS);

        let suins = ts::take_shared<SuiNS>(scenario);
        let admin_cap = suins::create_admin_cap_for_testing(ctx(scenario));
        reseller::set_enabled(&mut suins, &admin_cap, reseller, false);

        suins::burn_admin_cap_for_testing(admin_cap);
        ts::return_shared(suins);
    }

    fun set_reseller_commission(scenario: &mut Scenario, reseller: String, commission: u16){
        ts::next_tx(scenario, ADMIN_ADDRESS);

        let suins = ts::take_shared<SuiNS>(scenario);
        let admin_cap = suins::create_admin_cap_for_testing(ctx(scenario));
        reseller::set_commission(&mut suins, &admin_cap, reseller, commission);

        suins::burn_admin_cap_for_testing(admin_cap);
        ts::return_shared(suins);
    }

    fun pay_handler<App: drop>(app: App, scenario: &mut Scenario, amount: u64, code: Option<String>, user: address) {
        ts::next_tx(scenario, user);

        let suins = ts::take_shared<SuiNS>(scenario);

        let payment: Coin<SUI> = coin::mint_for_testing(amount, ctx(scenario));

        reseller::handle_payment(app, &mut suins, payment, code, ctx(scenario));

        ts::return_shared(suins);
    }

    fun assert_suins_balance(scenario: &mut Scenario, value: u64) {
        ts::next_tx(scenario, USER);
        let suins = ts::take_shared<SuiNS>(scenario);

        assert!(suins::total_balance(&suins) == value, 0);
        ts::return_shared(suins);
    }

    fun assert_reseller_withdraw_balance(scenario: &mut Scenario, reseller: address, value: u64) {

        ts::next_tx(scenario, reseller);
        let cap = ts::take_from_sender<ResellerCap>(scenario);
        let suins = ts::take_shared<SuiNS>(scenario);

        let coin = reseller::withdraw(&mut suins, &cap, ctx(scenario));

        assert!(coin::value(&coin) == value, 1);
        transfer::public_transfer(coin, reseller);

        ts::return_shared(suins);
        ts::return_to_sender(scenario, cap);
    }
}
