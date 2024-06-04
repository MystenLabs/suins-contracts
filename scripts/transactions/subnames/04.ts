// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import path from 'path';
import { TransactionBlock } from '@mysten/sui.js/transactions';

import { mainPackage } from '../../config/constants';
import { authorizeApp } from '../../init/authorization';
import { Packages } from '../../init/packages';
import { prepareMultisigTx, publishPackage } from '../../utils/utils';

export const execute = async () => {
	const constants = mainPackage.mainnet;
	const contractsFolder = path.resolve(__dirname + '../../../../packages');
	const txb = new TransactionBlock();

	// Publish subdomains package.
	publishPackage(txb, contractsFolder + '/temp_subdomain_proxy');

	// Authorize utils package.
	authorizeApp({
		txb,
		adminCap: constants.adminCap,
		suins: constants.suins,
		type: Packages('mainnet').Utils.authorizationType(
			'0xf7854c81cf500d60a4437f4599f7ff3b89abd13f645ae08f62345c7a25317bee',
		),
		suinsPackageIdV1: constants.packageId,
	});

	// Authorize utils package.
	authorizeApp({
		txb,
		adminCap: constants.adminCap,
		suins: constants.suins,
		type: Packages('mainnet').Subdomains.authorizationType(
			'0xe177697e191327901637f8d2c5ffbbde8b1aaac27ec1024c4b62d1ebd1cd7430',
		),
		suinsPackageIdV1: constants.packageId,
	});

	// setup subdomains package.
	Packages('mainnet').Subdomains.setupFunction(
		txb,
		'0xe177697e191327901637f8d2c5ffbbde8b1aaac27ec1024c4b62d1ebd1cd7430',
		constants.adminCap,
		constants.suins,
		constants.packageId,
	);

	await prepareMultisigTx(txb, 'mainnet', constants.adminAddress);
};

execute();
