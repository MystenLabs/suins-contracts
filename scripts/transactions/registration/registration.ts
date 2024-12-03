// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { getFullnodeUrl, SuiClient } from '@mysten/sui/client';
import { Transaction, TransactionObjectArgument } from '@mysten/sui/transactions';
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

export const initRenewal = (nft: TransactionObjectArgument, years: number) => (tx: Transaction) => {
	return tx.moveCall({
		target: `${config.packageId}::payment::init_renewal`,
		arguments: [tx.object(config.suins), nft, tx.pure.u8(years)],
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
				tx.pure.u64(1000 * Number(MIST_PER_SUI)), // This is the maximum user is willing to pay in SUI (20 USDC = approx 7 SUI)
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

export const renew =
	(receipt: TransactionObjectArgument, nft: TransactionObjectArgument) => (tx: Transaction) => {
		return tx.moveCall({
			target: `${config.packageId}::payment::renew`,
			arguments: [receipt, tx.object(config.suins), nft, tx.object.clock()],
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

export const exampleRegisteration = async (
	domain: string,
	years: number,
	coinConfig: {
		type: string;
		metadataID: string;
		feed: string;
	},
	coinId: string,
) => {
	const tx = new Transaction();

	const paymentIntent = tx.add(initRegistration(domain));
	const priceAfterDiscount = tx.add(calculatePriceAfterDiscount(paymentIntent, coinConfig.type));
	const baseAssetPurchase = coinConfig.feed === ''; // True if payment in base asset, no price feed

	const receipt = await (async () => {
		if (baseAssetPurchase) {
			// Handle base asset purchase
			const payment = tx.splitCoins(tx.object(coinId), [priceAfterDiscount]);
			return tx.add(handleBasePayment(paymentIntent, payment, coinConfig.type));
		} else {
			// Fetch price info object IDs asynchronously
			const priceInfoObjectIds = await getPriceInfoObject(tx, coinConfig.feed);

			// Calculate the price with discount and type adjustments
			const price = tx.add(
				calculatePrice(priceAfterDiscount, coinConfig.type, priceInfoObjectIds[0]),
			);

			// Handle payment based on the coin type
			const payment =
				coinConfig === config.coins.SUI
					? tx.splitCoins(tx.gas, [price]) // Use gas for SUI payments
					: tx.splitCoins(tx.object(coinId), [price]); // Use coin object for other payments

			return tx.add(handlePayment(paymentIntent, payment, coinConfig.type, priceInfoObjectIds[0]));
		}
	})();
	const nft = tx.add(register(receipt));

	if (years > 1) {
		return exampleRenewal(nft, years - 1, coinConfig, coinId, tx);
	}

	tx.transferObjects([nft], getActiveAddress());

	return signAndExecute(tx, network);
};

export const exampleRenewal = async (
	nft: string | TransactionObjectArgument,
	years: number,
	coinConfig: {
		type: string;
		metadataID: string;
		feed: string;
	},
	coinId: string,
	tx?: Transaction,
) => {
	let transferNft = true;
	if (!tx) {
		tx = new Transaction();
		transferNft = false;
	}
	if (typeof nft === 'string') {
		nft = tx.object(nft);
	}

	const paymentIntent = tx.add(initRenewal(nft, years));
	const priceAfterDiscount = tx.add(calculatePriceAfterDiscount(paymentIntent, coinConfig.type));
	const baseAssetPurchase = coinConfig.feed === ''; // True if payment in base asset, no price feed

	const receipt = await (async () => {
		if (baseAssetPurchase) {
			// Handle base asset purchase
			const payment = tx.splitCoins(tx.object(coinId), [priceAfterDiscount]);
			return tx.add(handleBasePayment(paymentIntent, payment, coinConfig.type));
		} else {
			// Fetch price info object IDs asynchronously
			const priceInfoObjectIds = await getPriceInfoObject(tx, coinConfig.feed);

			// Calculate the price with discount and type adjustments
			const price = tx.add(
				calculatePrice(priceAfterDiscount, coinConfig.type, priceInfoObjectIds[0]),
			);

			// Handle payment based on the coin type
			const payment =
				coinConfig === config.coins.SUI
					? tx.splitCoins(tx.gas, [price]) // Use gas for SUI payments
					: tx.splitCoins(tx.object(coinId), [price]); // Use coin object for other payments

			return tx.add(handlePayment(paymentIntent, payment, coinConfig.type, priceInfoObjectIds[0]));
		}
	})();
	tx.add(renew(receipt, nft));
	if (transferNft) {
		tx.transferObjects([nft], getActiveAddress());
	}

	return signAndExecute(tx, network);
};

// exampleRegisteration(
// 	'ajjdfksaljfddkdssd.sui', // Domain to register
// 	4,
// 	config.coins.USDC,
// 	'0xbdebb008a4434884fa799cda40ed3c26c69b2345e0643f841fe3f8e78ecdac46',
// ); // Example registration using USDC
// exampleRegisteration('ajadsadsasd.sui', 1, config.coins.SUI, ''); // Example registration using SUI
// exampleRenewal(
// 	'0x457b8c01d45ced39bef481e474090ee04c8465323a44d19f44123cce1fbbab78', // NFT to renew
// 	4,
// 	config.coins.SUI,
// 	'0xbdebb008a4434884fa799cda40ed3c26c69b2345e0643f841fe3f8e78ecdac46', // USDC coin object
// ); // example renewal using SUI
