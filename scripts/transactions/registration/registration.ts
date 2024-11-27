// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { getFullnodeUrl, SuiClient } from '@mysten/sui/client';
import { Transaction, TransactionObjectArgument } from '@mysten/sui/transactions';
import { MIST_PER_SUI } from '@mysten/sui/utils';
import { SuiPriceServiceConnection, SuiPythClient } from '@pythnetwork/pyth-sui-js';

import { mainPackage, MIST_PER_USDC, Network } from '../../config/constants';
import { getActiveAddress, signAndExecute } from '../../utils/utils';

const network = (process.env.NETWORK as Network) || 'testnet';
const config = mainPackage[network];

export const initRegistration = (domain: string) => (tx: Transaction) => {
	return tx.moveCall({
		target: `${config.packageId}::payment::init_registration`,
		arguments: [tx.object(config.suins), tx.pure.string(domain)],
	});
};

export const initRenewal = (nft: string, years: number) => (tx: Transaction) => {
	return tx.moveCall({
		target: `${config.packageId}::payment::init_renewal`,
		arguments: [tx.object(config.suins), tx.object(nft), tx.pure.u8(years)],
	});
};

export const getPriceInfoObject = async (tx: Transaction, feed: string) => {
	// Initialize connection to the Sui Price Service
	const connection = new SuiPriceServiceConnection('https://hermes-beta.pyth.network');

	// List of price feed IDs
	const priceIDs = [
		feed, // ASSET/USD price ID
	];

	// Fetch price feed update data
	const priceUpdateData = await connection.getPriceFeedsUpdateData(priceIDs);

	// Initialize Sui Client and Pyth Client
	const wormholeStateId = config.pyth.wormholeStateId;
	const pythStateId = config.pyth.pythStateId;
	const suiClient = new SuiClient({
		url: getFullnodeUrl(network),
	});

	const client = new SuiPythClient(suiClient, pythStateId, wormholeStateId);

	return await client.updatePriceFeeds(tx, priceUpdateData, priceIDs); // returns priceInfoObjectIds
};

export const calculatePrice =
	(baseAmount: number, paymentType: string, priceInfoObjectId: string) => (tx: Transaction) => {
		// Perform the Move call
		return tx.moveCall({
			target: `${config.payments.packageId}::payments::calculate_price`,
			arguments: [
				tx.object(config.suins),
				tx.pure.u64(baseAmount),
				tx.object.clock(),
				tx.object(priceInfoObjectId),
			],
			typeArguments: [paymentType],
		});
	};

// This function is called through the authorized app
export const handleBasePayment =
	(
		paymentIntent: TransactionObjectArgument,
		payment: TransactionObjectArgument,
		paymentType: string,
	) =>
	(tx: Transaction) => {
		return tx.moveCall({
			target: `${config.payments.packageId}::payments::handle_base_payment`,
			arguments: [tx.object(config.suins), paymentIntent, payment],
			typeArguments: [paymentType],
		});
	};

// This function is called through the authorized app
export const handlePayment =
	(
		paymentIntent: TransactionObjectArgument,
		payment: TransactionObjectArgument,
		paymentType: string,
		priceInfoObjectId: string,
	) =>
	(tx: Transaction) => {
		return tx.moveCall({
			target: `${config.payments.packageId}::payments::handle_payment`,
			arguments: [
				tx.object(config.suins),
				paymentIntent,
				payment,
				tx.object.clock(),
				tx.object(priceInfoObjectId),
				tx.pure.u64(10 * Number(MIST_PER_SUI)), // This is the maximum user is willing to pay in SUI (20 USDC = approx 7 SUI)
			],
			typeArguments: [paymentType],
		});
	};

export const register = (receipt: TransactionObjectArgument) => (tx: Transaction) => {
	return tx.moveCall({
		target: `${config.packageId}::payment::register`,
		arguments: [receipt, tx.object(config.suins), tx.object.clock()],
	});
};

export const exampleRegisterationBaseAsset = async (coinId: string, domain: string) => {
	const tx = new Transaction();
	const coin = tx.object(coinId);
	const coinIdType = config.coins.USDC.type;
	// The amount should be based on discount and the length of the domain
	const price = 100 * Number(MIST_PER_USDC);
	const payment = tx.splitCoins(coin, [price]);

	const paymentIntent = tx.add(initRegistration(domain));
	const receipt = tx.add(handleBasePayment(paymentIntent, payment, coinIdType));
	const nft = tx.add(register(receipt));

	tx.transferObjects([nft], getActiveAddress());

	return signAndExecute(tx, network);
};

export const exampleRegisterationSUI = async (domain: string) => {
	const tx = new Transaction();
	const coin = config.coins.SUI;
	const coinIdType = coin.type;
	// The amount should be based on discount and the length of the domain
	const coinAmount = 19 * Number(MIST_PER_USDC); // 5% discount using SUI

	const paymentIntent = tx.add(initRegistration(domain));
	const priceInfoObjectIds = await getPriceInfoObject(tx, coin.feed);
	const price = tx.add(calculatePrice(coinAmount, coinIdType, priceInfoObjectIds[0]));
	const payment = tx.splitCoins(tx.gas, [price]);
	const receipt = tx.add(handlePayment(paymentIntent, payment, coinIdType, priceInfoObjectIds[0]));
	const nft = tx.add(register(receipt));

	tx.transferObjects([nft], getActiveAddress());

	return signAndExecute(tx, network);
};

// exampleRegisterationBaseAsset(
// 	'0xbdebb008a4434884fa799cda40ed3c26c69b2345e0643f841fe3f8e78ecdac46',
// 	'tony.sui',
// );
exampleRegisterationSUI('manofdssl.sui');
