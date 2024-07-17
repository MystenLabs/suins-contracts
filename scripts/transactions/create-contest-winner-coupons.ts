// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
import { TransactionBlock } from '@mysten/sui.js/transactions';

import { mainPackage } from '../config/constants';
import { PercentageOffCoupon } from '../coupons/coupon';
import { prepareMultisigTx } from '../utils/utils';

const create = async () => {
	const pkg = mainPackage.mainnet;

	const tx = new TransactionBlock();

	new PercentageOffCoupon(100)
		.setName('0x88528ee645ca295e618fec3ad8735d79712a7c4964796717ac0dc2651261f795')
		.setAvailableClaims(1)
		.setLengthRule([4, 63])
		.setUser('0x88528ee645ca295e618fec3ad8735d79712a7c4964796717ac0dc2651261f795')
		.toTransaction(tx, pkg);

	new PercentageOffCoupon(100)
		.setName('0xda4e42546326a001086b70828e507ffe7a745e85cdc4bb1b25b52e54749999f4')
		.setAvailableClaims(1)
		.setLengthRule([4, 63])
		.setUser('0xda4e42546326a001086b70828e507ffe7a745e85cdc4bb1b25b52e54749999f4')
		.toTransaction(tx, pkg);

	new PercentageOffCoupon(100)
		.setName('0x74fed224663d295ba11e22522c53d76b09f7fa6ed1cce7ecf866c8edf417666e')
		.setAvailableClaims(1)
		.setLengthRule([4, 63])
		.setUser('0x74fed224663d295ba11e22522c53d76b09f7fa6ed1cce7ecf866c8edf417666e')
		.toTransaction(tx, pkg);

	await prepareMultisigTx(tx, 'mainnet', pkg.adminAddress);
};

create();
