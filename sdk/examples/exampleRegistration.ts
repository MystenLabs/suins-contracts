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

	/* Following can be used to fetch the coin type discount, registration price, and renewal price */
	// console.log(await suinsClient.getCoinTypeDiscount());
	// console.log(await suinsClient.getPriceList());
	// console.log(await suinsClient.getRenewalPriceList());

	/* Following can be used to fetch the domain record */
	// console.log('Domain Record: ', await suinsClient.getNameRecord('testing12345.sui'));

	/* Following can be used to fetch the domain record */
	const suinsTx = new SuinsTransaction(suinsClient, new Transaction());

	/* Registration Example */
	// const nft = await suinsTx.register('testing12345.sui', 2, suinsClient.config.coins.SUI, {
	// couponCode: 'fiveplus15percentoff',
	// coinId: '0x3a6f32a201ad7f7491a56a1f513c97ec24995494019ba02a586fa181c5d266c5',
	// });

	/* Renew Example */
	// const nft = await suinsTx.renew(
	// 	'0x122a6701488cf2cb73f8a2ba659f1f9b2b66017381236e06eeb60540f568d4d6',
	// 	2,
	// 	suinsClient.config.coins.SUI,
	// 	{
	// 		couponCode: 'fiveplus15percentoff',
	// 		// coinId: '0x3a6f32a201ad7f7491a56a1f513c97ec24995494019ba02a586fa181c5d266c5',
	// 	},
	// );

	// if (nft) {
	// 	/* Optionally set target address */
	// 	// suinsTx.setTargetAddress({ nft, address: suinsTx.getActiveAddress() });

	// 	/* Optionally set default */
	// 	// suinsTx.setDefault('testing12345.sui');

	// 	/* Optionally set user data */
	// 	// suinsTx.setUserData({
	// 	// 	nft,
	// 	// 	value: 'hello',
	// 	// 	key: 'avatar',
	// 	// });

	// 	suinsTx.transaction.transferObjects([nft], suinsTx.getActiveAddress());
	// }

	// // Creating a subname
	// // const subnameNft = suinsTx.createSubName({
	// // 	parentNft: '0x64b3f07fa11658117764108ef1232c9ca00c289f77e57bc56f1fba1cd6d30b41',
	// // 	name: 'testt.testingtesting.sui',
	// // 	expirationTimestampMs: 1766510698047,
	// // 	allowChildCreation: true,
	// // 	allowTimeExtension: true,
	// // });
	// // suinsTx.transaction.transferObjects([subnameNft], suinsTx.getActiveAddress());

	return suinsTx.signAndExecute();
})();
