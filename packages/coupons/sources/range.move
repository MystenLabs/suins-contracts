// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// A module to introduce `range` checks for the rules.
module suins_coupons::range;

/// Invalid [from, to] setup in the range!
/// `to` parameter has to be >= `from`
const EInvalidRange: u64 = 0;

/// A Range for u8 helper
public struct Range has copy, drop, store {
    vec: vector<u8>,
}

/// a new Range constructor[from, to]
public fun new(from: u8, to: u8): Range {
    assert!(to >= from, EInvalidRange);

    Range {
        vec: vector[from, to],
    }
}

// Verify that the number is in the range (includes from, to)
public fun is_in_range(range: &Range, number: u8): bool {
    number >= range.from() && number <= range.to()
}

/// Get floor limit for the range.
public fun from(range: &Range): u8 {
    range.vec[0]
}

/// Get upper limit for the range.
public fun to(range: &Range): u8 {
    range.vec[1]
}
