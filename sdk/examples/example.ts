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
	console.log(await suinsClient.getPriceList());
	console.log(await suinsClient.getRenewalPriceList());
	console.log(await suinsClient.getCoinTypeDiscount());

	/* Following can be used to fetch the domain record */
	console.log('Domain Record: ', await suinsClient.getNameRecord('myname.sui'));

	/* If discount NFT is used */
	// const discountNft = '0xMyDiscountNft'; // This can be a string or a kioskTransactionArgument
	// const discountNftType = await suinsClient.getObjectType(discountNft);

	/* Registration Example Using SUI */
	const tx = new Transaction();
	const suinsTx = new SuinsTransaction(suinsClient, tx);
	const maxPaymentAmount = 5 * 1_000_000; // In MIST of the payment coin type
	const [coin] = suinsTx.transaction.splitCoins('0xMyCoin', [maxPaymentAmount]);

	/* Registration Example Using NS */
	const coinConfig = suinsClient.config.coins.NS; // Specify the coin type used for the transaction
	const priceInfoObjectId = (await suinsClient.getPriceInfoObject(tx, coinConfig.feed))[0];
	const nft = suinsTx.register({
		domain: 'myname.sui',
		years: 2,
		coinConfig,
		couponCode: 'fiveplus15percentoff',
		priceInfoObjectId,
		coin,
	});

	/* Registration Example Using USDC */
	// const coinConfig = suinsClient.config.coins.USDC; // Specify the coin type used for the transaction
	// const nft = suinsTx.register({
	// 	domain: 'myname.sui',
	// 	years: 2,
	// 	coinConfig,
	// 	coin,
	// });

	// /* Renew Example */
	// const coinConfig = suinsClient.config.coins.SUI; // Specify the coin type used for the transaction
	// const priceInfoObjectId = await suinsClient.getPriceInfoObject(tx, coinConfig.feed)[0];
	// suinsTx.renew({
	// 	nft: '0xMyNft',
	// 	years: 2,
	// 	coinConfig,
	// 	coin,
	// 	priceInfoObjectId,
	// });

	/* Optionally set target address */
	suinsTx.setTargetAddress({ nft, address: '0xMyAddress' });

	/* Optionally set default */
	suinsTx.setDefault('myname.sui');

	/* Optionally set user data */
	suinsTx.setUserData({
		nft,
		value: 'hello',
		key: 'walrus_site_id',
	});

	/* Optionally transfer the NFT */
	suinsTx.transaction.transferObjects([nft], '0xMyAddress');

	/* Optionally transfer coin */
	suinsTx.transaction.transferObjects([coin], '0xMyAddress');

	/* Subname Example */
	// const subnameNft = suinsTx.createSubName({
	// 	parentNft: '0xMyParentNft',
	// 	name: 'name.myname.sui',
	// 	expirationTimestampMs: 1862491339394,
	// 	allowChildCreation: true,
	// 	allowTimeExtension: true,
	// });
	// suinsTx.transaction.transferObjects([subnameNft], 'YOUR_ADDRESS');

	/* Extend Subname Expiration */
	// suinsTx.extendExpiration({
	// 	nft: '0xMySubnameNft',
	// 	expirationTimestampMs: 1862511339394,
	// });
})();
