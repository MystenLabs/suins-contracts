// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { TransactionBlock } from '@mysten/sui.js/transactions';

import { mainPackage } from '../config/constants';
import { prepareMultisigTx } from '../utils/utils';

const craftTx = async () => {
	const txb = new TransactionBlock();
	const config = mainPackage.mainnet;

	const adminCapObj = txb.object(config.adminCap);

	const generalProfits = txb.moveCall({
		target: `${config.packageId}::suins::withdraw`,
		arguments: [adminCapObj, txb.object(config.suins)],
	});

	txb.transferObjects([generalProfits], txb.pure(config.treasuryAddress, 'address'));
	await prepareMultisigTx(txb, 'mainnet', config.adminAddress);
};

craftTx();
