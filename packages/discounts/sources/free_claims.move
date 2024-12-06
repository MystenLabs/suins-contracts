// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// A module that allows claiming names of a set length for free by presenting
/// an object T.
/// Each `T` can have a separate configuration for a discount percentage.
/// If a `T` doesn't exist, registration will fail.
///
/// Can be called only when promotions are active for a specific type T.
/// Activation / deactivation happens through PTBs.
module discounts::free_claims;

use day_one::day_one::{DayOne, is_active};
use discounts::house::{Self, DiscountHouse};
use std::type_name;
use sui::dynamic_field as df;
use sui::linked_table::{Self, LinkedTable};
use suins::payment::PaymentIntent;
use suins::pricing_config::Range;
use suins::suins::{AdminCap, SuiNS};

use fun internal_apply_full_discount as DiscountHouse.internal_apply_full_discount;
use fun assert_config_exists as DiscountHouse.assert_config_exists;
use fun config_mut as DiscountHouse.config_mut;
use fun df::add as UID.add;
use fun df::exists_with_type as UID.exists_with_type;
use fun df::exists_ as UID.exists_;
use fun df::borrow_mut as UID.borrow_mut;
use fun df::remove as UID.remove;

/// A configuration already exists
const EConfigExists: u64 = 1;
/// A configuration doesn't exist
const EConfigNotExists: u64 = 2;
/// Invalid length array
const EInvalidCharacterRange: u64 = 3;
/// Object has already been used in this promotion.
const EAlreadyClaimed: u64 = 4;
/// Tries to use DayOne on regular register flow.
const ENotValidForDayOne: u64 = 5;
/// Tries to claim with a non active DayOne
const ENotActiveDayOne: u64 = 6;

/// A key that allows DiscountHouse to apply free claims.
public struct FreeClaimsApp() has drop;

/// A key that opens up free claims for type T.
public struct FreeClaimsKey<phantom T>() has copy, store, drop;

/// We hold the configuration for the promotion
/// We only allow 1 claim / per configuration / per promotion.
/// We keep the used ids as a LinkedTable so we can get our rebates when closing
/// the promotion.
public struct FreeClaimsConfig has store {
    domain_length_range: Range,
    used_objects: LinkedTable<ID, bool>,
}

/// A function to register a name with a discount using type `T`.
public fun free_claim<T: key>(
    self: &mut DiscountHouse,
    suins: &mut SuiNS,
    intent: &mut PaymentIntent,
    object: &T,
    ctx: &mut TxContext,
) {
    // For normal flow, we do not allow DayOne to be used.
    // DayOne can only be used on `register_with_day_one` function.
    assert!(type_name::get<T>() != type_name::get<DayOne>(), ENotValidForDayOne);
    // Apply the discount.
    self.internal_apply_full_discount<T>(suins, intent, object::id(object), ctx);
}

// A function to register a free name using `DayOne`.
public fun free_claim_with_day_one(
    self: &mut DiscountHouse,
    suins: &mut SuiNS,
    intent: &mut PaymentIntent,
    day_one: &DayOne,
    ctx: &mut TxContext,
) {
    assert!(day_one.is_active(), ENotActiveDayOne);
    self.internal_apply_full_discount<DayOne>(suins, intent, object::id(day_one), ctx);
}

/// An admin action to authorize a type T for free claiming of names by
/// presenting
/// an object of type `T`.
public fun authorize_type<T: key>(
    self: &mut DiscountHouse,
    _: &AdminCap,
    domain_length_range: Range,
    ctx: &mut TxContext,
) {
    self.assert_version_is_valid();
    assert!(!self.uid_mut().exists_(FreeClaimsKey<T>()), EConfigExists);

    self
        .uid_mut()
        .add(
            FreeClaimsKey<T>(),
            FreeClaimsConfig {
                domain_length_range,
                used_objects: linked_table::new(ctx),
            },
        );
}

/// Force-deauthorize type T from free claims.
/// Drops the linked_table.
public fun deauthorize_type<T>(self: &mut DiscountHouse, _: &AdminCap): LinkedTable<ID, bool> {
    self.assert_version_is_valid();
    self.assert_config_exists<T>();

    let FreeClaimsConfig { used_objects, domain_length_range: _ } = self
        .uid_mut()
        .remove(FreeClaimsKey<T>());

    used_objects
}

/// Internal helper that checks if there's a valid configuration for T,
/// validates that the domain name is of vlaid length, and then does the
/// registration.
fun internal_apply_full_discount<T: key>(
    self: &mut DiscountHouse,
    suins: &mut SuiNS,
    intent: &mut PaymentIntent,
    id: ID,
    _ctx: &mut TxContext,
) {
    self.assert_version_is_valid();
    self.assert_config_exists<T>();

    let config = self.config_mut<T>();

    // We only allow one free registration per object.
    // We shall check the id hasn't been used before first.
    assert!(!config.used_objects.contains(id), EAlreadyClaimed);

    // add the supplied object's id to the used objects list.
    config.used_objects.push_back(id, true);

    assert!(
        config
            .domain_length_range
            .is_between_inclusive(intent.request_data().domain().sld().length()),
        EInvalidCharacterRange,
    );

    // applies 100% discount to the intent (so payment cost becomes 0).
    intent.apply_percentage_discount(
        suins,
        FreeClaimsApp(),
        house::discount_house_key!(),
        100,
        false,
    );
}

fun config_mut<T>(self: &mut DiscountHouse): &mut FreeClaimsConfig {
    self.uid_mut().borrow_mut<_, FreeClaimsConfig>(FreeClaimsKey<T>())
}

// Validate that there is a config for `T`
fun assert_config_exists<T>(self: &mut DiscountHouse) {
    assert!(
        self.uid_mut().exists_with_type<_, FreeClaimsConfig>(FreeClaimsKey<T>()),
        EConfigNotExists,
    );
}
