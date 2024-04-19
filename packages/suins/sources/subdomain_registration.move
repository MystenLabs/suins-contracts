// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// A wrapper for `SuinsRegistration` subdomain objects.
/// 
/// With the wrapper, we are allowing easier distinction between second 
/// level names & subdomains in RPC Querying | filtering.
/// 
/// We maintain all core functionality unchanged for registry, expiration etc.
module suins::subdomain_registration {
    use sui::clock::Clock;

    use suins::suins_registration::SuinsRegistration;

    /* friend suins::registry; */
    /* #[test_only] */ /* friend suins::sub_name_tests; */

    /// === Error codes ===
    /// 
    /// NFT is expired.
    const EExpired: u64 = 1;
    /// NFT is not a subdomain.
    const ENotSubdomain: u64 = 2;
    /// Tries to destroy a subdomain that has not expired.
    const ENameNotExpired: u64 = 3;

    /// A wrapper for SuinsRegistration object specifically for SubNames.
    public struct SubDomainRegistration has key, store {
        id: UID,
        nft: SuinsRegistration
    }

    /// Creates a `SubName` wrapper for SuinsRegistration object 
    /// (as long as it's used for a subdomain).
    public(package) fun new(nft: SuinsRegistration, clock: &Clock, ctx: &mut TxContext): SubDomainRegistration {
        // Can't wrap a non-subdomain NFT.
        assert!(nft.domain().is_subdomain(), ENotSubdomain);
        // Can't wrap an expired NFT.
        assert!(!nft.has_expired(clock), EExpired);

        SubDomainRegistration {
            id: object::new(ctx),
            nft: nft
        }
    }

    /// Destroys the wrapper and returns the SuinsRegistration object.
    /// Fails if the subname is not expired.
    public(package) fun burn(name: SubDomainRegistration, clock: &Clock): SuinsRegistration {
        // tries to unwrap a non-expired subname.
        assert!(name.nft.has_expired(clock), ENameNotExpired);
        
        let SubDomainRegistration {
            id, nft
        } = name;

        id.delete();
        nft
    }

    public fun nft(name: &SubDomainRegistration): &SuinsRegistration {
        &name.nft
    }

    public fun nft_mut(name: &mut SubDomainRegistration): &mut SuinsRegistration {
        &mut name.nft
    }
}
