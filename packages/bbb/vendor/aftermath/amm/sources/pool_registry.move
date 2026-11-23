// Copyright (c) Aftermath Technologies, Inc.
// SPDX-License-Identifier: Apache-2.0

module amm::pool_registry {
	struct PoolRegistryStateV1 has store, key {
		id: sui::object::UID,
		coins: sui::table::Table<std::ascii::String, bool>,
		lp_coin_map: sui::table::Table<std::ascii::String, sui::object::ID>,
		registered_pools: sui::table::Table<vector<u8>, bool>
	}

	struct PoolRegistry has store, key {
		id: sui::object::UID,
		protocol_version: u64
	}

	fun init(
		_arg0: &mut sui::tx_context::TxContext
	)
	{
		abort 0
	}

	public fun protocol_version(
		_arg0: &amm::pool_registry::PoolRegistry
	): u64
	{
		abort 0
	}

	public fun lp_coin_map(
		_arg0: &amm::pool_registry::PoolRegistry
	): &sui::table::Table<std::ascii::String, sui::object::ID>
	{
		abort 0
	}

	public fun contains_lp_coin<T0>(
		_arg0: &amm::pool_registry::PoolRegistry
	): bool
	{
		abort 0
	}

	public fun lp_type_to_pool_id<T0>(
		_arg0: &amm::pool_registry::PoolRegistry
	): sui::object::ID
	{
		abort 0
	}

	public fun supported_coins(
		_arg0: &amm::pool_registry::PoolRegistry
	): &sui::table::Table<std::ascii::String, bool>
	{
		abort 0
	}

	public fun contains_coin<T0>(
		_arg0: &amm::pool_registry::PoolRegistry
	): bool
	{
		abort 0
	}
}