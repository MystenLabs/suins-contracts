// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
import { TransactionBlock } from '@mysten/sui.js/transactions';
import { MIST_PER_SUI } from '@mysten/sui.js/utils';

import { mainPackage } from '../config/constants';
import { mainnetConfig } from '../config/day_one';
import { setupDiscountForType } from '../config/discounts';
import { dayOneType } from '../day_one/setup';
import { prepareMultisigTx } from '../utils/utils';

export const run = async () => {
	const txb = new TransactionBlock();

	setupDiscountForType(txb, mainPackage.mainnet, dayOneType(mainnetConfig), {
		threeCharacterPrice: 250n * MIST_PER_SUI,
		fourCharacterPrice: 50n * MIST_PER_SUI,
		fivePlusCharacterPrice: 10n * MIST_PER_SUI,
	});

	await prepareMultisigTx(txb, 'mainnet', mainPackage.mainnet.adminAddress);
};

run();
