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

	const suinsTx = new SuinsTransaction(suinsClient, new Transaction());
	const nft = await suinsTx.registerPTB(
		'ajadsaddksdssafaaaddddsssssssssaasd.sui',
		1,
		suinsClient.config.coins.SUI,
		{
			couponCode: 'fiveplus15percentoff',
		},
	);

	if (nft) {
		suinsTx.transaction.transferObjects([nft], suinsTx.getActiveAddress());
	}

	return suinsTx.signAndExecute();
})();
