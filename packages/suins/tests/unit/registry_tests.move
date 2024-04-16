// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module suins::registry_tests {
    use std::{string::utf8, option::{some}};
    use sui::{clock::{Self, Clock}, test_utils::assert_eq};

    use suins::{
        suins_registration::{Self as nft, SuinsRegistration}, 
        name_record as record, 
        registry::{Self, Registry}, 
        domain::{Self, Domain}, constants
    };

    // === Registry + Record Addition ===

    #[test]
    fun test_registry() {
        let mut ctx = tx_context::dummy();
        let (mut registry, clock, domain) = setup(&mut ctx);

        // create a record for the test domain with expiration set to 1 year
        let nft = registry.add_record(domain, 1, &clock, &mut ctx);

        // make sure that the nft matches the domain
        assert_eq(nft.domain(), domain);
        assert_eq(registry.has_record(nft.domain()), true);

        // take the record and compare it against the nft
        let record = registry.remove_record_for_testing(domain);
        assert_eq(record.expiration_timestamp_ms(), nft.expiration_timestamp_ms());


        burn_nfts(vector[ nft ]);
        wrapup(registry, clock);
    }

    #[test]
    /// 1. Create a normal record that acts as a parent
    /// 2. Add a leaf subdomain for that parent
    /// 3. Validate valid scenarios of using that leaf_node.
    fun test_leaf_records() {
        let mut ctx = tx_context::dummy();
        let (mut registry, clock, domain) = setup(&mut ctx);

        // leaf subdomain to be added
        let subdomain_one = domain::new(utf8(b"test.hahaha.sui"));

        // create a record for the test domain with expiration set to 1 year
        let nft = registry.add_record(domain, 1, &clock, &mut ctx);

        // register a leaf record and set the target to @0x0
        registry.add_leaf_record(subdomain_one, &clock, @0x0, &mut ctx);
    
        // set the reverse_Registry of @0x0 to be that leaf subdomain
        registry.set_reverse_lookup(@0x0, subdomain_one);

        let name_record = option::extract(&mut registry.lookup(subdomain_one));
        // validate that the parent nft_id is the same as the leaf's one.
        assert_eq(object::id(&nft), name_record.nft_id());

        // Reverse lookup should work as expected, since it's set.
        let name = option::extract(&mut registry.reverse_lookup(@0x0));
        assert!(name == subdomain_one, 0);

        // remove leaf_record to test removal too
        registry.remove_leaf_record(subdomain_one);

        // validate that now @0x0 doesn't have a reverse lookup anymore.
        let res = registry::reverse_lookup(&registry, @0x0);
        assert!(option::is_none(&res), 0);

        burn_nfts(vector[ nft ]);
        wrapup_non_empty(registry, clock);
    }

    #[test]
    /// Overrides a leaf record (by just adding it again) as a new domain owner, 
    /// while this leaf name existed before.
    fun override_leaf_record_after_change_of_parent_owner() {
        let mut ctx = tx_context::dummy();
        let (mut registry, mut clock, _domain) = setup(&mut ctx);

        let nft = registry.add_record(domain::new(utf8(b"test.sui")), 1, &clock, &mut ctx);

        // add 2 leaf records as nft
        registry.add_leaf_record(domain::new(utf8(b"test.test.sui")), &clock, @0x0, &mut ctx);
        registry.add_leaf_record(domain::new(utf8(b"test2.test.sui")), &clock, @0x0, &mut ctx);

        // increment the clock to 1 years + grace period
        clock::increment_for_testing(&mut clock, constants::year_ms() + constants::grace_period_ms() + 1);

        // become a new owner, `new_oner_nft`
        let new_owner_nft = registry.add_record(domain::new(utf8(b"test.sui")), 1, &clock, &mut ctx);

        // override both leaf records, one with a node subdomain, the other iwth a leaf subdomain 
        let normal_subdomain_override = registry.add_record_ignoring_grace_period(domain::new(utf8(b"test.test.sui")), 1, &clock, &mut ctx);
        registry.add_leaf_record(domain::new(utf8(b"test2.test.sui")), &clock, @0x1, &mut ctx);

        burn_nfts(vector[ nft, new_owner_nft, normal_subdomain_override ]);
        wrapup_non_empty(registry, clock);
    }

    #[test]
    /// 1. Create a registry, increment clock to 1 year;
    /// 2. Increment the clock to 1 year so that the record is expired;
    /// 3. Override the record and discard the old data;
    fun test_registry_expired_override() {
        let mut ctx = tx_context::dummy();
        let (mut registry, mut clock, domain) = setup(&mut ctx);

        // create a record for the test domain with expiration set to 1 year
        let nft = registry.add_record(domain, 1, &clock, &mut ctx);

        // increment the clock to 1 years + grace period
        clock::increment_for_testing(&mut clock, constants::year_ms() + constants::grace_period_ms() + 1);

        // override the record
        let nft_2 = registry.add_record(domain, 2, &clock, &mut ctx);
        let record = registry.remove_record_for_testing(domain);

        // make sure the old NFT is no longer matches to the domain
        assert!(object::id(&nft) != record::nft_id(&record), 0);

        assert_eq(nft::expiration_timestamp_ms(&nft_2), record::expiration_timestamp_ms(&record));
        assert_eq(nft::expiration_timestamp_ms(&nft_2), clock::timestamp_ms(&clock) + (2 * constants::year_ms()));

        wrapup(registry, clock);
        burn_nfts(vector[ nft, nft_2 ])
    }

    #[test]
    /// 1. Create a registry, increment clock to 1 year;
    /// 2. Increment the clock to 1 year so that the record is expired, ignoring the grace period
    /// 3. Override the record and discard the old data;
    fun test_registry_expired_without_grace_period_override() {
        let mut ctx = tx_context::dummy();
        let (mut registry, mut clock, domain) = setup(&mut ctx);

        // create a record for the test domain with expiration set to 1 year
        let nft = registry.add_record(domain, 1, &clock, &mut ctx);

        // increment the clock to 1 years + grace period
        clock::increment_for_testing(&mut clock, constants::year_ms() + 1);

        // override the record
        let nft_2 = registry.add_record_ignoring_grace_period(domain, 2, &clock, &mut ctx);
        let record = registry.remove_record_for_testing(domain);

        // make sure the old NFT is no longer matches to the domain
        assert!(object::id(&nft) != record::nft_id(&record), 0);

        assert_eq(nft::expiration_timestamp_ms(&nft_2), record::expiration_timestamp_ms(&record));
        assert_eq(nft::expiration_timestamp_ms(&nft_2), clock::timestamp_ms(&clock) + (2 * constants::year_ms()));

        wrapup(registry, clock);
        burn_nfts(vector[ nft, nft_2 ])
    }

    #[test, expected_failure(abort_code = suins::registry::ERecordNotExpired)]
    /// 1. Create a registry, increment clock to 1 year;
    /// 2. Increment the clock to less than 1 year so that the record is expired;
    /// 3. Try to override the record and fail - not expired;
    fun test_registry_expired_override_fail() {
        let mut ctx = tx_context::dummy();
        let (mut registry, clock, domain) = setup(&mut ctx);

        // create a record for the test domain with expiration set to 1 year
        let _nft = registry.add_record(domain, 1, &clock, &mut ctx);

        // try to override the record and fail - not expired
        let _nft = registry.add_record(domain, 1, &clock, &mut ctx);

        abort 1337
    }

    #[test, expected_failure(abort_code = suins::registry::ERecordNotExpired)]
    /// Check that `add_record` preserves the 
    fun test_registry_grace_period() {
        let mut ctx = tx_context::dummy();
        let (mut registry, mut clock, domain) = setup(&mut ctx);

        // create a record for the test domain with expiration set to 1 year
        let _nft = registry.add_record(domain, 1, &clock, &mut ctx);
        // increment the clock to 1 years + grace period
        clock::increment_for_testing(&mut clock, constants::year_ms() + 1);
        // try to override the record and fail - not expired
        let _nft = registry.add_record(domain, 1, &clock, &mut ctx);

        abort 1337
    }

    // === Burn Names === 

    #[test]
    /// Checks that `burn_registration_object` burns `SuinsRegistration` object
    /// but doesn't touch the NameRecord, as this name has been re-registered by a different user (after its expiration).
    fun test_registry_burn_name() {
        let mut ctx = tx_context::dummy();
        let (mut registry, mut clock, domain) = setup(&mut ctx);

        // create a record for the test domain with expiration set to 1 year
        let nft = registry.add_record(domain, 1, &clock, &mut ctx);

        // increment the clock to 1 years + grace period
        clock::increment_for_testing(&mut clock, constants::year_ms() + constants::grace_period_ms() + 1);

        // we re-register the same domain now that the other has expired.
        let new_nft = registry.add_record(domain, 1, &clock, &mut ctx);

        // we burn the first one as it is an expired name now.
        registry.burn_registration_object(nft, &clock);

        // we still have a registry entry though, it's not removed as the owner is different.
        assert!(option::is_some(&registry.lookup(domain)), 1);

        // remove the record so we can wrap this up.
        registry.remove_record_for_testing(domain);

        wrapup(registry, clock);
        burn_nfts(vector[new_nft]);
    }

    #[test]
    /// `burn_registration_object` burns the SuinsRegistration object as well as removes the record, 
    /// since it still points to the old owner.
    fun test_registry_burn_name_and_removes_record() {
        let mut ctx = tx_context::dummy();
        let (mut registry, mut clock, domain) = setup(&mut ctx);

        // create a record for the test domain with expiration set to 1 year
        let nft = registry.add_record(domain, 1, &clock, &mut ctx);

        // increment the clock to 1 years + grace period
        clock::increment_for_testing(&mut clock, constants::year_ms() + constants::grace_period_ms() + 1);

        // we burn the first one as it is an expired name now.
        registry.burn_registration_object(nft, &clock);

        // we still have a registry entry though, it's not removed as the owner is different.
        assert!(option::is_none(&registry.lookup(domain)), 1);

        wrapup(registry, clock);
    }

    // === Target Address ===

    #[test]
    /// 1. Create a registry, add a record;
    /// 2. Call `set_target_address` and make sure that the address is set;
    /// 3. Check target address lookup; check that record has correct target;
    fun set_target_address() {
        let mut ctx = tx_context::dummy();
        let (mut registry, clock, domain) = setup(&mut ctx);

        // create a record for the test domain with expiration set to 1 year
        let nft = registry.add_record(domain, 1, &clock, &mut ctx);
        registry.set_target_address(domain, some(@0x2));

        // try to find a record and then get a record
        let mut search = registry.lookup(domain);
        let record = registry.remove_record_for_testing(domain);

        // make sure the search is a success
        assert!(option::is_some(&search), 0);
        assert_eq(option::extract(&mut search), record);
        assert_eq(record::target_address(&record), some(@0x2));

        wrapup(registry, clock);
        burn_nfts(vector[ nft ]);
    }

    // === Reverse Lookup ===

    #[test]
    /// 1. Create a registry, add a record;
    /// 2. Call `set_target_address` and make sure that the address is set;
    /// 3. Call `set_reverse_lookup` and make sure that reverse registry updated;
    fun set_reverse_lookup() {
        let mut ctx = tx_context::dummy();
        let (mut registry, clock, domain) = setup(&mut ctx);
        let nft = registry.add_record(domain, 1, &clock, &mut ctx);

        // set the `domain` points to @0x0; set the reverse lookup too
        registry.set_target_address(domain, some(@0xB0B));
        registry.set_reverse_lookup(@0xB0B, domain);

        // search for the reverse_lookup record
        let mut search = registry::reverse_lookup(&registry, @0xB0B);

        assert!(option::is_some(&search), 0);
        assert!(option::extract(&mut search) == domain, 0);

        // wrapup
        registry.unset_reverse_lookup(@0xB0B);
        let _ = registry.remove_record_for_testing(domain);

        wrapup(registry, clock);
        burn_nfts(vector[ nft ]);
    }

    #[test]
    fun burn_expired_subdomain() {
        let mut ctx = tx_context::dummy();
        let (mut registry, mut clock, _domain) = setup(&mut ctx);
        
        let nft = registry.add_record(domain::new(utf8(b"node.test.sui")), 1, &clock, &mut ctx);

        let subdomain = registry.wrap_subdomain(nft, &clock, &mut ctx);

        clock::increment_for_testing(&mut clock, constants::year_ms() + 1);

        registry.burn_subdomain_object(subdomain, &clock);

        wrapup(registry, clock);
    }

    #[test]
    fun burn_expired_suins_registration() {
        let mut ctx = tx_context::dummy();
        let (mut registry, mut clock, domain) = setup(&mut ctx);
        let nft = registry.add_record(domain, 1, &clock, &mut ctx);
        // increment the clock to 1 years + grace period
        clock::increment_for_testing(&mut clock, constants::year_ms() + 1);

        // burn the registration object
        registry.burn_registration_object(nft, &clock);

        let name = registry.lookup(domain);
        assert!(option::is_none(&name), 0);
        
        wrapup(registry, clock);
    }

    #[test]
    fun burn_expired_registration_without_overriding() {
        let mut ctx = tx_context::dummy();
        let (mut registry, mut clock, domain) = setup(&mut ctx);
        let nft = registry.add_record(domain, 1, &clock, &mut ctx);
        // increment the clock to 1 years + grace period
        clock::increment_for_testing(&mut clock, constants::year_ms() + constants::grace_period_ms() + 1);
        
        // re-register 
        let new_nft_post_expiration = registry.add_record(domain, 1, &clock, &mut ctx);

        // burn the expired object
        registry.burn_registration_object(nft, &clock);

        // Validate that the record still exists (no invalidation happened),
        // since the name was bought again after this.
        let name = registry.lookup(domain);
        assert!(option::is_some(&name), 0);
        
        wrapup_non_empty(registry, clock);
        burn_nfts(vector[ new_nft_post_expiration]);
    }

    #[test, expected_failure(abort_code = suins::registry::ETargetNotSet)]
    /// 1. Create a registry, add a record;
    /// 2. Try calling `set_reverse_lookup` and fail
    fun set_reverse_lookup_fail_target_not_set() {
        let mut ctx = tx_context::dummy();
        let (mut registry, clock, domain) = setup(&mut ctx);
        let _nft = registry.add_record(domain, 1, &clock, &mut ctx);

        // set the `domain` points to @0x0
        registry.set_reverse_lookup(@0x0, domain);

        abort 1337
    }

    #[test, expected_failure(abort_code = suins::registry::ERecordMismatch)]
    /// 1. Create a registry, add a record;
    /// 2. Set target_address to address Alice
    /// 2. Try calling `set_reverse_lookup` and use address Bob
    fun set_reverse_lookup_fail_record_mismatch() {
        let mut ctx = tx_context::dummy();
        let (mut registry, clock, domain) = setup(&mut ctx);
        let _nft = registry.add_record(domain, 1, &clock, &mut ctx);

        // set the `domain` points to @0x0
        registry.set_target_address(domain, some(@0xB0B));
        registry.set_reverse_lookup(@0xA11CE, domain);

        abort 1337
    }

    #[test, expected_failure(abort_code = suins::registry::EInvalidDepth)]
    /// Attempt to add a SLD record as a `leaf` record.
    fun add_sld_as_leaf_record_failure() {
        let mut ctx = tx_context::dummy();
        let (mut registry, clock, _domain) = setup(&mut ctx);

        registry.add_leaf_record(domain::new(utf8(b"test.sui")), &clock,@0x0, &mut ctx);

        abort 1337
    }

    #[test, expected_failure(abort_code = suins::registry::ERecordNotFound)]
   /// Attempt to add a leaf record without a valid parent existing.
    fun add_leaf_record_without_valid_parent_failure() {
        let mut ctx = tx_context::dummy();
        let (mut registry, clock, _domain) = setup(&mut ctx);

        registry.add_leaf_record(domain::new(utf8(b"test.test.sui")), &clock,@0x0, &mut ctx);

        abort 1337
    }

    #[test, expected_failure(abort_code = suins::registry::ENotLeafRecord)]
   /// Attempts to remove a non leaf record.
    fun remove_non_leaf_record_failure() {
        let mut ctx = tx_context::dummy();
        let (mut registry, clock, _domain) = setup(&mut ctx);

        let _nft = registry.add_record(domain::new(utf8(b"test.test.sui")), 1, &clock, &mut ctx);

         registry.remove_leaf_record(domain::new(utf8(b"test.test.sui")));

        abort 1337
    }

    #[test, expected_failure(abort_code = suins::registry::ERecordNotExpired)]
    /// Tries to add a `leaf` record on-top of an existing subdomain (fails).
    fun try_to_override_existing_node_subdomain() {
        let mut ctx = tx_context::dummy();
        let (mut registry, clock, _domain) = setup(&mut ctx);

        let _nft = registry.add_record(domain::new(utf8(b"test.sui")), 1, &clock, &mut ctx);
        let _existing = registry.add_record(domain::new(utf8(b"test.test.sui")), 1, &clock, &mut ctx);
        
        registry.add_leaf_record(domain::new(utf8(b"test.test.sui")), &clock,@0x0, &mut ctx);

        abort 1337
    }

    #[test, expected_failure(abort_code = suins::registry::ERecordNotExpired)]
    /// Tries to add a `node` record on-top of an existing subdomain (fails).
    fun try_to_override_existing_leaf_subdomain() {
        let mut ctx = tx_context::dummy();
        let (mut registry, clock, _domain) = setup(&mut ctx);

        let _nft = registry.add_record(domain::new(utf8(b"test.sui")), 1, &clock, &mut ctx);

        registry.add_leaf_record(domain::new(utf8(b"test.test.sui")), &clock,@0x0, &mut ctx);

        let _existing = registry.add_record_ignoring_grace_period(domain::new(utf8(b"test.test.sui")), 1, &clock, &mut ctx);
    

        abort 1337
    }

    #[test, expected_failure(abort_code = suins::registry::ERecordNotExpired)]
    fun burn_non_expired_domain_failure() {
        let mut ctx = tx_context::dummy();
        let (mut registry, clock, domain) = setup(&mut ctx);
        let nft = registry.add_record(domain, 1, &clock, &mut ctx);

                // burn the expired object
        registry.burn_registration_object(nft, &clock);

        abort 1337
    }

    // === XXX ===


    // === Helpers ===

    fun setup(ctx: &mut TxContext): (Registry, Clock, Domain) {
        (
            registry::new_for_testing(ctx),
            clock::create_for_testing(ctx),
            domain::new(utf8(b"hahaha.sui"))
        )
    }

    fun wrapup(registry: Registry, clock: Clock) {
        registry::destroy_empty_for_testing(registry);
        clock.destroy_for_testing();
    }

    fun wrapup_non_empty(registry: Registry, clock: Clock) {
        registry::destroy_for_testing(registry);
        clock.destroy_for_testing();
    }
    
    #[test_only] 
    public fun burn_nfts(mut nfts: vector<SuinsRegistration>) {
        while (vector::length(&nfts) > 0) {
            nft::burn_for_testing(vector::pop_back(&mut nfts));
        };
        vector::destroy_empty(nfts);
    }
}
