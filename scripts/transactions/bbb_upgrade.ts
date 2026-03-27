// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { execSync } from 'child_process';
import { writeFileSync } from 'fs';

const BBB_UPGRADE_CAP = '0x3d046d10bd8c3f4bee7679086c094efa73662e02708a67903836dbc9d0fd1c15';

const bbbUpgrade = async () => {
	const gasObjectId = process.env.GAS_OBJECT;

	if (!gasObjectId) throw new Error('No gas object supplied for a mainnet transaction');

	const currentDir = process.cwd();
	const bbbDir = `${currentDir}/../packages/bbb`;
	const txFilePath = `${currentDir}/tx/tx-data.txt`;
	const upgradeCall = `sui client upgrade --upgrade-capability ${BBB_UPGRADE_CAP} --gas-budget 2000000000 --gas ${gasObjectId} --skip-dependency-verification --serialize-unsigned-transaction`;

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
