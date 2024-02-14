// Copyright (c) 2023, Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { TransactionBlock } from '@mysten/sui.js';
import dotenv from 'dotenv';

import { prepareMultisigTx } from '../../airdrop/helper';
import { authorizeApp } from '../../config/authorize';
import { mainPackage } from '../../config/constants';

dotenv.config();

const gasObject = process.env.GAS_OBJECT;

// Github actions are always on mainnet.
const execute = async () => {
	if (!gasObject) throw new Error('Gas Object not supplied for a mainnet transaction');
	const txb = new TransactionBlock();
	const config = mainPackage.mainnet;

	authorizeApp('mainnet', txb, `${config.renewalsPackageId}::renew::Renew`);

	prepareMultisigTx(txb, 'mainnet');
};

execute();
