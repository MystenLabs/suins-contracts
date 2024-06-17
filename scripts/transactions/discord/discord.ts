// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { TransactionBlock } from '@mysten/sui.js/transactions';

import { mainPackage, PackageInfo } from '../../config/constants';
import { signAndExecute } from '../../utils/utils';
import { attachRoles, setAddress } from './user';

export const discordRoles = {
	master: {
		id: 0,
		percentage: 100,
	},
	adept: {
		id: 1,
		percentage: 50,
	},
	superOG: {
		id: 2,
		percentage: 75,
	},
	citizen: {
		id: 3,
		percentage: 15,
	},
	earlyTester: {
		id: 4,
		percentage: 90,
	},
	supporter2022: {
		id: 5,
		percentage: 10,
	},
	twitterFam: {
		id: 6,
		percentage: 10,
	},
	suinsFriend: {
		id: 7,
		percentage: 50,
	},
	suinsVip: {
		id: 8,
		percentage: 100,
	},
};

export const authorizeDiscordApp = (txb: TransactionBlock, config: PackageInfo) => {
	txb.moveCall({
		target: `${config.coupons.packageId}::coupons::authorize_app`,
		arguments: [txb.object(config.adminCap), txb.object(config.suins)],
		typeArguments: [`${config.discord?.packageId}::discord::DiscordApp`],
	});
};

// add role to discord.
export const addDiscordRole = (
	txb: TransactionBlock,
	role: {
		id: number;
		percentage: number;
	},
	config: PackageInfo,
) => {
	txb.moveCall({
		target: `${config.discord?.packageId}::discord::add_discord_role`,
		arguments: [
			txb.object(config.discord?.discordCap),
			txb.object(config.discord?.discordObjectId),
			txb.pure(role.id, 'u8'),
			txb.pure(role.percentage, 'u8'),
		],
	});
};

export const setPublicKey = async (
	txb: TransactionBlock,
	pubKey: Uint8Array,
	config: PackageInfo,
) => {
	if (!pubKey || pubKey.length === 0) throw new Error('Invalid Public Key on configuration');

	txb.moveCall({
		target: `${config.discord?.packageId}::discord::set_public_key`,
		arguments: [
			txb.object(config.discord?.discordCap),
			txb.object(config.discord?.discordObjectId),
			txb.pure([...pubKey]),
		],
	});
};

// const prepareTestnetContract = async () => {
// 	const config = mainPackage.testnet;
// 	const publicKey = Uint8Array.from([
// 		3, 202, 251, 116, 250, 209, 47, 31, 156, 77, 81, 12, 59, 90, 45, 189, 89, 69, 131, 250, 125, 24,
// 		69, 39, 116, 176, 59, 114, 83, 28, 209, 143, 129,
// 	]);

// 	const tx = new TransactionBlock();

// 	for (let role of Object.values(discordRoles)) {
// 		addDiscordRole(tx, role, config);
// 	}

// 	setPublicKey(tx, publicKey, config);

// 	await signAndExecute(tx, 'testnet');
// };

const demoTestnetUserCreation = async () => {
	const config = mainPackage.testnet;

	const tx = new TransactionBlock();

	attachRoles(
		tx,
		'discord_demo_usr_1',
		[0, 1, 2],
		Uint8Array.from([
			53, 89, 173, 74, 68, 120, 194, 76, 103, 209, 68, 234, 113, 247, 82, 0, 184, 5, 229, 49, 86,
			74, 201, 26, 163, 166, 155, 190, 57, 222, 169, 15, 92, 213, 252, 236, 156, 236, 56, 45, 217,
			69, 4, 217, 173, 57, 97, 9, 109, 158, 93, 212, 196, 190, 60, 48, 198, 239, 142, 248, 60, 72,
			253, 84,
		]),
		config,
	);

	setAddress(
		tx,
		'discord_demo_usr_1',
		'0xe0b97bff42fcef320b5f148db69033b9f689555348b2e90f1da72b0644fa37d0',
		Uint8Array.from([
			8, 220, 197, 237, 206, 56, 12, 159, 149, 27, 197, 214, 220, 8, 217, 149, 201, 25, 155, 220,
			69, 79, 117, 110, 209, 87, 228, 167, 234, 174, 130, 68, 48, 148, 99, 232, 213, 93, 14, 8, 226,
			115, 49, 82, 249, 183, 213, 222, 125, 79, 250, 85, 116, 196, 197, 73, 225, 187, 127, 234, 195,
			80, 65, 164,
		]),
		config,
	);

	await signAndExecute(tx, 'testnet');
};

demoTestnetUserCreation();
