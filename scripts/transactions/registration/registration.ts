// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { getFullnodeUrl, SuiClient } from '@mysten/sui/client';
import { coinWithBalance, Transaction, TransactionObjectArgument } from '@mysten/sui/transactions';
import { MIST_PER_SUI } from '@mysten/sui/utils';
import { SuiPriceServiceConnection, SuiPythClient } from '@pythnetwork/pyth-sui-js';

import { mainPackage, Network } from '../../config/constants';
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

	// Implement this inside sdk
	return await client.updatePriceFeeds(tx, priceUpdateData, priceIDs); // returns priceInfoObjectIds
};

export const calculatePrice =
	(baseAmount: TransactionObjectArgument, paymentType: string, priceInfoObjectId: string) =>
	(tx: Transaction) => {
		// Perform the Move call
		return tx.moveCall({
			target: `${config.payments.packageId}::payments::calculate_price`,
			arguments: [
				tx.object(config.suins),
				baseAmount,
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

export const calculatePriceAfterDiscount =
	(paymentIntent: TransactionObjectArgument, paymentType: string) => (tx: Transaction) => {
		return tx.moveCall({
			target: `${config.payments.packageId}::payments::calculate_price_after_discount`,
			arguments: [tx.object(config.suins), paymentIntent],
			typeArguments: [paymentType],
		});
	};

export const exampleRegisterationBaseAsset = async (domain: string, coinId: string) => {
	const tx = new Transaction();
	const coin = tx.object(coinId);
	const coinIdType = config.coins.USDC.type;

	const paymentIntent = tx.add(initRegistration(domain));
	const payment = tx.splitCoins(coin, [
		tx.add(calculatePriceAfterDiscount(paymentIntent, coinIdType)),
	]);
	const receipt = tx.add(handleBasePayment(paymentIntent, payment, coinIdType));
	const nft = tx.add(register(receipt));

	tx.transferObjects([nft], getActiveAddress());

	return signAndExecute(tx, network);
};

export const exampleRegisterationSUI = async (
	domain: string,
	coin: {
		type: string;
		metadataID: string;
		feed: string;
	},
	coinId: string,
) => {
	const tx = new Transaction();
	const coinIdType = coin.type;

	const paymentIntent = tx.add(initRegistration(domain));
	const priceInfoObjectIds = await getPriceInfoObject(tx, coin.feed);
	const priceAfterDiscount = tx.add(calculatePriceAfterDiscount(paymentIntent, coinIdType));
	const price = tx.add(calculatePrice(priceAfterDiscount, coinIdType, priceInfoObjectIds[0]));
	const payment =
		coin == config.coins.SUI
			? tx.splitCoins(tx.gas, [price])
			: tx.splitCoins(tx.object(coinId), [price]);
	const receipt = tx.add(handlePayment(paymentIntent, payment, coinIdType, priceInfoObjectIds[0]));
	const nft = tx.add(register(receipt));

	tx.transferObjects([nft], getActiveAddress());

	return signAndExecute(tx, network);
};

// exampleRegisterationBaseAsset(
// 	'ton.sui',
// 	'0xbdebb008a4434884fa799cda40ed3c26c69b2345e0643f841fe3f8e78ecdac46',
// ); // Example registration using base (USDC)
exampleRegisterationSUI('ajsdasd.sui', config.coins.SUI, ''); // Example registration using SUI
// exampleRegisterationSUI('john.sui', config.coins.NS, ''); // Example registration using NS
