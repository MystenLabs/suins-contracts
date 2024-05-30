// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { execSync } from 'child_process';
import * as fs from 'fs';
import path from 'path';
import type { TransactionBlock } from '@mysten/sui.js/transactions';

import type { Constants } from '../src/types.js';
import { TestToolbox } from './toolbox.js';

const SUI_BIN = process.env.VITE_SUI_BIN ?? `sui`;

/**
 * Publishes the contracts and does the initial setups needed.
 * Returns the constants from the contracts.
 * */
export async function publishAndSetupSuinsContracts(toolbox: TestToolbox): Promise<Constants> {
	const folder = path.resolve(__dirname, './../../scripts');

	// publishes & sets-up the contracts on our localnet.
	execSync(`cd ${folder} && pnpm publish-and-setup`, {
		env: {
			...process.env,
			PRIVATE_KEY: toolbox.keypair.getSecretKey(),
			SUI_BINARY: SUI_BIN,
			NETWORK: 'localnet',
		},
	});

	console.log('SuiNS Contract published & set up successfully.');

	return JSON.parse(fs.readFileSync(`${folder}/constants.sdk.json`, 'utf8'));
}

export async function execute(toolbox: TestToolbox, transactionBlock: TransactionBlock) {
	return toolbox.client.signAndExecuteTransactionBlock({
		transactionBlock,
		signer: toolbox.keypair,
		options: {
			showEffects: true,
			showObjectChanges: true,
		},
	});
}
