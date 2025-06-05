// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { Transaction } from '@mysten/sui/transactions';

import { mainPackage } from '../config/constants';
import { prepareMultisigTx } from '../utils/utils';

const fundsToTreasury = async () => {
	const txb = new Transaction();
	const config = mainPackage.mainnet;

	const adminCapObj = txb.object(config.adminCap);

	const suiProfits = txb.moveCall({
		target: `${config.packageId}::suins::withdraw`,
		arguments: [adminCapObj, txb.object(config.suins)],
	});

	const nsProfits = txb.moveCall({
		target: `${config.packageId}::suins::withdraw_custom`,
		arguments: [txb.object(config.suins), adminCapObj],
		typeArguments: [config.coins.NS.type],
	});

	const usdcProfits = txb.moveCall({
		target: `${config.packageId}::suins::withdraw_custom`,
		arguments: [txb.object(config.suins), adminCapObj],
		typeArguments: [config.coins.USDC.type],
	});

	txb.transferObjects(
		[suiProfits, nsProfits, usdcProfits],
		txb.pure.address(config.treasuryAddress!),
	);
	await prepareMultisigTx(txb, 'mainnet', config.adminAddress);
};

fundsToTreasury();
