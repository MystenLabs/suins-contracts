// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { Transaction } from '@mysten/sui/transactions';

import { mainPackage, MIST_PER_USDC, TESTNET_CONFIG } from '../config/constants.js';
import { prepareMultisigTx, signAndExecute } from '../utils/utils.js';
import {
	addConfig,
	addRegistry,
	authorizeApp,
	deauthorizeApp,
	newLookupRegistry,
	newPaymentsConfig,
	newPriceConfigV1,
	newPriceConfigV2,
	newRenewalConfig,
	setupApp,
} from './authorization';

const craftTx = async () => {
	const txb = new Transaction();
	const adminCap = TESTNET_CONFIG.suinsPackageId.adminCap;
	const suins = TESTNET_CONFIG.suinsObjectId;
	const packageId = TESTNET_CONFIG.suinsPackageId.latest;

	addConfig({
		txb,
		adminCap,
		suins,
		suinsPackageIdV1: packageId,
		config: newPriceConfigV2({
			txb,
			packageId,
			ranges: [
				[3, 3],
				[4, 4],
				[5, 63],
			],
			prices: [
				500 * Number(MIST_PER_USDC),
				100 * Number(MIST_PER_USDC),
				10 * Number(MIST_PER_USDC),
			],
		}),
		type: `${packageId}::pricing_config::PricingConfig`,
	});
	addConfig({
		txb,
		adminCap,
		suins,
		suinsPackageIdV1: packageId,
		config: newRenewalConfig({
			txb,
			packageId,
			ranges: [
				[3, 3],
				[4, 4],
				[5, 63],
			],
			prices: [150 * Number(MIST_PER_USDC), 50 * Number(MIST_PER_USDC), 5 * Number(MIST_PER_USDC)],
		}),
		type: `${packageId}::pricing_config::RenewalConfig`,
	});
	authorizeApp({
		txb,
		adminCap,
		suins,
		type: `${packageId}::controller::Controller`,
		suinsPackageIdV1: packageId,
	});

	await signAndExecute(txb, 'testnet');
};

craftTx();
