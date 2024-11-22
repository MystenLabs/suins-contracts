// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { SuiTransactionBlockResponse } from '@mysten/sui/client';
import { Transaction } from '@mysten/sui/transactions';
import { MIST_PER_SUI } from '@mysten/sui/utils';

import {
	addConfig,
	addRegistry,
	newLookupRegistry,
	newPaymentsConfig,
	newPriceConfigV1,
	newPriceConfigV2,
	setupApp,
} from './authorization';
import { createDisplay } from './display_tp';
import { SuiNS, SuiNSDependentPackages, TempSubdomainProxy } from './manifests';

export type Network = 'mainnet' | 'testnet' | 'devnet' | 'localnet';

/// TODO: Move these constants to a constants file
const MIST_PER_USDC = 1000000;
const USDC_TYPE = '0xdba34672e30cb065b1f93e3ab55318768fd6fef66c15942c9f7cb846e2f900e7::usdc::USDC';
const USDC_METADATA = '0x69b7a7c3c200439c1b5f3b19d7d495d5966d5f08de66c69276152f8db3992ec6';
const SUINS_TYPE = '0x5145494a5f5100e645e4b0aa950fa6b68f614e8c59e17bc5ded3495123a79178::ns::NS';
const SUINS_METADATA = '0x279adec041f8ec5c2d419abf2c32713ae7930a9a3a1ff244c88e5ceced40db6e';
const SUI_TYPE = '0x2::sui::SUI';
const SUI_METADATA = '0x9258181f5ceac8dbffb7030890243caed69a9599d2886d957a9cb7656af3bdb3';
const MAX_AGE = 1000 * 60 * 60; // 1 Hour as max age, can be updated

const parseCorePackageObjects = (data: SuiTransactionBlockResponse) => {
	const packageId = data.objectChanges!.find((x) => x.type === 'published');
	if (!packageId || packageId.type !== 'published') throw new Error('Expected Published object');
	const upgradeCap = parseCreatedObject(data, '0x2::package::UpgradeCap');

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
					config: newPriceConfigV1({
						txb,
						suinsPackageIdV1: packageId,
						priceList: {
							three: 5 * Number(MIST_PER_SUI),
							four: 2 * Number(MIST_PER_SUI),
							fivePlus: 0.5 * Number(MIST_PER_SUI),
						},
					}),
					type: `${packageId}::config::Config`,
				});
				addConfig({
					txb,
					adminCap,
					suins,
					suinsPackageIdV1: packageId,
					config: newPriceConfigV2({
						txb,
						suinsPackageIdV1: packageId,
						ranges: [
							[3, 3],
							[4, 4],
							[5, 63],
						],
						prices: [
							500 * Number(MIST_PER_USDC),
							100 * Number(MIST_PER_USDC),
							20 * Number(MIST_PER_USDC),
						],
					}),
					type: `${packageId}::config::Config`,
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
		Registration: {
			order: 2,
			folder: 'registration',
			manifest: SuiNSDependentPackages(rev, 'registration'),
			processPublish: (data: SuiTransactionBlockResponse) => {
				const { packageId, upgradeCap } = parseCorePackageObjects(data);

				return {
					packageId,
					upgradeCap,
				};
			},
			authorizationType: (packageId: string) => `${packageId}::register::Register`,
		},
		Renewal: {
			order: 2,
			folder: 'renewal',
			manifest: SuiNSDependentPackages(rev, 'renewal'),
			processPublish: (data: SuiTransactionBlockResponse) => {
				const { packageId, upgradeCap } = parseCorePackageObjects(data);

				return {
					packageId,
					upgradeCap,
				};
			},
			authorizationType: (packageId: string) => `${packageId}::renew::Renew`,
			setupFunction: ({
				txb,
				packageId,
				adminCap,
				suinsPackageIdV1,
				suins,
				priceList,
			}: {
				txb: Transaction;
				packageId: string;
				suinsPackageIdV1: string;
				adminCap: string;
				suins: string;
				priceList: { [key: string]: number };
			}) => {
				const configuration = newPriceConfigV1({
					txb,
					suinsPackageIdV1,
					priceList,
				});
				setupApp({
					txb,
					adminCap,
					suins: suins,
					target: `${packageId}::renew::setup`,
					args: [configuration],
				});
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
				const paymentsconfig = newPaymentsConfig({
					txb,
					packageId,
					coinTypeAndDiscount: [
						[USDC_TYPE, USDC_METADATA, 0],
						[SUINS_TYPE, SUINS_METADATA, 10],
						[SUI_TYPE, SUI_METADATA, 0],
					],
					baseCurrencyType: USDC_TYPE,
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
			authorizationType: (packageId: string) => `${packageId}::house::DiscountHouseApp`,
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
