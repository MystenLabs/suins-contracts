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

	const freeCouponAddresses25 = [
		'0xd7087d60e4c945e14c74e7037b6f31ec8a7fd70a761844cd7c80b787301c9dab',
		'0x9335c256a5338ac356dd21a21fe5f615b2a60557d95834ba92f67eedcd6aecff',
		'0xa625325b6f2f955a2db9183f450419df276fbf171e5e63293799f797bd79673b', //jmorgs
		'0x96196979add1646bc54d395829da9feac4baf4d56a94089f4e232034ecb091ab', //saevon
		'0xbb684e2faca83054dcf28e19cad91225647b76db76fff59f92114cd84479c853', //louisa
		'0x19b801391d32790263ce571ea0c52433dc7f1976ea48636981a6e12be695c7f3', //boon
	];

	for (const freeCouponAddress of freeCouponAddresses25) {
		new PercentageOffCoupon(100)
			.setName(freeCouponAddress)
			.setAvailableClaims(25)
			.setYears([1, 1])
			.setUser(freeCouponAddress)
			.toTransaction(tx, pkg);
	}

	const freeCouponAddress350 = '0xe347045b6f10cd3390aaa6971cd4b2395842ff9eac5fb4eac0cf2eee52e4fa2c';
	new PercentageOffCoupon(100)
		.setName(freeCouponAddress350)
		.setAvailableClaims(350)
		.setYears([1, 1])
		.setUser(freeCouponAddress350)
		.toTransaction(tx, pkg);

	// const lengthRange = optionalRangeConstructor(tx, pkg, [3, 63]);
	// const yearsRange = optionalRangeConstructor(tx, pkg, [1, 1]);

	// // for batch operations with same setup coupons, we can create the coupon rules
	// // once and re-use them (as they can be copied on-chain).
	// const rules = newCouponRules(
	// 	tx,
	// 	pkg,
	// 	{
	// 		availableClaims: 1,
	// 	},
	// 	lengthRange,
	// 	yearsRange,
	// );

	// const coupons80Off = [];

	// // create 300 80% coupons
	// for (let i = 0; i < 300; i++) {
	// 	const coupon = generateRandomString(16);
	// 	coupons80Off.push(coupon);
	// 	new PercentageOffCoupon(80).setName(coupon).toTransaction(tx, pkg, rules);
	// }

	// const coupons25Off = [];

	// // create 500 25% coupons.
	// for (let i = 0; i < 500; i++) {
	// 	const coupon = generateRandomString(16);
	// 	coupons25Off.push(coupon);
	// 	new PercentageOffCoupon(25).setName(coupon).toTransaction(tx, pkg, rules);
	// }

	// console.log('******** 80% Coupons ********');
	// console.dir(coupons80Off, { depth: null });
	// console.log('******** 25% Coupons ********');
	// console.dir(coupons25Off, { depth: null });

	// const lengthRange2 = optionalRangeConstructor(tx, pkg, [3, 3]);
	// const yearsRange2 = optionalRangeConstructor(tx, pkg, [1, 1]);

	// const rules2 = newCouponRules(
	// 	tx,
	// 	pkg,
	// 	{
	// 		expiration: '1729656000000',
	// 	},
	// 	lengthRange2,
	// 	yearsRange2,
	// );

	// const unlimitedCoupon = [];

	// // create 30% coupons for 3 length names
	// const coupon = generateRandomString(16);
	// unlimitedCoupon.push(coupon);
	// new PercentageOffCoupon(30).setName(coupon).toTransaction(tx, pkg, rules2);

	// writeFileSync(
	// 	'./tx/coupon-list.json',
	// 	JSON.stringify(
	// 		{
	// 			couponsOff,
	// 		},
	// 		null,
	// 		2,
	// 	),
	// );

	await prepareMultisigTx(tx, 'mainnet', pkg.adminAddress);
};

create();
