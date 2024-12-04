// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { getFullnodeUrl, SuiClient } from '@mysten/sui/client';
import { Transaction, TransactionObjectArgument } from '@mysten/sui/transactions';
import { MIST_PER_SUI } from '@mysten/sui/utils';
import { SuiPriceServiceConnection, SuiPythClient } from '@pythnetwork/pyth-sui-js';

import { mainPackage, Network } from '../config/constants';
import { CouponType } from '../coupons/coupon';
import { getActiveAddress, signAndExecute } from '../utils/utils';

const network = (process.env.NETWORK as Network) || 'testnet';
const config = mainPackage[network];

export const createCoupon = () => {
	const tx = new Transaction();
	const couponConfig = new CouponType(15, 0); // type = 0 for percentage discount, 15% off
	couponConfig.setName('fiveplus15percentoff');
	couponConfig.setLengthRule([5, 63]);
	couponConfig.setAvailableClaims(100);
	couponConfig.setYears([1, 3]);
	couponConfig.setExpiration('1800000000000');
	couponConfig.toTransaction(tx, config);

	return signAndExecute(tx, network);
};

createCoupon();
