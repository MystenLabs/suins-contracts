// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import path from 'path';
import { TransactionBlock } from '@mysten/sui.js/transactions';

import { mainPackage } from '../../config/constants';
import { createDisplay } from '../../init/display_tp';
import { prepareMultisigTx, publishPackage } from '../../utils/utils';

export const secondTransaction = async () => {
	const constants = mainPackage.mainnet;
	const contractsFolder = path.resolve(__dirname + '../../../../packages');
	const txb = new TransactionBlock();

	publishPackage(txb, contractsFolder + '/utils');
	publishPackage(txb, contractsFolder + '/denylist');

	createDisplay({
		txb,
		publisher: constants.publisherId,
		isSubdomain: true,
		suinsPackageIdV1: 'TBD AFTER PACKAGE UPGRADE',
	});

	await prepareMultisigTx(txb, constants.adminAddress, 'mainnet');
};

secondTransaction();
