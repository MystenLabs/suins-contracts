// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0


/// A simple wrapper to allow having a `third-party` managed `SuinsRegistration` object
/// without the danger of losing it.
/// 
/// It's particularly useful for `Enoki<->SuiNS`, where the `SuinsRegistration` object
/// will be owned by a multi-sig address (for any company), and Enoki addresses will be able to 
/// borrow it for creating subdomains.
/// 
/// Also, instead of going the `cap` way, we go with the `address` way to remove any chance of 
/// equivocation, both for Enoki Backends + owner actions on the domain.
/// 
/// Since `SuiNS` is required as a parameter to create subdomains anyways, 
/// we're also using it to store the managed names (to avoid using separate shared objects).
/// 
module managed::managed {
    use std::vector;
    use std::string::{String};
    use std::option::{Self, Option};

    use sui::object::{Self, ID};
    use sui::table::{Self, Table};
    use sui::tx_context::{TxContext, sender};
    use sui::clock::Clock;
    use sui::transfer;

    use suins::domain::{Self, Domain};
    use suins::suins_registration::{Self, SuinsRegistration};
    use suins::suins::{Self, SuiNS, AdminCap};

    /// Tries to add an NFT that has expired.
    const EExpiredNFT: u64 = 1;
    /// Tries to add a name that already exists (that's impossible but protecting anyways).
    const EAlreadyExists: u64 = 2;
    /// Tries to borrow a name that doesn't exist in the managed registry
    const ENameNotExists: u64 = 3;
    /// Tries to do an unauthorized action on a name.
    const ENotAuthorized: u64 = 4;
    /// Tries to return an NFT that doesn't match the promise.
    const EInvalidReturnedNFT: u64 = 5;

    /// Authorizes the `ManagedNames` to add a `registry` under the main SuiNS object.
    struct ManagedNamesApp has drop {}


    /// The `registry` that holds the managed names per domain.
    /// To simplify, we can only hold a single managed name per domain.
    /// If a valid NFT is passed, the previous name is returned to the owner (who can burn it, as it's an expired one).
    struct ManagedNames has store {
        names: Table<Domain, ManagedName>
    }

    /// A managed name.
    /// `owner`: the only address that can get the `NFT` back
    /// `allowlist`: A list of allowed addresses (that can borrow + return the `NFT`)
    /// `nft`: The `SuinsRegistration` object that can be borrowed.
    struct ManagedName has store {
        owner: address,
        allowed_addresses: vector<address>,
        nft: Option<SuinsRegistration>
    }

    /// A hot-potato promise that the NFT will be returned upon borrowing.
    struct ReturnPromise {
        id: ID
    }

    // Create the store that will hold the managed names as an admin.
    public fun setup(self: &mut SuiNS, cap: &AdminCap, ctx: &mut TxContext) {
        suins::add_registry(cap, self, ManagedNames {
            names: table::new(ctx)
        });
    }


    /// Attaches a `SuinsRegistration` object for usability from third-party addresses.
    public fun attach_managed_name(
        suins: &mut SuiNS,
        nft: SuinsRegistration,
        clock: &Clock,
        allowed_addresses: vector<address>,
        ctx: &mut TxContext
    ) {
        assert!(!suins_registration::has_expired(&nft, clock), EExpiredNFT);

        let managed_names = managed_names_mut(suins);

        let domain = suins_registration::domain(&nft);

        // if the name exists. We check if it's expired, and return it to the owner.
        if(table::contains(&managed_names.names, domain)) {
            let existing = table::remove(&mut managed_names.names, domain);

            let ManagedName { nft, allowed_addresses: _, owner } = existing;

            let existing_nft = option::destroy_some(nft);

            assert!(suins_registration::has_expired(&existing_nft, clock), EAlreadyExists);
            // transfer it back to the owner.
            transfer::public_transfer(existing_nft, owner);
        };

        // add the name to the managed names list.
        table::add(&mut managed_names.names, domain, ManagedName {
            owner: sender(ctx),
            allowed_addresses,
            nft: option::some(nft)
        });
    }

    /// Allows the `owner` to remove a name from the managed system.
    public fun remove_attached_name(
        suins: &mut SuiNS,
        name: String,
        ctx: &mut TxContext
    ): SuinsRegistration {
        let managed_names = managed_names_mut(suins);
        let domain = domain::new(name);

        assert!(table::contains(&managed_names.names, domain), ENameNotExists);
        let existing = table::remove(&mut managed_names.names, domain);

        assert!(is_owner(&existing, sender(ctx)), ENotAuthorized);

        let ManagedName { nft, allowed_addresses: _, owner: _ } = existing;

        option::destroy_some(nft)
    }


    /// Allow a list of addresses to borrow the `SuinsRegistration` object.
    public fun allow_addresses(
        suins: &mut SuiNS,
        name: String,
        addresses: vector<address>,
        ctx: &mut TxContext
    ) {
        let existing = internal_get_managed_name(managed_names_mut(suins), domain::new(name));
        assert!(is_owner(existing, sender(ctx)), ENotAuthorized);

        while(vector::length(&addresses) > 0) {
            let addr = vector::pop_back(&mut addresses);

            if(!vector::contains(&existing.allowed_addresses, &addr)) {
                vector::push_back(&mut existing.allowed_addresses, addr);
            }
        }
    }

    // Removes a list of addresses from the allow-list.
    public fun revoke_addresses(
        suins: &mut SuiNS,
        name: String,
        addresses: vector<address>,
        ctx: &mut TxContext
    ) {
        let existing = internal_get_managed_name(managed_names_mut(suins), domain::new(name));
        assert!(is_owner(existing, sender(ctx)), ENotAuthorized);

        while(vector::length(&addresses) > 0) {
            let addr = vector::pop_back(&mut addresses);

            let (has_address, index) = vector::index_of(&existing.allowed_addresses, &addr);

            if (has_address) {
                vector::remove(&mut existing.allowed_addresses, index);
            }
        }
    }

    /// Borrows the `SuinsRegistration` object.
    public fun borrow_val(
        suins: &mut SuiNS,
        name: String,
        ctx: &mut TxContext
    ): (SuinsRegistration, ReturnPromise) {
        let existing = internal_get_managed_name(managed_names_mut(suins), domain::new(name));

        assert!(is_authorized_address(existing, sender(ctx)), ENotAuthorized);

        let nft = option::extract(&mut existing.nft);
        let id = object::id(&nft);

        (nft, ReturnPromise {
            id
        })
    }

    /// Returns the `SuinsRegistration` object back with the promise.
    public fun return_val(
        suins: &mut SuiNS,
        nft: SuinsRegistration,
        promise: ReturnPromise
    ) {
        let ReturnPromise { id } = promise;
        assert!(object::id(&nft) == id, EInvalidReturnedNFT);

        let existing = internal_get_managed_name(managed_names_mut(suins), suins_registration::domain(&nft));

        // return the NFT back.
        option::fill(&mut existing.nft, nft)
    }


    fun internal_get_managed_name(managed_names: &mut ManagedNames, domain: Domain): &mut ManagedName {
        assert!(table::contains(&managed_names.names, domain), ENameNotExists);
        
        table::borrow_mut(&mut managed_names.names, domain)
    }


    fun is_owner(self: &ManagedName, addr: address): bool {
        self.owner == addr
    }
    /// Check if an address is authorized for borrowing.
    fun is_authorized_address(self: &ManagedName, addr: address): bool {
        self.owner == addr || vector::contains(&self.allowed_addresses, &addr)
    }


    /// an immutable reference to the registry.
    fun managed_names(self: &SuiNS): &ManagedNames {
        suins::registry<ManagedNames>(self)
    }

    /// a mutable reference to the registry
    fun managed_names_mut(self: &mut SuiNS): &mut ManagedNames {
        suins::app_registry_mut<ManagedNamesApp, ManagedNames>(ManagedNamesApp {}, self)
    }
}
