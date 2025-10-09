// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { Transaction } from '@mysten/sui/transactions';

import { mainPackage } from '../config/constants';
import { prepareMultisigTx } from '../utils/utils';

const transferSuinsName = async () => {
	const txb = new Transaction();
	const config = mainPackage.mainnet;

	const multisigAddress = '0xa81a2328b7bbf70ab196d6aca400b5b0721dec7615bf272d95e0b0df04517e72';
	const suinsName = '0xea28f6f6cb6168a1b5a82804685cd80310a5570ac47ec920e26a2b09144ee9c3';

	const receiverAddress = '0xf4e213eb67291bbe135a63ed2311c4e411917d3a39da56aa2ff6bc81a36a4e8a';

	txb.transferObjects([suinsName], txb.pure.address(receiverAddress));
	await prepareMultisigTx(txb, 'mainnet', multisigAddress);
};

transferSuinsName();
