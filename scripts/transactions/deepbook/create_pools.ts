// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { TransactionBlock } from '@mysten/sui.js/transactions';
import dotenv from 'dotenv';

import { Network, mainPackage } from '../../config/constants';
import { prepareMultisigTx, signAndExecute } from '../../utils/utils';

dotenv.config();

// const SUI = '0x0000000000000000000000000000000000000000000000000000000000000002::sui::SUI';
// const USDY = '0x960b531667636f39e85867775f52f6b1f220a058c4de786905bdf761e06a56bb::usdy::USDY';
const WUSDC = '0x5d4b302506645c37ff133b98c4b50a5ae14841659738d6d733d59d0d217a93bf::coin::COIN';
const USDC = '0xdba34672e30cb065b1f93e3ab55318768fd6fef66c15942c9f7cb846e2f900e7::usdc::USDC';

export const CREATION_FEE = 100 * 1e9;
export const PACKAGE_ID = '0xdee9';
export const MODULE_CLOB = 'clob_v2';

// 2 - 2 for fees on the more volatile assets
const DEFAULT_MAKER_FEE = 200000;
const DEFAULT_TAKER_FEE = 200000;

// 1 - 1 for fees
const DEFAULT_STABLE_MAKER_FEE = 100000;
const DEFAULT_STABLE_TAKER_FEE = 100000;

// Setup Deepbook Pool.
const setup = async (network: Network) => {
	const txb = new TransactionBlock();
	const [coin] = txb.splitCoins(txb.gas, [txb.pure(CREATION_FEE)]);

	// Create USDY / USDC
	txb.moveCall({
		typeArguments: [WUSDC, USDC],
		target: `${PACKAGE_ID}::${MODULE_CLOB}::create_customized_pool`,
		arguments: [
			txb.pure(100000), // tick
			txb.pure(100000), // lot
			txb.pure(0), // taker fee
			txb.pure(0), // maker rebate
			coin, // creation fee
		],
	});

	// for mainnet, we prepare the multi-sig tx.
	if (network === 'mainnet') return prepareMultisigTx(txb, 'mainnet', mainPackage.mainnet.adminAddress);

	// For testnet, we execute the TX directly.
	return signAndExecute(txb, network);
};

if (process.env.NETWORK === 'mainnet') setup('mainnet');
else setup('testnet');
