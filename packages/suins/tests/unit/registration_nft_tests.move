// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
/// Testing strategy:
///
/// - test setters and values after updates
/// - make sure that new NFTs get correct a expiration setting
/// - IMPORTANT: test expiration timestamps and the grace period
///
module suins::registation_nft_tests {
    use std::string::{utf8, String};
    use sui::{clock::{Self, Clock}, test_utils::assert_eq};

    use suins::{suins_registration::{Self as nft, SuinsRegistration}, constants, domain};

    #[test]
    fun test_new() {
        let mut ctx = tx_context::dummy();
        let mut clock = clock::create_for_testing(&mut ctx);
        let nft = new(utf8(b"test.sui"), 1, &clock, &mut ctx);

        // expiration date for 1 year should be 365 days from now
        assert_eq(nft.expiration_timestamp_ms(), 365 * 24 * 60 * 60 * 1000);
        assert_eq(nft.image_url(), constants::default_image());
        assert_eq(nft.domain(), domain::new(utf8(b"test.sui")));

        // bump the clock value to 1 year from now
        // and create a new NFT with expiration in 2 years + 1 ms
        clock.increment_for_testing(constants::year_ms() + 1);

        // test if the first NFT would have expired by then (but no grace period)
        assert_eq(nft.has_expired(&clock), true);
        assert_eq(nft.has_expired_past_grace_period(&clock), false);
        burn(nft);

        // create a new NFT with expiration in 2 years
        let nft = new(utf8(b"test.sui"), 2, &clock, &mut ctx);

        // expiration timestamp for 2 years (1 off) should be 3 * 365 days (and 1 ms) from now
        assert_eq(nft.expiration_timestamp_ms(), 3 * constants::year_ms() + 1);
        burn(nft);

        clock.destroy_for_testing();
    }

    #[test]
    fun test_update_values() {
        let mut ctx = tx_context::dummy();
        let clock = clock::create_for_testing(&mut ctx);
        let mut nft = new(utf8(b"test.sui"), 5, &clock, &mut ctx);

        nft.set_expiration_timestamp_ms_for_testing(0);
        assert_eq(nft.expiration_timestamp_ms(), 0);

        nft.update_image_url_for_testing(utf8(b"test_image_url"));
        assert_eq(nft.image_url(), utf8(b"test_image_url"));

        clock.destroy_for_testing();
        burn(nft);
    }

    // === Helpers ===

    fun new(
        domain_name: String,
        no_years: u8,
        clock: &Clock,
        ctx: &mut TxContext,
    ): SuinsRegistration {
        nft::new_for_testing(
            domain::new(domain_name),
            no_years,
            clock,
            ctx,
        )
    }

    fun burn(nft: SuinsRegistration) {
        nft.burn_for_testing()
    }
}
