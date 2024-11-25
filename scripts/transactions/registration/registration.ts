// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { Transaction } from '@mysten/sui/transactions';
import type { TransactionObjectArgument } from '@mysten/sui/transactions';

import { mainPackage, MIST_PER_USDC } from '../../config/constants';
import { getActiveAddress, signAndExecute } from '../../utils/utils';

const network = 'testnet';
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

// This function is called through the authorized app
export const applyPercentageDiscount =
	(
		paymentIntent: TransactionObjectArgument,
		discount_key: string,
		discount: number,
		allow_multiple: boolean,
	) =>
	(tx: Transaction) => {
		tx.moveCall({
			target: `${config.packageId}::payment::apply_percentage_discount`,
			arguments: [
				paymentIntent,
				tx.object(config.suins),
				tx.object(''), // A object
				tx.pure.string(discount_key),
				tx.pure.u8(discount),
				tx.pure.bool(allow_multiple),
			],
			typeArguments: ['Type_0'], // This should be the A type
		});

		return signAndExecute(tx, network);
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

export const register = (receipt: TransactionObjectArgument) => (tx: Transaction) => {
	return tx.moveCall({
		target: `${config.packageId}::payment::register`,
		arguments: [receipt, tx.object(config.suins), tx.object.clock()],
	});
};

export const exampleRegisteration = async (domain: string) => {
	const tx = new Transaction();
	const coin = tx.object('0xbdebb008a4434884fa799cda40ed3c26c69b2345e0643f841fe3f8e78ecdac46'); // This should be the payment coin object
	const coinIdType = config.coins.USDC.type;
	const coinAmount = 20 * Number(MIST_PER_USDC);
	const payment = tx.splitCoins(coin, [coinAmount]);

	const paymentIntent = tx.add(initRegistration(domain));
	const receipt = tx.add(handleBasePayment(paymentIntent, payment, coinIdType));
	const nft = tx.add(register(receipt));

	tx.transferObjects([nft], getActiveAddress());

	return signAndExecute(tx, network);
};

exampleRegisteration('example.sui');
