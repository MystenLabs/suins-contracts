// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { getFullnodeUrl, SuiClient } from '@mysten/sui/client';
import { Transaction, TransactionObjectArgument } from '@mysten/sui/transactions';
import { SuiPriceServiceConnection, SuiPythClient } from '@pythnetwork/pyth-sui-js';

import { mainPackage, Network } from '../../config/constants';
import { applyCoupon } from '../../coupons/couponTransactions';
import { applyDiscount } from '../../discounts/discounts';
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

export const zeroCoin = (type: string) => (tx: Transaction) => {
	return tx.moveCall({
		target: '0x2::coin::zero',
		typeArguments: [type],
	});
};

export const generateReceipt = async (
	tx: Transaction,
	paymentIntent: TransactionObjectArgument,
	priceAfterDiscount: TransactionObjectArgument,
	coinConfig: { type: string; metadataID: string; feed: string },
	options: {
		coinId?: string;
		maxAmount?: bigint;
		infoObjectId?: string;
	} = {},
): Promise<{ receipt: TransactionObjectArgument; priceInfoObjectId?: string }> => {
	const baseAssetPurchase = coinConfig.feed === '';
	if (baseAssetPurchase) {
		const payment = options.coinId
			? tx.splitCoins(tx.object(options.coinId), [priceAfterDiscount])
			: tx.add(zeroCoin(coinConfig.type));
		const receipt = tx.add(handleBasePayment(paymentIntent, payment, coinConfig.type));
		return { receipt };
	} else {
		const priceInfoObjectId =
			options.infoObjectId || (await getPriceInfoObject(tx, coinConfig.feed))[0];
		const price = tx.add(calculatePrice(priceAfterDiscount, coinConfig.type, priceInfoObjectId));
		const payment =
			coinConfig === config.coins.SUI
				? tx.splitCoins(tx.gas, [price])
				: options.coinId
					? tx.splitCoins(tx.object(options.coinId), [price])
					: (() => {
							throw new Error('coinId is not defined');
						})();
		const receipt = tx.add(
			handlePayment(paymentIntent, payment, coinConfig.type, priceInfoObjectId, options.maxAmount),
		);
		return { receipt, priceInfoObjectId };
	}
};

export const exampleRegistration = async (
	domain: string,
	years: number,
	coinConfig: { type: string; metadataID: string; feed: string },
	options: { coinId?: string; couponCode?: string; discountNft?: string; maxAmount?: bigint } = {},
) => {
	const tx = new Transaction();

	const paymentIntent = tx.add(initRegistration(domain));
	if (options.couponCode) {
		tx.add(applyCoupon(paymentIntent, options.couponCode));
	}
	if (options.discountNft) {
		await applyDiscount(paymentIntent, options.discountNft, network, tx);
	}
	const priceAfterDiscount = tx.add(calculatePriceAfterDiscount(paymentIntent, coinConfig.type));
	const { receipt, priceInfoObjectId } = await generateReceipt(
		tx,
		paymentIntent,
		priceAfterDiscount,
		coinConfig,
		options,
	);
	const nft = tx.add(register(receipt));

	if (years > 1) {
		return exampleRenewal(nft, years - 1, coinConfig, {
			...options,
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
	options: {
		coinId?: string;
		couponCode?: string;
		discountNft?: string;
		maxAmount?: bigint;
		infoObjectId?: string;
		tx?: Transaction;
	} = {},
) => {
	const tx = options.tx || new Transaction();
	const transferNft = options.tx;

	const nftObject = typeof nft === 'string' ? tx.object(nft) : nft;

	const paymentIntent = tx.add(initRenewal(nftObject, years));
	if (options.couponCode) {
		tx.add(applyCoupon(paymentIntent, options.couponCode));
	}
	if (options.discountNft) {
		await applyDiscount(paymentIntent, options.discountNft, network, tx);
	}
	const priceAfterDiscount = tx.add(calculatePriceAfterDiscount(paymentIntent, coinConfig.type));
	const { receipt } = await generateReceipt(
		tx,
		paymentIntent,
		priceAfterDiscount,
		coinConfig,
		options,
	);
	tx.add(renew(receipt, nftObject));

	if (transferNft) {
		tx.transferObjects([nftObject], getActiveAddress());
	}

	return signAndExecute(tx, network);
};

/// Note: For free registration/renewals, use SUI

/// Example registration using USDC, with discountNft
// exampleRegistration(
// 	'ajjdfksadsskdddddsddsssddddddsd.sui', // Domain to register
// 	4,
// 	config.coins.USDC,
// 	{
// 		coinId: '0xbdebb008a4434884fa799cda40ed3c26c69b2345e0643f841fe3f8e78ecdac46',
// 		discountNft: '0x6612ccfe862e62ff581cd886db1e61cc335ebcde6ec4e4a4a3bdfda9b92f0b28',
// 	},
// );

/// Example registration using USDC, with coupon code
// exampleRegistration(
// 	'ajjdsskdddddsdassdssddddddsd.sui', // Domain to register
// 	4,
// 	config.coins.USDC,
// 	{
// 		coinId: '0xbdebb008a4434884fa799cda40ed3c26c69b2345e0643f841fe3f8e78ecdac46',
// 		couponCode: 'fiveplus15percentoff',
// 	},
// );

/// Example FREE registration (use USDC by default), with 100% off coupon code
// exampleRegistration(
// 	'ajjdfksadsskdddddsdssssdssddddddsd.sui', // Domain to register
// 	4,
// 	config.coins.USDC,
// 	{
// 		couponCode: '100percentoff',
// 	},
// );

// Example registration using SUI
// exampleRegistration('ajadsadsdssafddddssssssaasd.sui', 1, config.coins.SUI, {
// 	couponCode: 'fiveplus15percentoff',
// });

//// Example renewal using SUI
// exampleRenewal(
// 	'0xb62cbec397e8ca5249a1abd02befbf571d64b3e2d1d96e3a1c58ba6937859733', // NFT to renew
// 	2,
// 	config.coins.SUI,
// 	{ couponCode: 'fiveplus15percentoff' },
// );

//// Example renewal using USDC
// exampleRenewal(
// 	'0xb62cbec397e8ca5249a1abd02befbf571d64b3e2d1d96e3a1c58ba6937859733', // NFT to renew
// 	3,
// 	config.coins.USDC,
// 	{
// 		coinId: '0xbdebb008a4434884fa799cda40ed3c26c69b2345e0643f841fe3f8e78ecdac46',
// 		couponCode: 'fiveplus15percentoff',
// 	},
// );
