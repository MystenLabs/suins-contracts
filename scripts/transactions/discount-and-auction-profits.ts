// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { TransactionBlock } from '@mysten/sui.js/transactions';
import { MIST_PER_SUI, SUI_CLOCK_OBJECT_ID } from '@mysten/sui.js/utils';

import { mainPackage } from '../config/constants';
import { setupDiscountForType } from '../config/discounts';
import { prepareMultisigTx } from '../utils/utils';

export const run = async () => {
	const tx = new TransactionBlock();

	if (!mainPackage.mainnet.treasuryAddress) throw new Error('Treasury address not set');

	const auction = {
		packageId: '0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0',
		objectId: '0x2588e11685b460c725e1dc6739a57c483fcd23977369af53d432605225e387f9',
	};

	const adminCapObj = tx.object(mainPackage.mainnet.adminCap);

	// Presenting any SuinsRegistration NFT gives 30% discount.
	setupDiscountForType(
		tx,
		mainPackage.mainnet,
		`${mainPackage.mainnet.packageId}::suins_registration::SuinsRegistration`,
		{
			threeCharacterPrice: 350n * MIST_PER_SUI,
			fourCharacterPrice: 70n * MIST_PER_SUI,
			fivePlusCharacterPrice: 14n * MIST_PER_SUI,
		},
	);

	// auctions clean up (finalize).
	tx.moveCall({
		target: `${mainPackage.mainnet.packageId}::auction::admin_try_finalize_auctions`,
		arguments: [
			adminCapObj,
			tx.object(auction.objectId),
			tx.pure.u64(261),
			tx.object(SUI_CLOCK_OBJECT_ID),
		],
	});

	// Auction house profits.
	const auctionProfits = tx.moveCall({
		target: `${mainPackage.mainnet.packageId}::auction::admin_withdraw_funds`,
		arguments: [
			adminCapObj,
			tx.object('0x2588e11685b460c725e1dc6739a57c483fcd23977369af53d432605225e387f9'),
		],
	});

	const generalProfits = tx.moveCall({
		target: `${mainPackage.mainnet.packageId}::suins::withdraw`,
		arguments: [adminCapObj, tx.object(mainPackage.mainnet.suins)],
	});

	tx.transferObjects(
		[auctionProfits, generalProfits],
		tx.pure(mainPackage.mainnet.treasuryAddress, 'address'),
	);

	await prepareMultisigTx(tx, 'mainnet', mainPackage.mainnet.adminAddress);
};

run();
