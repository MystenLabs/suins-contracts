// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
/// Testing strategy:
///
/// - Admin can add new records to SuiNS and get the SuinsRegistrations
/// for the registered domains.
/// - Admin keeps the registration NFTs at their account for now.
///
module suins::admin_tests {
    use std::string::utf8;
    use sui::{clock, test_utils::assert_eq};

    use suins::{admin::{Self, Admin}, constants, domain, suins, registry};

    #[test, expected_failure(abort_code = ::suins::suins::EAppNotAuthorized)]
    fun try_unathorized_fail() {
        let mut ctx = tx_context::dummy();
        let mut suins = suins::init_for_testing(&mut ctx);
        let cap = suins::create_admin_cap_for_testing(&mut ctx);
        let clock = clock::create_for_testing(&mut ctx);

        let _nft = admin::reserve_domain(
            &cap,
            &mut suins,
            utf8(b"test.sui"),
            1,
            &clock,
            &mut ctx,
        );

        abort 1337
    }

    #[test]
    fun authorized() {
        let mut ctx = tx_context::dummy();
        let mut suins = suins::init_for_testing(&mut ctx);
        let cap = suins::create_admin_cap_for_testing(&mut ctx);
        let clock = clock::create_for_testing(&mut ctx);
        registry::init_for_testing(&cap, &mut suins, &mut ctx);

        suins::authorize_app_for_testing<Admin>(&mut suins);

        let nft = admin::reserve_domain(
            &cap,
            &mut suins,
            utf8(b"test.sui"),
            1,
            &clock,
            &mut ctx,
        );

        assert_eq(nft.domain(), domain::new(utf8(b"test.sui")));
        assert_eq(nft.expiration_timestamp_ms(), constants::year_ms());

        nft.burn_for_testing();
        clock.destroy_for_testing();
        suins::burn_admin_cap_for_testing(cap);
        suins::share_for_testing(suins);
    }
}
