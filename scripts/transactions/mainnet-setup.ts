// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { Transaction } from '@mysten/sui/transactions';

import { mainPackage, MAX_AGE, MIST_PER_USDC } from '../config/constants';
import {
	addConfig,
	addCoreConfig,
	authorizeApp,
	deauthorizeApp,
	newPaymentsConfig,
	newPriceConfigV2,
	newRenewalConfig,
	removeConfig,
} from '../init/authorization';
import { prepareMultisigTx } from '../utils/utils';

// Upgrade Suins
const setupSuins = (txb: Transaction) => {
	const config = mainPackage['mainnet'];

	// Add new core config
	addConfig({
		txb,
		adminCap: config.adminCap,
		suins: config.suins,
		suinsPackageIdV1: config.packageIdV1,
		config: addCoreConfig({ txb, latestPackageId: config.packageId }),
		type: `${config.packageId}::core_config::CoreConfig`,
	});

	// Add new price configs
	addConfig({
		txb,
		adminCap: config.adminCap,
		suins: config.suins,
		suinsPackageIdV1: config.packageIdV1,
		config: newPriceConfigV2({
			txb,
			packageId: config.packageId,
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
		type: `${config.packageIdPricing}::pricing_config::PricingConfig`,
	});
	addConfig({
		txb,
		adminCap: config.adminCap,
		suins: config.suins,
		suinsPackageIdV1: config.packageIdV1,
		config: newRenewalConfig({
			txb,
			packageId: config.packageId,
			ranges: [
				[3, 3],
				[4, 4],
				[5, 63],
			],
			prices: [150 * Number(MIST_PER_USDC), 50 * Number(MIST_PER_USDC), 5 * Number(MIST_PER_USDC)],
		}),
		type: `${config.packageIdPricing}::pricing_config::RenewalConfig`,
	});

	authorizeApp({
		txb,
		adminCap: config.adminCap,
		suins: config.suins,
		type: `${config.packageId}::controller::ControllerV2`,
		suinsPackageIdV1: config.packageIdV1,
	});

	// authorize new discounts package
	authorizeApp({
		txb,
		adminCap: config.adminCap,
		suins: config.suins,
		type: `${config.discountsPackage}::discounts::RegularDiscountsApp`,
		suinsPackageIdV1: config.packageIdV1,
	});

	// authorize and add payments configs
	authorizeApp({
		txb,
		adminCap: config.adminCap,
		suins: config.suins,
		type: `${config.payments.packageId}::payments::PaymentsApp`,
		suinsPackageIdV1: config.packageIdV1,
	});
	const paymentsconfig = newPaymentsConfig({
		txb,
		packageId: config.payments.packageId,
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
		adminCap: config.adminCap,
		suins: config.suins,
		suinsPackageIdV1: config.packageIdV1,
		config: paymentsconfig,
		type: `${config.payments.packageId}::payments::PaymentsConfig`,
	});
	authorizeApp({
		txb,
		adminCap: config.adminCap,
		suins: config.suins,
		type: `${config.discountsPackage.packageId}::free_claims::FreeClaimsApp`,
		suinsPackageIdV1: config.packageIdV1,
	});
};

const deauthorize = (txb: Transaction) => {
	const config = mainPackage['mainnet'];

	deauthorizeApp({
		txb,
		adminCap: config.adminCap,
		suins: config.suins,
		type: `0x9d451fa0139fef8f7c1f0bd5d7e45b7fa9dbb84c2e63c2819c7abd0a7f7d749d::register::Register`,
		suinsPackageIdV1: config.packageIdV1,
	});
	deauthorizeApp({
		txb,
		adminCap: config.adminCap,
		suins: config.suins,
		type: `0xd5e5f74126e7934e35991643b0111c3361827fc0564c83fa810668837c6f0b0f::renew::Renew`,
		suinsPackageIdV1: config.packageIdV1,
	});

	// Remove old core/price config
	removeConfig({
		txb,
		adminCap: config.adminCap,
		suins: config.suins,
		type: `${config.packageIdV1}::config::Config`,
		suinsPackageIdV1: config.packageIdV1,
	});

	// Remove old direct setup configs
	removeConfig({
		txb,
		adminCap: config.adminCap,
		suins: config.suins,
		type: `0xf7854c81cf500d60a4437f4599f7ff3b89abd13f645ae08f62345c7a25317bee::direct_setup::DirectSetup`,
		suinsPackageIdV1: config.packageIdV1,
	});

	removeConfig({
		txb,
		adminCap: config.adminCap,
		suins: config.suins,
		type: `0xdac22652eb400beb1f5e2126459cae8eedc116b73b8ad60b71e3e8d7fdb317e2::direct_setup::DirectSetup`,
		suinsPackageIdV1: config.packageIdV1,
	});

	// Remove the old discount house app
	removeConfig({
		txb,
		adminCap: config.adminCap,
		suins: config.suins,
		type: `0x6a6ea140e095ddd82f7c745905054b3203129dd04a09d0375416c31161932d2d::house::DiscountHouseApp`,
		suinsPackageIdV1: config.packageIdV1,
	});

	// Deauthorize old controller, authorize new controller
	deauthorizeApp({
		txb,
		adminCap: config.adminCap,
		suins: config.suins,
		type: `${config.packageIdV1}::controller::Controller`,
		suinsPackageIdV1: config.packageIdV1,
	});
	// remove some more auths not needed
};

const deauthorizePackages = async () => {
	const config = mainPackage['mainnet'];
	const tx = new Transaction();

	// Setup Suins
	deauthorize(tx);

	// Prepare multisig tx
	await prepareMultisigTx(tx, 'mainnet', config.adminAddress);
};

const publishSetup = async () => {
	const config = mainPackage['mainnet'];
	const tx = new Transaction();

	// Setup Suins
	setupSuins(tx);

	// Prepare multisig tx
	await prepareMultisigTx(tx, 'mainnet', config.adminAddress);
};

publishSetup();
// deauthorize();
