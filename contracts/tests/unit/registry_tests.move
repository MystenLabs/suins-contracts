#[test_only]
///
module suins::registry_tests {
    use std::string::utf8;
    use sui::tx_context;
    use sui::clock; // ::{Self, Clock};
    use sui::test_utils::assert_eq;

    use suins::registration_nft::{Self as nft};
    use suins::name_record as record;
    use suins::registry;
    use suins::domain;

    #[test]
    fun test_registry() {
        let ctx = tx_context::dummy();
        let clock = clock::create_for_testing(&mut ctx);
        let domain = domain::new(utf8(b"hahaha.sui"));
        let registry = registry::new_for_testing(&mut ctx);

        // create a record for the test domain with expiration set to 1 year
        let nft = registry::add_record(&mut registry, domain, 1, &clock, &mut ctx);

        // make sure that the nft matches the domain
        assert_eq(nft::domain(&nft), domain);
        assert_eq(registry::has_record(&registry, nft::domain(&nft)), true);

        // take the record and compare it against the nft
        let record = registry::remove_record_for_testing(&mut registry, domain);
        assert_eq(record::expiration_timestamp_ms(&record), nft::expiration_timestamp_ms(&nft));

        registry::destroy_empty_for_testing(registry);
        clock::destroy_for_testing(clock);
        nft::burn_for_testing(nft);
    }
}
