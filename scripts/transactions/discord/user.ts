// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { TransactionBlock } from '@mysten/sui.js/transactions';

import { PackageInfo } from '../../config/constants';

export const attachRoles = (
	tx: TransactionBlock,
	discordId: string,
	roles: number[],
	signature: Uint8Array,
	config: PackageInfo,
) => {
	tx.moveCall({
		target: `${config.discord?.packageId}::discord::attach_roles`,
		arguments: [
			tx.object(config.discord?.discordObjectId),
			tx.pure([...signature], 'vector<u8>'),
			tx.pure(discordId),
			tx.pure([...roles], 'vector<u8>'),
		],
	});
};

/** Set the address of a discord_id */
export const setAddress = (
	tx: TransactionBlock,
	discordId: string,
	address: string,
	signature: Uint8Array,
	config: PackageInfo,
) => {
	tx.moveCall({
		target: `${config.discord?.packageId}::discord::set_address`,
		arguments: [
			tx.object(config.discord?.discordObjectId),
			tx.pure([...signature], 'vector<u8>'),
			tx.pure(discordId),
			tx.pure(address, 'address'),
		],
	});
};
