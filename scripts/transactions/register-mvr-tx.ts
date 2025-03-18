// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
import { TransactionArgument } from '@mysten/sui.js/transactions';
import { SuiGraphQLClient } from '@mysten/sui/graphql';
import { namedPackagesPlugin, Transaction } from '@mysten/sui/transactions';

import { mainPackage } from '../config/constants';
import { TempSubdomainProxy } from '../init/manifests';
import { prepareMultisigTx, sender } from '../utils/utils';

/** Register the MVR plugin globally (once) for our PTB construction */
Transaction.registerGlobalSerializationPlugin(
	'namedPackagesPlugin',
	namedPackagesPlugin({
		suiGraphQLClient: new SuiGraphQLClient({
			url: 'https://mvr-rpc.sui-mainnet.mystenlabs.com/graphql',
		}),
	}),
);

const MVRAppCaps = {
	core: '0xf30a07fc1fadc8bd33ed4a9af5129967008201387b979a9899e52fbd852b29a9',
	payments: '0xcb44143e2921ed0fb82529ba58f5284ec77da63a8640e57c7fa8c12e87fa8baf',
	subnames: '0x969978eba35e57ad66856f137448da065bc27962a1bc4a6dd8b6cc229c899d5a',
	coupons: '0x4f3fa0d4da16578b8261175131bc7a24dcefe3ec83b45690e29cbc9bb3edc4de',
	discounts: '0x327702a5751c9582b152db81073e56c9201fad51ecbaf8bb522ae8df49f8dfd1',
	tempSubnameProxy: '0x3b2582036fe9aa17c059e7b3993b8dc97ae57d2ac9e1fe603884060c98385fb2',
};

const UpgradeCaps = {
	core: '0x9cda28244a0d0de294d2b271e772a9c33eb47d316c59913d7369b545b4af098c',
	payments: '0x48c3b8897a70e34d7f482926a3453452c182fd1c78821a892584205d667206ce',
	coupons: '0x8773a3f2642c73fc1e418d70915b9fc26cd2647ecb3dac6b4040992ca6cc91b0',
	discounts: '0x111f34b015bbcc4f2f3d1ba27691cf6a5de09c9337c60812ec4769aed4ad4674',
	subnames: '0xc70ac60c1d65da22ed5f30def1a7dfd33ff3a70eb0bf75f12ab559c5f342ea12',
	tempSubnameProxy: '0x30cdbd781c027a129e0e15feb0409e950a78b376904ee66615a9d5d8d502c95b',
};

const DefaultRepository = 'https://github.com/mystenlabs/suins-contracts';

const AppsMetadata = {
	core: {
		title: 'SuiNS - Core Metadata',
		versions: [
			{
				version: 3,
				repository: DefaultRepository,
				path: 'packages/suins',
				sha: 'releases/mainnet/core/v3',
			},
			{
				version: 4,
				repository: DefaultRepository,
				path: 'packages/suins',
				sha: '5d1b2459dfde3447b12704cff5ae6f9149baaeaa',
			},
		],
		testnetPackageInfo: '0x729aefdbf015ed3cbe477d01ffba89658e5b1503a596c4e86c256c382307bfba',
		testnetAddress: '0x40eee27b014a872f5c3330dcd5329aa55c7fe0fcc6e70c6498852e2e3727172e',
		description:
			'The core SuiNS package. Used for registration/renewal, creating subdomains, and other core functionalities.',
		documentation_url: 'https://docs.suins.io/',
		homepage_url: 'https://suins.io/',
	},
	payments: {
		title: 'SuiNS - Payments Metadata',
		versions: [
			{
				version: 1,
				repository: DefaultRepository,
				path: 'packages/payments',
				sha: '5d1b2459dfde3447b12704cff5ae6f9149baaeaa',
			},
		],
		testnetPackageInfo: '0xc65ee429a1de9d5dc5069382ac14b303eef4d79bd5f9fa7fada6cff0da42dea9',
		testnetAddress: '0x9e8b85270cf5e7ec0ae44c745abe000b6dd7d8b54ca2d367e044d8baccefc10c',
		description: 'The SuiNS payments package. Used for registration/renewal payments.',
		documentation_url: 'https://docs.suins.io/',
		homepage_url: 'https://suins.io/',
	},
	coupons: {
		title: 'SuiNS - Coupons Metadata',
		versions: [
			{
				version: 2,
				repository: DefaultRepository,
				path: 'packages/coupons',
				sha: '5d1b2459dfde3447b12704cff5ae6f9149baaeaa',
			},
		],
		testnetPackageInfo: '0x5523dcc537bc04792b92e6c909daeed5fab3c9dc2e7d5cac58533aacb20be6ca',
		testnetAddress: '0x63029aae8abbefae4f4ac6c5e3e0021159ea93a94ba648681fd64caf5b40677a',
		description:
			'The SuiNS coupons package. Coupon codes can be used for lower registration/renewal fees.',
		documentation_url: 'https://docs.suins.io/',
		homepage_url: 'https://suins.io/',
	},
	discounts: {
		title: 'SuiNS - Discounts Metadata',
		versions: [
			{
				version: 1,
				repository: DefaultRepository,
				path: 'packages/discounts',
				sha: '5d1b2459dfde3447b12704cff5ae6f9149baaeaa',
			},
		],
		testnetPackageInfo: '0xb383570ed441a38ea341bb870ce5127e46057c269135e0ff3c2fd34c793be873',
		testnetAddress: '0x7976f9bfe81dcbdbb635efb0ecb02844cd79109d3a698d05c06ca9fd2f97d262',
		description:
			'The SuiNS discounts package. Specific NFTs can be used for lower registration/renewal fees.',
		documentation_url: 'https://docs.suins.io/',
		homepage_url: 'https://suins.io/',
	},
	subnames: {
		title: 'SuiNS - Subnames Metadata',
		versions: [
			{
				version: 1,
				repository: DefaultRepository,
				path: 'packages/subdomains',
				sha: '5d1b2459dfde3447b12704cff5ae6f9149baaeaa',
			},
		],
		testnetPackageInfo: '0xef48920513abd8c64f89a27d562082d9d3d7c0c8c0395a0334c7c02eb3bafca7',
		testnetAddress: '0x3c272bc45f9157b7818ece4f7411bdfa8af46303b071aca4e18c03119c9ff636',
		description: 'The SuiNS subnames package. Can be used to create and renew subdomains.',
		documentation_url: 'https://docs.suins.io/',
		homepage_url: 'https://suins.io/',
	},
	tempSubnameProxy: {
		title: 'SuiNS - Temp Subdomain Proxy Metadata',
		versions: [
			{
				version: 1,
				repository: DefaultRepository,
				path: 'packages/temp_subdomain_proxy',
				sha: '5d1b2459dfde3447b12704cff5ae6f9149baaeaa',
			},
		],
		testnetPackageInfo: '0xbb5fce6ef1236e2284b2889c511dd9ca57fe36b3b0307fa0fa6413000213de92',
		testnetAddress: '0x295a0749dae0e76126757c305f218f929df0656df66a6361f8b6c6480a943f12',
		description:
			'The SuiNS subname proxy package. A temporary proxy used to proxy subdomain requests.',
		documentation_url: 'https://docs.suins.io/',
		homepage_url: 'https://suins.io/',
	},
};

export const registerMvrApps = async () => {
	const transaction = new Transaction();

	const admin = sender(transaction);

	for (const key of Object.keys(AppsMetadata)) {
		const metadata = AppsMetadata[key as keyof typeof AppsMetadata];
		const appCapObject = transaction.object(MVRAppCaps[key as keyof typeof MVRAppCaps]);
		const upgradeCapObject = transaction.object(UpgradeCaps[key as keyof typeof UpgradeCaps]);

		// Creates new package info object.
		const packageInfo = transaction.moveCall({
			target: `@mvr/metadata::package_info::new`,
			arguments: [upgradeCapObject],
		});

		// Sets package info metadata
		transaction.moveCall({
			target: '@mvr/metadata::package_info::set_metadata',
			arguments: [
				packageInfo,
				transaction.pure.string('default'),
				transaction.pure.string(`@suins/${key}`),
			],
		});

		// Sets title of the package info
		const display = transaction.moveCall({
			target: `@mvr/metadata::display::default`,
			arguments: [transaction.pure.string(AppsMetadata[key as keyof typeof AppsMetadata].title)],
		});

		transaction.moveCall({
			target: `@mvr/metadata::package_info::set_display`,
			arguments: [transaction.object(packageInfo), display],
		});

		// time to create the git versioning too.
		for (const version of metadata.versions) {
			const git = transaction.moveCall({
				target: `@mvr/metadata::git::new`,
				arguments: [
					transaction.pure.string(version.repository),
					transaction.pure.string(version.path),
					transaction.pure.string(version.sha),
				],
			});

			transaction.moveCall({
				target: `@mvr/metadata::package_info::set_git_versioning`,
				arguments: [transaction.object(packageInfo), transaction.pure.u64(version.version), git],
			});
		}

		// now let's assign this to the equivalent `appCap` object.
		transaction.moveCall({
			target: `@mvr/core::move_registry::assign_package`,
			arguments: [
				// the registry obj: Can also be resolved as `registry-obj@mvr` from mainnet SuiNS.
				transaction.object(`0x0e5d473a055b6b7d014af557a13ad9075157fdc19b6d51562a18511afd397727`),
				appCapObject,
				transaction.object(packageInfo),
			],
		});

		if (metadata.testnetAddress) {
			// let's assign the testnet equivalent objects.
			const appInfo = transaction.moveCall({
				target: `@mvr/core::app_info::new`,
				arguments: [
					transaction.pure.option('address', metadata.testnetPackageInfo),
					transaction.pure.option('address', metadata.testnetAddress),
					transaction.pure.option('address', null),
				],
			});

			transaction.moveCall({
				target: `@mvr/core::move_registry::set_network`,
				arguments: [
					transaction.object('0x0e5d473a055b6b7d014af557a13ad9075157fdc19b6d51562a18511afd397727'),
					appCapObject,
					transaction.pure.string('4c78adac'),
					appInfo,
				],
			});
		}

		transaction.moveCall({
			target: `@mvr/core::move_registry::set_metadata`,
			arguments: [
				transaction.object(
					'0x0e5d473a055b6b7d014af557a13ad9075157fdc19b6d51562a18511afd397727', // Move registry
				),
				appCapObject,
				transaction.pure.string('description'), // key
				transaction.pure.string(AppsMetadata[key as keyof typeof AppsMetadata].description), // value
			],
		});

		transaction.moveCall({
			target: `@mvr/core::move_registry::set_metadata`,
			arguments: [
				transaction.object(
					'0x0e5d473a055b6b7d014af557a13ad9075157fdc19b6d51562a18511afd397727', // Move registry
				),
				appCapObject,
				transaction.pure.string('documentation_url'), // key
				transaction.pure.string(AppsMetadata[key as keyof typeof AppsMetadata].documentation_url), // value
			],
		});

		transaction.moveCall({
			target: `@mvr/core::move_registry::set_metadata`,
			arguments: [
				transaction.object(
					'0x0e5d473a055b6b7d014af557a13ad9075157fdc19b6d51562a18511afd397727', // Move registry
				),
				appCapObject,
				transaction.pure.string('homepage_url'), // key
				transaction.pure.string(AppsMetadata[key as keyof typeof AppsMetadata].homepage_url), // value
			],
		});

		// and now transfer the `PackageInfo` objects to the admin address (sender of tx).
		transaction.moveCall({
			target: `@mvr/metadata::package_info::transfer`,
			arguments: [transaction.object(packageInfo), admin],
		});
	}

	await prepareMultisigTx(transaction, 'mainnet', mainPackage.mainnet.adminAddress);
};

registerMvrApps();
