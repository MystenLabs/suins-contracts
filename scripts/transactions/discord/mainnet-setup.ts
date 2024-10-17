// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { Transaction } from '@mysten/sui/transactions';

import { mainPackage } from '../../config/constants';
import { authorizeApp } from '../../init/authorization';
import { Packages } from '../../init/packages';
import { prepareMultisigTx } from '../../utils/utils';
import { authorizeDiscordApp } from './discord';

export const prepareMainnetSetupPTB = async () => {
	const txb = new Transaction();
	const config = mainPackage.mainnet;

	Packages('mainnet').Coupons.setupFunction({
		txb,
		packageId: config.coupons.packageId,
		adminCap: config.adminCap,
		suins: config.suins,
	});

	authorizeApp({
		txb,
		adminCap: config.adminCap,
		suins: config.suins,
		type: Packages('mainnet').Coupons.authorizationType(config.coupons.packageId),
		suinsPackageIdV1: config.packageId,
	});

	authorizeDiscordApp(txb, config);

	await prepareMultisigTx(txb, 'mainnet', config.adminAddress);
};

prepareMainnetSetupPTB();
