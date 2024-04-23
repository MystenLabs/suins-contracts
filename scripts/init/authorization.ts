// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
import { TransactionArgument, TransactionBlock } from '@mysten/sui.js/transactions';

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
	txb: TransactionBlock;
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
	txb: TransactionBlock;
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
	txb: TransactionBlock;
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
	txb: TransactionBlock;
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
 * Creates a default `config` which saves the price list and public key.
 */
export const newPriceConfig = ({
	txb,
	suinsPackageIdV1,
	priceList,
	publicKey = [...Array(33).keys()],
}: {
	txb: TransactionBlock;
	suinsPackageIdV1: string;
	priceList: { [key: string]: number };
	publicKey?: number[];
}): TransactionArgument => {
	return txb.moveCall({
		target: `${suinsPackageIdV1}::config::new`,
		arguments: [
			txb.pure(publicKey),
			txb.pure(priceList.three),
			txb.pure(priceList.four),
			txb.pure(priceList.fivePlus),
		],
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
	txb: TransactionBlock;
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
	txb: TransactionBlock;
	adminCap: string;
	suinsPackageIdV1: string;
}): TransactionArgument => {
	return txb.moveCall({
		target: `${suinsPackageIdV1}::registry::new`,
		arguments: [txb.object(adminCap)],
	});
};
