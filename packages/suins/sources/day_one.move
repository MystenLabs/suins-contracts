// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// This module defines the `DayOne` Object airdropped to early supporters
/// of the SuiNS project.
module suins::day_one {
    use sui::object::UID;

    /// The DayOne object, granting participants special privileges in
    /// different promotions and events organized by SuiNS.
    struct DayOne has key, store { id: UID }

    // === Distribution ===

    /// Get the immutable reference to the UID of the DayOne object.
    public fun uid(self: &DayOne): &UID { &self.id }

    /// Get the mutable reference to the UID of the DayOne object.
    public fun uid_mut(self: &mut DayOne): &mut UID { &mut self.id }
}
