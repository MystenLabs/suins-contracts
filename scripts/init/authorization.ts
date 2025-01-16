// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
import { Transaction, TransactionArgument } from '@mysten/sui/transactions';
import { hexToBytes } from '@noble/hashes/utils';

/**
 * A helper to authorize any app in the SuiNS object.
 */
export const authorizeApp = ({
	txb,
	adminCap,
	suins,
	type,
	suinsPackageIdV1,
}: {
	txb: Transaction;
	adminCap: string;
	suins: string;
	type: string;
	suinsPackageIdV1: string;
}) => {
	txb.moveCall({
		target: `${suinsPackageIdV1}::suins::authorize_app`,
		arguments: [txb.object(adminCap), txb.object(suins)],
		typeArguments: [type],
	});
};

/**
 * A helper to deauthorize any app that has been authorized on the SuiNS object.
 */
export const deauthorizeApp = ({
	txb,
	adminCap,
	suins,
	type,
	suinsPackageIdV1,
}: {
	txb: Transaction;
	adminCap: string;
	suins: string;
	type: string;
	suinsPackageIdV1: string;
}) => {
	txb.moveCall({
		target: `${suinsPackageIdV1}::suins::deauthorize_app`,
		arguments: [txb.object(adminCap), txb.object(suins)],
		typeArguments: [type],
	});
};

/**
 * A helper to call `setup` function for many apps that create a "registry" to hold state.
 */
export const setupApp = ({
	txb,
	adminCap,
	suins,
	target,
	args,
}: {
	txb: Transaction;
	adminCap: string;
	suins: string;
	target: `${string}::${string}`;
	args?: TransactionArgument[];
}) => {
	txb.moveCall({
		target: `${target}::setup`,
		arguments: [txb.object(suins), txb.object(adminCap), ...(args || [])],
	});
};

/**
 * Add a config to the SuiNS object.
 */
export const addConfig = ({
	txb,
	adminCap,
	suins,
	type,
	config,
	suinsPackageIdV1,
}: {
	txb: Transaction;
	adminCap: string;
	suins: string;
	suinsPackageIdV1: string;
	config: TransactionArgument;
	type: string;
}) => {
	txb.moveCall({
		target: `${suinsPackageIdV1}::suins::add_config`,
		arguments: [txb.object(adminCap), txb.object(suins), config],
		typeArguments: [type],
	});
};

/**
 * Remove a config from SuiNS object.
 */
export const removeConfig = ({
	txb,
	adminCap,
	suins,
	type,
	suinsPackageIdV1,
}: {
	txb: Transaction;
	adminCap: string;
	suins: string;
	suinsPackageIdV1: string;
	type: string;
}) => {
	txb.moveCall({
		target: `${suinsPackageIdV1}::suins::remove_config`,
		arguments: [txb.object(adminCap), txb.object(suins)],
		typeArguments: [type],
	});
};

/**
 * Creates a default `config` which saves the price list and public key.
 */
export const newPriceConfigV1 = ({
	txb,
	suinsPackageIdV1,
	priceList,
	publicKey = [...Array(33).keys()],
}: {
	txb: Transaction;
	suinsPackageIdV1: string;
	priceList: { [key: string]: number };
	publicKey?: number[];
}): TransactionArgument => {
	return txb.moveCall({
		target: `${suinsPackageIdV1}::config::new`,
		arguments: [
			txb.pure.vector('u8', publicKey),
			txb.pure.u64(priceList.three),
			txb.pure.u64(priceList.four),
			txb.pure.u64(priceList.fivePlus),
		],
	});
};

export const newPriceConfigV2 = ({
	txb,
	packageId,
	ranges,
	prices,
}: {
	txb: Transaction;
	packageId: string;
	ranges: number[][];
	prices: number[];
}): TransactionArgument => {
	var rangesList: TransactionArgument[] = [];
	for (const range of ranges) {
		if (range.length !== 2) {
			throw new Error('Each range must have exactly 2 elements');
		}
		rangesList.push(newRange({ txb, packageId, range }));
	}
	return txb.moveCall({
		target: `${packageId}::pricing_config::new`,
		arguments: [
			txb.makeMoveVec({ elements: rangesList, type: `${packageId}::pricing_config::Range` }),
			txb.pure.vector('u64', prices),
		],
	});
};

export const addCoreConfig = ({
	txb,
	latestPackageId,
}: {
	txb: Transaction;
	latestPackageId: string;
}) => {
	return txb.moveCall({
		target: `${latestPackageId}::core_config::new`,
		arguments: [
			txb.pure.vector('string', []),
			txb.pure.u8(3),
			txb.pure.u8(63),
			txb.pure.u8(1),
			txb.pure.u8(5),
			txb.pure.vector('string', ['sui']),
			txb.moveCall({
				target: '0x2::vec_map::empty',
				typeArguments: ['0x1::string::String', '0x1::string::String'],
			}),
		],
	});
};

export const newRenewalConfig = ({
	txb,
	packageId,
	ranges,
	prices,
}: {
	txb: Transaction;
	packageId: string;
	ranges: number[][];
	prices: number[];
}): TransactionArgument => {
	return txb.moveCall({
		target: `${packageId}::pricing_config::new_renewal_config`,
		arguments: [newPriceConfigV2({ txb, packageId, ranges, prices })],
	});
};

export const newRange = ({
	txb,
	packageId,
	range,
}: {
	txb: Transaction;
	packageId: string;
	range: number[];
}): TransactionArgument => {
	return txb.moveCall({
		target: `${packageId}::pricing_config::new_range`,
		arguments: [txb.pure.vector('u64', range)],
	});
};

export const newPaymentsConfig = ({
	txb,
	packageId,
	coinTypeAndDiscount,
	baseCurrencyType,
	maxAge,
}: {
	txb: Transaction;
	packageId: string;
	coinTypeAndDiscount: [Record<string, string>, number][]; // Array of [{type: string, metadataId: string, feed: string}, discountPercentage] pairs
	baseCurrencyType: string;
	maxAge: number;
}): TransactionArgument => {
	const coinTypeDataList: TransactionArgument[] = [];

	for (const [coin, discountPercentage] of coinTypeAndDiscount) {
		coinTypeDataList.push(
			newCoinTypeData({
				txb,
				packageId,
				discountPercentage,
				coinType: coin['type'],
				coinMetadataId: coin['metadataId'],
				priceFeed: coin['feed']
					? new Uint8Array(
							hexToBytes(coin['feed'].startsWith('0x') ? coin['feed'].slice(2) : coin['feed']),
						)
					: new Uint8Array(),
			}),
		);
	}

	return txb.moveCall({
		target: `${packageId}::payments::new_payments_config`,
		arguments: [
			txb.makeMoveVec({
				elements: coinTypeDataList,
				type: `${packageId}::payments::CoinTypeData`,
			}),
			getTypeName({ txb, coinType: baseCurrencyType }),
			txb.pure.u64(maxAge),
		],
	});
};

export const getTypeName = ({
	txb,
	coinType,
}: {
	txb: Transaction;
	coinType: string;
}): TransactionArgument => {
	return txb.moveCall({
		target: '0x1::type_name::get',
		typeArguments: [coinType],
	});
};

export const newCoinTypeData = ({
	txb,
	packageId,
	discountPercentage,
	coinType,
	coinMetadataId,
	priceFeed,
}: {
	txb: Transaction;
	packageId: string;
	discountPercentage: number;
	coinType: string;
	coinMetadataId: string;
	priceFeed: Uint8Array;
}): TransactionArgument => {
	return txb.moveCall({
		target: `${packageId}::payments::new_coin_type_data`,
		arguments: [
			txb.object(coinMetadataId),
			txb.pure.u8(discountPercentage),
			txb.pure.vector('u8', priceFeed),
		],
		typeArguments: [coinType],
	});
};

/**
 * Add a registry to the SuiNS object.
 */
export const addRegistry = ({
	txb,
	adminCap,
	suins,
	type,
	registry,
	suinsPackageIdV1,
}: {
	txb: Transaction;
	adminCap: string;
	suins: string;
	suinsPackageIdV1: string;
	registry: TransactionArgument;
	type: string;
}) => {
	txb.moveCall({
		target: `${suinsPackageIdV1}::suins::add_registry`,
		arguments: [txb.object(adminCap), txb.object(suins), registry],
		typeArguments: [type],
	});
};

/**
 * Creates a default `registry` which saves direct/reverse lookups.
 * That serves as the main registry for the SuiNS object after adding it.
 */
export const newLookupRegistry = ({
	txb,
	adminCap,
	suinsPackageIdV1,
}: {
	txb: Transaction;
	adminCap: string;
	suinsPackageIdV1: string;
}): TransactionArgument => {
	return txb.moveCall({
		target: `${suinsPackageIdV1}::registry::new`,
		arguments: [txb.object(adminCap)],
	});
};
