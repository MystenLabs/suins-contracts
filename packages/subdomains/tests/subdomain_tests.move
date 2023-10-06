// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module subdomains::subdomain_tests {


    use sui::test_scenario::{Self as ts, Scenario, ctx};
    use sui::clock;

    use suins::domain;
    use suins::suins::{Self, SuiNS, AdminCap};
    use suins::registry;

    use subdomains::app::{Self, SubDomains, SubDomainApp};

    const USER_ADDRESS: address = @0x01;

    public fun test_init(): Scenario {
        let scenario_val = ts::begin(USER_ADDRESS);
        let scenario = &mut scenario_val;
        {
            app::init_for_testing(ctx(scenario));
            let suins = suins::init_for_testing(ctx(scenario));
            suins::authorize_app_for_testing<SubDomains>(&mut suins);
            suins::share_for_testing(suins);
            let clock = clock::create_for_testing(ctx(scenario));
            clock::share_for_testing(clock);
        };
        {
            ts::next_tx(scenario, USER_ADDRESS);
            let admin_cap = ts::take_from_sender<AdminCap>(scenario);
            let suins = ts::take_shared<SuiNS>(scenario);

            registry::init_for_testing(&admin_cap, &mut suins, ctx(scenario));

            ts::return_shared(suins);
            ts::return_to_sender(scenario, admin_cap);
        };
        scenario_val
    }

    // public fun test_create_subdomain() {
    //     let scenario_val = test_init();
    //     let scenario = &mut scenario_val;
    //     {
    //         ts::next_tx(scenario, USER_ADDRESS);
    //         let subdomains = ts::take_shared<SubDomainApp>(scenario);
    //         let suins = ts::take_shared<SuiNS>(scenario);

    //         // app::create(&mut subdomains, &mut suins, ctx(scenario));

    //         ts::return_shared(suins);
    //         ts::return_to_sender(scenario, subdomains);
    //     };
    //     scenario
    // }

}
