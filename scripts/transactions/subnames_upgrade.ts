// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { execSync } from 'child_process';
import { writeFileSync } from 'fs';

import { mainPackage, Network } from '../config/constants';

const network = (process.env.NETWORK as Network) || 'mainnet';

// Active env of sui has to be the same with the env we're publishing to.
// if upgradeCap & gasObject is on mainnet, it has to be on mainnet.
// Github actions are always on mainnet.
const subnamesUpgrade = async () => {
	const gasObjectId = process.env.GAS_OBJECT;

	// Enabling the gas Object check only on mainnet, to allow testnet multisig tests.
	if (!gasObjectId) throw new Error('No gas object supplied for a mainnet transaction');

	const currentDir = process.cwd();
	const subdomainsDir = `${currentDir}/../packages/subdomains`;
	const txFilePath = `${currentDir}/tx/tx-data.txt`;
	const upgradeCap = '0xc70ac60c1d65da22ed5f30def1a7dfd33ff3a70eb0bf75f12ab559c5f342ea12'; // owner: 0x9b388a6da9dd4f73e0b13abc6100f1141782ef105f6f5e9d986fb6e00f0b2591
	const upgradeCall = `sui client upgrade --upgrade-capability ${upgradeCap} --gas-budget 2000000000 --gas ${gasObjectId} --serialize-unsigned-transaction`;

	try {
		// Execute the command with the specified working directory and capture the output
		const output = execSync(upgradeCall, { cwd: subdomainsDir, stdio: 'pipe' }).toString();

		writeFileSync(txFilePath, output);
		console.log('Upgrade transaction successfully created and saved to tx-data.txt');
	} catch (error: any) {
		console.error('Error during protocol upgrade:', error.message);
		console.error('stderr:', error.stderr?.toString());
		console.error('stdout:', error.stdout?.toString());
		console.error('Command:', error.cmd);
		process.exit(1); // Exit with an error code
	}
};

subnamesUpgrade();
