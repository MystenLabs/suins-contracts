// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { Transaction, TransactionObjectArgument } from '@mysten/sui/transactions';

import { mainPackage, Network } from '../config/constants';
import { newPriceConfigV2 } from '../init/authorization';
import { signAndExecute } from '../utils/utils';

const network = (process.env.NETWORK as Network) || 'testnet';
const config = mainPackage[network];

export const authorizeDiscountType = (type: string) => {
	const tx = new Transaction();
	tx.moveCall({
		target: `${config.discountsPackage.packageId}::discounts::authorize_type`,
		arguments: [
			tx.object(config.discountsPackage.discountHouseId),
			tx.object(config.adminCap),
			newPriceConfigV2({
				txb: tx,
				packageId: config.packageId,
				ranges: [
					[3, 3],
					[4, 4],
					[5, 63],
				],
				prices: [60, 60, 60],
			}),
		],
		typeArguments: [type],
	});

	return signAndExecute(tx, network);
};

export const applyDiscount =
	(intent: TransactionObjectArgument, discountNft: string, discountType: string) =>
	(tx: Transaction) => {
		return tx.moveCall({
			target: `${config.discountsPackage.packageId}::discounts::apply_percentage_discount`,
			arguments: [
				tx.object(config.discountsPackage.discountHouseId),
				intent,
				tx.object(config.suins),
				tx.object(discountNft),
			],
			typeArguments: [discountType],
		});
	};

// authorizeDiscountType(
// 	'0x1f38138944eaf52428d7bdfb5166902eab33081e3f2cab61e355a6c3e7b1b5a9::demo_bear::DemoBear',
// );
