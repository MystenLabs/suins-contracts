// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// A module that allows purchasing names in a different price by presenting a
/// reference of type T.
/// Each `T` can have a separate configuration for a discount percentage.
/// If a `T` doesn't exist, registration will fail.
///
/// Can be called only when promotions are active for a specific type T.
/// Activation / deactivation happens through PTBs.
module discounts::discounts;

use day_one::day_one::{DayOne, is_active};
use discounts::house::{Self, DiscountHouse};
use std::type_name;
use sui::dynamic_field as df;
use suins::payment::PaymentIntent;
use suins::pricing_config::PricingConfig;
use suins::suins::{AdminCap, SuiNS};

use fun internal_apply_discount as DiscountHouse.internal_apply_discount;
use fun assert_config_exists as DiscountHouse.assert_config_exists;
use fun config as DiscountHouse.config;
use fun df::add as UID.add;
use fun df::exists_with_type as UID.exists_with_type;
use fun df::exists_ as UID.exists_;
use fun df::borrow as UID.borrow;

#[error]
const EConfigAlreadyExists: vector<u8> = b"Config already exists";
#[error]
const EConfigNotExists: vector<u8> = b"Config does not exist";
#[error]
const EIncorrectAmount: vector<u8> = b"Incorrect amount";
#[error]
const ENotActiveDayOne: vector<u8> = b"DayOne is not active";
#[error]
const ENotValidForDayOne: vector<u8> = b"DayOne is not valid for this type";

/// A key allowing DiscountHouse to apply discounts.
public struct RegularDiscountsApp() has drop;

/// A key that determins the discounts for a type `T`.
public struct DiscountKey<phantom T>() has copy, store, drop;

/// A function to register a name with a discount using type `T`.
public fun apply_percentage_discount<T>(
    self: &mut DiscountHouse,
    intent: &mut PaymentIntent,
    suins: &mut SuiNS,
    _: &mut T, // proof of owning the type T mutably.
    ctx: &mut TxContext,
) {
    // We can only use this discount for types other than DayOne, because we
    // always check
    // that the `DayOne` object is active.
    assert!(
        type_name::get<T>() != type_name::get<DayOne>(),
        ENotValidForDayOne,
    );

    self.internal_apply_discount<T>(intent, suins, ctx);
}

/// A special function for DayOne registration.
/// We separate it from the normal registration flow because we only want it to
/// be usable
/// for activated DayOnes.
public fun apply_day_one_discount(
    self: &mut DiscountHouse,
    intent: &mut PaymentIntent,
    suins: &mut SuiNS,
    day_one: &mut DayOne, // proof of owning the type T mutably.
    ctx: &mut TxContext,
) {
    assert!(day_one.is_active(), ENotActiveDayOne);
    self.internal_apply_discount<DayOne>(intent, suins, ctx);
}

/// An admin action to authorize a type T for special pricing.
///
/// When authorizing, we reuse the core `PricingConfig` struct,
/// and only accept it if all the values are in the [0, 100] range.
/// make sure that all the percentages are in the [0, 99] range.
/// We can use `free_claims` to giveaway free names.
public fun authorize_type<T>(
    self: &mut DiscountHouse,
    _: &AdminCap,
    pricing_config: PricingConfig,
) {
    assert!(!self.uid_mut().exists_(DiscountKey<T>()), EConfigAlreadyExists);
    let (_, values) = (*pricing_config.pricing()).into_keys_values();

    assert!(!values.any!(|percentage| *percentage > 99), EIncorrectAmount);

    self.uid_mut().add(DiscountKey<T>(), pricing_config);
}

/// An admin action to deauthorize type T from getting discounts.
public fun deauthorize_type<T>(_: &AdminCap, self: &mut DiscountHouse) {
    self.assert_version_is_valid();
    self.assert_config_exists<T>();
    df::remove<_, PricingConfig>(
        self.uid_mut(),
        DiscountKey<T>(),
    );
}

fun internal_apply_discount<T>(
    self: &mut DiscountHouse,
    intent: &mut PaymentIntent,
    suins: &mut SuiNS,
    _ctx: &mut TxContext,
) {
    let config = self.config<T>();

    let discount_percent = config.calculate_base_price(intent
        .request_data()
        .domain()
        .sld()
        .length());

    intent.apply_percentage_discount(
        suins,
        RegularDiscountsApp(),
        house::discount_house_key!(),
        // SAFETY: We know that the discount percentage is in the [0, 99] range.
        discount_percent as u8,
        false,
    );
}

fun config<T>(self: &mut DiscountHouse): &PricingConfig {
    self.assert_config_exists<T>();
    self.uid_mut().borrow<_, PricingConfig>(DiscountKey<T>())
}

fun assert_config_exists<T>(self: &mut DiscountHouse) {
    assert!(
        self.uid_mut().exists_with_type<_, PricingConfig>(DiscountKey<T>()),
        EConfigNotExists,
    );
}
