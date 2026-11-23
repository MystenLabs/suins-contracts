// Copyright (c) Aftermath Technologies, Inc.
// SPDX-License-Identifier: Apache-2.0

module amm::events {
	struct CreatedPoolEvent has copy, drop {
		pool_id: sui::object::ID,
		name: std::string::String,
		creator: address,
		lp_type: std::ascii::String,
		coins: vector<std::ascii::String>,
		weights: vector<u64>,
		flatness: u64,
		fees_swap_in: vector<u64>,
		fees_swap_out: vector<u64>,
		fees_deposit: vector<u64>,
		fees_withdraw: vector<u64>
	}

	struct OraclePriceEvent has copy, drop {
		pool_id: sui::object::ID,
		base_type: std::ascii::String,
		quote_type: std::ascii::String,
		oracle_price: u128
	}

	struct SpotPriceEvent has copy, drop {
		pool_id: sui::object::ID,
		base_type: std::ascii::String,
		quote_type: std::ascii::String,
		spot_price: u128
	}

	struct DepositEvent has copy, drop {
		pool_id: sui::object::ID,
		issuer: address,
		referrer: std::option::Option<address>,
		types: vector<std::ascii::String>,
		deposits: vector<u64>,
		lp_coins_minted: u64
	}

	struct DepositEventV2 has copy, drop {
		pool_id: sui::object::ID,
		issuer: address,
		referrer: std::option::Option<address>,
		types: vector<std::ascii::String>,
		deposits: vector<u64>,
		reserves: vector<u64>,
		lp_coins_minted: u64,
	}

	struct WithdrawEvent has copy, drop {
		pool_id: sui::object::ID,
		issuer: address,
		referrer: std::option::Option<address>,
		types: vector<std::ascii::String>,
		withdrawn: vector<u64>,
		lp_coins_burned: u64
	}

	struct WithdrawEventV2 has copy, drop {
		pool_id: sui::object::ID,
		issuer: address,
		referrer: std::option::Option<address>,
		types: vector<std::ascii::String>,
		withdrawn: vector<u64>,
		reserves: vector<u64>,
		lp_coins_burned: u64
	}

	struct SwapEvent has copy, drop {
		pool_id: sui::object::ID,
		issuer: address,
		referrer: std::option::Option<address>,
		types_in: vector<std::ascii::String>,
		amounts_in: vector<u64>,
		types_out: vector<std::ascii::String>,
		amounts_out: vector<u64>
	}

	struct SwapEventV2 has copy, drop{
		pool_id: sui::object::ID,
		issuer: address,
		referrer: std::option::Option<address>,
		types_in: vector<std::ascii::String>,
		amounts_in: vector<u64>,
		types_out: vector<std::ascii::String>,
		amounts_out: vector<u64>,
		reserves: vector<u64>,
	}
}