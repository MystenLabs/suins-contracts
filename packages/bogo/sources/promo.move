// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// Buy 1 get 1 free promotion for DayOne NFT holders.
///
/// For every SuinsRegistration presented a user gets a free domain name of the
/// same (or more) length as the one registered. To do so, the user must present
/// the DayOne NFT to the promo module and `start` the process.
///
/// Then the user must present all of the SuinsRegistration NFT with the desired
/// domain names to the `register` function.
///
/// Once all names are specified, the user must `end` the process, which will
/// commit the results to the DayOne NFT and unpack the Hot Potato, finalizing
/// the transaction.
module bogo::promo {
    use std::string::{length, String};
    use sui::dynamic_field as df;
    use suins::day_one::{Self, DayOne};
    use suins::suins_registration::{Self, SuinsRegistration};

    /// DayOne or SuinsRegistration NFT has already been used.
    const EAlreadyUsed: u64 = 0;
    /// The length of the BOGO domain does not match the SuinsRegistration.
    const ELengthMismatch: u64 = 1;
    /// The registration is not implemented.
    const ENotImplemented: u64 = 2;

    /// A Hot Potato marking the a single registration flow.
    /// Once resolved, the results are committed to the DayOne NFT.
    struct Tracker { /* limit: u8 */ }

    /// A dynamic field attached to the DayOne and to the SuinsRegistration
    /// NFTs marking that they have been used for the promotion.
    struct UsedKey has copy, store, drop {}

    /// Start the registration.
    public fun start(self: &DayOne): Tracker {
        assert!(!df::exists_(day_one::uid(self), UsedKey {}), EAlreadyUsed);
        Tracker {}
    }

    /// While the promo action is active and the Tracker is present, show the
    /// SuinsRegistration to get a domain with the same or more length.
    public fun register(
        _tracker: &Tracker,
        registration: &mut SuinsRegistration,
        domain_name: String
    ): SuinsRegistration {
        let registered = suins_registration::domain_name(registration);

        assert!(!df::exists_(suins_registration::uid(registration), UsedKey {}), EAlreadyUsed);
        assert!(length(&registered) <= length(&domain_name), ELengthMismatch);

        df::add(suins_registration::uid_mut(registration), UsedKey {}, true);

        // perform the actual registration via the Registry / Suins modules.
        abort ENotImplemented
    }

    /// End the registration, committing the results to the DayOne NFT and
    /// unpack the Tracker Hot Potato.
    public fun end(self: &mut DayOne, tracker: Tracker) {
        df::add(day_one::uid_mut(self), UsedKey {}, true);
        let Tracker {} = tracker;
    }
}
