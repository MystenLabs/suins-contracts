// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { Transaction, TransactionObjectArgument } from '@mysten/sui/transactions';

import { mainPackage, Network } from '../config/constants';
import { signAndExecute } from '../utils/utils';
import { CouponType } from './coupon';

const network = (process.env.NETWORK as Network) || 'testnet';
const config = mainPackage[network];

export const createCoupon = () => {
	const tx = new Transaction();
	const couponConfig = new CouponType(100, 0); // type = 0 for percentage discount, 15% off
	// couponConfig.setName('fiveplus15percentoff');
	couponConfig.setName('100percentoff');
	couponConfig.setLengthRule([5, 63]);
	couponConfig.setAvailableClaims(100);
	couponConfig.setYears([1, 3]);
	couponConfig.setExpiration('1800000000000');
	couponConfig.toTransaction(tx, config);

	return signAndExecute(tx, network);
};

export const applyCoupon =
	(intent: TransactionObjectArgument, couponCode: string) => (tx: Transaction) => {
		return tx.moveCall({
			target: `${config.coupons.packageId}::coupon_house::apply_coupon`,
			arguments: [tx.object(config.suins), intent, tx.pure.string(couponCode), tx.object.clock()],
		});
	};

// createCoupon();
