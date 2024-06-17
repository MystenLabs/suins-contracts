// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { TransactionBlock } from '@mysten/sui.js/transactions';

import { mainPackage, PackageInfo } from '../../config/constants';
import { signAndExecute } from '../../utils/utils';
import { attachRoles, setAddress } from './user';
import { bcs } from '@mysten/sui.js/bcs';

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
    serverBoost: {
        id: 9,
        percentage: 50
    }
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
			txb.pure.u8(role.id),
			txb.pure.u8(role.percentage),
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
			txb.pure(bcs.vector(bcs.U8).serialize([...pubKey])),
		],
	});
};

const prepareTestnetContract = async () => {
	const config = mainPackage.testnet;
	const publicKey = Uint8Array.from([
		3, 202, 251, 116, 250, 209, 47, 31, 156, 77, 81, 12, 59, 90, 45, 189, 89, 69, 131, 250, 125, 24,
		69, 39, 116, 176, 59, 114, 83, 28, 209, 143, 129,
	]);

	const tx = new TransactionBlock();

	for (let role of Object.values(discordRoles)) {
		addDiscordRole(tx, role, config);
	}

	setPublicKey(tx, publicKey, config);

	const res = await signAndExecute(tx, 'testnet');
    console.dir(res, { depth: null });
};

const demoTestnetUserCreation = async () => {
	const config = mainPackage.testnet;

	const tx = new TransactionBlock();

	// attachRoles(
	// 	tx,
	// 	'discord_demo_usr_1',
	// 	[3, 4],
	// 	Uint8Array.from([
	// 		106,17,155,184,210,81,79,170,139,163,251,98,118,7,10,115,70,146,70,127,227,248,75,33,117,121,127,1,83,12,134,102,30,88,60,6,50,140,88,127,50,130,149,35,218,191,83,73,32,36,136,196,43,53,10,79,203,211,36,156,73,73,164,134,
	// 	]),
	// 	config,
	// );

	setAddress(
		tx,
		'discord_demo_usr_1',
		Uint8Array.from([
            224,179,0,88,228,89,228,175,245,218,85,229,51,90,28,164,37,32,175,210,232,39,61,31,169,179,158,245,207,232,61,147,58,145,250,153,237,178,116,28,122,227,249,86,242,67,86,205,223,242,64,13,63,108,34,2,174,83,42,17,180,175,69,156
        ]),
		config,
	);

    try{
        const res = await signAndExecute(tx, 'testnet');
        console.log(res, { depth: null });
    } catch(e) {
        console.dir(e, { depth: null })
    }

};

demoTestnetUserCreation();
