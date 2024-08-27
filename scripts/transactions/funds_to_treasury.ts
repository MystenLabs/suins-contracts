// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { TransactionBlock } from '@mysten/sui.js/transactions';

import { mainPackage } from '../config/constants';
import { prepareMultisigTx } from '../utils/utils';

const craftTx = async () => {
	const txb = new TransactionBlock();
	const config = mainPackage.mainnet;

	const adminCapObj = txb.object(config.adminCap);

	// Auction house profits.
	const auctionProfits = txb.moveCall({
		target: `${config.packageId}::auction::admin_withdraw_funds`,
		arguments: [
			adminCapObj,
			txb.object('0x2588e11685b460c725e1dc6739a57c483fcd23977369af53d432605225e387f9'),
		],
	});

	const generalProfits = txb.moveCall({
		target: `${config.packageId}::suins::withdraw`,
		arguments: [adminCapObj, txb.object(config.suins)],
	});

	txb.transferObjects(
		[auctionProfits, generalProfits],
		txb.pure(config.treasuryAddress, 'address'),
	);
	await prepareMultisigTx(txb, 'mainnet', config.adminAddress);
};

craftTx();
