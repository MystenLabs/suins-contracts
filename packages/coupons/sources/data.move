// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module suins_coupons::data;

use std::string::String;
use sui::bag::{Self, Bag};
use suins_coupons::coupon::Coupon;

const ECouponAlreadyExists: u64 = 1;
const ECouponDoesNotExist: u64 = 2;

/// Create a `Data` struct that only authorized apps can get mutable access to.
/// We don't save the coupon's table directly on the shared object, because we
/// want authorized apps to only perform
/// certain actions with the table (and not give full `mut` access to it).
public struct Data has store {
    // hold a list of all coupons in the system.
    coupons: Bag,
}

public(package) fun new(ctx: &mut TxContext): Data {
    Data {
        coupons: bag::new(ctx),
    }
}

/// Private internal functions
/// An internal function to save the coupon in the shared object's config.
public(package) fun save_coupon(self: &mut Data, code: String, coupon: Coupon) {
    assert!(!self.coupons.contains(code), ECouponAlreadyExists);
    self.coupons.add(code, coupon);
}

// A function to remove a coupon from the system.
public(package) fun remove_coupon(self: &mut Data, code: String) {
    assert!(self.coupons.contains(code), ECouponDoesNotExist);
    let _: Coupon = self.coupons.remove(code);
}

public(package) fun coupons(data: &Data): &Bag {
    &data.coupons
}

public(package) fun coupons_mut(data: &mut Data): &mut Bag {
    &mut data.coupons
}
