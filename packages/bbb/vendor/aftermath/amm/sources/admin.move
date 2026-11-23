// Copyright (c) Aftermath Technologies, Inc.
// SPDX-License-Identifier: Apache-2.0

module amm::admin {
	struct AdminCap has store, key {
		id: sui::object::UID
	}

	struct AuthKey has copy, drop, store {
		dummy_field: bool
	}

	struct AuthCap has drop, store {
		dummy_field: bool
	}

	fun init(
		_arg0: &mut sui::tx_context::TxContext
	)
	{
		abort 0
	}

	public fun transfer(
		_arg0: amm::admin::AdminCap,
		_arg1: address
	)
	{
		abort 0
	}

	public fun is_authorized(
		_arg0: &sui::object::UID
	): bool
	{
		abort 0
	}

	public fun authorize(
		_arg0: &amm::admin::AdminCap,
		_arg1: &mut sui::object::UID
	)
	{
		abort 0
	}

	public fun revoke_auth(
		_arg0: &amm::admin::AdminCap,
		_arg1: &mut sui::object::UID
	)
	{
		abort 0
	}
}