#[test_only]
/// Testing strategy:
///
/// - test setters and values after updates
/// - make sure that new NFTs get correct a expiration setting
/// - IMPORTANT: test expiration timestamps and the grace period
///
module suins::registation_nft_tests {
    use std::string::{utf8, String};
    use sui::tx_context::{Self, TxContext};
    use sui::clock::{Self, Clock};
    use sui::test_utils::assert_eq;

    use suins::registration_nft::{Self as nft, RegistrationNFT};
    use suins::constants;
    use suins::domain;

    #[test]
    fun test_new() {
        let ctx = tx_context::dummy();
        let clock = clock::create_for_testing(&mut ctx);
        let nft = new(utf8(b"test.sui"), 1, &clock, &mut ctx);

        // expiration date for 1 year should be 365 days from now
        assert_eq(nft::expiration_timestamp_ms(&nft), 365 * 24 * 60 * 60 * 1000);
        assert_eq(nft::image_url(&nft), constants::default_image());
        assert_eq(nft::domain(&nft), domain::new(utf8(b"test.sui")));

        // bump the clock value to 1 year from now
        // and create a new NFT with expiration in 2 years + 1 ms
        clock::increment_for_testing(&mut clock, constants::year_ms() + 1);

        // test if the first NFT would have expired by then (but no grace period)
        assert_eq(nft::has_expired(&nft, &clock), true);
        assert_eq(nft::has_expired_with_grace(&nft, &clock), false);
        burn(nft);

        // create a new NFT with expiration in 2 years
        let nft = new(utf8(b"test.sui"), 2, &clock, &mut ctx);

        // expiration timestamp for 2 years (1 off) should be 3 * 365 days (and 1 ms) from now
        assert_eq(nft::expiration_timestamp_ms(&nft), 3 * constants::year_ms() + 1);
        burn(nft);

        clock::destroy_for_testing(clock);
    }

    #[test]
    fun test_update_values() {
        let ctx = tx_context::dummy();
        let clock = clock::create_for_testing(&mut ctx);
        let nft = new(utf8(b"test.sui"), 5, &clock, &mut ctx);

        nft::set_expiration_timestamp_ms_for_testing(&mut nft, 0);
        assert_eq(nft::expiration_timestamp_ms(&nft), 0);

        nft::update_image_url_for_testing(&mut nft, utf8(b"test_image_url"));
        assert_eq(nft::image_url(&nft), utf8(b"test_image_url"));

        clock::destroy_for_testing(clock);
        burn(nft);
    }

    // === Helpers ===

    fun new(
        domain_name: String,
        no_years: u8,
        clock: &Clock,
        ctx: &mut TxContext,
    ): RegistrationNFT {
        nft::new_for_testing(
            domain::new(domain_name),
            no_years,
            clock,
            ctx,
        )
    }

    fun burn(nft: RegistrationNFT) {
        nft::burn_for_testing(nft)
    }
}
