// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
import { SuiGraphQLClient } from '@mysten/sui/graphql';
import { namedPackagesPlugin, Transaction } from '@mysten/sui/transactions';

import { mainPackage } from '../config/constants';
import objects from '../owned-objects.json';
import { prepareMultisigTx } from '../utils/utils';

/** Register the MVR plugin globally (once) for our PTB construction */
Transaction.registerGlobalSerializationPlugin(
	'namedPackagesPlugin',
	namedPackagesPlugin({
		suiGraphQLClient: new SuiGraphQLClient({
			url: 'https://mvr-rpc.sui-mainnet.mystenlabs.com/graphql',
		}),
	}),
);

export const registerMvrApps = async () => {
	const domainNft = objects.find((x) => x.data.content.fields.domain_name === 'suins.sui')!;

	const transaction = new Transaction();

	const coreApp = transaction.moveCall({
		target: `@mvr/core::move_registry::register`,
		arguments: [
			// the registry obj: Can also be resolved as `registry-obj@mvr` from mainnet SuiNS.
			transaction.object('0x0e5d473a055b6b7d014af557a13ad9075157fdc19b6d51562a18511afd397727'),
			transaction.object(domainNft.data.objectId),
			transaction.pure.string('core'),
			transaction.object.clock(),
		],
	});

	const paymentsApp = transaction.moveCall({
		target: `@mvr/core::move_registry::register`,
		arguments: [
			// the registry obj: Can also be resolved as `registry-obj@mvr` from mainnet SuiNS.
			transaction.object('0x0e5d473a055b6b7d014af557a13ad9075157fdc19b6d51562a18511afd397727'),
			transaction.object(domainNft.data.objectId),
			transaction.pure.string('payments'),
			transaction.object.clock(),
		],
	});

	const discounts = transaction.moveCall({
		target: `@mvr/core::move_registry::register`,
		arguments: [
			// the registry obj: Can also be resolved as `registry-obj@mvr` from mainnet SuiNS.
			transaction.object('0x0e5d473a055b6b7d014af557a13ad9075157fdc19b6d51562a18511afd397727'),
			transaction.object(domainNft.data.objectId),
			transaction.pure.string('discounts'),
			transaction.object.clock(),
		],
	});

	const coupons = transaction.moveCall({
		target: `@mvr/core::move_registry::register`,
		arguments: [
			// the registry obj: Can also be resolved as `registry-obj@mvr` from mainnet SuiNS.
			transaction.object('0x0e5d473a055b6b7d014af557a13ad9075157fdc19b6d51562a18511afd397727'),
			transaction.object(domainNft.data.objectId),
			transaction.pure.string('coupons'),
			transaction.object.clock(),
		],
	});

	const subnames = transaction.moveCall({
		target: `@mvr/core::move_registry::register`,
		arguments: [
			// the registry obj: Can also be resolved as `registry-obj@mvr` from mainnet SuiNS.
			transaction.object('0x0e5d473a055b6b7d014af557a13ad9075157fdc19b6d51562a18511afd397727'),
			transaction.object(domainNft.data.objectId),
			transaction.pure.string('subnames'),
			transaction.object.clock(),
		],
	});

	const tempSubnameProxy = transaction.moveCall({
		target: `@mvr/core::move_registry::register`,
		arguments: [
			// the registry obj: Can also be resolved as `registry-obj@mvr` from mainnet SuiNS.
			transaction.object('0x0e5d473a055b6b7d014af557a13ad9075157fdc19b6d51562a18511afd397727'),
			transaction.object(domainNft.data.objectId),
			transaction.pure.string('temp-subnames-proxy'),
			transaction.object.clock(),
		],
	});

	transaction.transferObjects(
		[coreApp, paymentsApp, discounts, coupons, subnames, tempSubnameProxy],
		mainPackage.mainnet.adminAddress,
	);

	await prepareMultisigTx(transaction, 'mainnet', mainPackage.mainnet.previousAdminAddress!);
};

registerMvrApps();
