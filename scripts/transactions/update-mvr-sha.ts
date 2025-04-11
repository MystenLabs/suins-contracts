// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
import { namedPackagesPlugin, Transaction } from '@mysten/sui/transactions';

import { mainPackage } from '../config/constants';
import { prepareMultisigTx } from '../utils/utils';

const mainnetPlugin = namedPackagesPlugin({ url: 'https://mainnet.mvr.mystenlabs.com' });

const MVRAppCaps = {
	core: '0xf30a07fc1fadc8bd33ed4a9af5129967008201387b979a9899e52fbd852b29a9',
	payments: '0xcb44143e2921ed0fb82529ba58f5284ec77da63a8640e57c7fa8c12e87fa8baf',
	subnames: '0x969978eba35e57ad66856f137448da065bc27962a1bc4a6dd8b6cc229c899d5a',
	coupons: '0x4f3fa0d4da16578b8261175131bc7a24dcefe3ec83b45690e29cbc9bb3edc4de',
	discounts: '0x327702a5751c9582b152db81073e56c9201fad51ecbaf8bb522ae8df49f8dfd1',
	tempSubnameProxy: '0x3b2582036fe9aa17c059e7b3993b8dc97ae57d2ac9e1fe603884060c98385fb2',
};

const iconUrl = 'https://docs.suins.io/logo.svg';

export const updateMvrSha = async () => {
	const transaction = new Transaction();
	transaction.addSerializationPlugin(mainnetPlugin);
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

	const moveRegistry = transaction.object(
		'0x0e5d473a055b6b7d014af557a13ad9075157fdc19b6d51562a18511afd397727',
	);

	for (const appCapObject of Object.values(MVRAppCaps)) {
		transaction.moveCall({
			target: `@mvr/core::move_registry::set_metadata`,
			arguments: [
				moveRegistry,
				transaction.object(appCapObject),
				transaction.pure.string('icon_url'), // key
				transaction.pure.string(iconUrl), // value
			],
		});
	}

	await prepareMultisigTx(transaction, env, mainPackage.mainnet.adminAddress);
};

updateMvrSha();
