// Copyright (c) 2023, Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import dotenv from 'dotenv';

import { authorizeBogoApp } from '../airdrop/authorize-app';
import { prepareMultisigTx } from '../airdrop/helper';

dotenv.config();

const authorizeApp = async () => {
	// read addresses from file
	// convert to batches.
	const tx = await authorizeBogoApp('mainnet');

	if (!tx) throw new Error('TX not defined');

	prepareMultisigTx(tx, 'mainnet');
};

authorizeApp();
