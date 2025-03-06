// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[deprecated(note = b"Use `core_config` instead")]
module suins::config;

use suins::domain::Domain;

/// The configuration object, holds current settings of the SuiNS
/// application. Does not carry any business logic and can easily
/// be replaced with any other module providing similar interface
/// and fitting the needs of the application.
#[allow(unused_field)]
public struct Config has drop, store {
    public_key: vector<u8>,
    three_char_price: u64,
    four_char_price: u64,
    five_plus_char_price: u64,
}

/// Create a new instance of the configuration object.
/// Define all properties from the start.
public fun new(
    _public_key: vector<u8>,
    _three_char_price: u64,
    _four_char_price: u64,
    _five_plus_char_price: u64,
): Config { abort 1337 }

public fun set_public_key(_: &mut Config, _: vector<u8>) { abort 1337 }

public fun set_three_char_price(_: &mut Config, _: u64) { abort 1337 }

public fun set_four_char_price(_: &mut Config, _: u64) { abort 1337 }

public fun set_five_plus_char_price(_: &mut Config, _: u64) { abort 1337 }

public fun calculate_price(_: &Config, _: u8, _: u8): u64 { abort 1337 }

public fun public_key(_: &Config): &vector<u8> { abort 1337 }

public fun three_char_price(_: &Config): u64 { abort 1337 }

public fun four_char_price(_: &Config): u64 { abort 1337 }

public fun five_plus_char_price(_: &Config): u64 { abort 1337 }

public fun assert_valid_user_registerable_domain(_: &Domain) { abort 1337 }
