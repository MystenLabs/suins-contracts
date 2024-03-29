// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module renewal::renew_tests {
    use std::string::utf8;

    use sui::coin;
    use sui::sui::SUI;
    use sui::clock::{Self, Clock};
    use sui::tx_context::{Self, TxContext};

    use suins::constants::{mist_per_sui, year_ms, grace_period_ms};
    use suins::suins::{Self, SuiNS};
    use suins::suins_registration::{Self as nft, SuinsRegistration};
    use suins::registry;
    use suins::domain;
    use suins::config;

    use renewal::renew::{Self as renewal, Renew};

    const REGULAR_PRICE: u64 = 35;

    const DOMAIN_NAME: vector<u8> = b"12345.sui";

    #[test]
    fun regular_renewal_5_years() {
        let mut ctx = tx_context::dummy();
        let (mut suins, mut nft) = prepare_registry(&mut ctx);

        let mut clock = clock::create_for_testing(&mut ctx);

        clock.increment_for_testing(10);

        renew_util(&mut suins, &mut nft, 5, &clock, &mut ctx);

        // our fresh domain with 5 years renewal is now 6 years
        assert!(nft.expiration_timestamp_ms() == clock.timestamp_ms() + (6 * year_ms()) - 10, 0);

        clock.destroy_for_testing();

        wrapup(suins);
        wrapup_name(nft);
    }

    #[test, expected_failure(abort_code= ::renewal::renew::EMoreThanSixYears)]
    fun fail_to_go_beyond_6_years() {
        let mut ctx = tx_context::dummy();
        let (mut suins, mut nft) = prepare_registry(&mut ctx);

        let clock = clock::create_for_testing(&mut ctx);
        
        renew_util(&mut suins, &mut nft, 2, &clock, &mut ctx);
        renew_util(&mut suins, &mut nft, 4, &clock, &mut ctx);
        abort 1337
    }

    #[test, expected_failure(abort_code= ::renewal::renew::EInvalidYearsArgument)]
    fun fail_invalid_arg() {
        let mut ctx = tx_context::dummy();
        let (mut suins, mut nft) = prepare_registry(&mut ctx);

        let clock = clock::create_for_testing(&mut ctx);
        
        renew_util(&mut suins, &mut nft, 6, &clock, &mut ctx);
        abort 1337
    }


    #[test, expected_failure(abort_code= ::renewal::renew::ERecordNftIDMismatch)]
    fun failed_record_id_missmatch() {
        let mut ctx = tx_context::dummy();
        let (mut suins, _nft) = prepare_registry(&mut ctx);
        let clock = clock::create_for_testing(&mut ctx);
        let mut nft = nft::new_for_testing(domain::new(utf8(DOMAIN_NAME)), 1, &clock, &mut ctx);
        
        renew_util(&mut suins, &mut nft, 3, &clock, &mut ctx);
        abort 1337
    }

    #[test, expected_failure(abort_code= ::renewal::renew::ERecordNotFound)]
    fun failed_record_not_exist() {
        let mut ctx = tx_context::dummy();
        let (mut suins, _nft) = prepare_registry(&mut ctx);
        let clock = clock::create_for_testing(&mut ctx);
        let mut nft = nft::new_for_testing(domain::new(utf8(b"hehehe.sui")), 1, &clock, &mut ctx);
        
        renew_util(&mut suins, &mut nft, 3, &clock, &mut ctx);
        abort 1337
    }

    #[test, expected_failure(abort_code= ::renewal::renew::ERecordExpired)]
    fun failed_expired_record() {
        let mut ctx = tx_context::dummy();
        let (mut suins, mut nft) = prepare_registry(&mut ctx);
        let mut clock = clock::create_for_testing(&mut ctx);
        
        clock::increment_for_testing(&mut clock, year_ms() + grace_period_ms() + 1);

        renew_util(&mut suins, &mut nft, 1, &clock, &mut ctx);
        abort 1337
    }

    #[test, expected_failure(abort_code= ::renewal::renew::EIncorrectAmount)]
    fun failed_not_enough_money() {
        let mut ctx = tx_context::dummy();
        let (mut suins, mut nft) = prepare_registry(&mut ctx);
        let clock = clock::create_for_testing(&mut ctx);
        
        renewal::renew(&mut suins, &mut nft, 2,coin::mint_for_testing<SUI>((1 as u64) * REGULAR_PRICE * mist_per_sui(), &mut ctx), &clock);
        abort 1337
    }
    
    public fun renew_util(suins: &mut SuiNS, nft: &mut SuinsRegistration, no_years: u8, clock: &Clock, ctx: &mut TxContext) {
        renewal::renew(suins, nft, no_years,coin::mint_for_testing<SUI>((no_years as u64) * REGULAR_PRICE * mist_per_sui(), ctx), clock);
    }

    /// Local test to prepare a registry with a domain. 
    /// Authorizes registry, adds domain, and burns admin cap.
    public fun prepare_registry(ctx: &mut TxContext): (SuiNS, SuinsRegistration) {

        let mut suins = suins::init_for_testing(ctx);
        let mut registry = registry::new_for_testing(ctx);

        let domain = domain::new(utf8(DOMAIN_NAME));        
        suins::authorize_app_for_testing<Renew>(&mut suins);

        let clock = clock::create_for_testing(ctx);

        let cap = suins::create_admin_cap_for_testing(ctx);

        let config = config::new(
            // We do not care about the public key of the configuration in tests.
            // Also, for renewals, we do not care about it in production mode too.
            // We re-use the type to be able to use the same utilities.
            b"000000000000000000000000000000000",
            // random price, not being tested in renewal tests.
            1200 * ::suins::constants::mist_per_sui(),
            // Random price, not being tested in renewal tests.
            200 * ::suins::constants::mist_per_sui(),
            REGULAR_PRICE * ::suins::constants::mist_per_sui(),
        );

        renewal::setup(&cap, &mut suins, config);

        let nft = registry.add_record(domain, 1,&clock, ctx);
        suins::add_registry(&cap, &mut suins, registry);

        suins::burn_admin_cap_for_testing(cap);
        clock.destroy_for_testing();
    
        (suins, nft)
    }

    public fun wrapup_name(nft: SuinsRegistration) {
        sui::transfer::public_transfer(nft, @0x2);
    }

    public fun wrapup(suins: SuiNS) {
        suins.share_for_testing();
    }
}
