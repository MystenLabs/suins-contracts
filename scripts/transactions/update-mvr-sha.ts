// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
import { SuiGraphQLClient } from '@mysten/sui/graphql';
import { namedPackagesPlugin, Transaction } from '@mysten/sui/transactions';

import { mainPackage } from '../config/constants';
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

export const updateMvrSha = async () => {
	const transaction = new Transaction();
	const env = 'mainnet';
	const repository = 'https://github.com/MystenLabs/suins-contracts';

	const data = {
		core: {
			packageInfo: '0xf709e4075c19d9ab1ba5acb17dfbf08ddc1e328ab20eaa879454bf5f6b98758e',
			sha: '5fc29e165dfb6d8046c81eedfba8d276375ae66d',
			version: '4',
			path: 'packages/suins',
		},
		payments: {
			packageInfo: '0xa46d971d0e9298488605e1850d64fa067db9d66570dda8dad37bbf61ab2cca21',
			sha: '5fc29e165dfb6d8046c81eedfba8d276375ae66d',
			version: '1',
			path: 'packages/payments',
		},
		subnames: {
			packageInfo: '0x9470cf5deaf2e22232244da9beeabb7b82d4a9f7b9b0784017af75c7641950ee',
			sha: '5fc29e165dfb6d8046c81eedfba8d276375ae66d',
			version: '1',
			path: 'packages/subdomains',
		},
		coupons: {
			packageInfo: '0xf7f29dce2246e6c79c8edd4094dc3039de478187b1b13e871a6a1a87775fe939',
			sha: '5fc29e165dfb6d8046c81eedfba8d276375ae66d',
			version: '2',
			path: 'packages/coupons',
		},
		discounts: {
			packageInfo: '0xcb8d0cefcda3949b3ff83c0014cb50ca2a7c7b2074a5a7c1f2fce68cb9ad7dd6',
			sha: '5fc29e165dfb6d8046c81eedfba8d276375ae66d',
			version: '1',
			path: 'packages/discounts',
		},
		tempSubnameProxy: {
			packageInfo: '0x9accbc6d7c86abf91dcbe247fd44c6eb006d8f1864ff93b90faaeb09114d3b6f',
			sha: '5fc29e165dfb6d8046c81eedfba8d276375ae66d',
			version: '1',
			path: 'packages/temp-subname-proxy',
		},
	};

	for (const [name, { packageInfo, sha, version, path }] of Object.entries(data)) {
		console.log(`Processing package: ${name}`);

		transaction.moveCall({
			target: `@mvr/metadata::package_info::unset_git_versioning`,
			arguments: [transaction.object(packageInfo), transaction.pure.u64(version)],
		});

		const git = transaction.moveCall({
			target: `@mvr/metadata::git::new`,
			arguments: [
				transaction.pure.string(repository),
				transaction.pure.string(path),
				transaction.pure.string(sha),
			],
		});

		transaction.moveCall({
			target: `@mvr/metadata::package_info::set_git_versioning`,
			arguments: [transaction.object(packageInfo), transaction.pure.u64(version), git],
		});
	}

	await prepareMultisigTx(transaction, env, mainPackage.mainnet.adminAddress);
};

updateMvrSha();
