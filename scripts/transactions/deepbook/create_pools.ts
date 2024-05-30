// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { TransactionBlock } from '@mysten/sui.js/transactions';
import dotenv from 'dotenv';

import { Network, mainPackage } from '../../config/constants';
import { prepareMultisigTx, signAndExecute } from '../../utils/utils';

dotenv.config();

const SUI = '0x0000000000000000000000000000000000000000000000000000000000000002::sui::SUI';
const USDY = '0x960b531667636f39e85867775f52f6b1f220a058c4de786905bdf761e06a56bb::usdy::USDY';
const USDC = '0x5d4b302506645c37ff133b98c4b50a5ae14841659738d6d733d59d0d217a93bf::coin::COIN';
// const WUSDCETH = '0x5d4b302506645c37ff133b98c4b50a5ae14841659738d6d733d59d0d217a93bf::coin::COIN';
// const WBTC = '0xbc3a676894871284b3ccfb2eec66f428612000e2a6e6d23f592ce8833c27c973::coin::COIN';
// const WETH = '0xaf8cd5edc19c4512f4259f0bee101a40d41ebed738ade5874359610ef8eeced5::coin::COIN';
// const USDT = '0xc060006111016b8a020ad5b33834984a437aaa7d3c74c18e09a95d48aceab08c::coin::COIN';
// const TESTNET_COIN =
// 	'0x0c5f16ebb22a354ccb8f4dc163df0e729d0d37b565b4178046ea342ea0a93391::gold::GOLD';
// const TESTNET_SUI = '0x0000000000000000000000000000000000000000000000000000000000000002::sui::SUI';
// const TESTNET_DAI = '0x700de8dea1aac1de7531e9d20fc2568b12d74369f91b7fad3abc1c4f40396e52::dai::DAI';

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
		typeArguments: [SUI, USDC],
		target: `${PACKAGE_ID}::${MODULE_CLOB}::create_customized_pool`,
		arguments: [
			txb.pure(100), // tick
			txb.pure(10000000), // lot
			txb.pure(DEFAULT_MAKER_FEE), // taker fee
			txb.pure(DEFAULT_TAKER_FEE), // maker rebate
			coin, // creation fee
		],
	});

	const constants = mainPackage.mainnet;
	// for mainnet, we prepare the multi-sig tx.
	if (network === 'mainnet') return prepareMultisigTx(txb, constants.adminAddress, 'mainnet');

	// For testnet, we execute the TX directly.
	return signAndExecute(txb, network);
};

if (process.env.NETWORK === 'mainnet') setup('mainnet');
else setup('testnet');
