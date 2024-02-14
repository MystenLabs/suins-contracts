// Copyright (c) 2023, Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { TransactionBlock } from '@mysten/sui.js';
import dotenv from 'dotenv';

import { prepareMultisigTx } from '../airdrop/helper';
import { mainPackage } from '../config/constants';

dotenv.config();

const migrateToDirectRegistration = async () => {
	// read addresses from file
	// convert to batches.
	const tx = new TransactionBlock();

	if (!tx) throw new Error('TX not defined');

	// deauthorize starting new auctions.
	tx.moveCall({
		target: `${mainPackage.mainnet.packageId}::suins::deauthorize_app`,
		arguments: [tx.object(mainPackage.mainnet.adminCap), tx.object(mainPackage.mainnet.suins)],
		typeArguments: [`${mainPackage.mainnet.packageId}::auction::App`],
	});
	// authorize the new registration app.
	tx.moveCall({
		target: `${mainPackage.mainnet.packageId}::suins::authorize_app`,
		arguments: [tx.object(mainPackage.mainnet.adminCap), tx.object(mainPackage.mainnet.suins)],
		typeArguments: [`${mainPackage.mainnet.registrationPackageId}::register::Register`],
	});

	// prepare tx data.
	prepareMultisigTx(tx, 'mainnet');
};

migrateToDirectRegistration();
