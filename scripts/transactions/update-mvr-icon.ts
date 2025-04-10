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

export const updateMvrIcons = async () => {
	const transaction = new Transaction();
	transaction.addSerializationPlugin(mainnetPlugin);

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

	await prepareMultisigTx(transaction, 'mainnet', mainPackage.mainnet.adminAddress);
};

updateMvrIcons();
