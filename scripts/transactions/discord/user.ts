// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { Transaction } from '@mysten/sui/transactions';

import { PackageInfo } from '../../config/constants';

export const attachRoles = (
	tx: Transaction,
	discordId: string,
	roles: number[],
	signature: Uint8Array,
	config: PackageInfo,
) => {
	tx.moveCall({
		target: `${config.discord?.packageId}::discord::attach_roles`,
		arguments: [
			tx.object(config.discord?.discordObjectId ?? ''),
			tx.pure.vector('u8', [...signature]),
			tx.pure.string(discordId),
			tx.pure.vector('u8', [...roles]),
		],
	});
};

/** Set the address of a discord_id */
export const setAddress = (
	tx: Transaction,
	discordId: string,
	signature: Uint8Array,
	config: PackageInfo,
) => {
	tx.moveCall({
		target: `${config.discord?.packageId}::discord::set_address`,
		arguments: [
			tx.object(config.discord?.discordObjectId ?? ''),
			tx.pure.vector('u8', [...signature]),
			tx.pure.string(discordId),
		],
	});
};
