// Copyright (c) Aftermath Technologies, Inc.
// SPDX-License-Identifier: Apache-2.0

module amm::math {
	public fun calc_invariant<T0>(
		_arg0: &amm::pool::Pool<T0>,
		_arg1: &vector<u128>
	): u128
	{
		abort 0
	}

	public fun calc_oracle_price<T0, T1, T2>(
		_arg0: &amm::pool::Pool<T0>
	): u128
	{
		abort 0
	}

	public fun calc_spot_price<T0, T1, T2>(
		_arg0: &amm::pool::Pool<T0>
	): u128
	{
		abort 0
	}

	public fun calc_swap_exact_in<T0, T1, T2>(
		_arg0: &amm::pool::Pool<T0>,
		_arg1: u64,
		_arg2: u64,
		_arg3: u64
	): u64
	{
		abort 0
	}

	public fun calc_swap_exact_out<T0, T1, T2>(
		_arg0: &amm::pool::Pool<T0>,
		_arg1: u64,
		_arg2: u64,
		_arg3: u64
	): u64
	{
		abort 0
	}

	public fun calc_all_coin_deposit<T0>(
		_arg0: &amm::pool::Pool<T0>,
		_arg1: &vector<std::ascii::String>,
		_arg2: &vector<u64>
	): (u64, vector<u64>)
	{
		abort 0
	}

	public fun calc_deposit_exact_in<T0>(
		_arg0: &amm::pool::Pool<T0>,
		_arg1: &vector<std::ascii::String>,
		_arg2: &vector<u64>,
		_arg3: u128,
		_arg4: u64
	): u64
	{
		abort 0
	}

	public fun calc_all_coin_withdraw<T0>(
		_arg0: &amm::pool::Pool<T0>,
		_arg1: u64
	): vector<u64>
	{
		abort 0
	}

	public fun calc_lp_coins_to_mint_from_t<T0>(
		_arg0: &amm::pool::Pool<T0>,
		_arg1: u64,
		_arg2: u64
	): u64
	{
		abort 0
	}

	public fun calc_lp_ratio_after_burning_lp_coin(
		_arg0: u64,
		_arg1: u64
	): u64
	{
		abort 0
	}

	public fun reorder_and_zero_out_empty_coins<T0>(
		_arg0: &amm::pool::Pool<T0>,
		_arg1: &vector<std::ascii::String>,
		_arg2: &vector<u64>
	): vector<u64>
	{
		abort 0
	}

	public fun reorder_by_order_of_calling_function<T0>(
		_arg0: &amm::pool::Pool<T0>,
		_arg1: &vector<std::ascii::String>,
		_arg2: &vector<u64>
	): vector<u64>
	{
		abort 0
	}
}