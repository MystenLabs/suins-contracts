// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
import { Transaction, TransactionArgument } from '@mysten/sui/transactions';
import { isValidSuiAddress } from '@mysten/sui/utils';

import { PackageInfo } from '../config/constants';

export class CouponType {
	name?: string;
	type?: number;
	value: string | number | bigint;
	rules: CouponRules;

	constructor(value: string | number | bigint, type?: number) {
		this.value = value;
		this.type = type;
		this.rules = {};
	}

	/**
	 * Accepts a range for characters.
	 * Use plain number for fixed length. (e.g. `setLengthRule(3)`)
	 * Use range for specific lengths. Max length = 63, min length = 3
	 */
	setLengthRule(range: number[] | number) {
		if (typeof range === 'number') range = [range, range];
		if (range.length !== 2 || range[1] < range[0] || range[0] < 3 || range[1] > 63)
			throw new Error('Range has to be 2 numbers, from smaller to number, between [3,63]');
		this.rules.length = range;
		return this;
	}

	setAvailableClaims(claims: number) {
		this.rules.availableClaims = claims;
		return this;
	}

	setUser(user: string) {
		if (!isValidSuiAddress(user)) throw new Error('Invalid address for user.');
		this.rules.user = user;
		return this;
	}

	setExpiration(timestamp_ms: string) {
		this.rules.expiration = timestamp_ms;
		return this;
	}

	/**
	 * Accepts a range for years, between [1,5]
	 */
	setYears(range: number[]) {
		if (range.length !== 2 || range[1] < range[0] || range[0] < 1 || range[1] > 5)
			throw new Error('Range has to be 2 numbers, from smaller to number, between [1,5]');
		this.rules.years = range;
		return this;
	}

	setName(name: string) {
		this.name = name;
		return this;
	}

	/**
	 * Converts the coupon to a transaction.
	 */
	toTransaction(txb: Transaction, config: PackageInfo, rules?: TransactionArgument): Transaction {
		if (this.type === undefined) throw new Error('You have to define a type');
		if (!this.name) throw new Error('Please define a name for the coupon');

		const hasRulesSet = !!rules;

		let adminCap = txb.object(config.adminCap);

		let lengthRule = rules ? null : optionalRangeConstructor(txb, config, this.rules.length);
		let yearsRule = hasRulesSet ? null : optionalRangeConstructor(txb, config, this.rules.years);

		let ruleArg = rules || newCouponRules(txb, config, this.rules, lengthRule!, yearsRule!);

		txb.moveCall({
			target: `${config.coupons.packageId}::coupon_house::admin_add_coupon`,
			arguments: [
				adminCap,
				txb.object(config.suins),
				txb.pure.string(this.name),
				txb.pure.u8(this.type),
				txb.pure.u64(this.value),
				ruleArg,
			],
		});

		return txb;
	}
}

export class FixedPriceCoupon extends CouponType {
	constructor(value: string | number | bigint) {
		super(value, 1);
	}
}
export class PercentageOffCoupon extends CouponType {
	constructor(value: string | number | bigint) {
		if (Number(value) <= 0 || Number(value) > 100)
			throw new Error('Percentage discount can be in (0, 100] range, 0 exclusive.');
		super(value, 0);
	}
}

export type CouponRules = {
	length?: number[];
	availableClaims?: number;
	user?: string;
	expiration?: string;
	years?: number[];
};

export const optionalRangeConstructor = (
	txb: Transaction,
	config: PackageInfo,
	range?: number[],
) => {
	if (!range)
		return txb.moveCall({
			target: '0x1::option::none',
			typeArguments: [`${config.coupons.packageId}::range::Range`],
			arguments: [],
		});

	let rangeArg = txb.moveCall({
		target: `${config.coupons.packageId}::range::new`,
		arguments: [txb.pure.u8(range[0]), txb.pure.u8(range[1])],
	});

	return txb.moveCall({
		target: '0x1::option::some',
		typeArguments: [`${config.coupons.packageId}::range::Range`],
		arguments: [rangeArg],
	});
};

export const newCouponRules = (
	txb: Transaction,
	config: PackageInfo,
	rules: CouponRules,
	lengthRule: TransactionArgument,
	yearsRule: TransactionArgument,
) => {
	return txb.moveCall({
		target: `${config.coupons.packageId}::rules::new_coupon_rules`,
		arguments: [
			lengthRule,
			txb.pure.option('u64', rules.availableClaims ?? null),
			txb.pure.option('address', rules.user ?? null),
			txb.pure.option('u64', rules.expiration ?? null),
			yearsRule,
		],
	});
};
