// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { TransactionBlock } from '@mysten/sui.js/transactions';
import { MIST_PER_SUI } from '@mysten/sui.js/utils';
import dotenv from 'dotenv';

import { mainPackage, Network } from '../../config/constants';
import { authorizeApp } from '../../init/authorization';
import { Packages } from '../../init/packages';
import { prepareMultisigTx, signAndExecute } from '../../utils/utils';

dotenv.config();

export const authorize = async (network: Network) => {
	const txb = new TransactionBlock();
	const config = mainPackage[network];

	authorizeApp({
		txb,
		adminCap: config.adminCap,
		suins: config.suins,
		type: `${config.renewalsPackageId}::renew::Renew`,
		suinsPackageIdV1: config.packageId,
	});

	Packages('mainnet').Renewal.setupFunction({
		txb,
		adminCap: config.adminCap,
		suins: config.suins,
		packageId: config.renewalsPackageId,
		suinsPackageIdV1: config.packageId,
		priceList: {
			three: 50 * Number(MIST_PER_SUI),
			four: 10 * Number(MIST_PER_SUI),
			fivePlus: 2 * Number(MIST_PER_SUI),
		},
	});

	// for mainnet, we just prepare multisig TX
	if (network === 'mainnet') return prepareMultisigTx(txb, 'mainnet');

	return signAndExecute(txb, network);
};

authorize('mainnet');
