// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module suins::register;

use std::string::String;
use sui::{clock::Clock, coin::Coin};
use suins::{
    core_config::CoreConfig,
    domain,
    pricing_config::PricingConfig,
    registry::Registry,
    suins::{Self, SuiNS},
    suins_registration::SuinsRegistration
};

/// Number of years passed is not within [1-5] interval.
const EInvalidYearsArgument: u64 = 0;
/// Trying to register a subdomain (only *.sui is currently allowed).
/// The payment does not match the price for the domain.
const EIncorrectAmount: u64 = 4;

/// Authorization token for the app.
public struct Register has drop {}

// Allows direct purchases of domains
//
// Makes sure that:
// - the domain is not already registered (or, if active, expired)
// - the domain TLD is .sui
// - the domain is not a subdomain
// - number of years is within [1-5] interval
public fun register<T>(
    suins: &mut SuiNS,
    domain_name: String,
    no_years: u8,
    payment: Coin<T>,
    clock: &Clock,
    ctx: &mut TxContext,
): SuinsRegistration {
    suins.assert_app_is_authorized<Register>();

    let config = suins.get_config<PricingConfig>();
    // If no PricingConfig of type T, add an error code

    let domain = domain::new(domain_name);
    suins.get_config<CoreConfig>().assert_is_valid_for_sale(&domain);

    assert!(0 < no_years && no_years <= 5, EInvalidYearsArgument);

    let label = domain.sld();
    let price = config.calculate_base_price(label.length()) * (no_years as u64);
    assert!(payment.value() == price, EIncorrectAmount);

    suins.app_add_custom_balance<_, T>(Register {}, payment.into_balance());
    let registry = suins::app_registry_mut<Register, Registry>(
        Register {},
        suins,
    );
    registry.add_record(domain, no_years, clock, ctx)
}
