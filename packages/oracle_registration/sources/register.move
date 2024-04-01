// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module oracle_registration::register {
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

    use pyth::price_feed::{Self};
    use pyth::price_info::{Self, PriceInfoObject, PriceInfo};
    use pyth::price_identifier::{Self};
    use pyth::price;
    use pyth::i64;

    /// Number of years passed is not within [1-5] interval.
    const EInvalidYearsArgument: u64 = 0;
    /// Trying to register a subdomain (only *.sui is currently allowed).
    /// The payment does not match the price for the domain.
    const EIncorrectAmount: u64 = 4;
    /// Pyth oracle reports a precision that's too high.
    const EIncorrectPrecision: u64 = 5;
    /// Incorrect price feed ID
    const EIncorrectPriceFeedID: u64 = 6;
    /// Sui Price Feed ID
    const SUI_PRICE_FEED_MAINNET_ID: vector<u8> = x"23d7315113f5b1d3ba7a83604c44b94d79f4fd69af77f804fc7f920a6dc65744";
    const SUI_PRICE_FEED_TESTNET_ID: vector<u8> = x"50c67b3fd225db8912a424dd4baed60ffdde625ed2feaaf283724f9608fea266";

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
        price_info_object: &PriceInfoObject,
        clock: &Clock,
        ctx: &mut TxContext
    ): SuinsRegistration {
        suins::assert_app_is_authorized<Register>(suins);

        let config = suins::get_config<Config>(suins);

        let domain = domain::new(domain_name);
        config::assert_valid_user_registerable_domain(&domain);

        assert!(0 < no_years && no_years <= 5, EInvalidYearsArgument);

        let label = domain::sld(&domain);
        let config_cost = config::calculate_price(config, (string::length(label) as u8), no_years);
        let sui_quantity_required = calculate_price_in_sui(price_info_object, config_cost);
        let sui_quantity_required_min = sui_quantity_required * 995 / 1000;
        let sui_quantity_required_max = sui_quantity_required * 1005 / 1000;

        assert!(sui_quantity_required_min <= coin::value(&payment), EIncorrectAmount);
        assert!(sui_quantity_required_max >= coin::value(&payment), EIncorrectAmount);

        suins::app_add_balance(Register {}, suins, coin::into_balance(payment));
        let registry = suins::app_registry_mut<Register, Registry>(Register {}, suins);
        registry::add_record(registry, domain, no_years, clock, ctx)
    }

    public fun calculate_price_in_sui(
        price_info_object: &PriceInfoObject,
        config_cost: u64
    ): u64 {
        let price_info = &price_info::get_price_info_from_price_info_object(price_info_object);
        validate_sui_price_feed(price_info);

        let price_feed = price_info::get_price_feed(price_info);
        let sui_price = &price_feed::get_price(price_feed);
        let sui_price_i64 = &price::get_price(sui_price);
        let sui_price_u64 = i64::get_magnitude_if_positive(sui_price_i64);

        let exponent_i64 = &price::get_expo(sui_price);
        let exponent_u64 = i64::get_magnitude_if_negative(exponent_i64);
        assert!(exponent_u64 < 256, EIncorrectPrecision);
        let exponent_u8 = (exponent_u64 as u8);

        config_cost * (math::pow(10, exponent_u8)) / sui_price_u64
    }

    fun validate_sui_price_feed(
        price_info: &PriceInfo
    ) {
        let price_identifier = &price_info::get_price_identifier(price_info);
        let price_id_bytes = price_identifier::get_bytes(price_identifier);
        assert!(price_id_bytes == SUI_PRICE_FEED_MAINNET_ID || price_id_bytes == SUI_PRICE_FEED_TESTNET_ID, EIncorrectPriceFeedID);
    }
}
