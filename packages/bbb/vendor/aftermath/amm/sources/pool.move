// Copyright (c) Aftermath Technologies, Inc.
// SPDX-License-Identifier: Apache-2.0

module amm::pool {
	struct CreatePoolCap<phantom T0> has key {
		id: sui::object::UID,
		lp_treasury_cap: sui::coin::TreasuryCap<T0>,
		lp_coin_metadata: sui::coin::CoinMetadata<T0>
	}

	struct Pool<phantom T0> has store, key {
		id: sui::object::UID,
		name: std::string::String,
		creator: address,
		lp_supply: sui::balance::Supply<T0>,
		illiquid_lp_supply: sui::balance::Balance<T0>,
		type_names: vector<std::ascii::String>,
		normalized_balances: vector<u128>,
		weights: vector<u64>,
		flatness: u64,
		fees_swap_in: vector<u64>,
		fees_swap_out: vector<u64>,
		fees_deposit: vector<u64>,
		fees_withdraw: vector<u64>,
		coin_decimals: std::option::Option<vector<u8>>,
		decimal_scalars: vector<u128>,
		lp_decimals: u8,
		lp_decimal_scalar: u128
	}

	public fun transfer_create_pool_cap<T0>(
		_arg0: amm::pool::CreatePoolCap<T0>,
		_arg1: address
	)
	{
		abort 0
	}

	public fun share<T0>(
		_arg0: amm::pool::Pool<T0>
	)
	{
		abort 0
	}

	public fun name<T0>(
		_arg0: &amm::pool::Pool<T0>
	): std::string::String
	{
		abort 0
	}

	public fun creator<T0>(
		_arg0: &amm::pool::Pool<T0>
	): address
	{
		abort 0
	}

	public fun flatness<T0>(
		_arg0: &amm::pool::Pool<T0>
	): u64
	{
		abort 0
	}

	public fun size<T0>(
		_arg0: &amm::pool::Pool<T0>
	): u64
	{
		abort 0
	}

	public fun lp_type<T0>(
		_arg0: &amm::pool::Pool<T0>
	): std::ascii::String
	{
		abort 0
	}

	public fun lp_supply_value<T0>(
		_arg0: &amm::pool::Pool<T0>
	): u64
	{
		abort 0
	}

	public fun type_names<T0>(
		_arg0: &amm::pool::Pool<T0>
	): vector<std::ascii::String>
	{
		abort 0
	}

	public fun contains_type<T0, T1>(
		_arg0: &amm::pool::Pool<T0>
	): bool
	{
		abort 0
	}

	public fun balance_of<T0, T1>(
		_arg0: &amm::pool::Pool<T0>
	): u64
	{
		abort 0
	}

	public fun balances<T0>(
		_arg0: &amm::pool::Pool<T0>
	): vector<u64>
	{
		abort 0
	}

	public fun weights<T0>(
		_arg0: &amm::pool::Pool<T0>
	): vector<u64>
	{
		abort 0
	}

	public fun weight_of<T0, T1>(
		_arg0: &amm::pool::Pool<T0>
	): u64
	{
		abort 0
	}

	public fun fees_swap_in<T0>(
		_arg0: &amm::pool::Pool<T0>
	): vector<u64>
	{
		abort 0
	}

	public fun fees_swap_in_for<T0, T1>(
		_arg0: &amm::pool::Pool<T0>
	): u64
	{
		abort 0
	}

	public fun fees_swap_out<T0>(
		_arg0: &amm::pool::Pool<T0>
	): vector<u64>
	{
		abort 0
	}

	public fun fees_swap_out_for<T0, T1>(
		_arg0: &amm::pool::Pool<T0>
	): u64
	{
		abort 0
	}

	public fun fees_deposit<T0>(
		_arg0: &amm::pool::Pool<T0>
	): vector<u64>
	{
		abort 0
	}

	public fun fees_deposit_for<T0, T1>(
		_arg0: &amm::pool::Pool<T0>
	): u64
	{
		abort 0
	}

	public fun fees_withdraw<T0>(
		_arg0: &amm::pool::Pool<T0>
	): vector<u64>
	{
		abort 0
	}

	public fun fees_withdraw_for<T0, T1>(
		_arg0: &amm::pool::Pool<T0>
	): u64
	{
		abort 0
	}

	public fun lp_decimals<T0>(
		_arg0: &amm::pool::Pool<T0>
	): u8
	{
		abort 0
	}

	public fun coin_decimals<T0>(
		_arg0: &amm::pool::Pool<T0>
	): &std::option::Option<vector<u8>>
	{
		abort 0
	}
}