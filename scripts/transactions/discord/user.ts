// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { bcs } from '@mysten/sui.js/bcs';
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
			tx.pure(bcs.vector(bcs.U8).serialize([...signature])),
			tx.pure.string(discordId),
			tx.pure(bcs.vector(bcs.U8).serialize([...roles])),
		],
	});
};

/** Set the address of a discord_id */
export const setAddress = (
	tx: TransactionBlock,
	discordId: string,
	signature: Uint8Array,
	config: PackageInfo,
) => {
	tx.moveCall({
		target: `${config.discord?.packageId}::discord::set_address`,
		arguments: [
			tx.object(config.discord?.discordObjectId),
			tx.pure(bcs.vector(bcs.U8).serialize([...signature])),
			tx.pure.string(discordId),
		],
	});
};
