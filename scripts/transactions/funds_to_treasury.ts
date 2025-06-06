// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { Transaction } from '@mysten/sui/transactions';

import { mainPackage } from '../config/constants';
import { prepareMultisigTx } from '../utils/utils';

const fundsToTreasury = async () => {
	const txb = new Transaction();
	const config = mainPackage.mainnet;

	const adminCapObj = txb.object(config.adminCap);

	const oldSuiProfits = txb.moveCall({
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

	const newSuiProfits = txb.moveCall({
		target: `${config.packageId}::suins::withdraw_custom`,
		arguments: [txb.object(config.suins), adminCapObj],
		typeArguments: [config.coins.SUI.type],
	});

	const amountPerWallet = 5555 * 1_000_000; // NS

	const [coin1, coin2, coin3, coin4] = txb.splitCoins(nsProfits, [
		amountPerWallet,
		amountPerWallet,
		amountPerWallet,
		amountPerWallet,
	]);

	// Twenty
	txb.transferObjects(
		[coin1],
		txb.pure.address('0x2b18746962b0726f52a1270159029127fb2b0bb162988e0846a12e66be47412b'),
	);

	// Hadess
	txb.transferObjects(
		[coin2],
		txb.pure.address('0x6de713dd053f3b44058b4756c393237cb36da39be53170f645e0b45d80f1f91f'),
	);

	// Tobi
	txb.transferObjects(
		[coin3],
		txb.pure.address('0x1700a1c885b616711d75306ba637323ba954ab6a08796405b7b33a4315705b8e'),
	);

	// William
	txb.transferObjects(
		[coin4],
		txb.pure.address('0x1cabbf164d13044f32e34cd075c1bd90596af9798e187d89035aa56d2683267c'),
	);

	txb.transferObjects(
		[oldSuiProfits, nsProfits, usdcProfits, newSuiProfits],
		txb.pure.address(config.adminAddress!),
	);
	await prepareMultisigTx(txb, 'mainnet', config.adminAddress);
};

fundsToTreasury();
