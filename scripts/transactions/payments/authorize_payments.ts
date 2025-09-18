// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { Transaction } from '@mysten/sui/transactions';

import { mainPackage, MAX_AGE, Network } from '../../config/constants';
import { addConfig, authorizeApp, newPaymentsConfig } from '../../init/authorization';
import { prepareMultisigTx, signAndExecute } from '../../utils/utils';

export const authorize = async (network: Network) => {
	const txb = new Transaction();
	const config = mainPackage[network];

	// authorize and add payments configs
	authorizeApp({
		txb,
		adminCap: config.adminCap,
		suins: config.suins,
		type: `${config.payments.packageId}::payments::PaymentsApp`,
		suinsPackageIdV1: config.packageIdV1,
	});
	const paymentsconfig = newPaymentsConfig({
		txb,
		packageId: config.payments.packageId,
		coinTypeAndDiscount: [
			[config.coins.USDC, 0],
			[config.coins.SUI, 0],
			[config.coins.NS, 25],
		],
		baseCurrencyType: config.coins.USDC.type,
		maxAge: MAX_AGE,
		bps: 8000, // 80% burned
	});
	addConfig({
		txb,
		adminCap: config.adminCap,
		suins: config.suins,
		suinsPackageIdV1: config.packageIdV1,
		config: paymentsconfig,
		type: `${config.payments.packageId}::payments::PaymentsConfig`,
	});

	// for mainnet, we just prepare multisig TX
	if (network === 'mainnet') return prepareMultisigTx(txb, 'mainnet', config.adminAddress);

	return signAndExecute(txb, network);
};

authorize('mainnet');
