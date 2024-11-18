// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
import { Transaction } from '@mysten/sui/transactions';

import { mainPackage } from '../config/constants';
import { prepareMultisigTx } from '../utils/utils';

const NETWORK = 'mainnet';
const config = mainPackage.mainnet;

// The new multisig address to transfer the caps to.
const NEW_MULTISIG_ADDR = '0x9b388a6da9dd4f73e0b13abc6100f1141782ef105f6f5e9d986fb6e00f0b2591';

const UPGRADE_CAPS_TO_TRANSFER = [
    // subdomains proxy
    '0x2418376bf13706188d300f077b2378e1b3853490dd1b2007e0b736cc22f5115a',
    // denylist
    '0x72a3c603d0218ab59ae81363e608d6c3c0c344890df40bd6ca7de575f28feb7d',
    // registration
    '0x779ed3df4bdfa55948580f1688ab1fede83f09d6d38fedb2a87b90d5c5179e58',
    // coupons
    '0x8773a3f2642c73fc1e418d70915b9fc26cd2647ecb3dac6b4040992ca6cc91b0',
    // discord
    '0x92420e30681a76fe01df4b54b0e01cc728f3cb3a3cec44f66cdcb4e95f0cb8fc',
    // utils (direct_setup), extended with subnames.
    '0x929162c097e47cffabb57e8c1cf334ff44a84b963f0bbaacfbaf792d79993866',
    // discounts
    '0x94e2a248ea1c6885b873eb0185abfd3a60fe1e4e552c419233a4ad4a0a5053ca',
    // SuiNS (!! core package)
    '0x9cda28244a0d0de294d2b271e772a9c33eb47d316c59913d7369b545b4af098c',
    // subnames
    '0xc70ac60c1d65da22ed5f30def1a7dfd33ff3a70eb0bf75f12ab559c5f342ea12',
    // AEON
    '0xd5e3b3b8adc2358e031990f3be5c1c8999967666bb3a8ff7c35fd8bc961e06c5',
    // DayOne NFT
    '0xe6b62ca1590fec4191e58f295ad62c2ac0a335027ffc7afb492d06eaace6e105',
    // another utils (direct_setup), initial
    '0xe6e24cdf4824e0e14c2cfa97052df2d85ebac61bd8e6ab3d5094c477f4db2eda',
    // renewals
    '0xf7750345cc6c90dc40b1dd93ea761ddfb429761d98ff57d2df3a41a492ba3979'
];

const MISC_PACKAGE_OBJECTS_TO_TRANSFER = [
    // Transfer Policy Cap: AeonNFT 
    '0xda9a0354509849dbbdc4aa3fdd6fa855eee92a5107fe971ccfcc42558e32e9fb',
    // Transfer Policy Cap: DayOne nft
    '0x9b8b6f61f6eb837a00d586f153bb7003dbf82b1dfba49d3b90a0c529c718469a',
    // Transfer Policy Cap: Subname NFTs
    '0x82535637ee6e59592a8c3e5c9112ee2a2df18fe9544e517be1f85ebdfadfc4ca',
    // Transfer Policy Cap: NS NFTs
    '0x50e63d31137d695e0a42294509d09ba3277a74d634dccf1a703c20a8c1d633f7',

    // Display: Subname NFTs
    '0xaf0cdabb6592026c58dae385d84791f21ce8e35a75f343f7e11acaf224f6a680',
    // Display: NS NFTs
    '0x866fbd8e51b6637c25f0e811ece9a85eb417f3987ecdfefb80f15d1192d72b4c',
    // Display: Aeon
    '0x91086cd554b47838d482521a8a302376120e000abe0c29b227a1371661060074',
    // Display: DayOne NFT
    '0x821acc2362883cbe8b896bd2656a8b22c31cd3598797a2ad3db2b9a697d98508',

    // Publisher: Aeon
    '0x47339900499df62ac40c21d44198331119d5335c7f94777295e5a84f5ae351f7',
    // Publisher: SuiNS
    '0x7339f23f06df3601167d67a31752781d307136fd18304c48c928778e752caae1',
    // Publisher: DayOne NFT
    '0x7b9fa20eb51210af6060f88fd1468b405d6306f6518deecf93c5ab1955165ce0',
];

const APP_CAPS_TO_TRANSFER = [
    // DiscordCap
    '0xd369c89ef88534b5ba9a78f16fec6adb3b5bc5d2ae72c990fd8aaccae1f2c56b',
    // SuiNS Admin Cap (!! core package)
    '0x3f8d702d90c572b60ac692fb5074f7a7ac350b80d9c59eab4f6b7692786cae0a'
];

const profitsToTreasury = (txb: Transaction) => {
	const generalProfits = txb.moveCall({
		target: `${config.packageId}::suins::withdraw`,
		arguments: [txb.object(config.adminCap), txb.object(config.suins)],
	});

	txb.transferObjects([generalProfits], txb.pure.address(config.treasuryAddress!));
};

const treasuryClaimAndMoveCapsToFoundation = async () => {
	const txb = new Transaction();

	// transfer profits to treasury
	profitsToTreasury(txb);
    
    txb.transferObjects([
        ...UPGRADE_CAPS_TO_TRANSFER,
        ...MISC_PACKAGE_OBJECTS_TO_TRANSFER,
        ...APP_CAPS_TO_TRANSFER
    ], txb.pure.address(NEW_MULTISIG_ADDR));

	await prepareMultisigTx(txb, 'mainnet', config.adminAddress);
};

treasuryClaimAndMoveCapsToFoundation();
