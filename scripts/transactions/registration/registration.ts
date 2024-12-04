// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { getFullnodeUrl, SuiClient } from '@mysten/sui/client';
import { Transaction, TransactionObjectArgument } from '@mysten/sui/transactions';
import { SuiPriceServiceConnection, SuiPythClient } from '@pythnetwork/pyth-sui-js';

import { mainPackage, Network } from '../../config/constants';
import { applyCoupon } from '../../coupons/couponTransactions';
import { getActiveAddress, signAndExecute } from '../../utils/utils';

const network = (process.env.NETWORK as Network) || 'testnet';
const config = mainPackage[network];
const MAX_U64 = BigInt('18446744073709551615');

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
		maxAmount: bigint = MAX_U64,
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
				tx.pure.u64(maxAmount), // This is the maximum user is willing to pay
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

const generateReceipt = async (
	tx: Transaction,
	paymentIntent: TransactionObjectArgument,
	priceAfterDiscount: TransactionObjectArgument,
	coinConfig: { type: string; metadataID: string; feed: string },
	coinId: string,
	maxAmount?: bigint,
	infoObjectId?: string,
): Promise<{ receipt: TransactionObjectArgument; priceInfoObjectId?: string }> => {
	const baseAssetPurchase = coinConfig.feed === '';
	if (baseAssetPurchase) {
		const payment = tx.splitCoins(tx.object(coinId), [priceAfterDiscount]);
		const receipt = tx.add(handleBasePayment(paymentIntent, payment, coinConfig.type));
		return { receipt };
	} else {
		const priceInfoObjectId = infoObjectId || (await getPriceInfoObject(tx, coinConfig.feed))[0];
		const price = tx.add(calculatePrice(priceAfterDiscount, coinConfig.type, priceInfoObjectId));
		const payment =
			coinConfig === config.coins.SUI
				? tx.splitCoins(tx.gas, [price])
				: tx.splitCoins(tx.object(coinId), [price]);
		const receipt = tx.add(
			handlePayment(paymentIntent, payment, coinConfig.type, priceInfoObjectId, maxAmount),
		);
		return { receipt, priceInfoObjectId };
	}
};
export const exampleRegistration = async (
	domain: string,
	years: number,
	coinConfig: { type: string; metadataID: string; feed: string },
	coinId: string,
	options: { couponCode?: string; maxAmount?: bigint } = {},
) => {
	const tx = new Transaction();

	const paymentIntent = tx.add(initRegistration(domain));
	if (options.couponCode) {
		tx.add(applyCoupon(paymentIntent, options.couponCode));
	}
	const priceAfterDiscount = tx.add(calculatePriceAfterDiscount(paymentIntent, coinConfig.type));
	const { receipt, priceInfoObjectId } = await generateReceipt(
		tx,
		paymentIntent,
		priceAfterDiscount,
		coinConfig,
		coinId,
		options.maxAmount,
	);
	const nft = tx.add(register(receipt));

	if (years > 1) {
		return exampleRenewal(nft, years - 1, coinConfig, coinId, {
			couponCode: options.couponCode,
			maxAmount: options.maxAmount,
			infoObjectId: priceInfoObjectId,
			tx,
		});
	}

	tx.transferObjects([nft], getActiveAddress());
	return signAndExecute(tx, network);
};

export const exampleRenewal = async (
	nft: string | TransactionObjectArgument,
	years: number,
	coinConfig: { type: string; metadataID: string; feed: string },
	coinId: string,
	options: {
		couponCode?: string;
		maxAmount?: bigint;
		infoObjectId?: string;
		tx?: Transaction;
	} = {},
) => {
	let transferNft = true;
	let tx = options.tx;

	if (!tx) {
		tx = new Transaction();
		transferNft = false;
	}
	if (typeof nft === 'string') {
		nft = tx.object(nft);
	}

	const paymentIntent = tx.add(initRenewal(nft, years));
	if (options.couponCode) {
		tx.add(applyCoupon(paymentIntent, options.couponCode));
	}
	const priceAfterDiscount = tx.add(calculatePriceAfterDiscount(paymentIntent, coinConfig.type));
	const { receipt } = await generateReceipt(
		tx,
		paymentIntent,
		priceAfterDiscount,
		coinConfig,
		coinId,
		options.maxAmount,
		options.infoObjectId,
	);
	tx.add(renew(receipt, nft));

	/// Only transfer NFT if it was a renewal part of a registration PTB
	if (transferNft) {
		tx.transferObjects([nft], getActiveAddress());
	}

	return signAndExecute(tx, network);
};

/// Example registration using USDC
// exampleRegistration(
// 	'ajjdfksadsskdsddddsd.sui', // Domain to register
// 	4,
// 	config.coins.USDC,
// 	'0xbdebb008a4434884fa799cda40ed3c26c69b2345e0643f841fe3f8e78ecdac46',
// 	{ couponCode: 'fiveplus15percentoff' },
// );

/// Example registration using SUI
// exampleRegistration('ajadsadsdssafddssssaasd.sui', 1, config.coins.SUI, '', {
// 	couponCode: 'fiveplus15percentoff',
// });

/// Example renewal using SUI
// exampleRenewal(
// 	'0xda9b5b992633b30adcbb82c2480bae1bd69e1049fefe5fd1b0fec66660412651', // NFT to renew
// 	2,
// 	config.coins.SUI,
// 	'',
// 	{ couponCode: 'fiveplus15percentoff' },
// );

/// Example renewal using USDC
// exampleRenewal(
// 	'0xda9b5b992633b30adcbb82c2480bae1bd69e1049fefe5fd1b0fec66660412651', // NFT to renew
// 	3,
// 	config.coins.USDC,
// 	'0xbdebb008a4434884fa799cda40ed3c26c69b2345e0643f841fe3f8e78ecdac46',
// 	{ couponCode: 'fiveplus15percentoff' },
// );
