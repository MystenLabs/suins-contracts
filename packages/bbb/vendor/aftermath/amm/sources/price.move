// Copyright (c) Aftermath Technologies, Inc.
// SPDX-License-Identifier: Apache-2.0

module amm::price {
	public fun oracle_price<T0, T1, T2>(
		_arg0: &amm::pool::Pool<T0>,
		_arg1: &amm::pool_registry::PoolRegistry
	): u128
	{
		abort 0
	}

	public fun spot_price<T0, T1, T2>(
		_arg0: &amm::pool::Pool<T0>,
		_arg1: &amm::pool_registry::PoolRegistry
	): u128
	{
		abort 0
	}
}