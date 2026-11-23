// Copyright (c) Aftermath Technologies, Inc.
// SPDX-License-Identifier: Apache-2.0

module amm::swap {
	public fun add_swap_exact_in_to_route<T0, T1, T2, T3>(
		_arg0: &sui::object::UID,
		_arg1: &amm::pool_registry::PoolRegistry,
		_arg2: &mut amm::pool::Pool<T1>,
		_arg3: sui::coin::Coin<T2>,
		_arg4: u64,
		_arg5: &mut sui::tx_context::TxContext
	): sui::coin::Coin<T3>
	{
		abort 0
	}

	public fun swap_exact_in<T0, T1, T2>(
		_arg0: &mut amm::pool::Pool<T0>,
		_arg1: &amm::pool_registry::PoolRegistry,
		_arg2: &protocol_fee_vault::vault::ProtocolFeeVault,
		_arg3: &mut treasury::treasury::Treasury,
		_arg4: &mut insurance_fund::insurance_fund::InsuranceFund,
		_arg5: &referral_vault::referral_vault::ReferralVault,
		_arg6: sui::coin::Coin<T1>,
		_arg7: u64,
		_arg8: u64,
		_arg9: &mut sui::tx_context::TxContext
	): sui::coin::Coin<T2>
	{
		abort 0
	}

	public fun add_swap_exact_out_to_route<T0, T1, T2, T3>(
		_arg0: &sui::object::UID,
		_arg1: &amm::pool_registry::PoolRegistry,
		_arg2: &mut amm::pool::Pool<T1>,
		_arg3: u64,
		_arg4: &mut sui::coin::Coin<T2>,
		_arg5: u64,
		_arg6: &mut sui::tx_context::TxContext
	): sui::coin::Coin<T3>
	{
		abort 0
	}

	public fun swap_exact_out<T0, T1, T2>(
		_arg0: &mut amm::pool::Pool<T0>,
		_arg1: &amm::pool_registry::PoolRegistry,
		_arg2: &protocol_fee_vault::vault::ProtocolFeeVault,
		_arg3: &mut treasury::treasury::Treasury,
		_arg4: &mut insurance_fund::insurance_fund::InsuranceFund,
		_arg5: &referral_vault::referral_vault::ReferralVault,
		_arg6: u64,
		_arg7: &mut sui::coin::Coin<T1>,
		_arg8: u64,
		_arg9: u64,
		_arg10: &mut sui::tx_context::TxContext
	): sui::coin::Coin<T2>
	{
		abort 0
	}
}