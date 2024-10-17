// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
import { getFullnodeUrl, SuiClient } from '@mysten/sui/client';
import { Transaction } from '@mysten/sui/transactions';
import { normalizeSuiAddress } from '@mysten/sui/utils';

import { ALLOWED_METADATA, SuinsClient, SuinsTransaction } from '../src';

export const e2eLiveNetworkDryRunFlow = async (network: 'mainnet' | 'testnet') => {
	const client = new SuiClient({ url: getFullnodeUrl(network) });

	const sender = normalizeSuiAddress('0x2');
	const suinsClient = new SuinsClient({
		client,
		network,
	});

	const tx = new Transaction();
	const suinsTx = new SuinsTransaction(suinsClient, tx);

	const uniqueName =
		(Date.now().toString(36) + Math.random().toString(36).substring(2)).repeat(2) + '.sui';

	const priceList = await suinsClient.getPriceList();
	// const _renewalPriceList = await suinsClient.getRenewalPriceList();
	const years = 1;

	// register test.sui for a year.
	const nft = suinsTx.register({
		name: uniqueName,
		years,
		price: suinsClient.calculatePrice({ name: uniqueName, years, priceList }),
	});
	// Sets the target address of the NFT.
	suinsTx.setTargetAddress({
		nft,
		address: sender,
		isSubname: false,
	});

	suinsTx.setDefault(uniqueName);

	// Sets the avatar of the NFT.
	suinsTx.setUserData({
		nft,
		key: ALLOWED_METADATA.avatar,
		value: '0x0',
	});

	suinsTx.setUserData({
		nft,
		key: ALLOWED_METADATA.contentHash,
		value: '0x1',
	});

	const subNft = suinsTx.createSubName({
		parentNft: nft,
		name: 'node.' + uniqueName,
		expirationTimestampMs: Date.now() + 1000 * 60 * 60 * 24 * 30,
		allowChildCreation: true,
		allowTimeExtension: true,
	});

	// create/remove some leaf names as an NFT
	suinsTx.createLeafSubName({
		parentNft: nft,
		name: 'leaf.' + uniqueName,
		targetAddress: sender,
	});
	suinsTx.removeLeafSubName({ parentNft: nft, name: 'leaf.' + uniqueName });

	// do it for sub nft too
	suinsTx.createLeafSubName({
		parentNft: subNft,
		name: 'leaf.node.' + uniqueName,
		targetAddress: sender,
	});
	suinsTx.removeLeafSubName({ parentNft: subNft, name: 'leaf.node.' + uniqueName });

	// extend expiration a bit further for the subNft
	suinsTx.extendExpiration({
		nft: subNft,
		expirationTimestampMs: Date.now() + 1000 * 60 * 60 * 24 * 30 * 2,
	});

	suinsTx.editSetup({
		parentNft: nft,
		name: 'node.' + uniqueName,
		allowChildCreation: true,
		allowTimeExtension: false,
	});

	// let's go 2 levels deep and edit setups!
	const moreNestedNft = suinsTx.createSubName({
		parentNft: subNft,
		name: 'more.node.' + uniqueName,
		allowChildCreation: true,
		allowTimeExtension: true,
		expirationTimestampMs: Date.now() + 1000 * 60 * 60 * 24 * 30,
	});

	suinsTx.editSetup({
		parentNft: subNft,
		name: 'more.node.' + uniqueName,
		allowChildCreation: false,
		allowTimeExtension: false,
	});

	// do it for sub nft too
	tx.transferObjects([moreNestedNft, subNft, nft], tx.pure.address(sender));

	tx.setSender(sender);

	if (network === 'mainnet') {
		tx.setGasPayment([
			{
				objectId: '0xc7fcf957faeb0cdd9809b2ab43e0a8bf7a945cfdac13e8cba527261fecefa4dd',
				version: '86466933',
				digest: '2F8iuFVJm55J96FnJ99Th493D254BaJkUccbwz5rHFDc',
			},
		]);
	} else if (network === 'testnet') {
		tx.setGasPayment([
			{
				objectId: '0xeb709b97ca3e87e385d019ccb7da4a9bd99f9405f9b0d692f21c9d2e5714f27a',
				version: '169261602',
				digest: 'HJehhEV1N8rqjjHbwDgjeCZJkHPRavMmihTvyTJme2rA',
			},
		]);
	}

	return client.dryRunTransactionBlock({
		transactionBlock: await tx.build({
			client,
		}),
	});
};
