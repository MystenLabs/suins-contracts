// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { Transaction } from '@mysten/sui/transactions';

import { mainPackage } from '../config/constants';
import { prepareMultisigTx } from '../utils/utils';

const fundsToTreasury = async () => {
	const txb = new Transaction();
	const config = mainPackage.mainnet;
	const coin = '0x1fdc78834208a8f777b45a6ed0bed664cf45f32421a6d60cfa8923755ea8d87d'; // NS coin

	const amountPerWallet = 7700 * 1_000_000; // NS

	const [coin1, coin2, coin3, coin4] = txb.splitCoins(coin, [
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

	await prepareMultisigTx(txb, 'mainnet', config.adminAddress);
};

fundsToTreasury();
