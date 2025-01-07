// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { Transaction } from '@mysten/sui/transactions';

import { mainPackage, MAX_AGE, MIST_PER_USDC, TESTNET_CONFIG } from '../config/constants.js';
import { prepareMultisigTx, signAndExecute } from '../utils/utils.js';
import {
	addConfig,
	addRegistry,
	authorizeApp,
	deauthorizeApp,
	newLookupRegistry,
	newPaymentsConfig,
	newPriceConfigV1,
	newPriceConfigV2,
	newRenewalConfig,
	removeConfig,
	setupApp,
} from './authorization';

// Upgrade Suins
const setupSuins = async () => {
	const txb = new Transaction();
	const adminCap = TESTNET_CONFIG.suinsPackageId.adminCap;
	const suins = TESTNET_CONFIG.suinsObjectId;
	const packageId = TESTNET_CONFIG.suinsPackageId.latest;

	addConfig({
		txb,
		adminCap,
		suins,
		suinsPackageIdV1: packageId,
		config: newPriceConfigV2({
			txb,
			packageId,
			ranges: [
				[3, 3],
				[4, 4],
				[5, 63],
			],
			prices: [
				500 * Number(MIST_PER_USDC),
				100 * Number(MIST_PER_USDC),
				10 * Number(MIST_PER_USDC),
			],
		}),
		type: `${packageId}::pricing_config::PricingConfig`,
	});
	addConfig({
		txb,
		adminCap,
		suins,
		suinsPackageIdV1: packageId,
		config: newRenewalConfig({
			txb,
			packageId,
			ranges: [
				[3, 3],
				[4, 4],
				[5, 63],
			],
			prices: [150 * Number(MIST_PER_USDC), 50 * Number(MIST_PER_USDC), 5 * Number(MIST_PER_USDC)],
		}),
		type: `${packageId}::pricing_config::RenewalConfig`,
	});
	deauthorizeApp({
		txb,
		adminCap,
		suins,
		type: `${TESTNET_CONFIG.suinsPackageId.oldid}::controller::Controller`,
		suinsPackageIdV1: packageId,
	});
	authorizeApp({
		txb,
		adminCap,
		suins,
		type: `${packageId}::controller::Controller`,
		suinsPackageIdV1: packageId,
	});

	await signAndExecute(txb, 'testnet');
};

// Publish coupons new
const couponsSetup = async () => {
	const txb = new Transaction();
	const adminCap = TESTNET_CONFIG.suinsPackageId.adminCap;
	const suins = TESTNET_CONFIG.suinsObjectId;
	const couponsPackageId = TESTNET_CONFIG.coupons.id;
	const packageId = TESTNET_CONFIG.suinsPackageId.latest;

	deauthorizeApp({
		txb,
		adminCap,
		suins,
		type: `${TESTNET_CONFIG.coupons.oldid}::coupon_house::CouponsApp`,
		suinsPackageIdV1: packageId,
	});
	authorizeApp({
		txb,
		adminCap,
		suins,
		type: `${couponsPackageId}::coupon_house::CouponsApp`,
		suinsPackageIdV1: packageId,
	});

	setupApp({ txb, adminCap, suins, target: `${couponsPackageId}::coupon_house` });

	await signAndExecute(txb, 'testnet');
};

// Publish discounts new
const discountsSetup = async () => {
	const txb = new Transaction();
	const adminCap = TESTNET_CONFIG.suinsPackageId.adminCap;
	const suins = TESTNET_CONFIG.suinsObjectId;
	const discountsPackageId = TESTNET_CONFIG.discountsPackage.id;
	const packageId = TESTNET_CONFIG.suinsPackageId.latest;

	authorizeApp({
		txb,
		adminCap,
		suins,
		type: `${discountsPackageId}::discounts::RegularDiscountsApp`,
		suinsPackageIdV1: packageId,
	});

	await signAndExecute(txb, 'testnet');
};

// Publish payments new
const paymentsSetup = async () => {
	const txb = new Transaction();
	const adminCap = TESTNET_CONFIG.suinsPackageId.adminCap;
	const suins = TESTNET_CONFIG.suinsObjectId;
	const paymentsPackageId = TESTNET_CONFIG.paymentsId;
	const packageId = TESTNET_CONFIG.suinsPackageId.latest;
	const config = mainPackage['testnet'];

	authorizeApp({
		txb,
		adminCap,
		suins,
		type: `${paymentsPackageId}::payments::PaymentsApp`,
		suinsPackageIdV1: packageId,
	});

	const paymentsconfig = newPaymentsConfig({
		txb,
		packageId: paymentsPackageId,
		coinTypeAndDiscount: [
			[config.coins.USDC, 0],
			[config.coins.SUI, 0],
			[config.coins.NS, 25],
		],
		baseCurrencyType: config.coins.USDC.type,
		maxAge: MAX_AGE,
	});
	addConfig({
		txb,
		adminCap,
		suins,
		suinsPackageIdV1: packageId,
		config: paymentsconfig,
		type: `${paymentsPackageId}::payments::PaymentsConfig`,
	});

	await signAndExecute(txb, 'testnet');
};

const deAuthorize = async () => {
	const txb = new Transaction();
	const registrationPackageId = TESTNET_CONFIG.registrationPackageId;
	const renewalPackageId = TESTNET_CONFIG.renewalPackageId;
	const adminCap = TESTNET_CONFIG.suinsPackageId.adminCap;
	const suins = TESTNET_CONFIG.suinsObjectId;
	const packageId = TESTNET_CONFIG.suinsPackageId.latest;

	deauthorizeApp({
		txb,
		adminCap,
		suins,
		type: `${registrationPackageId}::register::Register`,
		suinsPackageIdV1: packageId,
	});

	deauthorizeApp({
		txb,
		adminCap,
		suins,
		type: `${renewalPackageId}::renew::Renew`,
		suinsPackageIdV1: packageId,
	});

	await signAndExecute(txb, 'testnet');
};

// setupSuins();
// couponsSetup();
// discountsSetup();
// paymentsSetup();
// deAuthorize();
