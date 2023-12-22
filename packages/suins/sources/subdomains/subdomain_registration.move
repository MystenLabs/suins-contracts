// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// A wrapper for `SuinsRegistration` subdomain objects.
/// 
/// With the wrapper, we are allowing easier distinction between second 
/// level names & subdomains in RPC Querying | filtering.
/// 
/// We maintain all core functionality unchanged for registry, expiration etc.
module suins::subdomain_registration {
    use sui::object::{Self, UID, ID};

    use sui::tx_context::TxContext;
    use sui::clock::Clock;

    use suins::suins_registration::{Self as nft, SuinsRegistration};
    use suins::domain;

    friend suins::namespace;

    /// === Error codes ===
    /// 
    /// NFT is expired.
    const EExpired: u64 = 1;
    /// NFT is not a subdomain.
    const ENotSubdomain: u64 = 2;

    /// A wrapper for SuinsRegistration object specifically for SubNames.
    struct SubDomainRegistration has key, store {
        id: UID,
        nft: SuinsRegistration
    }

    /// Creates a `SubName` wrapper for SuinsRegistration object (as long as it's for a subdomain).
    public fun new(nft: SuinsRegistration, clock: &Clock, ctx: &mut TxContext): SubDomainRegistration {
        // Can't wrap a non-subdomain NFT.
        assert!(domain::is_subdomain(&nft::domain(&nft)), ENotSubdomain);
        // Can't wrap an expired NFT.
        assert!(!nft::has_expired(&nft, clock), EExpired);

        SubDomainRegistration {
            id: object::new(ctx),
            nft: nft
        }
    }

    /// Destroys the wrapper and returns the SuinsRegistration object.
    /// Fails if the subname is not expired.
    public(friend) fun destroy(name: SubDomainRegistration): SuinsRegistration {
        let SubDomainRegistration {
            id, nft
        } = name;

        object::delete(id);

        nft
    }

    public fun nft(name: &SubDomainRegistration): &SuinsRegistration {
        &name.nft
    }

    public fun nft_mut(name: &mut SubDomainRegistration): &mut SuinsRegistration {
        &mut name.nft
    }

    #[test_only]
    public fun destroy_for_testing(name: SubDomainRegistration): SuinsRegistration {
        let SubDomainRegistration {
            id, nft
        } = name;

        object::delete(id);
        nft
    }
}
