// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
import { Network } from './packages';
import { publishPackages } from './publish';
import { setup } from './setup';

export const init = async (network: Network) => {
	const published = await publishPackages(network);
	await setup(published, network);
};

init(process.env.NETWORK as Network);
