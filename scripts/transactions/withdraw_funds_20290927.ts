// Copyright (c) 2023, Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { TransactionBlock } from '@mysten/sui.js';
import { mainPackage } from '../config/constants';
import { prepareMultisigTx } from '../airdrop/helper';

/// MystenLabs treasury address.
const ADDRESS_TO_TRANSFER_FUNDS =
	'0x638791b625c4482bc1b917847cdf8aa76fe226c0f3e0a9b1aa595625989e98a1';

const craftTx = async () => {
	const txb = new TransactionBlock();
	const config = mainPackage.mainnet;

	const adminCapObj = txb.object(config.adminCap);

	// Auction house profits.
	const auctionProfits = txb.moveCall({
		target: `${config.packageId}::auction::admin_withdraw_funds`,
		arguments: [adminCapObj, txb.object('0x2588e11685b460c725e1dc6739a57c483fcd23977369af53d432605225e387f9')],
	});

	const generalProfits = txb.moveCall({
		target: `${config.packageId}::suins::withdraw`,
		arguments: [adminCapObj, txb.object(config.suins)],
	})

	txb.transferObjects(
		[auctionProfits, generalProfits],
		txb.pure(ADDRESS_TO_TRANSFER_FUNDS, 'address'),
	);
	await prepareMultisigTx(txb, 'mainnet');
};

craftTx();
