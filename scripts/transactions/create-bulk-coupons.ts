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
		'0xd7d0869fbb99c0489126d3726c802cd96eecfc6c787e8ba4d6b8a828518cb160',
		'0xfe9b9027e8b128fffe8e875544b8113011f6293354c725c83b82fca283b0ba83',
		'0x6eaf34907c2ea7731d2514b1c825f48b51e9969b640d40b35b29afca62d38611',
		'0x8511664660799efc60c9343c248edd737ab398ad6a21dfbd679c0ae10ac1c846',
		'0x84eec5448c9787c1bb599955b413ea93be8932ddd2c047da795733635eec7682',
		'0x12ad9b2ec47f349b8871c0dffd1afecfa3812f851d76a67e2b8c5f56a4281eb6',
		'0xac74f1822a2e958a5b0b96a64b9c81e7f7ba4be3a55052aee9d783888e936be6',
		'0x6a4ee2c623041b7a47678c3cb9e475399cda6e08c052a39e599c39a2b1d56462',
		'0xec423effd36516efff9cdf5c8146ac86badeeeb5d2b3ef907441201c9ab323d3',
		'0xd730d1a8ecc96c9aedf7fcb6e65dc3277ed63a2ff0fdbf7028da31bc1fa8f850',
	];

	const forPlusCharWinners = [
		'0x84c77cd0cb1ed702bbcc32a0f7befa66317967e850ae5c0248062590b630cdd5',
		'0x0ec7fe6976015c5545ac2b355a230d85c4d87d96e4c3787a866b4306cbfe7dab',
		'0x38fdd07f8fe5fa75ce77584d19e71447b14586cacdfc4b5b648ccf62c433625e',
		'0xf94b01642de7044d85b58cb4d0d64a92b7d62e01fde364b0de55a61e17614c25',
		'0xae16101f2638c2f9518a6ae6bfe1040ec2e13b207dac4f7eeb97d8c58e2cb041',
		'0x58f50bb973ec8ba53f2b6eb6b5ece817e37fef9cb9fcba06379be4e4d0de1d19',
		'0x15bbeea2a5cf826e9be47731c6d68b452c04ce75da3b5c38fda7320bbe4c6c86',
		'0xbdf958fe4a63f36690838348e40852c254a9cf68a02396b22e6dd7e82e682256',
		'0x1b0192cf7e1eadff280a3a40806e3220d6da883390e34d9b2dad908f81e7d121',
		'0xcb674e6906ff2ad4251e43b04309bfe1769c7d11a2d832ef9335c27f09cddb47',
		'0x964d3d01b9b433cefa1ce518f05c825e6a7c61c3925ae13c2643aaaa9688ebda',
		'0xc1ad93fd3e3aa913a8f729bcd21124ec0c99b035aa2e3a1e83678a610ce1d360',
		'0xddced6f24381f80ac5c2a24cd3d624389d25a789b89ec0c1230dd3f538c58e9f',
		'0xfc8be10e2766d4c3c06586bbe3861bbf3ee97ca15456149265b157f6548eb582',
		'0xe3f58e8e29fdd16baf6114ed5520e002d6d2c93691d9dd1f44efb62320de4cab',
		'0xfb509fa4ef2911938885fbf4fa32b8657abe6e2fccd2c4a26f2cdf30ed49df71',
		'0x6be18cc70ece7bf7cef8f4dd226a725952fba8dfca53845cc89eb67656c595a1',
		'0xbb7bdecf85dacf514ebbdf798340b2af44a3c38ec8b2c324d75c5c524a51bc08',
		'0x88528ee645ca295e618fec3ad8735d79712a7c4964796717ac0dc2651261f795',
		'0x8c3026cdca74f2dfaece33c1fc311f1c95fd0a3484114c1764035a62d81e30bc',
		'0x4c8d02ce023c77674c3e945d380b9b107127f178652ba6d18c762837cf37d40d',
		'0x45bf5c2602c1613ef1dadf65c72684834837af2dbfe43035614fcee299b4b875',
		'0xb7ca42c98659eeb7fe0e58f18e9a2012c717dd72d4ebfe8509854ad6db023858',
		'0x1fdcbb373789b14efe96ed1213f33b23aadf445b98efd6a8cbf26f00a8b36bc7',
		'0x9a07b94c3d1e71a775129f4b504ed1442bfa25a2fe0e1dca953abcf4825c30e7',
		'0x70f9af22da17e777c6b8a075bf9944cb503cce82ced51cb0545063cfdf21a909',
		'0x3a177fd99335e6a09f5f52fb7a1223788607059a7ea932144cfb1d65fd51362f',
		'0xc83d96d9bf8531424a30de69dddadd0889cfaf7d8f13264a038d2dfd1f0774fe',
		'0xce788a85525182291cddbb8a6ec390b241869e78235ea52586d7c1341bd4bde5',
		'0x92f1d8925fc613dcec25c6aa9f4407c945e04d7aa2a63411011a058f51a13488',
		'0x8f1680cb07b19947ff9c4400bcc452427d7765cec31de08966688dd46cb9e73d',
		'0xf8e104b93ef573725859870bb549c6108e67bcd682842d67ac2794ec527477f4',
		'0x1ffc8941ff9432c485a16e8a60482944c9f1d497888c6cdbeea244a7de0cdb62',
		'0x5dc5c1eacbc75d0697f14aafb04b5f666f4be840bf4b8006d949a136c2a9e19a',
		'0x04b6a8fb0485edbb414702836f1a3aa95f6f7559f230d510a11c4de95f5b9b38',
		'0x655096f35e75dbf2c4ee46bbf129896fe3c40e5f613aea4014a097e415689155',
		'0x340f2225c6ad1894fe133206166e18727d21bed9acca43c697f36601ec14b671',
		'0x9c03deedd937470cba60b58a4fcac8e7f3908d48564cdbc89deff889e131c753',
		'0x44b57e6bfffed4fbf4950cae2d051a1d4ab7c916a6073b6e3719d1079a4781b8',
		'0xb34c8afb65e89c78226fe16f148ec520765d34eb45e7e1439ceb9a4f9be9114f',
		'0xf97ee8562ff2ac92c4600ad869df98f1f21843b8e7b7a25ed08f5b1bda15a548',
		'0x2d231bc8dc12c6c19cc8a1695199eba720628739107d86c41e7b1fb464597b0f',
		'0x623bf168bb6a2be9ea92c2304cdccde2f6d34863a2d31f12264c37fff5e7fc8c',
		'0x230384b4888fe7f3a447824e85f30568fdb35006115d1f956df88ca2c7f43958',
		'0xfea3e95fefaae7a4396d65909c4611220de51ee6819098702ccfcf1a87e4f998',
		'0x33beea921f54acd8e11bc13e91ff957c7895789241650d5bb34b153c53c9ff0e',
		'0x3d9789262329e51af0ae401dc000f4a89609aa5858ffdbcba67f65ab65d11489',
		'0xc38880e32bcdd678a5a578cbf889f473e2273ae86d1c882fe41560c21147d486',
		'0xecc17c2179bc5aabc0405e5b3fa5d467923a36718ee0bd44020e0b119618be23',
		'0x0373ac37f9f158ffb55601170fa2938d9a142d43dd310e608d8c6ee0ca6c1c38',
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

	// // Also de-authorize the DayOne NFT discounts!
	// removeDiscountForType(tx, pkg, dayOneType(mainnetConfig));

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

	// // create 130 50% coupons
	// for (let i = 0; i < 130; i++) {
	// 	const coupon = generateRandomString(16);
	// 	coupons50Off.push(coupon);
	// 	new PercentageOffCoupon(50).setName(coupon).toTransaction(tx, pkg, rules);
	// }

	// const coupons33Off = [];

	// // create 650 33% coupons.
	// for (let i = 0; i < 640; i++) {
	// 	const coupon = generateRandomString(16);
	// 	coupons33Off.push(coupon);
	// 	new PercentageOffCoupon(33).setName(coupon).toTransaction(tx, pkg, rules);
	// }

	// console.log('******** 50% Coupons ********');
	// console.dir(coupons50Off, { depth: null });
	// console.log('******** 33% Coupons ********');
	// console.dir(coupons33Off, { depth: null });

	// writeFileSync(
	// 	'./tx/coupon-list.json',
	// 	JSON.stringify(
	// 		{
	// 			coupons50Off,
	// 			coupons33Off,
	// 		},
	// 		null,
	// 		2,
	// 	),
	// );

	await prepareMultisigTx(tx, 'mainnet', pkg.adminAddress);
};

create();
