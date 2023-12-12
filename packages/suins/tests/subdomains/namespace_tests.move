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
    use suins::registry_tests::{burn_nfts, setup, wrapup, burn_subname_nfts};
    use suins::domain;
    use suins::name_record;
    use suins::constants;
    use suins::suins_registration::{Self as nft};
    use suins::subdomain_registration::{Self as sub_nft};
    use suins::sub_name_record;

    /// Authorized witness to access the registry
    struct TestApp has drop {}

    const USER: address = @0x1;
    const ADMIN: address = @0x2;

    // We test the flow e2e.
    // 1. Create a namespace.
    // 2. Add a node name to the namespace
    // 3. Validate the DF values are proper.
    // 4. Validate the registry has the right values.
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

    /// Test e2e flows with leaf record additions and removals.
    #[test]
    fun test_leafs_e2e() {
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

        // add name
        namespace::add_leaf_record(&mut namespace, &nft, utf8(b"leaf.test.sui"), &clock, USER, ctx(scenario));

        // look it up and check if its leaf.
        let subname_record = namespace::lookup(&namespace, domain::new(utf8(b"leaf.test.sui")));
        assert!(option::is_some(&subname_record), 1);

        // validate that its leaf.
        assert!(sub_name_record::is_leaf(option::borrow(&subname_record)), 1);

        // validate that leaf's NFT ID is the parent's one.
        assert!(name_record::nft_id(sub_name_record::name_record(option::borrow(&subname_record))) == object::id(&nft), 1);

        // remove the leaf record
        namespace::remove_leaf_record(&mut namespace, &nft, utf8(b"leaf.test.sui"), &clock);
        
        // look up again
        subname_record = namespace::lookup(&namespace, domain::new(utf8(b"leaf.test.sui")));

        // validate that no record exists.
        assert!(option::is_none(&subname_record), 1);

        // burn the nfts.
        burn_nfts(vector[ nft ]);

        // return everything.
        ts::return_shared(suins);
        ts::return_shared(clock);
        ts::return_shared(namespace);
        ts::end(scenario_val);
    }


    /// Tries to create a subdomain without first initializing a namespace.
    #[test, expected_failure(abort_code=suins::namespace::ENFTExpired)]
    fun create_with_expired_nft() {
        let ctx = tx_context::dummy();
        let (registry, clock, domain) = setup(&mut ctx);

        let nft = registry::add_record(&mut registry, domain, 1, &clock, &mut ctx);
        clock::increment_for_testing(&mut clock, nft::expiration_timestamp_ms(&nft) + 1);

        namespace::create_namespace(&mut registry, &mut nft, &clock, &mut ctx);
    
        abort 1337
    }

    /// Tries to create a namespace after having created one already.
    #[test, expected_failure(abort_code=suins::namespace::ENameSpaceAlreadyCreated)]
    fun create_second_namespace() {
        let ctx = tx_context::dummy();
        let (registry, clock, domain) = setup(&mut ctx);
        let nft = registry::add_record(&mut registry, domain, 1, &clock, &mut ctx);

        namespace::create_namespace(&mut registry, &mut nft, &clock, &mut ctx);
        namespace::create_namespace(&mut registry, &mut nft, &clock, &mut ctx);
    
        abort 1337
    }

    /// Tries to create a namespace after having created one already.
    #[test, expected_failure(abort_code=suins::namespace::ENotASLDName)]
    fun create_namespace_with_subdomain() {
        let ctx = tx_context::dummy();
        let (registry, clock, domain) = setup(&mut ctx);

        // create a subdomain
        let nft = nft::new_for_testing(domain::new(utf8(b"example.test.sui")), 1, &clock, &mut ctx);

        namespace::create_namespace(&mut registry, &mut nft, &clock, &mut ctx);
    
        abort 1337
    }

    /// Tries a record in a miss-matched namespace.
    #[test, expected_failure(abort_code=suins::namespace::ENamespaceMissmatch)]
    fun create_subdomain_in_missmatched_namespace() {
        let ctx = tx_context::dummy();
        let (registry, clock, domain) = setup(&mut ctx);

        let nft_1 = registry::add_record(&mut registry, domain::new(utf8(b"test.sui")), 1, &clock, &mut ctx);
        let nft_2 = registry::add_record(&mut registry, domain::new(utf8(b"haha.sui")), 1, &clock, &mut ctx);

        let namespace = namespace::create_namespace_for_testing(&mut registry, &mut nft_2, &clock, &mut ctx);

        namespace::add_leaf_record(&mut namespace, &mut nft_1, utf8(b"leaf.test.sui"), &clock, USER, &mut ctx);
    
        abort 1337
    }

    /// Tries a record in a miss-matched namespace.
    #[test, expected_failure(abort_code=suins::namespace::EInvalidParent)]
    fun create_with_invalid_parent() {
        let ctx = tx_context::dummy();
        let (registry, clock, domain) = setup(&mut ctx);

        let nft_1 = registry::add_record(&mut registry, domain::new(utf8(b"test.sui")), 1, &clock, &mut ctx);
        let nft_2 = registry::add_record(&mut registry, domain::new(utf8(b"haha.sui")), 1, &clock, &mut ctx);

        let namespace = namespace::create_namespace_for_testing(&mut registry, &mut nft_2, &clock, &mut ctx);

        namespace::add_leaf_record(&mut namespace, &mut nft_2, utf8(b"leaf.test.sui"), &clock, USER, &mut ctx);
    
        abort 1337
    }

    #[test, expected_failure(abort_code=suins::namespace::EInvalidExpirationDate)]
    fun create_expiration_greater_than_parent_expiration() {
        let ctx = tx_context::dummy();
        let (registry, clock, domain) = setup(&mut ctx);

        let nft = registry::add_record(&mut registry, domain::new(utf8(b"test.sui")), 1, &clock, &mut ctx);

        let namespace = namespace::create_namespace_for_testing(&mut registry, &mut nft, &clock, &mut ctx);

        let expiration = nft::expiration_timestamp_ms(&nft) + 1;

        let _subname = namespace::add_record(&mut namespace, &nft, expiration, true, true, utf8(b"node.test.sui"), &clock, &mut ctx);
    
        abort 1337
    }

    #[test, expected_failure(abort_code=suins::namespace::ERecordNotExpired)]
    fun override_non_expired_name() {
        let ctx = tx_context::dummy();
        let (registry, clock, domain) = setup(&mut ctx);

        let nft = registry::add_record(&mut registry, domain::new(utf8(b"test.sui")), 1, &clock, &mut ctx);

        let namespace = namespace::create_namespace_for_testing(&mut registry, &mut nft, &clock, &mut ctx);

        let expiration = nft::expiration_timestamp_ms(&nft);
        let _subname = namespace::add_record(&mut namespace, &nft, expiration, true, true, utf8(b"node.test.sui"), &clock, &mut ctx);

        namespace::add_leaf_record(&mut namespace, &nft, utf8(b"node.test.sui"), &clock, USER, &mut ctx);
    
        abort 1337
    }

    #[test, expected_failure(abort_code=suins::namespace::ENotLeafRecord)]
    fun remove_node_from_leaf() {
        let ctx = tx_context::dummy();
        let (registry, clock, domain) = setup(&mut ctx);

        let nft = registry::add_record(&mut registry, domain::new(utf8(b"test.sui")), 1, &clock, &mut ctx);

        let namespace = namespace::create_namespace_for_testing(&mut registry, &mut nft, &clock, &mut ctx);

        let expiration = nft::expiration_timestamp_ms(&nft);
        let _subname = namespace::add_record(&mut namespace, &nft, expiration, true, true, utf8(b"node.test.sui"), &clock, &mut ctx);

        // remove the leaf record
        namespace::remove_leaf_record(&mut namespace, &nft, utf8(b"node.test.sui"), &clock);
    
        abort 1337
    }

    #[test, expected_failure(abort_code=suins::namespace::ENotSupportedTLD)]
    fun create_namespace_without_supported_tld() {
        let ctx = tx_context::dummy();
        let (registry, clock, domain) = setup(&mut ctx);

        let nft = registry::add_record(&mut registry, domain::new(utf8(b"test.move")), 1, &clock, &mut ctx);

        namespace::create_namespace(&mut registry, &mut nft, &clock, &mut ctx);
    
        abort 1337
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
}
