// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
import { SuiGraphQLClient } from '@mysten/sui/graphql';
import { namedPackagesPlugin, Transaction } from '@mysten/sui/transactions';

import { mainPackage } from '../config/constants';
import { prepareMultisigTx, sender } from '../utils/utils';
import { TempSubdomainProxy } from '../init/manifests';
import { TransactionArgument } from '@mysten/sui.js/transactions';

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
	tempSubnameProxy: '0x3b2582036fe9aa17c059e7b3993b8dc97ae57d2ac9e1fe603884060c98385fb2'
}

const UpgradeCaps = {
	core: '0x9cda28244a0d0de294d2b271e772a9c33eb47d316c59913d7369b545b4af098c',
	payments: '0x48c3b8897a70e34d7f482926a3453452c182fd1c78821a892584205d667206ce',
	coupons: '0x8773a3f2642c73fc1e418d70915b9fc26cd2647ecb3dac6b4040992ca6cc91b0',
	discounts: '0x111f34b015bbcc4f2f3d1ba27691cf6a5de09c9337c60812ec4769aed4ad4674',
	subnames: '0xc70ac60c1d65da22ed5f30def1a7dfd33ff3a70eb0bf75f12ab559c5f342ea12',
	tempSubnameProxy: '0x30cdbd781c027a129e0e15feb0409e950a78b376904ee66615a9d5d8d502c95b'
}

const DefaultRepository = 'https://github.com/mystenlabs/suins-contracts';

const AppsMetadata = {
	core: {
		title: 'SuiNS - Core Metadata',
		versions: [
			{ version: 3, repository: DefaultRepository, path: 'packages/suins', sha: 'releases/mainnet/core/v3' },
			{ version: 4, repository: DefaultRepository, path: 'packages/suins', sha: '5d1b2459dfde3447b12704cff5ae6f9149baaeaa' },
		],
		testnetPackageInfo: '',
		testnetAddress: '',
	},
	payments: {
		title: 'SuiNS - Payments Metadata',
		versions: [
			{ version: 1, repository: DefaultRepository, path: 'packages/payments', sha: '5d1b2459dfde3447b12704cff5ae6f9149baaeaa' },
		],
		testnetPackageInfo: '',
		testnetAddress: '',
	},
	coupons: {
		title: 'SuiNS - Coupons Metadata',
		versions: [
			{ version: 1, repository: DefaultRepository, path: 'packages/coupons', sha: '5d1b2459dfde3447b12704cff5ae6f9149baaeaa' },
		],
		testnetPackageInfo: '',
		testnetAddress: '',
	},
	discounts: {
		title: 'SuiNS - Discounts Metadata',
		versions: [
			{ version: 1, repository: DefaultRepository, path: 'packages/discounts', sha: '5d1b2459dfde3447b12704cff5ae6f9149baaeaa' },
		],
		testnetPackageInfo: '',
		testnetAddress: '',
	},
	subnames: {
		title: 'SuiNS - Subnames Metadata',
		versions: [
			{ version: 1, repository: DefaultRepository, path: 'packages/subnames', sha: '5d1b2459dfde3447b12704cff5ae6f9149baaeaa' },
		],
		testnetPackageInfo: '',
		testnetAddress: '',
	},
	tempSubnameProxy: {
		title: 'SuiNS - Temp Subdomain Proxy Metadata',
		versions: [
			{ version: 1, repository: DefaultRepository, path: 'packages/temp_subdomain_proxy', sha: '5d1b2459dfde3447b12704cff5ae6f9149baaeaa' },
		],
		testnetPackageInfo: '',
		testnetAddress: '',
	},
}

export const registerMvrApps = async () => {
	const transaction = new Transaction();

	const admin = sender(transaction);

	for (const key of Object.keys(AppsMetadata)) {

		const metadata = AppsMetadata[key as keyof typeof AppsMetadata];
		const appCapObject = transaction.object(MVRAppCaps[key as keyof typeof MVRAppCaps]);
		const upgradeCapObject = transaction.object(UpgradeCaps[key as keyof typeof UpgradeCaps]);


		const packageInfo = transaction.moveCall({
			target: `@mvr/metadata::package_info::new`,
			arguments: [upgradeCapObject],
		});

		const display = transaction.moveCall({
			target: `@mvr/metadata::display::default`,
			arguments: [
				transaction.pure.string(AppsMetadata[key as keyof typeof AppsMetadata].title)
			],
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
				arguments: [
					transaction.object(packageInfo),
					transaction.pure.u64(version.version),
					git,
				],
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
					transaction.pure.option("address", metadata.testnetPackageInfo),
					transaction.pure.option("address", metadata.testnetAddress),
					transaction.pure.option("address", null),
				],
			});

			transaction.moveCall({
				target: `@mvr/core::move_registry::set_network`,
				arguments: [
					transaction.object('0x0e5d473a055b6b7d014af557a13ad9075157fdc19b6d51562a18511afd397727'),
					appCapObject,
					transaction.pure.string("4c78adac"),
					appInfo,
				],
			});
		}

		// and now transfer the `PackageInfo` objects to the admin address (sender of tx).
		transaction.moveCall({
			target: `@mvr/metadata::package_info::transfer`,
			arguments: [transaction.object(packageInfo), admin],
		});
	}

	await prepareMultisigTx(transaction, 'mainnet', mainPackage.mainnet.adminAddress);
};

registerMvrApps();
