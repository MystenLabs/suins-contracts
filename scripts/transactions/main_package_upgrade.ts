// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { execSync } from 'child_process';
import { Transaction } from '@mysten/sui/transactions';
import dotenv from 'dotenv';

import { mainPackage, Network } from '../config/constants';
import { prepareMultisigTx, upgradePackage } from '../utils/utils';

dotenv.config();

const gasObject = process.env.GAS_OBJECT;
const network = (process.env.NETWORK as Network) || 'mainnet';

// Active env of sui has to be the same with the env we're publishing to.
// if upgradeCap & gasObject is on mainnet, it has to be on mainnet.
// Github actions are always on mainnet.
const mainPackageUpgrade = async () => {
	if (!gasObject) throw new Error('Gas Object not supplied for a mainnet transaction');
	const gasObjectId = process.env.GAS_OBJECT;

	// Enabling the gas Object check only on mainnet, to allow testnet multisig tests.
	if (!gasObjectId) throw new Error('No gas object supplied for a mainnet transaction');

	const upgradeCall = `sui client upgrade --upgrade-capability ${mainPackage[network].upgradeCap} --gas-budget 3000000000 --gas ${gasObjectId} --skip-dependency-verification --serialize-unsigned-transaction`;

	try {
		// Execute the command with the specified working directory and capture the output
		execSync(`cd $PWD/../packages/suins && ${upgradeCall} > $PWD/../../scripts/tx/tx-data.txt`);

		console.log('Upgrade transaction successfully created and saved to tx-data.txt');
	} catch (error: any) {
		console.error('Error during protocol upgrade:', error.message);
		console.error('stderr:', error.stderr?.toString());
		console.error('stdout:', error.stdout?.toString());
		console.error('Command:', error.cmd);
		process.exit(1); // Exit with an error code
	}
};

// const upgradePackages = async () => {
// 	const tx = new Transaction();

// 	upgradePackage(
// 		tx,
// 		'packages/coupons',
// 		mainPackage[network].packageId,
// 		mainPackage[network].upgradeCap!,
// 	);

// 	await prepareMultisigTx(tx, network, mainPackage[network].upgradeCapOwner!);
// };

mainPackageUpgrade();
// upgradePackages();
