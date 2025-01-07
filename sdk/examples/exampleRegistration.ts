// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { getFullnodeUrl, SuiClient } from '@mysten/sui/client';
import { Transaction } from '@mysten/sui/transactions';

import { SuinsClient } from '../src/suins-client';
import { SuinsTransaction } from '../src/suins-transaction';

// Initialize and execute the SuinsClient to fetch the renewal price list
(async () => {
	const network = 'testnet';
	// Step 1: Create a SuiClient instance
	const suiClient = new SuiClient({
		url: getFullnodeUrl(network), // Sui testnet endpoint
	});

	// Step 2: Create a SuinsClient instance using TESTNET_CONFIG
	const suinsClient = new SuinsClient({
		client: suiClient,
		network,
	});

	// console.log(await suinsClient.getCoinTypeDiscount());
	// console.log('asd2.asdasd1.sui', await suinsClient.getNameRecord('asd2.asdasd1.sui'));
	// console.log('asdasd1.sui', await suinsClient.getNameRecord('asdasd1.sui'));
	// console.log(await suinsClient.getNameRecord('testingtesting.sui'));
	// console.log(await suinsClient.getNameRecord('testt.testingtesting.sui'));

	const suinsTx = new SuinsTransaction(suinsClient, new Transaction());

	/* Register a new SuiNS name */
	const nft = await suinsTx.register('testisssngtesting.sui', 1, suinsClient.config.coins.USDC, {
		// couponCode: 'fiveplus15percentoff',
		coinId: '0x3a6f32a201ad7f7491a56a1f513c97ec24995494019ba02a586fa181c5d266c5',
	});

	if (nft) {
		/* Set target address */
		// const nft = '0x1f7c9f5c34b43ce71cf2a5bb42f0b91dc7971ef0256bb6dea28a33bd9ab4cfe1';
		const address = '0xb3d277c50f7b846a5f609a8d13428ae482b5826bb98437997373f3a0d60d280e';
		// suinsTx.setTargetAddress({ nft, address });

		// suinsTx.setDefault('tonysstddondytony.sui');
		// suinsTx.setUserData({
		// 	nft,
		// 	value: 'hello',
		// 	key: 'avatar',
		// });

		suinsTx.transaction.transferObjects([nft], suinsTx.getActiveAddress());
	}

	// Creating a subname
	// const subnameNft = suinsTx.createSubName({
	// 	parentNft: '0x64b3f07fa11658117764108ef1232c9ca00c289f77e57bc56f1fba1cd6d30b41',
	// 	name: 'testt.testingtesting.sui',
	// 	expirationTimestampMs: 1766510698047,
	// 	allowChildCreation: true,
	// 	allowTimeExtension: true,
	// });
	// suinsTx.transaction.transferObjects([subnameNft], suinsTx.getActiveAddress());

	return suinsTx.signAndExecute();
})();
