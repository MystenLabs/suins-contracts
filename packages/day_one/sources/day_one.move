// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// This module defines the `DayOne` Object airdropped to early supporters of the SuiNS project.
module day_one::day_one;

use sui::{bcs, dynamic_field as df, hash, package};

///  We mark as friend just the BOGO module.
/// This is the only one that can activate a DayOne object.
/// This is a one-time operation that won't happen from any other modules.

/// The shared object that stores the receivers destination.
public struct DropList has key {
    id: UID,
    total_minted: u32,
}

/// The Setup Capability for the airdrop module. Sent to the publisher on
/// publish. Consumed in the setup call.
public struct SetupCap has key { id: UID }

/// == ERRORS ==
// Error emitted when trying to mint with invalid addresses (non existent DF).
const ENotFound: u64 = 0;

// Error emitted when passing more than 1000 hashes to the setup function.
const ETooManyHashes: u64 = 1;

/// OTW for the Publisher object
public struct DAY_ONE has drop {}

/// Share the `DropList` object, send the `SetupCap` to the publisher.
fun init(otw: DAY_ONE, ctx: &mut TxContext) {
    // Claim the `Publisher` for the package!
    package::claim_and_keep(otw, ctx);

    transfer::share_object(DropList { id: object::new(ctx), total_minted: 0 });
    // For SuiNS, we need 1 SetupCap to manage all the required addresses. We'll be setting up around 75K addresses.
    // We can mint 2K objects per run!
    transfer::transfer(SetupCap { id: object::new(ctx) }, ctx.sender());
}

/// The DayOne object, granting participants special offers in
/// different future promotions.
public struct DayOne has key, store {
    id: UID,
    active: bool,
    serial: u32,
}

/// Mint the DayOne objects for the recipients. Can be triggered by anyone.
/// The only functionality it has is mint the DayOne & send it to the an address
/// that is part of the list.
public fun mint(self: &mut DropList, mut recipients: vector<address>, ctx: &mut TxContext) {
    let bytes = bcs::to_bytes(&recipients);
    let hash = hash::blake2b256(&bytes);

    // fails if not found.
    let lookup = df::remove_if_exists(&mut self.id, sui::address::from_bytes(hash));
    assert!(lookup.is_some<bool>(), ENotFound);

    let mut i: u32 = self.total_minted;

    while (vector::length(&recipients) > 0) {
        let recipient = recipients.pop_back();
        transfer::public_transfer(
            DayOne {
                id: object::new(ctx),
                active: false,
                serial: i + 1,
            },
            recipient,
        );
        i = i + 1;
    };

    // assign i to total_minted.
    self.total_minted = i
}

/// Setup the airdrop module. This is called by the publisher.
/// Hashes can be a vector of up to 1000 elements.
/// Hashes needs to be generated by the `buffer` module.
public fun setup(self: &mut DropList, cap: SetupCap, mut hashes: vector<address>) {
    // verify we only pass less than 1000 hashes at the setup.
    // That's the max amount of DFs we can create in a single run.
    assert!(hashes.length() <= 1000, ETooManyHashes);

    let SetupCap { id } = cap;
    id.delete();

    // attach every hash as a dynamic field to the `DropList` object;
    while (hashes.length() > 0) {
        df::add(&mut self.id, hashes.pop_back(), true);
    };
}

/// Private helper to activate the DayOne object
/// Will only be called by the `bogo` module (friend), which marks the
/// beginning of the DayOne promotions.
public(package) fun activate(self: &mut DayOne) {
    self.active = true
}

// === Distribution ===

/// Get the immutable reference to the UID of the DayOne object.
public fun uid(self: &DayOne): &UID { &self.id }

/// Get the mutable reference to the UID of the DayOne object.
public fun uid_mut(self: &mut DayOne): &mut UID { &mut self.id }

/// Get if a day_one object is active. Used for future promotions
/// of the DayOne Object
public fun is_active(self: &DayOne): bool {
    self.active
}

#[test_only]
public fun mint_for_testing(ctx: &mut TxContext): DayOne {
    DayOne {
        id: object::new(ctx),
        active: false,
        serial: 0,
    }
}

#[test_only]
public fun burn_for_testing(nft: DayOne) {
    let DayOne {
        id,
        active: _,
        serial: _,
    } = nft;

    id.delete();
}

#[test_only]
public fun set_is_active_for_testing(nft: &mut DayOne, status: bool) {
    nft.active = status;
}
