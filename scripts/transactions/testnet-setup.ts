// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { Transaction } from '@mysten/sui/transactions';

import { mainPackage, MIST_PER_USDC, PackageInfo } from '../config/constants';
import { addConfig, newPriceConfigV2, newRenewalConfig, removeConfig } from '../init/authorization';
import { signAndExecute } from '../utils/utils';

const setupSuins = (txb: Transaction, config: PackageInfo) => {
	removeConfig({
		txb,
		adminCap: config.adminCap,
		suins: config.suins,
		type: `${config.packageIdPricing}::pricing_config::PricingConfig`,
		suinsPackageIdV1: config.packageIdV1,
	});

	removeConfig({
		txb,
		adminCap: config.adminCap,
		suins: config.suins,
		type: `${config.packageIdPricing}::pricing_config::RenewalConfig`,
		suinsPackageIdV1: config.packageIdV1,
	});

	// Add new price configs
	addConfig({
		txb,
		adminCap: config.adminCap,
		suins: config.suins,
		suinsPackageIdV1: config.packageIdV1,
		config: newPriceConfigV2({
			txb,
			packageId: config.packageId,
			ranges: [
				[3, 3],
				[4, 4],
				[5, 63],
			],
			prices: [50 * Number(MIST_PER_USDC), 10 * Number(MIST_PER_USDC), 1 * Number(MIST_PER_USDC)],
		}),
		type: `${config.packageIdPricing}::pricing_config::PricingConfig`,
	});
	addConfig({
		txb,
		adminCap: config.adminCap,
		suins: config.suins,
		suinsPackageIdV1: config.packageIdV1,
		config: newRenewalConfig({
			txb,
			packageId: config.packageId,
			ranges: [
				[3, 3],
				[4, 4],
				[5, 63],
			],
			prices: [15 * Number(MIST_PER_USDC), 5 * Number(MIST_PER_USDC), 0.5 * Number(MIST_PER_USDC)],
		}),
		type: `${config.packageIdPricing}::pricing_config::RenewalConfig`,
	});
};

const publishSetup = async () => {
	const config = mainPackage['testnet'];
	const tx = new Transaction();

	setupSuins(tx, config);

	console.log(await signAndExecute(tx, 'testnet'));
};

publishSetup();
