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
	console.log(await suinsClient.getCoinTypeDiscount());
	console.log(await suinsClient.getPriceList());
	console.log(await suinsClient.getRenewalPriceList());

	/* Following can be used to fetch the domain record */
	console.log('Domain Record: ', await suinsClient.getNameRecord('name123.sui'));
	console.log('Domain Record: ', await suinsClient.getNameRecord('name.name123.sui'));

	const suinsTx = new SuinsTransaction(suinsClient, new Transaction());

	/* Registration Example Using SUI */
	const nft = await suinsTx.register('name123.sui', 3, suinsClient.config.coins.SUI, {
		couponCode: 'fiveplus15percentoff',
	});

	/* Registration Example Using USDC */
	// const nft = await suinsTx.register('name123.sui', 2, suinsClient.config.coins.USDC, {
	// 	couponCode: 'fiveplus15percentoff',
	// 	coinId: '0x3a6f32a201ad7f7491a56a1f513c97ec24995494019ba02a586fa181c5d266c5',
	// });

	/* Registration Example Using NS */
	// const nft = await suinsTx.register('name123.sui', 2, suinsClient.config.coins.NS, {
	// 	couponCode: 'fiveplus15percentoff',
	// 	coinId: '0x8211160f8d782d11bdcfbe625880bc3d944ddb09b4a815278263260b037cd509',
	// });

	/* Renew Example */
	// const nft = await suinsTx.renew(
	// 	'0x8d4af9dc54023182ae8ca78717587f4d99b10458821fc94be7716681f164507b',
	// 	1,
	// 	suinsClient.config.coins.SUI,
	// 	{
	// 		couponCode: 'fiveplus15percentoff',
	// 		// coinId: '0x3a6f32a201ad7f7491a56a1f513c97ec24995494019ba02a586fa181c5d266c5',
	// 	},
	// );

	if (nft) {
		/* Optionally set target address */
		suinsTx.setTargetAddress({ nft, address: 'YOUR_ADDRESS' });

		/* Optionally set default */
		suinsTx.setDefault('name123.sui');

		/* Optionally set user data */
		suinsTx.setUserData({
			nft,
			value: 'hello',
			key: 'walrus_site_id',
		});

		suinsTx.transaction.transferObjects([nft], 'YOUR_ADDRESS');
	}

	/* Subname Example */
	const subnameNft = suinsTx.createSubName({
		parentNft: '0x0',
		name: 'name.name123.sui',
		expirationTimestampMs: 1862491339394,
		allowChildCreation: true,
		allowTimeExtension: true,
	});
	suinsTx.transaction.transferObjects([subnameNft], 'YOUR_ADDRESS');

	/* Extend Subname Expiration */
	suinsTx.extendExpiration({
		nft: '0x0',
		expirationTimestampMs: 1862511339394,
	});
})();
