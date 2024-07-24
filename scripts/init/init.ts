// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
import { Network } from './packages';
import { publishPackages } from './publish';
import { setup } from './setup';

export const init = async (network: Network, isCIJob: boolean) => {
	if (!network)
		throw new Error(
			'Network not defined. Please run `export NETWORK=mainnet|testnet|devnet|localnet`',
		);
	const published = await publishPackages(isCIJob ? 'mainnet' : network);
	await setup(published, network);
};

init(process.env.NETWORK as Network, !!process.env.IS_CI_JOB);
