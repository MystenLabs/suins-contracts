// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// A base module that holds a shared object for the configuration of the
/// package
/// and exports some package utilities for the 2 systems to use.
module suins_discounts::house;

use std::string::String;
use suins::suins::AdminCap;

#[error]
const EInvalidVersion: vector<u8> = b"Invalid version";

/// The version of the DiscountHouse.
const VERSION: u8 = 1;

// The Shared object responsible for the discounts.
public struct DiscountHouse has key, store {
    id: UID,
    version: u8,
}

/// Share the house.
/// This will hold DFs with the configuration for different types.
fun init(ctx: &mut TxContext) {
    transfer::public_share_object(DiscountHouse {
        id: object::new(ctx),
        version: VERSION,
    })
}

public fun set_version(self: &mut DiscountHouse, _: &AdminCap, version: u8) {
    self.version = version;
}

public(package) macro fun discount_house_key(): String {
    b"object_discount".to_string()
}

public(package) fun assert_version_is_valid(self: &DiscountHouse) {
    assert!(self.version == VERSION, EInvalidVersion);
}

/// A helper function to get a mutable reference to the UID.
public(package) fun uid_mut(self: &mut DiscountHouse): &mut UID {
    &mut self.id
}

#[test_only]
public fun init_for_testing(ctx: &mut TxContext) {
    init(ctx);
}

#[test_only]
public fun house_for_testing(ctx: &mut TxContext): DiscountHouse {
    DiscountHouse {
        id: object::new(ctx),
        version: VERSION,
    }
}
