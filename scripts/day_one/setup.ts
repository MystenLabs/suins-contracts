// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
import { KioskClient, Network as KioskNetwork, TransferPolicyTransaction } from '@mysten/kiosk';
import { Transaction } from '@mysten/sui/transactions';

import { mainPackage, Network } from '../config/constants';
import { addressConfig, AirdropConfig, mainnetConfig } from '../config/day_one';
import { getClient } from '../utils/utils';

export const dayOneType = (config: AirdropConfig) => `${config.packageId}::day_one::DayOne`;

export const createDayOneDisplay = async (tx: Transaction, network: Network) => {
	const config = network === 'mainnet' ? mainnetConfig : addressConfig;
	const displayObject = {
		keys: ['name', 'description', 'link', 'image_url'],
		values: [
			'SuiNS Day 1 NFT #{serial}',
			'The SuiNS Day 1 NFT represents community members who have been with SuiNS since day 1 of launch.',
			'https://suins.io/',
			'https://suins.io/day_one_active_{active}.webp',
		],
	};

	const mainPackageConfig = mainPackage[network];

	let display = tx.moveCall({
		target: '0x2::display::new_with_fields',
		arguments: [
			tx.object(config.publisher),
			tx.pure.vector('string', displayObject.keys),
			tx.pure.vector('string', displayObject.values),
		],
		typeArguments: [dayOneType(config)],
	});

	tx.moveCall({
		target: '0x2::display::update_version',
		arguments: [display],
		typeArguments: [dayOneType(config)],
	});

	tx.transferObjects([display], tx.pure.address(mainPackageConfig.adminAddress));
};

export const createDayOneTransferPolicy = async (tx: Transaction, network: Network) => {
	const config = network === 'mainnet' ? mainnetConfig : addressConfig;
	const mainPackageConfig = mainPackage[network];

	const kioskClient = new KioskClient({
		client: getClient(network),
		network: network === 'mainnet' ? KioskNetwork.MAINNET : KioskNetwork.TESTNET,
	});

	const existingPolicy = await kioskClient.getTransferPolicies({ type: dayOneType(config) });

	if (existingPolicy.length > 0) {
		console.warn(`Type ${dayOneType} already had a transfer policy so the transaction was skipped.`);
		return false;
	}

	// create transfer policy
	let tpTx = new TransferPolicyTransaction({ kioskClient, transaction: tx });
	await tpTx.create({
		type: `${dayOneType(config)}`,
		publisher: config.publisher,
	});

	// transfer cap to owner
	tpTx.shareAndTransferCap(mainPackageConfig.adminAddress);

	return true;
};
