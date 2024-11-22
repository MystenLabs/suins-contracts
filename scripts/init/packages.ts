// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { SuiTransactionBlockResponse } from '@mysten/sui/client';
import { Transaction } from '@mysten/sui/transactions';
import { MIST_PER_SUI } from '@mysten/sui/utils';

import {
	addConfig,
	addRegistry,
	newLookupRegistry,
	newPriceConfig,
	setupApp,
} from './authorization';
import { createDisplay } from './display_tp';
import { SuiNS, SuiNSDependentPackages, TempSubdomainProxy } from './manifests';

export type Network = 'mainnet' | 'testnet' | 'devnet' | 'localnet';

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
					config: newPriceConfig({
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
				const configuration = newPriceConfig({
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
			// setupFunction: ({
			// 	txb,
			// 	packageId,
			// 	adminCap,
			// 	suins,
			// }: {
			// 	txb: Transaction;
			// 	packageId: string;
			// 	adminCap: string;
			// 	suins: string;
			// }) => {
			// 	setupApp({ txb, adminCap, suins, target: `${packageId}::payments` });
			// },
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
