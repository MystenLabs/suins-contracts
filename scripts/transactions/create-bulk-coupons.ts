// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
import { writeFileSync } from 'fs';
import { TransactionBlock } from '@mysten/sui.js/transactions';

import { mainPackage } from '../config/constants';
import { newCouponRules, optionalRangeConstructor, PercentageOffCoupon } from '../coupons/coupon';
import { prepareMultisigTx } from '../utils/utils';

function generateRandomString(length: number) {
	const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
	let result = '';
	const charactersLength = characters.length;

	for (let i = 0; i < length; i++) {
		result += characters.charAt(Math.floor(Math.random() * charactersLength));
	}

	return result;
}

const create = async () => {
	const pkg = mainPackage.mainnet;

	const tx = new TransactionBlock();

	const coupons50Off = [];

	const lengthRange = optionalRangeConstructor(tx, pkg, [3, 63]);
	const yearsRange = optionalRangeConstructor(tx, pkg, [1, 1]);

	// for batch operations with same setup coupons, we can create the coupon rules
	// once and re-use them (as they can be copied on-chain).
	const rules = newCouponRules(
		tx,
		pkg,
		{
			availableClaims: 1,
		},
		lengthRange,
		yearsRange,
	);

	// create 130 50% coupons
	for (let i = 0; i < 130; i++) {
		const coupon = generateRandomString(16);
		coupons50Off.push(coupon);
		new PercentageOffCoupon(50).setName(coupon).toTransaction(tx, pkg, rules);
	}

	const coupons33Off = [];

	// create 650 33% coupons.
	for (let i = 0; i < 650; i++) {
		const coupon = generateRandomString(16);
		coupons33Off.push(coupon);
		new PercentageOffCoupon(33).setName(coupon).toTransaction(tx, pkg, rules);
	}

	console.log('******** 50% Coupons ********');
	console.dir(coupons50Off, { depth: null });
	console.log('******** 33% Coupons ********');
	console.dir(coupons33Off, { depth: null });

	writeFileSync(
		'./tx/coupon-list.json',
		JSON.stringify(
			{
				coupons50Off,
				coupons33Off,
			},
			null,
			2,
		),
	);

	await prepareMultisigTx(tx, 'mainnet', pkg.adminAddress);
};

create();
