// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module suins::pricing_config;

use sui::vec_map::{Self, VecMap};

/// Tries to create a range with more than 2 values
const EInvalidLength: u64 = 1;
/// Tries to create a range with the first value greater than the second
const EInvalidRange: u64 = 2;
/// Tries to create a pricing config with different lengths for ranges and
/// prices
const ELengthMismatch: u64 = 3;
/// Tries to calculate the price for a given length
const EPriceNotSet: u64 = 4;

/// A range struct that holds the start and end of a range (inclusive).
public struct Range(u64, u64) has copy, drop, store;

/// A struct that holds the length range and the price of a service.
public struct PricingConfig has drop, store { pricing: VecMap<Range, u64> }

/// A struct that holds the renewal configuration. Exposed from base pricing
/// module
/// to allow easy access to the pricing config by external packages.
public struct RenewalConfig has drop, store { config: PricingConfig }

/// Calculates the base price for a given length.
/// - Base price type is abstracted away. We can switch to a different base.
///  Our core base will become USDC.
/// - The price is calculated based on the length of the domain name and the
/// available ranges.
public fun calculate_base_price(config: &PricingConfig, length: u64): u64 {
    let keys = config.pricing.keys();
    let mut idx = keys.find_index!(|range| range.is_between_inclusive(length));

    assert!(idx.is_some(), EPriceNotSet);
    let range = keys[idx.extract()];

    *config.pricing.get(&range)
}

/// Creates a new PricingConfig with the given ranges and prices.
/// - The ranges should be sorted in `ascending order` and should not overlap.
/// - The length of the ranges and prices should be the same.
///
/// All the ranges are inclusive (e.g. [3,5]: includes 3, 4, and 5).
public fun new(ranges: vector<Range>, prices: vector<u64>): PricingConfig {
    assert!(ranges.length() == prices.length(), ELengthMismatch);
    // Validate that our ranges are passed in the correct order
    // we expect them to be sorted in ascending order, and we expect them
    // to not have any overlaps.
    let mut i = 1;

    while (i < ranges.length()) {
        assert!(ranges[i - 1].1 < ranges[i].0, EInvalidRange);
        i = i + 1;
    };

    // let sorted = ranges.
    PricingConfig {
        pricing: vec_map::from_keys_values(ranges, prices),
    }
}

/// Checks if the value is between the range (inclusive).
public fun is_between_inclusive(range: &Range, length: u64): bool {
    length >= range.0 && length <= range.1
}

/// Returns the pricing config for usage in external apps.
public fun pricing(config: &PricingConfig): &VecMap<Range, u64> {
    &config.pricing
}

/// Constructor for Renewal<T> that initializes it with a PricingConfig.
public fun new_renewal_config(config: PricingConfig): RenewalConfig {
    RenewalConfig { config }
}

public fun new_range(range: vector<u64>): Range {
    assert!(range.length() == 2, EInvalidLength);
    assert!(range[0] <= range[1], EInvalidRange);

    Range(range[0], range[1])
}

public fun config(renewal: &RenewalConfig): &PricingConfig {
    &renewal.config
}
