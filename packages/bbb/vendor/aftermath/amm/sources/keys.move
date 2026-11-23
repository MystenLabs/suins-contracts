// Copyright (c) Aftermath Technologies, Inc.
// SPDX-License-Identifier: Apache-2.0

module amm::keys {
	struct BalanceKey<phantom T0> has copy, drop, store {
		dummy_field: bool
	}

	public fun type_to_string<T0>(): std::ascii::String
	{
		abort 0
	}

	public fun type_to_balance_key<T0>(): amm::keys::BalanceKey<T0>
	{
		abort 0
	}
}