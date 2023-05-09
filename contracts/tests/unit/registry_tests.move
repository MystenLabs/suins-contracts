#[test_only]
///
module suins::registry_tests {
    use std::string::utf8;
    use std::vector;
    use sui::object;
    use sui::tx_context::{Self, TxContext};
    use sui::clock::{Self, Clock};
    use sui::test_utils::assert_eq;

    use suins::registration_nft::{Self as nft, RegistrationNFT};
    use suins::name_record as record;
    use suins::registry::{Self, Registry};
    use suins::domain::{Self, Domain};
    use suins::constants;

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
        clock::destroy_for_testing(clock);
    }

    fun burn_nfts(nfts: vector<RegistrationNFT>) {
        while (vector::length(&nfts) > 0) {
            nft::burn_for_testing(vector::pop_back(&mut nfts));
        };
        vector::destroy_empty(nfts);
    }
}
