// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module d3::d3_tests {
    use std::string::{utf8, String};

    use sui::test_scenario::{Self as ts, Scenario, ctx};
    use sui::clock::{Self, Clock};
    use sui::transfer;

    use suins::registry::{Self};
    use suins::suins::{Self, SuiNS, AdminCap};

    use d3::d3::{Self};
    use d3::auth::{Self, DThreeApp, DThreeCap};

    const SUINS_ADDRESS: address = @0x1;
    const DTHREE_ADDRESS: address = @0x2;
    const USER: address = @0x3;

    fun test_init(): Scenario {
        let scenario_val = ts::begin(SUINS_ADDRESS);
        let scenario = &mut scenario_val;
        {
            let suins = suins::init_for_testing(ctx(scenario));
            suins::authorize_app_for_testing<DThreeApp>(&mut suins);
            suins::share_for_testing(suins);
            let clock = clock::create_for_testing(ctx(scenario));
            clock::share_for_testing(clock);
        };
        {
            ts::next_tx(scenario, SUINS_ADDRESS);
            let admin_cap = ts::take_from_sender<AdminCap>(scenario);
            let suins = ts::take_shared<SuiNS>(scenario);

            auth::setup(&mut suins, &admin_cap);

            // mint a cap for DThreeAddress
            auth::mint_cap(&mut suins, &admin_cap, DTHREE_ADDRESS, ctx(scenario));

            registry::init_for_testing(&admin_cap, &mut suins, ctx(scenario));

            ts::return_shared(suins);
            ts::return_to_sender(scenario, admin_cap);
        };
        scenario_val
    }

    /// A helper to mint a name as D3.
    fun mint_name(scenario: &mut Scenario, domain_name: String, recipient: address){
        ts::next_tx(scenario, DTHREE_ADDRESS);
        let suins = ts::take_shared<SuiNS>(scenario);
        let cap = ts::take_from_sender<DThreeCap>(scenario);
        let clock = ts::take_shared<Clock>(scenario);

        let name = d3::create_name(&mut suins, domain_name, 1, &clock, &cap, ctx(scenario));
        transfer::public_transfer(name, recipient);

        ts::return_to_sender(scenario, cap);
        ts::return_shared(suins);
        ts::return_shared(clock);
    }

    /// A helpe to toggle lock status as D3.
    fun icann_lock_toggle(scenario: &mut Scenario, domain_name: String, lock: bool) {
        ts::next_tx(scenario, DTHREE_ADDRESS);
        let suins = ts::take_shared<SuiNS>(scenario);
        let cap = ts::take_from_sender<DThreeCap>(scenario);

        if(lock) {
            d3::icann_lock(&mut suins, &cap, domain_name);
        }else{
            d3::icann_unlock(&mut suins, &cap, domain_name);
        };

        ts::return_to_sender(scenario, cap);
        ts::return_shared(suins);
    }

    #[test]
    /// We test a full scenario of D3 operations.
    /// 1. Mint a name
    /// 2. ICANN lock it
    /// 3. ICANN unlock it
    fun test_e2e() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;

        let name = utf8(b"d3name.sui");
        mint_name(scenario, name, USER);

        // Lock the name.
        icann_lock_toggle(scenario, name, true);

        // Query to see the state (validate)
        {
            ts::next_tx(scenario, USER);
            let suins = ts::take_shared<SuiNS>(scenario);

            assert!(d3::registry_is_compatible_d3_name(&suins, name), 0);
            assert!(d3::registry_is_icann_locked_name(&suins, name), 0);

            ts::return_shared(suins);
        };

        // now we can query to see if the registry has the correct data after toggling (on `data`).
        icann_lock_toggle(scenario, name, false);

        // Query to see the state (validate)
        {
            ts::next_tx(scenario, USER);
            let suins = ts::take_shared<SuiNS>(scenario);

            assert!(d3::registry_is_compatible_d3_name(&suins, name), 0);
            assert!(!d3::registry_is_icann_locked_name(&suins, name), 0);
            ts::return_shared(suins);
        };
        

        // We register a name using a DThreeCap.

        ts::end(scenario_val);
    }
}
