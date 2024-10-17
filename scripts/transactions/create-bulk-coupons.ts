// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
import { writeFileSync } from 'fs';
import { Transaction } from '@mysten/sui/transactions';

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

	const tx = new Transaction();

	const freeCouponAddress = '0x11469060268ba1d611e3ad95f3134332f68e21198ce068a14f30975336be9ca1';

	new PercentageOffCoupon(100)
		.setName(freeCouponAddress)
		.setAvailableClaims(200)
		.setYears([1, 1])
		.setUser(freeCouponAddress)
		.toTransaction(tx, pkg);

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

	const coupons80Off = [];

	// create 300 80% coupons
	for (let i = 0; i < 300; i++) {
		const coupon = generateRandomString(16);
		coupons80Off.push(coupon);
		new PercentageOffCoupon(80).setName(coupon).toTransaction(tx, pkg, rules);
	}

	const coupons25Off = [];

	// create 500 25% coupons.
	for (let i = 0; i < 500; i++) {
		const coupon = generateRandomString(16);
		coupons25Off.push(coupon);
		new PercentageOffCoupon(25).setName(coupon).toTransaction(tx, pkg, rules);
	}

	console.log('******** 80% Coupons ********');
	console.dir(coupons80Off, { depth: null });
	console.log('******** 25% Coupons ********');
	console.dir(coupons25Off, { depth: null });

	const lengthRange2 = optionalRangeConstructor(tx, pkg, [3, 3]);
	const yearsRange2 = optionalRangeConstructor(tx, pkg, [1, 1]);

	const rules2 = newCouponRules(
		tx,
		pkg,
		{
			expiration: '1729656000000',
		},
		lengthRange2,
		yearsRange2,
	);

	const unlimitedCoupon = [];

	// create 30% coupons for 3 length names
	const coupon = generateRandomString(16);
	unlimitedCoupon.push(coupon);
	new PercentageOffCoupon(30).setName(coupon).toTransaction(tx, pkg, rules2);

	writeFileSync(
		'./tx/coupon-list.json',
		JSON.stringify(
			{
				coupons80Off,
				coupons25Off,
				unlimitedCoupon,
			},
			null,
			2,
		),
	);

	await prepareMultisigTx(tx, 'mainnet', pkg.adminAddress);
};

create();
