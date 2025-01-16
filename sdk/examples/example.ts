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
	// console.log(await suinsClient.getPriceList());
	// console.log(await suinsClient.getRenewalPriceList());
	// console.log(await suinsClient.getCoinTypeDiscount());

	// /* Following can be used to fetch the domain record */
	// console.log('Domain Record: ', await suinsClient.getNameRecord('testing12345.sui'));

	const tx = new Transaction();
	const coinConfig = suinsClient.config.coins.USDC; // Specify the coin type used for the transaction
	const priceInfoObjectId =
		coinConfig !== suinsClient.config.coins.USDC
			? (await suinsClient.getPriceInfoObject(tx, coinConfig.feed))[0]
			: null;

	// If discount NFT is used
	const discountNft = '0xd047f37bbf8f21dc0a9422c5e99fd208c19bb58884b2671a09c0e1c1cbac6983'; // This can be a string or a kioskTransactionArgument
	const discountNftType = await suinsClient.getObjectType(discountNft);

	/* Registration Example Using SUI */
	const suinsTx = new SuinsTransaction(suinsClient, tx);
	// const nft = suinsTx.register({
	// 	domain: 'testinsssg1ddd2345.sui',
	// 	years: 3,
	// 	coinConfig,
	// 	discountInfo: {
	// 		discountNft,
	// 		type: discountNftType,
	// 	},
	// 	priceInfoObjectId,
	// });

	// /* Registration Example Using USDC */
	const nft = suinsTx.register({
		domain: 'namdde1sssa23.sui',
		years: 2,
		coinConfig,
		couponCode: 'fiveplus15percentoff',
		coin: '0x3a6f32a201ad7f7491a56a1f513c97ec24995494019ba02a586fa181c5d266c5',
	});

	// /* Registration Example Using NS */
	// const nft = suinsTx.register({
	// 	domain: 'names123.sui',
	// 	years: 2,
	// 	coinConfig,
	// 	couponCode: 'fiveplus15percentoff',
	// 	coin: '0x8211160f8d782d11bdcfbe625880bc3d944ddb09b4a815278263260b037cd509',
	// 	priceInfoObjectId,
	// });

	// /* Renew Example */
	// suinsTx.renew({
	// 	nft: '0xde6815eaf725e49e34e8d9422098e71fea787c0278663877650007b83eed10af',
	// 	years: 2,
	// 	coinConfig,
	// 	couponCode: 'fiveplus15percentoff',
	// 	coin: '0x8211160f8d782d11bdcfbe625880bc3d944ddb09b4a815278263260b037cd509',
	// 	priceInfoObjectId,
	// });

	/* Optionally set target address */
	// suinsTx.setTargetAddress({ nft, address: 'YOUR_ADDRESS' });

	// /* Optionally set default */
	// suinsTx.setDefault('name123.sui');

	// /* Optionally set user data */
	// suinsTx.setUserData({
	// 	nft,
	// 	value: 'hello',
	// 	key: 'walrus_site_id',
	// });

	// /* Optionally transfer the NFT */
	suinsTx.transaction.transferObjects(
		[nft],
		'0xb3d277c50f7b846a5f609a8d13428ae482b5826bb98437997373f3a0d60d280e',
	);

	// /* Subname Example */
	// const subnameNft = suinsTx.createSubName({
	// 	parentNft: '0x0',
	// 	name: 'name.name123.sui',
	// 	expirationTimestampMs: 1862491339394,
	// 	allowChildCreation: true,
	// 	allowTimeExtension: true,
	// });
	// suinsTx.transaction.transferObjects([subnameNft], 'YOUR_ADDRESS');

	// /* Extend Subname Expiration */
	// suinsTx.extendExpiration({
	// 	nft: '0x0',
	// 	expirationTimestampMs: 1862511339394,
	// });
})();
