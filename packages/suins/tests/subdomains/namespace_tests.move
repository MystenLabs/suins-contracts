// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
#[allow(unused_assignment)]
module suins::namespace_tests {
    use std::string::{Self, utf8};
    use std::option::{Self};
    use sui::object;
    use sui::tx_context;
    use sui::clock::{Self, Clock};
    use sui::vec_map;
    use sui::address;
    use sui::test_scenario::{Self as ts, Scenario, ctx};
    use sui::transfer;

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


    #[test]
    // We test the flow e2e.
    // 1. Create a namespace.
    // 2. Add a node name to the namespace
    // 3. Validate the DF values are proper.
    // 4. Validate the registry has the right values.
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

        // go one level deeper.
        let sub_subname = namespace::add_record(&mut namespace, sub_nft::borrow(&subname), expiration, true, true, utf8(b"nested.subdomain.test.sui"), &clock, ctx(scenario));
        
        // try setting the target address for the new name.
        namespace::set_target_address(&mut namespace, sub_nft::borrow(&sub_subname), &clock, @0x3);
        
        clock::increment_for_testing(&mut clock, expiration + 1);
        
        // check that subname's nft is also set correctly.
        assert!(namespace::namespace(sub_nft::borrow(&subname)) == &object::id(&namespace), 1);

        burn_nfts(vector[ nft ]);
        burn_subname_nfts(vector[ subname, sub_subname ], &clock);

        // return everything.
        ts::return_shared(suins);
        ts::return_shared(clock);
        ts::return_shared(namespace);
        ts::end(scenario_val);
    }

    #[test]
    /// Test e2e flows with leaf record additions and removals.
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

    #[test]
    // Test some flows in which we extend the expiration of a node name successfuly.
    fun extend_expiration_tests(){
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        let domain = domain::new(utf8(b"test.sui"));
        let child_name = utf8(b"child.test.sui");

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
        
        let initial_expiration = nft::expiration_timestamp_ms(&nft) - 100;

        // create a child for which we allow extension.
        let child = namespace::add_record(&mut namespace, &nft, initial_expiration, true, true, child_name, &clock, ctx(scenario));
        assert!(nft::expiration_timestamp_ms(sub_nft::borrow(&child)) == initial_expiration, 1);
        // check name_record has the correct initial expiration.
        assert!(name_record::expiration_timestamp_ms(
            sub_name_record::name_record(option::borrow(&namespace::lookup(&namespace, domain::new(child_name))))) 
            == initial_expiration, 1);

        // we extend the expiration of the child a bit.
        namespace::extend_expiration(&mut namespace, sub_nft::borrow_mut(&mut child), initial_expiration + 50);

        // check nft has the correct new expiration.
        assert!(nft::expiration_timestamp_ms(sub_nft::borrow(&child)) == initial_expiration + 50, 1);

        // check name_record has the correct new expiration.
        assert!(name_record::expiration_timestamp_ms(
            sub_name_record::name_record(option::borrow(&namespace::lookup(&namespace, domain::new(child_name))))) 
            == initial_expiration + 50, 1);


        burn_nfts(vector[ nft ]);

        clock::increment_for_testing(&mut clock, initial_expiration + 51);

        burn_subname_nfts(vector [child], &clock);
        // return everything.
        ts::return_shared(suins);
        ts::return_shared(clock);
        ts::return_shared(namespace);
        ts::end(scenario_val);
    }

    #[test]
    // Just some basic coverage on getters.
    fun plain_coverage(){
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

        let _uid = namespace::uid(&namespace);
        let _uid_mut = namespace::uid_mut(&mut namespace, &nft);
        let parent = namespace::parent(&namespace);

        assert!(parent == domain, 1);

        burn_nfts(vector[ nft ]);
        // return everything.
        ts::return_shared(suins);
        ts::return_shared(clock);
        ts::return_shared(namespace);
        ts::end(scenario_val);
    }

    #[test]
    /// Extend a namespace's expiration based on renewal of the parent SLD.
    fun extend_namespace_expiration() {
        let ctx = tx_context::dummy();
        let (registry, clock, domain) = setup(&mut ctx);

        let nft = registry::add_record(&mut registry, domain, 1, &clock, &mut ctx);
        let expiration = nft::expiration_timestamp_ms(&nft);

        let namespace = namespace::create_namespace_for_testing(&mut registry, &mut nft, &clock, &mut ctx);

        nft::set_expiration_timestamp_ms_for_testing(&mut nft, expiration + 100);

        namespace::update_expiration(&mut namespace, &nft);
        // call twice but has no difference in the effects.
        namespace::update_expiration(&mut namespace, &nft);

        assert!(namespace::expiration_timestamp_ms(&namespace) == expiration + 100, 1);

        burn_nfts(vector[ nft ]);
        wrapup(registry, clock);
        namespace::burn_namespace_for_testing(namespace);
    }

    #[test]
    fun override_leaf_record_of_expired_node_name() {
        let ctx = tx_context::dummy();
        let (registry, clock, domain) = setup(&mut ctx);

        let nft = registry::add_record(&mut registry, domain, 1, &clock, &mut ctx);

        let namespace = namespace::create_namespace_for_testing(&mut registry, &mut nft, &clock, &mut ctx);

        // determine expiration.
        let expiration = nft::expiration_timestamp_ms(&nft) - (constants::minimum_subdomain_duration() * 3);

        let subname = namespace::add_record(&mut namespace, &nft, expiration, true, true, utf8(b"nest.hahaha.sui"), &clock, &mut ctx);
        namespace::add_leaf_record(&mut namespace, sub_nft::borrow(&subname), utf8(b"more.nest.hahaha.sui"), &clock, USER, &mut ctx);

        // subname has expired, so the leaf record must also be expired and can be ovewriten.
        clock::increment_for_testing(&mut clock, expiration + 1);

        // we override the node name normally as the previous one has expired.
        let subname_2 = namespace::add_record(&mut namespace, &nft, expiration + constants::minimum_subdomain_duration() + 1, true, true, utf8(b"nest.hahaha.sui"), &clock, &mut ctx);

        namespace::add_leaf_record(&mut namespace, sub_nft::borrow(&subname_2), utf8(b"more.nest.hahaha.sui"), &clock, USER, &mut ctx);

        // increment to a far far away time.
        clock::increment_for_testing(&mut clock, expiration *2 );
        namespace::burn_namespace_for_testing(namespace);
        burn_nfts(vector[ nft ]);
        burn_subname_nfts(vector[ subname, subname_2 ], &clock);
        wrapup(registry, clock);
    }


    #[test, expected_failure(abort_code=suins::namespace::ENFTExpired)]
    /// Tries to create a subdomain without first initializing a namespace.
    fun create_with_expired_nft() {
        let ctx = tx_context::dummy();
        let (registry, clock, domain) = setup(&mut ctx);

        let nft = registry::add_record(&mut registry, domain, 1, &clock, &mut ctx);
        clock::increment_for_testing(&mut clock, nft::expiration_timestamp_ms(&nft) + 1);

        namespace::create_namespace(&mut registry, &mut nft, &clock, &mut ctx);
    
        abort 1337
    }


    #[test, expected_failure(abort_code=suins::namespace::ENameSpaceAlreadyCreated)]
    /// Tries to create a namespace after having created one already.
    fun create_second_namespace() {
        let ctx = tx_context::dummy();
        let (registry, clock, domain) = setup(&mut ctx);
        let nft = registry::add_record(&mut registry, domain, 1, &clock, &mut ctx);

        namespace::create_namespace(&mut registry, &mut nft, &clock, &mut ctx);
        namespace::create_namespace(&mut registry, &mut nft, &clock, &mut ctx);
    
        abort 1337
    }


    #[test, expected_failure(abort_code=suins::namespace::ENotASLDName)]
    /// Tries to create a namespace after having created one already.
    fun create_namespace_with_subdomain() {
        let ctx = tx_context::dummy();
        let (registry, clock, domain) = setup(&mut ctx);

        // create a subdomain
        let nft = nft::new_for_testing(domain::new(utf8(b"example.test.sui")), 1, &clock, &mut ctx);

        namespace::create_namespace(&mut registry, &mut nft, &clock, &mut ctx);
    
        abort 1337
    }

    #[test, expected_failure(abort_code=suins::namespace::ENamespaceMissmatch)]
    /// Tries a record in a miss-matched namespace.
    fun create_subdomain_in_missmatched_namespace() {
        let ctx = tx_context::dummy();
        let (registry, clock, domain) = setup(&mut ctx);

        let nft_1 = registry::add_record(&mut registry, domain::new(utf8(b"test.sui")), 1, &clock, &mut ctx);
        let nft_2 = registry::add_record(&mut registry, domain::new(utf8(b"haha.sui")), 1, &clock, &mut ctx);

        let namespace = namespace::create_namespace_for_testing(&mut registry, &mut nft_2, &clock, &mut ctx);

        namespace::add_leaf_record(&mut namespace, &nft_1, utf8(b"leaf.test.sui"), &clock, USER, &mut ctx);
    
        abort 1337
    }

    #[test, expected_failure(abort_code=suins::namespace::EInvalidParent)]
    fun create_with_invalid_parent() {
        let ctx = tx_context::dummy();
        let (registry, clock, domain) = setup(&mut ctx);

        let nft_1 = registry::add_record(&mut registry, domain::new(utf8(b"test.sui")), 1, &clock, &mut ctx);
        let nft_2 = registry::add_record(&mut registry, domain::new(utf8(b"haha.sui")), 1, &clock, &mut ctx);

        let namespace = namespace::create_namespace_for_testing(&mut registry, &mut nft_2, &clock, &mut ctx);

        namespace::add_leaf_record(&mut namespace, &nft_2, utf8(b"leaf.test.sui"), &clock, USER, &mut ctx);
    
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

    #[test, expected_failure(abort_code=suins::namespace::EInvalidExpirationDate)]
    fun create_expiration_too_short_lived() {
        let ctx = tx_context::dummy();
        let (registry, clock, domain) = setup(&mut ctx);

        let nft = registry::add_record(&mut registry, domain::new(utf8(b"test.sui")), 1, &clock, &mut ctx);

        let namespace = namespace::create_namespace_for_testing(&mut registry, &mut nft, &clock, &mut ctx);

        let _subname = namespace::add_record(&mut namespace, &nft, clock::timestamp_ms(&clock), true, true, utf8(b"node.test.sui"), &clock, &mut ctx);
    
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

    #[test, expected_failure(abort_code=suins::namespace::ENameCreationDisabled)]
    fun create_while_not_allowed_to_create() {
        let ctx = tx_context::dummy();
        let (registry, clock, domain) = setup(&mut ctx);

        let nft = registry::add_record(&mut registry, domain::new(utf8(b"test.sui")), 1, &clock, &mut ctx);

        let namespace = namespace::create_namespace_for_testing(&mut registry, &mut nft, &clock, &mut ctx);

        let expiration = nft::expiration_timestamp_ms(&nft);

        let subname = namespace::add_record(&mut namespace, &nft, expiration, false, true, utf8(b"node.test.sui"), &clock, &mut ctx);

         let subname = namespace::add_record(&mut namespace, sub_nft::borrow(&subname), expiration, true, true, utf8(b"nested.node.test.sui"), &clock, &mut ctx);
    
        abort 1337
    }

    #[test, expected_failure(abort_code=suins::namespace::EInvalidSubdomainDepth)]
    fun create_too_nested_name() {
        let ctx = tx_context::dummy();
        let (registry, clock, domain) = setup(&mut ctx);
        let nft = registry::add_record(&mut registry, domain::new(utf8(b"test.sui")), 1, &clock, &mut ctx);
        let namespace = namespace::create_namespace_for_testing(&mut registry, &mut nft, &clock, &mut ctx);
        let expiration = nft::expiration_timestamp_ms(&nft);

        let subname = namespace::add_record(&mut namespace, &nft, expiration, true, true, utf8(b"1.test.sui"), &clock, &mut ctx);
        let subname1 = namespace::add_record(&mut namespace, sub_nft::borrow(&subname), expiration, true, true, utf8(b"1.1.test.sui"), &clock, &mut ctx);
        let subname2 = namespace::add_record(&mut namespace, sub_nft::borrow(&subname1), expiration, true, true, utf8(b"1.1.1.test.sui"), &clock, &mut ctx);
        let subname3 = namespace::add_record(&mut namespace, sub_nft::borrow(&subname2), expiration, true, true, utf8(b"1.1.1.1.test.sui"), &clock, &mut ctx);
        let subname4 = namespace::add_record(&mut namespace, sub_nft::borrow(&subname3), expiration, true, true, utf8(b"1.1.1.1.1.test.sui"), &clock, &mut ctx);
        let subname5 = namespace::add_record(&mut namespace, sub_nft::borrow(&subname4), expiration, true, true, utf8(b"1.1.1.1.1.1.test.sui"), &clock, &mut ctx);
        let subname6 = namespace::add_record(&mut namespace, sub_nft::borrow(&subname5), expiration, true, true, utf8(b"1.1.1.1.1.1.1.test.sui"), &clock, &mut ctx);
        
        abort 1337
    }

    #[test, expected_failure(abort_code=suins::namespace::EUnauthorizedNFT)]
    /// Tries to create a subdomain without first initializing a namespace.
    fun borrow_mut_without_parent_nft() {
        let ctx = tx_context::dummy();
        let (registry, clock, domain) = setup(&mut ctx);

        let nft = registry::add_record(&mut registry, domain::new(utf8(b"test.sui")), 1, &clock, &mut ctx);
        let expiration = nft::expiration_timestamp_ms(&nft);
        let namespace = namespace::create_namespace_for_testing(&mut registry, &mut nft, &clock, &mut ctx);

        let subname = namespace::add_record(&mut namespace, &nft, expiration, true, true, utf8(b"1.test.sui"), &clock, &mut ctx);

        let _uid_mut = namespace::uid_mut(&mut namespace, sub_nft::borrow(&subname));
    
        abort 1337
    }

    #[test, expected_failure(abort_code=suins::namespace::EUnauthorizedNFT)]
    /// Extend a namespace's expiration based on renewal of the parent SLD.
    fun extend_namespace_expiration_with_invalid_nft() {
        let ctx = tx_context::dummy();
        let (registry, clock, domain) = setup(&mut ctx);

        let nft = registry::add_record(&mut registry, domain, 1, &clock, &mut ctx);
        let nft2 = registry::add_record(&mut registry, domain::new(utf8(b"test2.sui")), 1, &clock, &mut ctx);
        let expiration = nft::expiration_timestamp_ms(&nft);

        let namespace = namespace::create_namespace_for_testing(&mut registry, &mut nft, &clock, &mut ctx);

        namespace::update_expiration(&mut namespace, &nft2);

        abort 1337
    }

    #[test, expected_failure(abort_code=suins::namespace::ETimeExtensionDisabled)]
    /// Extend a namespace's expiration based on renewal of the parent SLD.
    fun extend_expiration_while_not_allowed() {
        let ctx = tx_context::dummy();
        let (registry, clock, domain) = setup(&mut ctx);

        let nft = registry::add_record(&mut registry, domain, 1, &clock, &mut ctx);
        let expiration = nft::expiration_timestamp_ms(&nft) - 10;

        let namespace = namespace::create_namespace_for_testing(&mut registry, &mut nft, &clock, &mut ctx);

        let record = namespace::add_record(&mut namespace, &nft, expiration, false, false, utf8(b"1.hahaha.sui"), &clock, &mut ctx);

        namespace::extend_expiration(&mut namespace, sub_nft::borrow_mut(&mut record), expiration + 1);

        abort 1337
    }

    #[test, expected_failure(abort_code=suins::namespace::EInvalidExpirationDate)]
    fun extend_without_changing_output() {
        let ctx = tx_context::dummy();
        let (registry, clock, domain) = setup(&mut ctx);

        let nft = registry::add_record(&mut registry, domain, 1, &clock, &mut ctx);
        let expiration = nft::expiration_timestamp_ms(&nft) - 10;

        let namespace = namespace::create_namespace_for_testing(&mut registry, &mut nft, &clock, &mut ctx);

        let record = namespace::add_record(&mut namespace, &nft, expiration, false, true, utf8(b"1.hahaha.sui"), &clock, &mut ctx);

        namespace::extend_expiration(&mut namespace, sub_nft::borrow_mut(&mut record), expiration);

        abort 1337
    }

    #[test, expected_failure(abort_code=suins::namespace::EInvalidExpirationDate)]
    fun extend_exceeding_parent_failure() {
        let ctx = tx_context::dummy();
        let (registry, clock, domain) = setup(&mut ctx);

        let nft = registry::add_record(&mut registry, domain, 1, &clock, &mut ctx);
        let expiration = nft::expiration_timestamp_ms(&nft) - 10;

        let namespace = namespace::create_namespace_for_testing(&mut registry, &mut nft, &clock, &mut ctx);

        let record = namespace::add_record(&mut namespace, &nft, expiration, false, true, utf8(b"1.hahaha.sui"), &clock, &mut ctx);

        namespace::extend_expiration(&mut namespace, sub_nft::borrow_mut(&mut record), expiration + 11);

        abort 1337
    }

    #[test, expected_failure(abort_code=suins::namespace::ENamespaceMissmatch)]
    fun extend_on_wrong_namespace() {
        let ctx = tx_context::dummy();
        let (registry, clock, domain) = setup(&mut ctx);

        let nft = registry::add_record(&mut registry, domain, 1, &clock, &mut ctx);
        let nft2 = registry::add_record(&mut registry, domain::new(utf8(b"1.hahaha.sui")), 1, &clock, &mut ctx);
        let expiration = nft::expiration_timestamp_ms(&nft) - 10;

        let namespace = namespace::create_namespace_for_testing(&mut registry, &mut nft, &clock, &mut ctx);

        namespace::extend_expiration(&mut namespace, &mut nft2, expiration + 10);

        abort 1337
    }


    #[test, expected_failure(abort_code=suins::namespace::ERecordNotExpired)]
    fun override_leaf_record_with_no_expired_parent() {
        let ctx = tx_context::dummy();
        let (registry, clock, domain) = setup(&mut ctx);

        let nft = registry::add_record(&mut registry, domain, 1, &clock, &mut ctx);

        let namespace = namespace::create_namespace_for_testing(&mut registry, &mut nft, &clock, &mut ctx);

        namespace::add_leaf_record(&mut namespace, &nft, utf8(b"leaf.hahaha.sui"), &clock, USER, &mut ctx);
        namespace::add_leaf_record(&mut namespace, &nft, utf8(b"leaf.hahaha.sui"), &clock, USER, &mut ctx);

        abort 1337
    }

    #[test, expected_failure(abort_code=suins::namespace::ERecordNotExpired)]
    fun override_node_record_leaf_child_failure() {
        let ctx = tx_context::dummy();
        let (registry, clock, domain) = setup(&mut ctx);

        let nft = registry::add_record(&mut registry, domain, 1, &clock, &mut ctx);

        let namespace = namespace::create_namespace_for_testing(&mut registry, &mut nft, &clock, &mut ctx);
        
        let subname = namespace::add_record(&mut namespace, &nft, nft::expiration_timestamp_ms(&nft), true, true, utf8(b"nest.hahaha.sui"), &clock, &mut ctx);

        namespace::add_leaf_record(&mut namespace, sub_nft::borrow(&subname), utf8(b"more.nest.hahaha.sui"), &clock, USER, &mut ctx);
        namespace::add_leaf_record(&mut namespace, sub_nft::borrow(&subname), utf8(b"more.nest.hahaha.sui"), &clock, USER, &mut ctx);

        abort 1337
    }

    #[test, expected_failure(abort_code=suins::namespace::ERecordNotExpired)]
    fun override_node_that_has_not_expired() {
        let ctx = tx_context::dummy();
        let (registry, clock, domain) = setup(&mut ctx);

        let nft = registry::add_record(&mut registry, domain, 1, &clock, &mut ctx);

        let namespace = namespace::create_namespace_for_testing(&mut registry, &mut nft, &clock, &mut ctx);

        let subname = namespace::add_record(&mut namespace, &nft, nft::expiration_timestamp_ms(&nft), true, true, utf8(b"nest.hahaha.sui"), &clock, &mut ctx);
        let subname_2 = namespace::add_record(&mut namespace, &nft, nft::expiration_timestamp_ms(&nft), true, true, utf8(b"nest.hahaha.sui"), &clock, &mut ctx);

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
