// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
import { writeFileSync } from 'fs';
import { TransactionBlock } from '@mysten/sui.js/transactions';

import { mainPackage } from '../config/constants';
import { mainnetConfig } from '../config/day_one';
import { removeDiscountForType } from '../config/discounts';
import { newCouponRules, optionalRangeConstructor, PercentageOffCoupon } from '../coupons/coupon';
import { dayOneType } from '../day_one/setup';
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

	// Extend this PTB to also do the contest winner coupons.
	const threeCharacterWinners = [
		'0xf8e104b93ef573725859870bb549c6108e67bcd682842d67ac2794ec527477f4',
		'0xc6348ec469793ec2178860a7ac327843424062668cef3911b813e504b70f6994',
		'0x663d023eb7a68b625ab13abeee6d2e5d73ac3e2b0e0cd1a16a37086aa23777a6',
	];

	const forPlusCharWinners = [
		'0xd67336274170202b44065b34bfb1a28f431761172614462afb7ec1149ffa9857',
		'0xec7413a9f8c808059b4f609124eb6881218728da8db96028092c7475ce251f47',
		'0x259f728f9158f1c14e15ae7a8437ace4cb07fdc029bc68a0b8744c5af483818c',
		'0x82af78026b071fe0a7336513bf093cd18323909986d12bc9c0a4a11b2ca89a7b',
		'0x2fee8b921747f0ddf937e1257391884173bebc32825480e1430dbb2907a18026',
		'0xc9b43975021bdda84230882545e5ec274eb55227ee3c400e50ffcf06f50df400',
		'0xa04f30c0f21606d96ecd3c1a67eaa77537fed08151bd185332bd3f421a4f384f',
	];

	for (const winner of threeCharacterWinners) {
		new PercentageOffCoupon(100)
			.setName(winner)
			.setAvailableClaims(1)
			.setYears([1, 1])
			.setUser(winner)
			.toTransaction(tx, pkg);
	}

	for (const winner of forPlusCharWinners) {
		new PercentageOffCoupon(100)
			.setName(winner)
			.setAvailableClaims(1)
			.setYears([1, 1])
			.setLengthRule([4, 63])
			.setUser(winner)
			.toTransaction(tx, pkg);
	}

	// Also de-authorize the DayOne NFT discounts!
	removeDiscountForType(tx, pkg, dayOneType(mainnetConfig));

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
	for (let i = 0; i < 640; i++) {
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
