// Copyright (c) 2023, Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import dotenv from 'dotenv';

import { deauthorizeBogoApp } from '../airdrop/deauthorize-app';
import { prepareMultisigTx } from '../airdrop/helper';

dotenv.config();

const deauthorizeApp = async () => {
	// read addresses from file
	// convert to batches.
	const tx = await deauthorizeBogoApp('mainnet');

	if (!tx) throw new Error('TX not defined');

	prepareMultisigTx(tx, 'mainnet');
};

deauthorizeApp();
