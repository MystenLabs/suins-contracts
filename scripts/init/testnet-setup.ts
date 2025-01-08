// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { Transaction } from '@mysten/sui/transactions';

import { mainPackage, MAX_AGE, MIST_PER_USDC, TESTNET_CONFIG } from '../config/constants.js';
import { prepareMultisigTx, signAndExecute } from '../utils/utils.js';
import {
	addConfig,
	addCoreConfig,
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
	const packageIdOld = TESTNET_CONFIG.suinsPackageId.oldid;
	const packageV1 = TESTNET_CONFIG.suinsPackageId.v1;

	// removeConfig({
	// 	txb,
	// 	adminCap,
	// 	suins,
	// 	type: `${TESTNET_CONFIG.suinsPackageId.oldid}::pricing_config::PricingConfig`,
	// 	suinsPackageIdV1: TESTNET_CONFIG.suinsPackageId.v1,
	// });
	// removeConfig({
	// 	txb,
	// 	adminCap,
	// 	suins,
	// 	type: `${TESTNET_CONFIG.suinsPackageId.oldid}::pricing_config::RenewalConfig`,
	// 	suinsPackageIdV1: TESTNET_CONFIG.suinsPackageId.v1,
	// });

	// removeConfig({
	// 	txb,
	// 	adminCap,
	// 	suins,
	// 	type: `0x54800ebb4606fd0c03b4554976264373b3374eeb3fd63e7ff69f31cac786ba8c::renew::RenewalConfig`,
	// 	suinsPackageIdV1: TESTNET_CONFIG.suinsPackageId.v1,
	// });

	// addConfig({
	// 	txb,
	// 	adminCap,
	// 	suins,
	// 	suinsPackageIdV1: packageId,
	// 	config: newPriceConfigV2({
	// 		txb,
	// 		packageId,
	// 		ranges: [
	// 			[3, 3],
	// 			[4, 4],
	// 			[5, 63],
	// 		],
	// 		prices: [
	// 			500 * Number(MIST_PER_USDC),
	// 			100 * Number(MIST_PER_USDC),
	// 			10 * Number(MIST_PER_USDC),
	// 		],
	// 	}),
	// 	type: `${packageIdOld}::pricing_config::PricingConfig`,
	// });
	// addConfig({
	// 	txb,
	// 	adminCap,
	// 	suins,
	// 	suinsPackageIdV1: packageId,
	// 	config: newRenewalConfig({
	// 		txb,
	// 		packageId,
	// 		ranges: [
	// 			[3, 3],
	// 			[4, 4],
	// 			[5, 63],
	// 		],
	// 		prices: [150 * Number(MIST_PER_USDC), 50 * Number(MIST_PER_USDC), 5 * Number(MIST_PER_USDC)],
	// 	}),
	// 	type: `${packageIdOld}::pricing_config::RenewalConfig`,
	// });
	// deauthorizeApp({
	// 	txb,
	// 	adminCap,
	// 	suins,
	// 	type: `${packageId}::controller::Controller`,
	// 	suinsPackageIdV1: TESTNET_CONFIG.suinsPackageId.v1,
	// });
	// authorizeApp({
	// 	txb,
	// 	adminCap,
	// 	suins,
	// 	type: `${packageId}::controller::ControllerV2`,
	// 	suinsPackageIdV1: TESTNET_CONFIG.suinsPackageId.v1,
	// });

	// removeConfig({
	// 	txb,
	// 	adminCap,
	// 	suins,
	// 	type: `${packageIdV1}::core_config::CoreConfig`,
	// 	suinsPackageIdV1: TESTNET_CONFIG.suinsPackageId.v1,
	// });

	// addConfig({
	// 	txb,
	// 	adminCap,
	// 	suins,
	// 	suinsPackageIdV1: TESTNET_CONFIG.suinsPackageId.v1,
	// 	config: addCoreConfig({ txb, latestPackageId: packageId }),
	// 	type: `${packageIdOld}::core_config::CoreConfig`,
	// });

	await signAndExecute(txb, 'testnet');
};

// Publish coupons new
const couponsSetup = async () => {
	const txb = new Transaction();
	const adminCap = TESTNET_CONFIG.suinsPackageId.adminCap;
	const suins = TESTNET_CONFIG.suinsObjectId;
	const couponsPackageId = TESTNET_CONFIG.coupons.id;
	const packageId = TESTNET_CONFIG.suinsPackageId.latest;

	// deauthorizeApp({
	// 	txb,
	// 	adminCap,
	// 	suins,
	// 	type: `${TESTNET_CONFIG.coupons.oldid}::coupon_house::CouponsApp`,
	// 	suinsPackageIdV1: TESTNET_CONFIG.suinsPackageId.oldid,
	// });
	authorizeApp({
		txb,
		adminCap,
		suins,
		type: `${couponsPackageId}::coupon_house::CouponsApp`,
		suinsPackageIdV1: TESTNET_CONFIG.suinsPackageId.v1,
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
		suinsPackageIdV1: TESTNET_CONFIG.suinsPackageId.v1,
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

	// authorizeApp({
	// 	txb,
	// 	adminCap,
	// 	suins,
	// 	type: `${paymentsPackageId}::payments::PaymentsApp`,
	// 	suinsPackageIdV1: TESTNET_CONFIG.suinsPackageId.v1,
	// });

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
	// removeConfig({
	// 	txb,
	// 	adminCap,
	// 	suins,
	// 	type: `${paymentsPackageId}::payments::PaymentsConfig`,
	// 	suinsPackageIdV1: TESTNET_CONFIG.suinsPackageId.v1,
	// });
	addConfig({
		txb,
		adminCap,
		suins,
		suinsPackageIdV1: TESTNET_CONFIG.suinsPackageId.v1,
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
		suinsPackageIdV1: TESTNET_CONFIG.suinsPackageId.v1,
	});

	deauthorizeApp({
		txb,
		adminCap,
		suins,
		type: `${renewalPackageId}::renew::Renew`,
		suinsPackageIdV1: TESTNET_CONFIG.suinsPackageId.v1,
	});

	await signAndExecute(txb, 'testnet');
};

setupSuins();
// couponsSetup();
// discountsSetup();
// paymentsSetup();
// deAuthorize();
