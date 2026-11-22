// Copyright (c) Aftermath Technologies, Inc.
// SPDX-License-Identifier: Apache-2.0

module amm::pool_factory {
	public fun create_lp_coin<T0: drop>(
		_arg0: T0,
		_arg1: u8,
		_arg2: &mut sui::tx_context::TxContext
	): amm::pool::CreatePoolCap<T0>
	{
		abort 0
	}

	public fun create_pool_2_coins<T0, T1, T2>(
		_arg0: amm::pool::CreatePoolCap<T0>,
		_arg1: &mut amm::pool_registry::PoolRegistry,
		_arg2: vector<u8>,
		_arg3: vector<u8>,
		_arg4: vector<u8>,
		_arg5: vector<u8>,
		_arg6: vector<u8>,
		_arg7: vector<u64>,
		_arg8: u64,
		_arg9: vector<u64>,
		_arg10: vector<u64>,
		_arg11: vector<u64>,
		_arg12: vector<u64>,
		_arg13: sui::coin::Coin<T1>,
		_arg14: sui::coin::Coin<T2>,
		_arg15: std::option::Option<vector<u8>>,
		_arg16: bool,
		_arg17: std::option::Option<u8>,
		_arg18: &mut sui::tx_context::TxContext
	): (amm::pool::Pool<T0>, sui::coin::Coin<T0>)
	{
		abort 0
	}

	public fun create_pool_3_coins<T0, T1, T2, T3>(
		_arg0: amm::pool::CreatePoolCap<T0>,
		_arg1: &mut amm::pool_registry::PoolRegistry,
		_arg2: vector<u8>,
		_arg3: vector<u8>,
		_arg4: vector<u8>,
		_arg5: vector<u8>,
		_arg6: vector<u8>,
		_arg7: vector<u64>,
		_arg8: u64,
		_arg9: vector<u64>,
		_arg10: vector<u64>,
		_arg11: vector<u64>,
		_arg12: vector<u64>,
		_arg13: sui::coin::Coin<T1>,
		_arg14: sui::coin::Coin<T2>,
		_arg15: sui::coin::Coin<T3>,
		_arg16: std::option::Option<vector<u8>>,
		_arg17: bool,
		_arg18: std::option::Option<u8>,
		_arg19: &mut sui::tx_context::TxContext
	): (amm::pool::Pool<T0>, sui::coin::Coin<T0>)
	{
		abort 0
	}

	public fun create_pool_4_coins<T0, T1, T2, T3, T4>(
		_arg0: amm::pool::CreatePoolCap<T0>,
		_arg1: &mut amm::pool_registry::PoolRegistry,
		_arg2: vector<u8>,
		_arg3: vector<u8>,
		_arg4: vector<u8>,
		_arg5: vector<u8>,
		_arg6: vector<u8>,
		_arg7: vector<u64>,
		_arg8: u64,
		_arg9: vector<u64>,
		_arg10: vector<u64>,
		_arg11: vector<u64>,
		_arg12: vector<u64>,
		_arg13: sui::coin::Coin<T1>,
		_arg14: sui::coin::Coin<T2>,
		_arg15: sui::coin::Coin<T3>,
		_arg16: sui::coin::Coin<T4>,
		_arg17: std::option::Option<vector<u8>>,
		_arg18: bool,
		_arg19: std::option::Option<u8>,
		_arg20: &mut sui::tx_context::TxContext
	): (amm::pool::Pool<T0>, sui::coin::Coin<T0>)
	{
		abort 0
	}

	public fun create_pool_5_coins<T0, T1, T2, T3, T4, T5>(
		_arg0: amm::pool::CreatePoolCap<T0>,
		_arg1: &mut amm::pool_registry::PoolRegistry,
		_arg2: vector<u8>,
		_arg3: vector<u8>,
		_arg4: vector<u8>,
		_arg5: vector<u8>,
		_arg6: vector<u8>,
		_arg7: vector<u64>,
		_arg8: u64,
		_arg9: vector<u64>,
		_arg10: vector<u64>,
		_arg11: vector<u64>,
		_arg12: vector<u64>,
		_arg13: sui::coin::Coin<T1>,
		_arg14: sui::coin::Coin<T2>,
		_arg15: sui::coin::Coin<T3>,
		_arg16: sui::coin::Coin<T4>,
		_arg17: sui::coin::Coin<T5>,
		_arg18: std::option::Option<vector<u8>>,
		_arg19: bool,
		_arg20: std::option::Option<u8>,
		_arg21: &mut sui::tx_context::TxContext
	): (amm::pool::Pool<T0>, sui::coin::Coin<T0>)
	{
		abort 0
	}

	public fun create_pool_6_coins<T0, T1, T2, T3, T4, T5, T6>(
		_arg0: amm::pool::CreatePoolCap<T0>,
		_arg1: &mut amm::pool_registry::PoolRegistry,
		_arg2: vector<u8>,
		_arg3: vector<u8>,
		_arg4: vector<u8>,
		_arg5: vector<u8>,
		_arg6: vector<u8>,
		_arg7: vector<u64>,
		_arg8: u64,
		_arg9: vector<u64>,
		_arg10: vector<u64>,
		_arg11: vector<u64>,
		_arg12: vector<u64>,
		_arg13: sui::coin::Coin<T1>,
		_arg14: sui::coin::Coin<T2>,
		_arg15: sui::coin::Coin<T3>,
		_arg16: sui::coin::Coin<T4>,
		_arg17: sui::coin::Coin<T5>,
		_arg18: sui::coin::Coin<T6>,
		_arg19: std::option::Option<vector<u8>>,
		_arg20: bool,
		_arg21: std::option::Option<u8>,
		_arg22: &mut sui::tx_context::TxContext
	): (amm::pool::Pool<T0>, sui::coin::Coin<T0>)
	{
		abort 0
	}

	public fun create_pool_7_coins<T0, T1, T2, T3, T4, T5, T6, T7>(
		_arg0: amm::pool::CreatePoolCap<T0>,
		_arg1: &mut amm::pool_registry::PoolRegistry,
		_arg2: vector<u8>,
		_arg3: vector<u8>,
		_arg4: vector<u8>,
		_arg5: vector<u8>,
		_arg6: vector<u8>,
		_arg7: vector<u64>,
		_arg8: u64,
		_arg9: vector<u64>,
		_arg10: vector<u64>,
		_arg11: vector<u64>,
		_arg12: vector<u64>,
		_arg13: sui::coin::Coin<T1>,
		_arg14: sui::coin::Coin<T2>,
		_arg15: sui::coin::Coin<T3>,
		_arg16: sui::coin::Coin<T4>,
		_arg17: sui::coin::Coin<T5>,
		_arg18: sui::coin::Coin<T6>,
		_arg19: sui::coin::Coin<T7>,
		_arg20: std::option::Option<vector<u8>>,
		_arg21: bool,
		_arg22: std::option::Option<u8>,
		_arg23: &mut sui::tx_context::TxContext
	): (amm::pool::Pool<T0>, sui::coin::Coin<T0>)
	{
		abort 0
	}

	public fun create_pool_8_coins<T0, T1, T2, T3, T4, T5, T6, T7, T8>(
		_arg0: amm::pool::CreatePoolCap<T0>,
		_arg1: &mut amm::pool_registry::PoolRegistry,
		_arg2: vector<u8>,
		_arg3: vector<u8>,
		_arg4: vector<u8>,
		_arg5: vector<u8>,
		_arg6: vector<u8>,
		_arg7: vector<u64>,
		_arg8: u64,
		_arg9: vector<u64>,
		_arg10: vector<u64>,
		_arg11: vector<u64>,
		_arg12: vector<u64>,
		_arg13: sui::coin::Coin<T1>,
		_arg14: sui::coin::Coin<T2>,
		_arg15: sui::coin::Coin<T3>,
		_arg16: sui::coin::Coin<T4>,
		_arg17: sui::coin::Coin<T5>,
		_arg18: sui::coin::Coin<T6>,
		_arg19: sui::coin::Coin<T7>,
		_arg20: sui::coin::Coin<T8>,
		_arg21: std::option::Option<vector<u8>>,
		_arg22: bool,
		_arg23: std::option::Option<u8>,
		_arg24: &mut sui::tx_context::TxContext
	): (amm::pool::Pool<T0>, sui::coin::Coin<T0>)
	{
		abort 0
	}
}