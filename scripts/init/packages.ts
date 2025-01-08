// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { SuiTransactionBlockResponse } from '@mysten/sui/client';
import { Transaction } from '@mysten/sui/transactions';
import { MIST_PER_SUI } from '@mysten/sui/utils';

import { Config, mainPackage, MAX_AGE, MIST_PER_USDC, TESTNET_CONFIG } from '../config/constants';
import {
	addConfig,
	addRegistry,
	newLookupRegistry,
	newPaymentsConfig,
	newPriceConfigV1,
	newPriceConfigV2,
	newRenewalConfig,
	setupApp,
} from './authorization';
import { createDisplay } from './display_tp';
import { SuiNS, SuiNSDependentPackages, TempSubdomainProxy } from './manifests';

export type Network = 'mainnet' | 'testnet' | 'devnet' | 'localnet';

const parseCorePackageObjects = (data: SuiTransactionBlockResponse, isUpgrade = false) => {
	const packageId = data.objectChanges!.find((x) => x.type === 'published');
	if (!packageId || packageId.type !== 'published') throw new Error('Expected Published object');
	const upgradeCap = !isUpgrade
		? parseCreatedObject(data, '0x2::package::UpgradeCap')
		: parseMutatedObject(data, '0x2::package::UpgradeCap');

	return {
		packageId: packageId.packageId,
		upgradeCap: upgradeCap,
	};
};

const parseCreatedObject = (data: SuiTransactionBlockResponse, objectType: string) => {
	const obj = data.objectChanges!.find((x) => x.type === 'created' && x.objectType === objectType);
	if (!obj || obj.type !== 'created') throw new Error(`Expected ${objectType} object`);

	return obj.objectId;
};

const parseMutatedObject = (data: SuiTransactionBlockResponse, objectType: string) => {
	const obj = data.objectChanges!.find((x) => x.type === 'mutated' && x.objectType === objectType);
	if (!obj || obj.type !== 'mutated') throw new Error(`Expected ${objectType} object`);

	return obj.objectId;
};

export const Packages = (network: Network) => {
	const rev = network === 'localnet' ? 'main' : `framework/${network}`;
	const subdomainExtraDependencies = `denylist = { local = "../denylist" }`;

	return {
		SuiNS: {
			order: 1,
			folder: 'suins',
			manifest: SuiNS(rev),
			processPublish: (data: SuiTransactionBlockResponse) => {
				const { packageId, upgradeCap } = parseCorePackageObjects(data);
				const publisher = parseCreatedObject(data, '0x2::package::Publisher');
				const suins = parseCreatedObject(data, `${packageId}::suins::SuiNS`);
				const adminCap = parseCreatedObject(data, `${packageId}::suins::AdminCap`);

				return {
					packageId,
					upgradeCap,
					publisher,
					suins,
					adminCap,
				};
			},
			setupFunction: (
				txb: Transaction,
				packageId: string,
				adminCap: string,
				suins: string,
				publisher: string,
			) => {
				// Adds the default registry where name records and reverse records will live
				addRegistry({
					txb,
					adminCap,
					suins,
					suinsPackageIdV1: packageId,
					registry: newLookupRegistry({ txb, suinsPackageIdV1: packageId, adminCap: adminCap }),
					type: `${packageId}::registry::Registry`,
				});
				// Adds the configuration file (pricelist and public key)
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
						prices: [
							150 * Number(MIST_PER_USDC),
							50 * Number(MIST_PER_USDC),
							5 * Number(MIST_PER_USDC),
						],
					}),
					type: `${packageId}::pricing_config::RenewalConfig`,
				});
				// create display for names
				createDisplay({
					txb,
					publisher,
					isSubdomain: false,
					suinsPackageIdV1: packageId,
					network: 'testnet',
					subdomainsPackageId: packageId,
				});
				// create display for subnames
				createDisplay({
					txb,
					publisher,
					isSubdomain: true,
					suinsPackageIdV1: packageId,
					network: 'testnet',
					subdomainsPackageId: packageId,
				});
			},
			authorizationType: (packageId: string) => `${packageId}::controller::Controller`, // Authorize the suins controller
		},
		Utils: {
			order: 2,
			folder: 'utils',
			manifest: SuiNSDependentPackages(rev, 'utils'),
			processPublish: (data: SuiTransactionBlockResponse) => {
				const { packageId, upgradeCap } = parseCorePackageObjects(data);

				return {
					packageId,
					upgradeCap,
				};
			},
			authorizationType: (packageId: string) => `${packageId}::direct_setup::DirectSetup`,
		},
		DenyList: {
			order: 2,
			folder: 'denylist',
			manifest: SuiNSDependentPackages(rev, 'denylist'),
			processPublish: (data: SuiTransactionBlockResponse) => {
				const { packageId, upgradeCap } = parseCorePackageObjects(data);

				return {
					packageId,
					upgradeCap,
				};
			},
			authorizationType: (packageId: string) => `${packageId}::denylist::DenyListAuth`,
			setupFunction: (txb: Transaction, packageId: string, adminCap: string, suins: string) => {
				setupApp({ txb, adminCap, suins, target: `${packageId}::denylist` });
			},
		},
		DayOne: {
			order: 2,
			folder: 'day_one',
			manifest: SuiNSDependentPackages(rev, 'day_one'),
			processPublish: (data: SuiTransactionBlockResponse) => {
				const { packageId, upgradeCap } = parseCorePackageObjects(data);

				return {
					packageId,
					upgradeCap,
				};
			},
			authorizationType: (packageId: string) => `${packageId}::bogo::BogoApp`,
		},
		Coupons: {
			order: 2,
			folder: 'coupons',
			manifest: SuiNSDependentPackages(rev, 'coupons'),
			processPublish: (data: SuiTransactionBlockResponse) => {
				const { packageId, upgradeCap } = parseCorePackageObjects(data);

				return {
					packageId,
					upgradeCap,
				};
			},
			authorizationType: (packageId: string) => `${packageId}::coupon_house::CouponsApp`,
			setupFunction: ({
				txb,
				packageId,
				adminCap,
				suins,
			}: {
				txb: Transaction;
				packageId: string;
				adminCap: string;
				suins: string;
			}) => {
				setupApp({ txb, adminCap, suins, target: `${packageId}::coupon_house` });
			},
		},
		Payments: {
			order: 2,
			folder: 'payments',
			manifest: SuiNSDependentPackages(rev, 'payments'),
			processPublish: (data: SuiTransactionBlockResponse) => {
				const { packageId, upgradeCap } = parseCorePackageObjects(data);

				return {
					packageId,
					upgradeCap,
				};
			},
			authorizationType: (packageId: string) => `${packageId}::payments::PaymentsApp`,
			setupFunction: ({
				txb,
				packageId,
				adminCap,
				suins,
				suinsPackageIdV1,
			}: {
				txb: Transaction;
				packageId: string;
				adminCap: string;
				suins: string;
				suinsPackageIdV1: string;
			}) => {
				const config = mainPackage[network as keyof Config];
				const paymentsconfig = newPaymentsConfig({
					txb,
					packageId,
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
					suinsPackageIdV1,
					config: paymentsconfig,
					type: `${packageId}::payments::PaymentsConfig`,
				});
			},
		},
		Subdomains: {
			order: 3,
			folder: 'subdomains',
			manifest: SuiNSDependentPackages(rev, 'subdomains', subdomainExtraDependencies),
			processPublish: (data: SuiTransactionBlockResponse) => {
				const { packageId, upgradeCap } = parseCorePackageObjects(data);

				return {
					packageId,
					upgradeCap,
				};
			},
			setupFunction: (
				txb: Transaction,
				packageId: string,
				adminCap: string,
				suins: string,
				suinsPackageIdV1: string,
			) => {
				addConfig({
					txb,
					adminCap,
					suins,
					suinsPackageIdV1,
					config: txb.moveCall({
						target: `${packageId}::config::default`,
					}),
					type: `${packageId}::config::SubDomainConfig`,
				});
			},
			authorizationType: (packageId: string) => `${packageId}::subdomains::SubDomains`,
		},
		Discounts: {
			order: 3,
			folder: 'discounts',
			manifest: SuiNSDependentPackages(rev, 'discounts', 'day_one = { local = "../day_one" }'),
			processPublish: (data: SuiTransactionBlockResponse) => {
				const { packageId, upgradeCap } = parseCorePackageObjects(data);
				const discountHouse = parseCreatedObject(data, `${packageId}::house::DiscountHouse`);

				return {
					packageId,
					upgradeCap,
					discountHouse,
				};
			},
			authorizationType: (packageId: string) => `${packageId}::discounts::RegularDiscountsApp`,
		},
		TempSubdomainProxy: {
			order: 3,
			folder: 'temp_subdomain_proxy',
			manifest: TempSubdomainProxy(rev),
			processPublish: (data: SuiTransactionBlockResponse) => {
				const { packageId, upgradeCap } = parseCorePackageObjects(data);
				return {
					packageId,
					upgradeCap,
				};
			},
		},
	};
};
