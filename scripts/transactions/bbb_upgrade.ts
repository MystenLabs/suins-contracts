// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { execSync } from 'child_process';
import { writeFileSync } from 'fs';

import { Network } from '../config/constants';

const network = (process.env.NETWORK as Network) || 'mainnet';

const BBB_UPGRADE_CAP: Record<Network, string> = {
	mainnet: '0x7be6340da3af6cf40f2d77f289e178631f8c3e479167099b93769c5f1b82e6f9',
	testnet: '0x558d953cfff029f9dff7b42bb0e589b70441230112eb688eb7bd5ed908d4bd3c',
};

const bbbUpgrade = async () => {
	const gasObjectId = process.env.GAS_OBJECT;

	if (!gasObjectId) throw new Error('No gas object supplied. Export it using GAS_OBJECT');

	const currentDir = process.cwd();
	const bbbDir = `${currentDir}/../packages/bbb`;
	const txFilePath = `${currentDir}/tx/tx-data.txt`;
	const upgradeCall = `sui client upgrade --upgrade-capability ${BBB_UPGRADE_CAP[network]} --gas-budget 2000000000 --gas ${gasObjectId} --skip-dependency-verification --serialize-unsigned-transaction`;

	try {
		const output = execSync(upgradeCall, { cwd: bbbDir, stdio: 'pipe' }).toString();
		writeFileSync(txFilePath, output);
		console.log('BBB upgrade transaction successfully created and saved to tx-data.txt');
	} catch (error: any) {
		console.error('Error during BBB upgrade:', error.message);
		console.error('stderr:', error.stderr?.toString());
		console.error('stdout:', error.stdout?.toString());
		console.error('Command:', error.cmd);
		process.exit(1);
	}
};

bbbUpgrade();
