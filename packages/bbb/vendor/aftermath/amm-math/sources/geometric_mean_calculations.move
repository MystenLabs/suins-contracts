// Copyright (c) Aftermath Technologies, Inc.
// SPDX-License-Identifier: Apache-2.0

module amm_math::geometric_mean_calculations {
	public fun calc_invariant(
		_arg0: &vector<u128>,
		_arg1: &vector<u64>
	): u128
	{
		abort 0
	}

	public fun calc_invariant_full(
		_arg0: &vector<u128>,
		_arg1: &vector<u64>
	): u256
	{
		abort 0
	}

	public fun calc_spot_price_full(
		_arg0: u256,
		_arg1: u256,
		_arg2: u256,
		_arg3: u256
	): u256
	{
		abort 0
	}

	public fun calc_spot_price_full_with_fees(
		_arg0: u256,
		_arg1: u256,
		_arg2: u256,
		_arg3: u256,
		_arg4: u256,
		_arg5: u256
	): u256
	{
		abort 0
	}

	public fun calc_spot_price(
		_arg0: u128,
		_arg1: u128,
		_arg2: u64,
		_arg3: u64
	): u128
	{
		abort 0
	}

	public fun calc_spot_price_with_fees(
		_arg0: u128,
		_arg1: u128,
		_arg2: u64,
		_arg3: u64,
		_arg4: u64,
		_arg5: u64
	): u128
	{
		abort 0
	}

	public fun calc_out_given_in(
		_arg0: u128,
		_arg1: u128,
		_arg2: u64,
		_arg3: u64,
		_arg4: u64,
		_arg5: u64,
		_arg6: u128,
		_arg7: u128
	): u64
	{
		abort 0
	}

	public fun calc_in_given_out(
		_arg0: u128,
		_arg1: u128,
		_arg2: u64,
		_arg3: u64,
		_arg4: u64,
		_arg5: u64,
		_arg6: u128,
		_arg7: u128
	): u64
	{
		abort 0
	}

	public fun calc_swap_fixed_in(
		_arg0: &vector<u128>,
		_arg1: &vector<u64>,
		_arg2: &vector<u64>,
		_arg3: &vector<u64>,
		_arg4: &vector<u128>,
		_arg5: &vector<u128>
	): u64
	{
		abort 0
	}

	public fun calc_swap_fixed_out(
		_arg0: &vector<u128>,
		_arg1: &vector<u64>,
		_arg2: &vector<u64>,
		_arg3: &vector<u64>,
		_arg4: &vector<u128>,
		_arg5: &vector<u128>
	): u64
	{
		abort 0
	}

	public fun calc_withdraw_fixed_amounts(
		_arg0: &vector<u128>,
		_arg1: &vector<u64>,
		_arg2: &vector<u64>,
		_arg3: &vector<u64>,
		_arg4: &vector<u128>,
		_arg5: u128
	): u64
	{
		abort 0
	}

	public fun calc_deposit_fixed_amounts(
		_arg0: &vector<u128>,
		_arg1: &vector<u64>,
		_arg2: &vector<u64>,
		_arg3: &vector<u64>,
		_arg4: &vector<u128>,
		_arg5: u128
	): u64
	{
		abort 0
	}

	public fun calc_withdraw_flp_amounts_out(
		_arg0: &vector<u128>,
		_arg1: &vector<u64>,
		_arg2: &vector<u64>,
		_arg3: &vector<u64>,
		_arg4: &vector<u128>,
		_arg5: u128
	): u64
	{
		abort 0
	}

	public fun calc_all_coin_deposit(
		_arg0: &vector<u128>,
		_arg1: &vector<u128>
	): u64
	{
		abort 0
	}

	public fun calc_all_coin_withdraw(
		_arg0: &vector<u128>,
		_arg1: &vector<u128>
	): u64
	{
		abort 0
	}
}