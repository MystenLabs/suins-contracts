// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { execSync } from 'child_process';
import { writeFileSync } from 'fs';

import { mainPackage, Network } from '../config/constants';

const network = (process.env.NETWORK as Network) || 'mainnet';

const paymentsUpgrade = async () => {
	const gasObjectId = process.env.GAS_OBJECT;

	if (!gasObjectId) throw new Error('No gas object supplied. Export it using GAS_OBJECT');

	const upgradeCap = mainPackage[network].payments.upgradeCap;

	const currentDir = process.cwd();
	const paymentsDir = `${currentDir}/../packages/payments`;
	const txFilePath = `${currentDir}/tx/tx-data.txt`;
	const upgradeCall = `sui client upgrade --upgrade-capability ${upgradeCap} --gas-budget 2000000000 --gas ${gasObjectId} --skip-dependency-verification --serialize-unsigned-transaction`;

	try {
		const output = execSync(upgradeCall, { cwd: paymentsDir, stdio: 'pipe' }).toString();
		writeFileSync(txFilePath, output);
		console.log('Payments upgrade transaction successfully created and saved to tx-data.txt');
	} catch (error: any) {
		console.error('Error during Payments upgrade:', error.message);
		console.error('stderr:', error.stderr?.toString());
		console.error('stdout:', error.stdout?.toString());
		console.error('Command:', error.cmd);
		process.exit(1);
	}
};

paymentsUpgrade();
