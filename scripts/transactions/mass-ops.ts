// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { writeFileSync } from 'fs';
import { TransactionBlock } from '@mysten/sui.js/transactions';

import { mainPackage } from '../config/constants';
import { removeDiscountForType } from '../config/discounts';
import { newCouponRules, optionalRangeConstructor, PercentageOffCoupon } from '../coupons/coupon';
import reservedObjects from '../reserved-names/owned-objects.json';
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

const run = async () => {
	const config = mainPackage.mainnet;

	// This is a list of free names and their addresses.
	const freeNamesAddresses = [
		...new Set([
			'0x29aa83013e8e5646f479188761e510fd4e7062123d0e1f0ffc654ecfde4d7550',
			'0x74bd991f694eb5792c10c3715a125629da67a0494e95b299ae23264210a53cf5',
			'0x29aa83013e8e5646f479188761e510fd4e7062123d0e1f0ffc654ecfde4d7550',
			'0x0ec7fe6976015c5545ac2b355a230d85c4d87d96e4c3787a866b4306cbfe7dab',
			'0x74bd991f694eb5792c10c3715a125629da67a0494e95b299ae23264210a53cf5',
			'0xc9a48d48a29103c30425b00b6c32d296d77b8ff1b35b811f92dbe664cd8e7419',
			'0xe01d5b06a9d68d5f6b36be3429f29eec8a5cb67fff1a9012e62836b686195f0b',
			'0x802f00dcb48842291f0aa7522971384585c035fedbcf0114bdbd37872586c731',
			'0xf7ae864c85a80f18de601da2e49dcb05f4fd0f00652d6e85bd3ecf09a81a0b74',
			'0xfb878709eea5da4cacdfd3549b072941b67ab6e3e6a537a95ba63ef93ae6f66b',
			'0x8948554e99cea7de0909c99131b3a654ac3eeb98b7c949a9153bd81565039eb2',
			'0x7ae777999816166b67e976f61b47e75c728e35408204de043624873a6399ee2f',
			'0x6e3b59ee4387d92c4f62e91e6e0fc6b29a2054563d1f1b47c8ba621196359af2',
			'0x40cdfd49d252c798833ddb6e48900b4cd44eeff5f2ee8e5fad76b69b739c3e62',
			'0x9258a21b994786427e5a159d31bf694a6df3ca063cfbd120465940db29a1a08c',
			'0x10eefc7a3070baa5d72f602a0c89d7b1cb2fcc0b101cf55e6a70e3edb6229f8b',
			'0x70f9af22da17e777c6b8a075bf9944cb503cce82ced51cb0545063cfdf21a909',
			'0x4e21ffd44dc8d204614fa5023dca9805455cf7959bc7bd7e4e4d7c5dbdc094e9',
			'0x5313143fac0a673c2d0113bca19e329584abc123fa433acba34def690d7651d3',
			'0xb4d1a84ad03ad10789c96d77a5890b9a55f09b4e0cc77aca218bf503d3d1531b',
			'0x1b0192cf7e1eadff280a3a40806e3220d6da883390e34d9b2dad908f81e7d121',
			'0x7a33a3801b2f5f773ba217a2ca477b9fdbddfbf48ee5944fc6d3b3782bb71b90',
		]),
	];

	const tx = new TransactionBlock();

	// remove discount for NS objects
	removeDiscountForType(tx, config, `${config.packageId}::suins_registration::SuinsRegistration`);

	// Transfer list of names to the specified wallet
	const namesToTransfer = ['gateio.sui', 'bybit.sui', 'okx.sui', 'binance.sui', 'kucoin.sui'];

	const names = reservedObjects
		.filter((obj) => namesToTransfer.includes(obj.data.content.fields.domain_name))
		.map((x) => x.data.objectId);
	// transfer the list.
	tx.transferObjects(
		names,
		tx.pure.address('0x11469060268ba1d611e3ad95f3134332f68e21198ce068a14f30975336be9ca1'),
	);

	// transfer `notifi.sui` to `0x2a25e5d858849bf2af0bf30aaa106bff8cdce25b9ae8ec3acfe1f2c346f30c36`
	const obj = reservedObjects.find((obj) => obj.data.content.fields.domain_name === 'notifi.sui');
	tx.transferObjects(
		[obj!.data.objectId],
		tx.pure.address('0x2a25e5d858849bf2af0bf30aaa106bff8cdce25b9ae8ec3acfe1f2c346f30c36'),
	);

	// 100% free coupons with 1 claim for the list of addresses
	for (const address of freeNamesAddresses) {
		new PercentageOffCoupon(100)
			.setAvailableClaims(1)
			.setName(`free-` + address)
			.setUser(address)
			.setYears([1, 1])
			.toTransaction(tx, config);
	}

	// 200 free claims for the specified wallet
	new PercentageOffCoupon(100)
		.setName('200xAnySize')
		.setAvailableClaims(200)
		.setYears([1, 1])
		.setUser('0x11469060268ba1d611e3ad95f3134332f68e21198ce068a14f30975336be9ca1')
		.toTransaction(tx, config);

	// 10 3 letter claims for the specified wallet
	new PercentageOffCoupon(100)
		.setName('10x3Letter')
		.setUser('0x7058563ff08994f7a29c9ecd6bec1ab18d6092d045abcd906c75b7fca9bec636')
		.setLengthRule(3)
		.setAvailableClaims(10)
		.setYears([1, 1])
		.toTransaction(tx, config);

	// 50 4 letter claims for the specified wallet
	new PercentageOffCoupon(100)
		.setName('50x4Letter')
		.setUser('0x7058563ff08994f7a29c9ecd6bec1ab18d6092d045abcd906c75b7fca9bec636')
		.setLengthRule(4)
		.setAvailableClaims(50)
		.setYears([1, 1])
		.toTransaction(tx, config);

	const lengthRange = optionalRangeConstructor(tx, config);
	const yearsRange = optionalRangeConstructor(tx, config, [1, 1]);

	const rules = newCouponRules(
		tx,
		config,
		{
			availableClaims: 1,
		},
		lengthRange,
		yearsRange,
	);

	const coupons: Record<string, { total: number; coupons: string[] }> = {
		'60': {
			total: 150,
			coupons: [],
		},
		'40': {
			total: 150,
			coupons: [],
		},
		'50': {
			total: 500,
			coupons: [],
		},
		'25': {
			total: 75,
			coupons: [],
		},
	};

	for (const [discount, { total }] of Object.entries(coupons)) {
		for (let i = 0; i < total; i++) {
			const name = generateRandomString(10);
			coupons[discount].coupons.push(name);
			new PercentageOffCoupon(parseInt(discount)).setName(name).toTransaction(tx, config, rules);
		}
	}

	writeFileSync('./tx/coupons.json', JSON.stringify(coupons, null, 2));

	await prepareMultisigTx(tx, 'mainnet', mainPackage.mainnet.adminAddress);
};

run();
