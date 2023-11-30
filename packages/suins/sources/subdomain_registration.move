// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// A wrapper for `SuinsRegistration` subdomain objects.
/// 
/// With the wrapper, we are allowing easier distinction between second 
/// level names & subdomains in RPC Querying | filtering.
/// 
/// We maintain all core functionality unchanged for registry, expiration etc.
module suins::subdomain_registration {
    use sui::object::{Self, UID};

    use sui::tx_context::TxContext;
    use sui::clock::Clock;

    use suins::suins_registration::{Self, SuinsRegistration};
    use suins::domain;

    /// === Error codes ===
    /// 
    /// NFT is expired.
    const EExpired: u64 = 1;
    /// NFT is not a subdomain.
    const ENotSubdomain: u64 = 2;
    /// Tries to destroy a subdomain that has not expired.
    const ENameNotExpired: u64 = 3;

    /// A wrapper for SuinsRegistration object specifically for SubNames.
    struct SubDomainRegistration has key, store {
        id: UID,
        nft: SuinsRegistration
    }

    /// Creates a `SubName` wrapper for SuinsRegistration object (as long as it's for a subdomain).
    public fun new(nft: SuinsRegistration, clock: &Clock, ctx: &mut TxContext): SubDomainRegistration {
        // Can't wrap a non-subdomain NFT.
        assert!(domain::is_subdomain(&suins_registration::domain(&nft)), ENotSubdomain);
        // Can't wrap an expired NFT.
        assert!(!suins_registration::has_expired(&nft, clock), EExpired);

        SubDomainRegistration {
            id: object::new(ctx),
            nft: nft
        }
    }

    /// Destroys the wrapper and returns the SuinsRegistration object.
    /// Fails if the subname is not expired.
    public fun destroy(name: SubDomainRegistration, clock: &Clock): SuinsRegistration {
        // tries to unwrap a non-expired subname.
        assert!(suins_registration::has_expired(&name.nft, clock), ENameNotExpired);
        
        let SubDomainRegistration {
            id, nft
        } = name;

        object::delete(id);

        nft
    }

    public fun borrow(name: &SubDomainRegistration): &SuinsRegistration {
        &name.nft
    }

    public fun borrow_mut(name: &mut SubDomainRegistration): &mut SuinsRegistration {
        &mut name.nft
    }
}
