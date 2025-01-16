// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
import { Transaction, TransactionArgument } from '@mysten/sui/transactions';

import { Network, PackageInfo } from './constants';

export const SUIFREN_BULLSHARK_TYPE: Record<Network, string> = {
	mainnet:
		'0xee496a0cc04d06a345982ba6697c90c619020de9e274408c7819f787ff66e1a1::suifrens::SuiFren<0x8894fa02fc6f36cbc485ae9145d05f247a78e220814fb8419ab261bd81f08f32::bullshark::Bullshark>',
	testnet:
		'0x80d7de9c4a56194087e0ba0bf59492aa8e6a5ee881606226930827085ddf2332::suifrens::SuiFren<0x297d8afb6ede450529d347cf9254caeea2b685c8baef67b084122291ebaefb38::bullshark::Bullshark>',
};

export const SUIFREN_CAPY_TYPE: Record<Network, string> = {
	mainnet:
		'0xee496a0cc04d06a345982ba6697c90c619020de9e274408c7819f787ff66e1a1::suifrens::SuiFren<0xee496a0cc04d06a345982ba6697c90c619020de9e274408c7819f787ff66e1a1::capy::Capy>',
	testnet:
		'0x80d7de9c4a56194087e0ba0bf59492aa8e6a5ee881606226930827085ddf2332::suifrens::SuiFren<0x80d7de9c4a56194087e0ba0bf59492aa8e6a5ee881606226930827085ddf2332::capy::Capy>',
};

export const DAY_ONE_TYPE: Record<Network, string> = {
	mainnet: '0xbf1431324a4a6eadd70e0ac6c5a16f36492f255ed4d011978b2cf34ad738efe6::day_one::DayOne',
	testnet: '0x71c2dc2ce8a3cde0f7fa6638519c64f24b1b7bc20e8272d2ca0690ffbbfabc4a::day_one::DayOne',
};

// Discount setup. (Final pricing)
export type Discount = {
	threeCharacterPrice: bigint;
	fourCharacterPrice: bigint;
	fivePlusCharacterPrice: bigint;
};
// A char range available for free claims.
export type Range = {
	from: number;
	to: number;
};

// Sets up discount prices for type.
export const setupDiscountForType = (
	txb: Transaction,
	setup: PackageInfo,
	type: string,
	prices: Discount,
) => {
	txb.moveCall({
		target: `${setup.discountsPackage.packageId}::discounts::authorize_type`,
		arguments: [
			txb.object(setup.adminCap),
			txb.object(setup.discountsPackage.discountHouseId),
			txb.pure.u64(prices.threeCharacterPrice),
			txb.pure.u64(prices.fourCharacterPrice),
			txb.pure.u64(prices.fivePlusCharacterPrice),
		],
		typeArguments: [type],
	});
};

// remove discount for type
export const removeDiscountForType = (txb: Transaction, setup: PackageInfo, type: string) => {
	txb.moveCall({
		target: `${setup.discountsPackage.packageId}::discounts::deauthorize_type`,
		arguments: [txb.object(setup.adminCap), txb.object(setup.discountsPackage.discountHouseId)],
		typeArguments: [type],
	});
};

export const newRange = ({
	txb,
	setup,
	range,
}: {
	txb: Transaction;
	setup: PackageInfo;
	range: number[];
}): TransactionArgument => {
	return txb.moveCall({
		target: `${setup.packageId}::pricing_config::new_range`,
		arguments: [txb.pure.vector('u64', range)],
	});
};

// Sets up free claims for type.
export const setupFreeClaimsForType = (
	txb: Transaction,
	setup: PackageInfo,
	type: string,
	characters: Range,
) => {
	txb.moveCall({
		target: `${setup.discountsPackage.packageId}::free_claims::authorize_type`,
		arguments: [
			txb.object(setup.discountsPackage.discountHouseId),
			txb.object(setup.adminCap),
			newRange({ txb, setup, range: [characters.from, characters.to] }),
		],
		typeArguments: [type],
	});
};

export const removeFreeClaimsForType = (txb: Transaction, setup: PackageInfo, type: string) => {
	txb.moveCall({
		target: `${setup.discountsPackage.packageId}::free_claims::force_deauthorize_type`,
		arguments: [txb.object(setup.adminCap), txb.object(setup.discountsPackage.discountHouseId)],
		typeArguments: [type],
	});
};
