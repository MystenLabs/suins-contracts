// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module suins::namespace_tests {
    

    use std::string::{Self, utf8, String};
    use std::option::{Self, some};
    use std::vector;
    use sui::object;
    use sui::tx_context::{Self, TxContext};
    use sui::clock::{Self, Clock};
    use sui::vec_map;
    use sui::address;

    use sui::test_scenario::{Self as ts, Scenario, ctx};

    use suins::registry::{Self, Registry};
    use suins::namespace::{Self, Namespace};
    use suins::suins::{Self, SuiNS};
    use suins::registry_tests::{burn_nfts, burn_subname_nfts};
    use suins::domain;
    use suins::name_record;
    use suins::constants;
    use suins::suins_registration::{Self as nft};
    use suins::subdomain_registration::{Self as sub_nft};

    /// Authorized witness to access the registry
    struct TestApp has drop {}

    const USER: address = @0x1;
    const ADMIN: address = @0x2;

    // We test the flows e2e.
    // 1. Create a namespace
    // 2. Add node names to the namespace
    // 3. Validate their DF values are proper
    // 4. Validate the registry has the right values
    #[test]
    fun test_e2e(){
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        let domain = domain::new(utf8(b"test.sui"));

        ts::next_tx(scenario, USER);

        let suins = ts::take_shared<SuiNS>(scenario);
        let registry = suins::app_registry_mut<TestApp, Registry>(TestApp {}, &mut suins);

        let clock = ts::take_shared<Clock>(scenario);

        // create a record for the test domain with expiration set to 1 year
        let nft = registry::add_record(registry, domain, 1, &clock, ctx(scenario));

        // create a namespace
        namespace::create_namespace(registry, &mut nft, &clock, ctx(scenario));

        ts::next_tx(scenario, USER);

        // take the namespace and start validating that data is correctly set.
        let namespace = ts::take_shared<Namespace>(scenario);
        assert!(namespace::parent_nft_id(&namespace) == object::id(&nft), 1);

        let name_record = registry::lookup(registry, domain);

        assert!(option::is_some(&name_record), 1);

        let name_record_data = name_record::data(option::borrow(&name_record));

        assert!(vec_map::contains(name_record_data, &constants::namespace_key()), 1);
        assert!(vec_map::get(name_record_data, &constants::namespace_key()) == &address::to_string(object::id_address(&namespace)), 1);
        assert!(namespace::namespace(&nft) == &object::id(&namespace), 1);

        let expiration = nft::expiration_timestamp_ms(&nft);
        let subname = namespace::add_record(&mut namespace, &nft,expiration, true, true, utf8(b"subdomain.test.sui"), &clock, ctx(scenario));

        clock::increment_for_testing(&mut clock, expiration + 1);
        
        // check that subname's nft is also set correctly.
        assert!(namespace::namespace(sub_nft::borrow(&subname)) == &object::id(&namespace), 1);

        burn_nfts(vector[ nft ]);
        burn_subname_nfts(vector[ subname ], &clock);

        // return everything.
        ts::return_shared(suins);
        ts::return_shared(clock);
        ts::return_shared(namespace);
        ts::end(scenario_val);
    }

    /// Private helpers to prepare tests
    /// 
    public fun test_init(): (Scenario) {
        let scenario = ts::begin(USER);

        {
            ts::next_tx(&mut scenario, USER);

            let clock = clock::create_for_testing(ctx(&mut scenario));
            let (suins, cap) = suins::new_for_testing(ctx(&mut scenario));

            suins::authorize_app_for_testing<TestApp>(&mut suins);
            registry::init_for_testing(&cap, &mut suins, ctx(&mut scenario));
            clock::share_for_testing(clock);

            suins::share_for_testing(suins);
            suins::burn_admin_cap_for_testing(cap);
        };

        scenario
    }

    /// Prepare 
}
