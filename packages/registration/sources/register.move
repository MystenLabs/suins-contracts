// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module registration::register {
    use std::string::{Self, String};
    use sui::coin::{Self, Coin};
    use sui::math;
    use sui::tx_context::TxContext;
    use sui::clock::Clock;
    use sui::sui::SUI;

    use suins::domain;
    use suins::registry::{Self, Registry};
    use suins::suins::{Self, SuiNS};
    use suins::config::{Self, Config};
    use suins::suins_registration::SuinsRegistration;

    use pyth::price_feed::{Self, PriceFeed};
    use pyth::price;
    use pyth::i64;

    /// Number of years passed is not within [1-5] interval.
    const EInvalidYearsArgument: u64 = 0;
    /// Trying to register a subdomain (only *.sui is currently allowed).
    /// The payment does not match the price for the domain.
    const EIncorrectAmount: u64 = 4;

    /// Authorization token for the app.
    struct Register has drop {}

    // Allows direct purchases of domains
    //
    // Makes sure that:
    // - the domain is not already registered (or, if active, expired)
    // - the domain TLD is .sui
    // - the domain is not a subdomain
    // - number of years is within [1-5] interval
    public fun register(
        suins: &mut SuiNS,
        domain_name: String,
        no_years: u8,
        payment: Coin<SUI>,
        price_feed: &PriceFeed,
        clock: &Clock,
        ctx: &mut TxContext
    ): SuinsRegistration {
        suins::assert_app_is_authorized<Register>(suins);

        let config = suins::get_config<Config>(suins);

        let domain = domain::new(domain_name);
        config::assert_valid_user_registerable_domain(&domain);

        assert!(0 < no_years && no_years <= 5, EInvalidYearsArgument);

        let label = domain::sld(&domain);

        let (sui_value_in_usd_lower_bound, sui_value_in_usd_upper_bound) = calculate_lower_upper_price(price_feed, coin::value(&payment));
        let price_in_usd = config::calculate_price(config, (string::length(label) as u8), no_years);

        assert!(sui_value_in_usd_lower_bound <= price_in_usd, EIncorrectAmount);
        assert!(sui_value_in_usd_upper_bound >= price_in_usd, EIncorrectAmount);

        suins::app_add_balance(Register {}, suins, coin::into_balance(payment));
        let registry = suins::app_registry_mut<Register, Registry>(Register {}, suins);
        registry::add_record(registry, domain, no_years, clock, ctx)
    }

    fun calculate_lower_upper_price(
        price_feed: &PriceFeed,
        sui_quantity: u64
    ): (u64, u64) {
        // https://docs.pyth.network/price-feeds/pythnet-price-feeds/best-practices
        let sui_price = &price_feed::get_price(price_feed);
        let sui_price_i64 = &price::get_price(sui_price);
        let sui_price_u64 = i64::get_magnitude_if_positive(sui_price_i64);
        let sui_price_lower_bound = sui_price_u64 - price::get_conf(sui_price);
        let sui_price_upper_bound = sui_price_u64 + price::get_conf(sui_price);
        let exponent_i64 = &price::get_expo(sui_price);
        let exponent_u8 = (i64::get_magnitude_if_negative(exponent_i64) as u8);

        let sui_value_in_usd_lower_bound = sui_quantity * sui_price_lower_bound / (math::pow(10, exponent_u8));
        let sui_value_in_usd_upper_bound = sui_quantity * sui_price_upper_bound / (math::pow(10, exponent_u8));

        (sui_value_in_usd_lower_bound, sui_value_in_usd_upper_bound)
    }
}
