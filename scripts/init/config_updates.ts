// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { Transaction } from '@mysten/sui/transactions';

import { mainPackage, MIST_PER_USDC, Network } from '../config/constants';
import {
	addConfig,
	newPaymentsConfig,
	newPriceConfigV2,
	newRenewalConfig,
	removeConfig,
} from '../init/authorization';
import { signAndExecute } from '../utils/utils';

const network = (process.env.NETWORK as Network) || 'testnet';
const config = mainPackage[network];

const updateConfig = () => {
	const tx = new Transaction();
	const pricingType = `${config.packageId}::pricing_config::PricingConfig`;
	const renewalType = `${config.packageId}::pricing_config::RenewalConfig`;

	removeConfig({
		txb: tx,
		adminCap: config.adminCap,
		suins: config.suins,
		type: pricingType,
		suinsPackageIdV1: config.packageId,
	});

	addConfig({
		txb: tx,
		adminCap: config.adminCap,
		suins: config.suins,
		suinsPackageIdV1: config.packageId,
		config: newPriceConfigV2({
			txb: tx,
			packageId: config.packageId,
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
		type: pricingType,
	});

	removeConfig({
		txb: tx,
		adminCap: config.adminCap,
		suins: config.suins,
		type: renewalType,
		suinsPackageIdV1: config.packageId,
	});

	addConfig({
		txb: tx,
		adminCap: config.adminCap,
		suins: config.suins,
		suinsPackageIdV1: config.packageId,
		config: newRenewalConfig({
			txb: tx,
			packageId: config.packageId,
			ranges: [
				[3, 3],
				[4, 4],
				[5, 63],
			],
			prices: [150 * Number(MIST_PER_USDC), 50 * Number(MIST_PER_USDC), 5 * Number(MIST_PER_USDC)],
		}),
		type: renewalType,
	});

	return signAndExecute(tx, network);
};

const updatePaymentsConfig = () => {
	const tx = new Transaction();
	const paymentsType = `${config.payments.packageId}::payments::PaymentsConfig`;

	removeConfig({
		txb: tx,
		adminCap: config.adminCap,
		suins: config.suins,
		type: paymentsType,
		suinsPackageIdV1: config.packageId,
	});

	const paymentsconfig = newPaymentsConfig({
		txb: tx,
		packageId: config.payments.packageId,
		coinTypeAndDiscount: [
			[config.coins.USDC, 0],
			[config.coins.SUI, 0],
			[config.coins.NS, 25],
		],
		baseCurrencyType: config.coins.USDC.type,
		maxAge: 300,
	});
	addConfig({
		txb: tx,
		adminCap: config.adminCap,
		suins: config.suins,
		suinsPackageIdV1: config.packageId,
		config: paymentsconfig,
		type: paymentsType,
	});

	return signAndExecute(tx, network);
};

// updateConfig();
updatePaymentsConfig();
