// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { Transaction, TransactionObjectArgument } from '@mysten/sui/transactions';

import { mainPackage, Network } from '../config/constants';
import { newPriceConfigV2 } from '../init/authorization';
import { getObjectType, signAndExecute } from '../utils/utils';

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
				prices: [30, 30, 30], // Discount percentages
			}),
		],
		typeArguments: [type],
	});

	return signAndExecute(tx, network);
};

export const applyDiscount = async (
	intent: TransactionObjectArgument,
	discountNft: string,
	network: Network,
	tx: Transaction,
) => {
	const discountNftType = await getObjectType(network, discountNft);

	tx.moveCall({
		target: `${config.discountsPackage.packageId}::discounts::apply_percentage_discount`,
		arguments: [
			tx.object(config.discountsPackage.discountHouseId),
			intent,
			tx.object(config.suins),
			tx.object(discountNft),
		],
		typeArguments: [discountNftType],
	});
};

// authorizeDiscountType(
// 	'0x80d7de9c4a56194087e0ba0bf59492aa8e6a5ee881606226930827085ddf2332::suifrens::SuiFren<0x80d7de9c4a56194087e0ba0bf59492aa8e6a5ee881606226930827085ddf2332::capy::Capy>',
// );
