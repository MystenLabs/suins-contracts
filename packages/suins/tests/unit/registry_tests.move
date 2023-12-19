// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module suins::registry_tests {
    use std::string::utf8;
    use std::option::{Self, some};
    use std::vector;
    use sui::object;
    use sui::tx_context::{Self, TxContext};
    use sui::clock::{Self, Clock};
    use sui::test_utils::assert_eq;

    use suins::suins_registration::{Self as nft, SuinsRegistration};
    use suins::subdomain_registration::{Self as subdomain_nft, SubDomainRegistration};
    use suins::name_record as record;
    use suins::registry::{Self, Registry};
    use suins::domain::{Self, Domain};
    use suins::constants;

    // === Registry + Record Addition ===

    #[test]
    fun test_registry() {
        let ctx = tx_context::dummy();
        let (registry, clock, domain) = setup(&mut ctx);

        // create a record for the test domain with expiration set to 1 year
        let nft = registry::add_record(&mut registry, domain, 1, &clock, &mut ctx);

        // make sure that the nft matches the domain
        assert_eq(nft::domain(&nft), domain);
        assert_eq(registry::has_record(&registry, nft::domain(&nft)), true);

        // take the record and compare it against the nft
        let record = registry::remove_record_for_testing(&mut registry, domain);
        assert_eq(record::expiration_timestamp_ms(&record), nft::expiration_timestamp_ms(&nft));


        burn_nfts(vector[ nft ]);
        wrapup(registry, clock);
    }

    #[test]
    /// 1. Create a registry, increment clock to 1 year;
    /// 2. Increment the clock to 1 year so that the record is expired;
    /// 3. Override the record and discard the old data;
    fun test_registry_expired_override() {
        let ctx = tx_context::dummy();
        let (registry, clock, domain) = setup(&mut ctx);

        // create a record for the test domain with expiration set to 1 year
        let nft = registry::add_record(&mut registry, domain, 1, &clock, &mut ctx);

        // increment the clock to 1 years + grace period
        clock::increment_for_testing(&mut clock, constants::year_ms() + constants::grace_period_ms() + 1);

        // override the record
        let nft_2 = registry::add_record(&mut registry, domain, 2, &clock, &mut ctx);
        let record = registry::remove_record_for_testing(&mut registry, domain);

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
        let ctx = tx_context::dummy();
        let (registry, clock, domain) = setup(&mut ctx);

        // create a record for the test domain with expiration set to 1 year
        let _nft = registry::add_record(&mut registry, domain, 1, &clock, &mut ctx);

        // try to override the record and fail - not expired
        let _nft = registry::add_record(&mut registry, domain, 1, &clock, &mut ctx);

        abort 1337
    }

    // === Target Address ===

    #[test]
    /// 1. Create a registry, add a record;
    /// 2. Call `set_target_address` and make sure that the address is set;
    /// 3. Check target address lookup; check that record has correct target;
    fun set_target_address() {
        let ctx = tx_context::dummy();
        let (registry, clock, domain) = setup(&mut ctx);

        // create a record for the test domain with expiration set to 1 year
        let nft = registry::add_record(&mut registry, domain, 1, &clock, &mut ctx);
        registry::set_target_address(&mut registry, domain, some(@0x2));

        // try to find a record and then get a record
        let search = registry::lookup(&registry, domain);
        let record = registry::remove_record_for_testing(&mut registry, domain);

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
        let ctx = tx_context::dummy();
        let (registry, clock, domain) = setup(&mut ctx);
        let nft = registry::add_record(&mut registry, domain, 1, &clock, &mut ctx);

        // set the `domain` points to @0x0; set the reverse lookup too
        registry::set_target_address(&mut registry, domain, some(@0xB0B));
        registry::set_reverse_lookup(&mut registry, @0xB0B, domain);

        // search for the reverse_lookup record
        let search = registry::reverse_lookup(&registry, @0xB0B);

        assert!(option::is_some(&search), 0);
        assert!(option::extract(&mut search) == domain, 0);

        // wrapup
        registry::unset_reverse_lookup(&mut registry, @0xB0B);
        let _ = registry::remove_record_for_testing(&mut registry, domain);

        wrapup(registry, clock);
        burn_nfts(vector[ nft ]);
    }

    #[test]
    /// `burn_registration_object` burns the SuinsRegistration object as well as removes the record, 
    /// since it still points to the old owner.
    fun test_registry_burn_name_and_removes_record() {
        let ctx = tx_context::dummy();
        let (registry, clock, domain) = setup(&mut ctx);

        // create a record for the test domain with expiration set to 1 year
        let nft = registry::add_record(&mut registry, domain, 1, &clock, &mut ctx);

        // increment the clock to 1 years + grace period
        clock::increment_for_testing(&mut clock, constants::year_ms() + constants::grace_period_ms() + 1);

        // we burn the first one as it is an expired name now.
        registry::burn_registration_object(&mut registry, nft, &clock);

        // we still have a registry entry though, it's not removed as the owner is different.
        assert!(option::is_none(&registry::lookup(&registry, domain)), 1);

        wrapup(registry, clock);
    }

    #[test, expected_failure(abort_code = suins::registry::ETargetNotSet)]
    /// 1. Create a registry, add a record;
    /// 2. Try calling `set_reverse_lookup` and fail
    fun set_reverse_lookup_fail_target_not_set() {
        let ctx = tx_context::dummy();
        let (registry, clock, domain) = setup(&mut ctx);
        let _nft = registry::add_record(&mut registry, domain, 1, &clock, &mut ctx);

        // set the `domain` points to @0x0
        registry::set_reverse_lookup(&mut registry, @0x0, domain);

        abort 1337
    }

    #[test, expected_failure(abort_code = suins::registry::ERecordMismatch)]
    /// 1. Create a registry, add a record;
    /// 2. Set target_address to address Alice
    /// 2. Try calling `set_reverse_lookup` and use address Bob
    fun set_reverse_lookup_fail_record_mismatch() {
        let ctx = tx_context::dummy();
        let (registry, clock, domain) = setup(&mut ctx);
        let _nft = registry::add_record(&mut registry, domain, 1, &clock, &mut ctx);

        // set the `domain` points to @0x0
        registry::set_target_address(&mut registry, domain, some(@0xB0B));
        registry::set_reverse_lookup(&mut registry, @0xA11CE, domain);

        abort 1337
    }

    #[test]
    fun burn_expired_suins_registration() {
        let ctx = tx_context::dummy();
        let (registry, clock, domain) = setup(&mut ctx);
        let nft = registry::add_record(&mut registry, domain, 1, &clock, &mut ctx);
        // increment the clock to 1 years + grace period
        clock::increment_for_testing(&mut clock, constants::year_ms() + 1);

        // burn the registration object
        registry::burn_registration_object(&mut registry, nft, &clock);

        let name = registry::lookup(&registry, domain);
        assert!(option::is_none(&name), 0);

        wrapup(registry, clock);
    }

    #[test]
    fun burn_expired_registration_without_overriding() {
        let ctx = tx_context::dummy();
        let (registry, clock, domain) = setup(&mut ctx);
        let nft = registry::add_record(&mut registry, domain, 1, &clock, &mut ctx);
        // increment the clock to 1 years + grace period
        clock::increment_for_testing(&mut clock, constants::year_ms() + constants::grace_period_ms() + 1);

        // re-register 
        let new_nft_post_expiration = registry::add_record(&mut registry, domain, 1, &clock, &mut ctx);

        // burn the expired object
        registry::burn_registration_object(&mut registry, nft, &clock);

        // Validate that the record still exists (no invalidation happened), 
        // since the name was bought again after this.
        let name = registry::lookup(&registry, domain);
        assert!(option::is_some(&name), 0);

        wrapup_non_empty(registry, clock);
        burn_nfts(vector[ new_nft_post_expiration]);
    }

    #[test, expected_failure(abort_code = suins::registry::ERecordNotExpired)]
    fun burn_non_expired_domain_failure() {
        let ctx = tx_context::dummy();
        let (registry, clock, domain) = setup(&mut ctx);
        let nft = registry::add_record(&mut registry, domain, 1, &clock, &mut ctx);

                // burn the expired object
        registry::burn_registration_object(&mut registry, nft, &clock);

        abort 1337
    }

    // === XXX ===


    // === Helpers ===

    public fun setup(ctx: &mut TxContext): (Registry, Clock, Domain) {
        (
            registry::new_for_testing(ctx),
            clock::create_for_testing(ctx),
            domain::new(utf8(b"hahaha.sui"))
        )
    }

    public fun wrapup(registry: Registry, clock: Clock) {
        registry::destroy_empty_for_testing(registry);
        clock::destroy_for_testing(clock);
    }

    public fun wrapup_non_empty(registry: Registry, clock: Clock) {
        registry::destroy_for_testing(registry);
        clock::destroy_for_testing(clock);
    }

    public fun burn_nfts(nfts: vector<SuinsRegistration>) {
        while (vector::length(&nfts) > 0) {
            nft::burn_for_testing(vector::pop_back(&mut nfts));
        };
        vector::destroy_empty(nfts);
    }

    public fun burn_subname_nfts(nfts: vector<SubDomainRegistration>, clock: &Clock) {
        while (vector::length(&nfts) > 0) {
            let nft = subdomain_nft::destroy_for_testing(vector::pop_back(&mut nfts));
            nft::burn_for_testing(nft);
        };
        vector::destroy_empty(nfts);
    }
}
