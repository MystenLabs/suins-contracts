// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
import { Transaction } from '@mysten/sui/transactions';

import { mainPackage } from '../config/constants';
import { PercentageOffCoupon } from '../coupons/coupon';
import { prepareMultisigTx } from '../utils/utils';
import addresses from './addresses.json';

/// Issue free claim coupon for anyone who purchased 3-digit names
/// with full price.
const prepareCoupons = async () => {
	const pkg = mainPackage.mainnet;
	const tx = new Transaction();

	const expiration = `1760691600000`; // 2025 Oct 17 09:00:00 UTC

	// Create a free claim coupon for each wallet
	for (const wallet of addresses) {
		let coupon = new PercentageOffCoupon(100);

		coupon.setName(`free-claim-${wallet}`);

		coupon.setExpiration(expiration);
		coupon.setUser(wallet);
		coupon.setAvailableClaims(1);
		coupon.setYears([1, 1]);
		coupon.toTransaction(tx, pkg);
	}

	await prepareMultisigTx(tx, 'mainnet', pkg.adminAddress);
};

prepareCoupons();
