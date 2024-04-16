// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module suins::sub_name_tests {
    use std::string::utf8;

    use sui::clock;

    use suins::{suins_registration, subdomain_registration as subdomain, domain};

    #[test]
    fun test_wrap_and_destroy(){
        let mut ctx = tx_context::dummy();
        let mut clock = clock::create_for_testing(&mut ctx);

        let domain = domain::new(utf8(b"sub.example.sui"));

        let mut nft = suins_registration::new_for_testing(domain, 1, &clock, &mut ctx);

        // create subdomain from name
        let mut sub_nft = subdomain::new(nft, &clock, &mut ctx);

        assert!(sub_nft.nft().domain() == domain, 1);

        // destroy subdomain (added mut borrow for coverage)
        clock.set_for_testing(sub_nft.nft_mut().expiration_timestamp_ms() + 1);

        nft = sub_nft.burn(&clock);

        nft.burn_for_testing();

        clock.destroy_for_testing();
    }

    #[test, expected_failure(abort_code=suins::subdomain_registration::ENotSubdomain)]
    fun try_wrap_non_subdomain() {
        let mut ctx = tx_context::dummy();
        let clock = clock::create_for_testing(&mut ctx);

        let nft = suins_registration::new_for_testing(domain::new(utf8(b"example.sui")), 1, &clock, &mut ctx);

        // create subdomain from name
        let _sub_nft = subdomain::new(nft, &clock, &mut ctx);

        abort 1337
    }

    #[test, expected_failure(abort_code=suins::subdomain_registration::EExpired)]
    fun try_wrap_expired_subname() {
        let mut ctx = tx_context::dummy();
        let mut clock = clock::create_for_testing(&mut ctx);

        let nft = suins_registration::new_for_testing(domain::new(utf8(b"sub.example.sui")), 1, &clock, &mut ctx);
        clock.set_for_testing(nft.expiration_timestamp_ms() + 1);

        // create subdomain from name
        let _sub_nft = subdomain::new(nft, &clock, &mut ctx);

        abort 1337
    }

    #[test, expected_failure(abort_code=suins::subdomain_registration::ENameNotExpired)]
    fun try_unwrap_non_expired_subdomain() {
        let mut ctx = tx_context::dummy();
        let clock = clock::create_for_testing(&mut ctx);

        let nft = suins_registration::new_for_testing(domain::new(utf8(b"sub.example.sui")), 1, &clock, &mut ctx);

        // create subdomain from name
        let sub_nft = subdomain::new(nft, &clock, &mut ctx);

        // try to destroy
        let _nft = sub_nft.burn(&clock);

        abort 1337
    }
}

