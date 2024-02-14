// Copyright (c) 2023, Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { TransactionBlock } from '@mysten/sui.js';
import dotenv from 'dotenv';

import { executeTx, prepareMultisigTx, prepareSigner } from '../../airdrop/helper';
import { mainPackage, Network } from '../../config/constants';
import {
	DAY_ONE_TYPE,
	removeDiscountForType,
	SUIFREN_BULLSHARK_TYPE,
	SUIFREN_CAPY_TYPE,
} from '../../config/discounts';

dotenv.config();

const execute = async (network: Network) => {
	const setup = mainPackage[network];

	const txb = new TransactionBlock();

	removeDiscountForType(txb, setup, SUIFREN_BULLSHARK_TYPE[network]);
	removeDiscountForType(txb, setup, SUIFREN_CAPY_TYPE[network]);
	removeDiscountForType(txb, setup, DAY_ONE_TYPE[network]);

	// for mainnet, we prepare the multi-sig tx.
	if (network === 'mainnet') return prepareMultisigTx(txb, 'mainnet');

	// For testnet, we execute the TX directly.
	return executeTx(prepareSigner(setup.provider), txb);
};

if (process.env.NETWORK === 'mainnet') execute('mainnet');
else execute('testnet');
