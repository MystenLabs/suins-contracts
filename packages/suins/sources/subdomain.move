// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// A wrapper for `SuinsRegistration` subdomain objects.
/// 
/// With the wrapper, we are allowing easier distinction between names & subdomains in the code.
/// Main use-case is querying owned Subnames from RPC differently than Names.
/// 
/// The wrapper adds some small issues in our current phase, since we do not support references in PTBs.
/// 
/// As a work-around, we'll have to proxy the calls temporarily (using a package that can get discared once the PTB references are in).
/// We cannot support the wrapper with an `Option<SuinsRegistration>` (to proceed with borrow + return approach), as Display won't work for the wrapper.
module suins::subdomain {
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
    struct SubDomain has key, store {
        id: UID,
        nft: SuinsRegistration
    }

    /// Creates a `SubName` wrapper for SuinsRegistration object (as long as it's for a subdomain).
    public fun new(nft: SuinsRegistration, clock: &Clock, ctx: &mut TxContext): SubDomain {
        // Can't wrap a non-subdomain NFT.
        assert!(domain::is_subdomain(&suins_registration::domain(&nft)), ENotSubdomain);
        // Can't wrap an expired NFT.
        assert!(!suins_registration::has_expired(&nft, clock), EExpired);

        SubDomain {
            id: object::new(ctx),
            nft: nft
        }
    }

    /// Destroys the wrapper and returns the SuinsRegistration object.
    /// Fails if the subname is not expired.
    public fun destroy(name: SubDomain, clock: &Clock): SuinsRegistration {
        // tries to unwrap a non-expired subname.
        assert!(suins_registration::has_expired(&name.nft, clock), ENameNotExpired);
        
        let SubDomain {
            id, nft
        } = name;

        object::delete(id);

        nft
    }

    public fun borrow(name: &SubDomain): &SuinsRegistration {
        &name.nft
    }

    public fun borrow_mut(name: &mut SubDomain): &mut SuinsRegistration {
        &mut name.nft
    }
}
