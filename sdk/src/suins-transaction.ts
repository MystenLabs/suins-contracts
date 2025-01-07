// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
import { execFileSync, execSync } from 'child_process';
import fs, { readFileSync } from 'fs';
import { homedir } from 'os';
import path from 'path';
import { bcs } from '@mysten/sui/bcs';
import { decodeSuiPrivateKey } from '@mysten/sui/cryptography';
import { Ed25519Keypair } from '@mysten/sui/keypairs/ed25519';
import { Secp256k1Keypair } from '@mysten/sui/keypairs/secp256k1';
import { Secp256r1Keypair } from '@mysten/sui/keypairs/secp256r1';
import type { Transaction } from '@mysten/sui/transactions';
import { TransactionObjectArgument } from '@mysten/sui/transactions';
import {
	fromBase64,
	isValidSuiNSName,
	normalizeSuiNSName,
	SUI_CLOCK_OBJECT_ID,
	toBase64,
} from '@mysten/sui/utils';
import { SuiPriceServiceConnection, SuiPythClient } from '@pythnetwork/pyth-sui-js';

import { ALLOWED_METADATA, MAX_U64 } from './constants.js';
import { getObjectType, isNestedSubName, isSubName, validateYears } from './helpers.js';
import type { SuinsClient } from './suins-client.js';
import type { ObjectArgument } from './types.js';

export class SuinsTransaction {
	suinsClient: SuinsClient;
	transaction: Transaction;

	constructor(client: SuinsClient, transaction: Transaction) {
		this.suinsClient = client;
		this.transaction = transaction;
	}

	register = async (
		domain: string,
		years: number,
		coinConfig: { type: string; metadataID: string; feed: string },
		options: {
			coinId?: string;
			couponCode?: string;
			discountNft?: string;
			maxAmount?: bigint;
		} = {},
	) => {
		const tx = this.transaction;

		const paymentIntent = tx.add(this.initRegistration(domain));
		if (options.couponCode) {
			tx.add(this.applyCoupon(paymentIntent, options.couponCode));
		}
		if (options.discountNft) {
			await this.applyDiscount(paymentIntent, options.discountNft);
		}
		const priceAfterDiscount = tx.add(
			this.calculatePriceAfterDiscount(paymentIntent, coinConfig.type),
		);
		const { receipt, priceInfoObjectId } = await this.generateReceipt(
			paymentIntent,
			priceAfterDiscount,
			coinConfig,
			options,
		);
		const nft = tx.add(this.finalizeRegister(receipt));

		if (years > 1) {
			return this.renew(nft, years - 1, coinConfig, {
				...options,
				infoObjectId: priceInfoObjectId,
				tx,
			});
		}

		return nft as TransactionObjectArgument;
	};

	renew = async (
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
		const tx = options.tx || this.transaction;
		const transferNft = options.tx;

		const nftObject = typeof nft === 'string' ? tx.object(nft) : nft;

		const paymentIntent = tx.add(this.initRenewal(nftObject, years));
		if (options.couponCode) {
			tx.add(this.applyCoupon(paymentIntent, options.couponCode));
		}
		if (options.discountNft) {
			await this.applyDiscount(paymentIntent, options.discountNft);
		}
		const priceAfterDiscount = tx.add(
			this.calculatePriceAfterDiscount(paymentIntent, coinConfig.type),
		);
		const { receipt } = await this.generateReceipt(
			paymentIntent,
			priceAfterDiscount,
			coinConfig,
			options,
		);
		tx.add(this.finalizeRenew(receipt, nftObject));

		if (transferNft) {
			return nft as TransactionObjectArgument;
		}

		return null;
	};

	initRegistration = (domain: string) => (tx: Transaction) => {
		const config = this.suinsClient.config;
		return tx.moveCall({
			target: `${config.packageId}::payment::init_registration`,
			arguments: [tx.object(config.suins), tx.pure.string(domain)],
		});
	};

	initRenewal = (nft: TransactionObjectArgument, years: number) => (tx: Transaction) => {
		const config = this.suinsClient.config;
		return tx.moveCall({
			target: `${config.packageId}::payment::init_renewal`,
			arguments: [tx.object(config.suins), nft, tx.pure.u8(years)],
		});
	};

	getPriceInfoObject = async (feed: string) => {
		const tx = this.transaction;
		const config = this.suinsClient.config;
		// Initialize connection to the Sui Price Service
		const endpoint =
			this.suinsClient.network === 'testnet'
				? 'https://hermes-beta.pyth.network'
				: 'https://hermes.pyth.network';
		const connection = new SuiPriceServiceConnection(endpoint);

		// List of price feed IDs
		const priceIDs = [
			feed, // ASSET/USD price ID
		];

		// Fetch price feed update data
		const priceUpdateData = await connection.getPriceFeedsUpdateData(priceIDs);

		// Initialize Sui Client and Pyth Client
		const wormholeStateId = config.pyth.wormholeStateId;
		const pythStateId = config.pyth.pythStateId;

		const client = new SuiPythClient(this.suinsClient.client, pythStateId, wormholeStateId);

		// Implement this inside sdk
		return await client.updatePriceFeeds(tx, priceUpdateData, priceIDs); // returns priceInfoObjectIds
	};

	calculatePrice =
		(baseAmount: TransactionObjectArgument, paymentType: string, priceInfoObjectId: string) =>
		(tx: Transaction) => {
			const config = this.suinsClient.config;
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

	handleBasePayment =
		(
			paymentIntent: TransactionObjectArgument,
			payment: TransactionObjectArgument,
			paymentType: string,
		) =>
		(tx: Transaction) => {
			const config = this.suinsClient.config;
			return tx.moveCall({
				target: `${config.payments.packageId}::payments::handle_base_payment`,
				arguments: [tx.object(config.suins), paymentIntent, payment],
				typeArguments: [paymentType],
			});
		};

	handlePayment =
		(
			paymentIntent: TransactionObjectArgument,
			payment: TransactionObjectArgument,
			paymentType: string,
			priceInfoObjectId: string,
			maxAmount: bigint = MAX_U64,
		) =>
		(tx: Transaction) => {
			const config = this.suinsClient.config;
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

	// rename to finalize
	finalizeRegister = (receipt: TransactionObjectArgument) => (tx: Transaction) => {
		const config = this.suinsClient.config;
		return tx.moveCall({
			target: `${config.packageId}::payment::register`,
			arguments: [receipt, tx.object(config.suins), tx.object.clock()],
		});
	};

	finalizeRenew =
		(receipt: TransactionObjectArgument, nft: TransactionObjectArgument) => (tx: Transaction) => {
			const config = this.suinsClient.config;
			return tx.moveCall({
				target: `${config.packageId}::payment::renew`,
				arguments: [receipt, tx.object(config.suins), nft, tx.object.clock()],
			});
		};

	calculatePriceAfterDiscount =
		(paymentIntent: TransactionObjectArgument, paymentType: string) => (tx: Transaction) => {
			const config = this.suinsClient.config;
			return tx.moveCall({
				target: `${config.payments.packageId}::payments::calculate_price_after_discount`,
				arguments: [tx.object(config.suins), paymentIntent],
				typeArguments: [paymentType],
			});
		};

	zeroCoin = (type: string) => (tx: Transaction) => {
		return tx.moveCall({
			target: '0x2::coin::zero',
			typeArguments: [type],
		});
	};

	generateReceipt = async (
		paymentIntent: TransactionObjectArgument,
		priceAfterDiscount: TransactionObjectArgument,
		coinConfig: { type: string; metadataID: string; feed: string },
		options: {
			coinId?: string;
			maxAmount?: bigint;
			infoObjectId?: string;
		} = {},
	): Promise<{ receipt: TransactionObjectArgument; priceInfoObjectId?: string }> => {
		const tx = this.transaction;
		const config = this.suinsClient.config;
		const baseAssetPurchase = coinConfig.feed === '';
		if (baseAssetPurchase) {
			const payment = options.coinId
				? tx.splitCoins(tx.object(options.coinId), [priceAfterDiscount])
				: tx.add(this.zeroCoin(coinConfig.type));
			const receipt = tx.add(this.handleBasePayment(paymentIntent, payment, coinConfig.type));
			return { receipt };
		} else {
			const priceInfoObjectId =
				options.infoObjectId || (await this.getPriceInfoObject(coinConfig.feed))[0];
			const price = tx.add(
				this.calculatePrice(priceAfterDiscount, coinConfig.type, priceInfoObjectId),
			);
			const payment =
				coinConfig === config.coins.SUI
					? tx.splitCoins(tx.gas, [price])
					: options.coinId
						? tx.splitCoins(tx.object(options.coinId), [price])
						: (() => {
								throw new Error('coinId is not defined');
							})();
			const receipt = tx.add(
				this.handlePayment(
					paymentIntent,
					payment,
					coinConfig.type,
					priceInfoObjectId,
					options.maxAmount,
				),
			);
			return { receipt, priceInfoObjectId };
		}
	};

	applyCoupon = (intent: TransactionObjectArgument, couponCode: string) => (tx: Transaction) => {
		const config = this.suinsClient.config;
		return tx.moveCall({
			target: `${config.coupons.packageId}::coupon_house::apply_coupon`,
			arguments: [tx.object(config.suins), intent, tx.pure.string(couponCode), tx.object.clock()],
		});
	};

	applyDiscount = async (intent: TransactionObjectArgument, discountNft: string) => {
		const config = this.suinsClient.config;
		const tx = this.transaction;
		const discountNftType = await getObjectType(this.suinsClient.client, discountNft);

		tx.moveCall({
			target: `${config.discountsPackage.packageId}::discounts::apply_percentage_discount`,
			arguments: [
				tx.object(config.discountsPackage.discountHouseId),
				intent,
				tx.object(config.suins),
				tx.object(discountNft),
			],
			typeArguments: [discountNftType],
		});
	};

	createSubName({
		parentNft,
		name,
		expirationTimestampMs,
		allowChildCreation,
		allowTimeExtension,
	}: {
		parentNft: ObjectArgument;
		name: string;
		expirationTimestampMs: number;
		allowChildCreation: boolean;
		allowTimeExtension: boolean;
	}) {
		if (!isValidSuiNSName(name)) throw new Error('Invalid SuiNS name');
		const isParentSubdomain = isNestedSubName(name);
		if (!this.suinsClient.config.suins) throw new Error('SuiNS Object ID not found');
		if (!this.suinsClient.config.subNamesPackageId)
			throw new Error('Subnames package ID not found');
		if (isParentSubdomain && !this.suinsClient.config.tempSubdomainsProxyPackageId)
			throw new Error('Subnames proxy package ID not found');

		const subNft = this.transaction.moveCall({
			target: isParentSubdomain
				? `${this.suinsClient.config.tempSubdomainsProxyPackageId}::subdomain_proxy::new`
				: `${this.suinsClient.config.subNamesPackageId}::subdomains::new`,
			arguments: [
				this.transaction.object(this.suinsClient.config.suins),
				this.transaction.object(parentNft),
				this.transaction.object(SUI_CLOCK_OBJECT_ID),
				this.transaction.pure.string(normalizeSuiNSName(name, 'dot')),
				this.transaction.pure.u64(expirationTimestampMs),
				this.transaction.pure.bool(!!allowChildCreation),
				this.transaction.pure.bool(!!allowTimeExtension),
			],
		});

		return subNft;
	}

	/**
	 * Builds the PTB to create a leaf subdomain.
	 * Parent can be a `SuinsRegistration` or a `SubDomainRegistration` object.
	 * Can be passed in as an ID or a TransactionArgument.
	 */
	createLeafSubName({
		parentNft,
		name,
		targetAddress,
	}: {
		parentNft: ObjectArgument;
		name: string;
		targetAddress: string;
	}) {
		if (!isValidSuiNSName(name)) throw new Error('Invalid SuiNS name');
		const isParentSubdomain = isNestedSubName(name);
		if (!this.suinsClient.config.suins) throw new Error('SuiNS Object ID not found');
		if (!this.suinsClient.config.subNamesPackageId)
			throw new Error('Subnames package ID not found');
		if (isParentSubdomain && !this.suinsClient.config.tempSubdomainsProxyPackageId)
			throw new Error('Subnames proxy package ID not found');

		this.transaction.moveCall({
			target: isParentSubdomain
				? `${this.suinsClient.config.tempSubdomainsProxyPackageId}::subdomain_proxy::new_leaf`
				: `${this.suinsClient.config.subNamesPackageId}::subdomains::new_leaf`,
			arguments: [
				this.transaction.object(this.suinsClient.config.suins),
				this.transaction.object(parentNft),
				this.transaction.object(SUI_CLOCK_OBJECT_ID),
				this.transaction.pure.string(normalizeSuiNSName(name, 'dot')),
				this.transaction.pure.address(targetAddress),
			],
		});
	}

	/**
	 * Removes a leaf subname.
	 */
	removeLeafSubName({ parentNft, name }: { parentNft: ObjectArgument; name: string }) {
		if (!isValidSuiNSName(name)) throw new Error('Invalid SuiNS name');
		const isParentSubdomain = isNestedSubName(name);
		if (!isSubName(name)) throw new Error('This can only be invoked for subnames');
		if (!this.suinsClient.config.suins) throw new Error('SuiNS Object ID not found');
		if (!this.suinsClient.config.subNamesPackageId)
			throw new Error('Subnames package ID not found');
		if (isParentSubdomain && !this.suinsClient.config.tempSubdomainsProxyPackageId)
			throw new Error('Subnames proxy package ID not found');

		this.transaction.moveCall({
			target: isParentSubdomain
				? `${this.suinsClient.config.tempSubdomainsProxyPackageId}::subdomain_proxy::remove_leaf`
				: `${this.suinsClient.config.subNamesPackageId}::subdomains::remove_leaf`,
			arguments: [
				this.transaction.object(this.suinsClient.config.suins),
				this.transaction.object(parentNft),
				this.transaction.object(SUI_CLOCK_OBJECT_ID),
				this.transaction.pure.string(normalizeSuiNSName(name, 'dot')),
			],
		});
	}

	signAndExecute = async () => {
		const signer = this.getSigner();
		return this.suinsClient.client.signAndExecuteTransaction({
			transaction: this.transaction,
			signer,
			options: {
				showEffects: true,
				showObjectChanges: true,
			},
		});
	};

	getSigner = () => {
		if (process.env.PRIVATE_KEY) {
			console.log('Using supplied private key.');
			const { schema, secretKey } = decodeSuiPrivateKey(process.env.PRIVATE_KEY);

			if (schema === 'ED25519') return Ed25519Keypair.fromSecretKey(secretKey);
			if (schema === 'Secp256k1') return Secp256k1Keypair.fromSecretKey(secretKey);
			if (schema === 'Secp256r1') return Secp256r1Keypair.fromSecretKey(secretKey);

			throw new Error('Keypair not supported.');
		}

		const sender = this.getActiveAddress();

		const keystore = JSON.parse(
			readFileSync(path.join(homedir(), '.sui', 'sui_config', 'sui.keystore'), 'utf8'),
		);

		for (const priv of keystore) {
			const raw = fromBase64(priv);
			if (raw[0] !== 0) {
				continue;
			}

			const pair = Ed25519Keypair.fromSecretKey(raw.slice(1));
			if (pair.getPublicKey().toSuiAddress() === sender) {
				return pair;
			}
		}

		throw new Error(`keypair not found for sender: ${sender}`);
	};

	getActiveAddress = () => {
		const SUI = process.env.SUI_BINARY ?? `sui`;

		return execSync(`${SUI} client active-address`, { encoding: 'utf8' }).trim();
	};

	setTargetAddress({
		nft, // Can be string or argument
		address,
		isSubname,
	}: {
		nft: any;
		address?: string;
		isSubname?: boolean;
	}) {
		if (!this.suinsClient.config.utils?.packageId) throw new Error('SuiNS Object ID not found');

		if (isSubname && !this.suinsClient.config.tempSubdomainsProxyPackageId)
			throw new Error('Subnames proxy package ID not found');

		const nftObject = typeof nft === 'string' ? this.transaction.object(nft) : nft;

		this.transaction.moveCall({
			target: isSubname
				? `${this.suinsClient.config.tempSubdomainsProxyPackageId}::subdomain_proxy::set_target_address`
				: `${this.suinsClient.config.utils.packageId}::direct_setup::set_target_address`, // Update this
			arguments: [
				this.transaction.object(this.suinsClient.config.suins),
				nftObject,
				this.transaction.pure(bcs.option(bcs.Address).serialize(address).toBytes()),
				this.transaction.object(SUI_CLOCK_OBJECT_ID),
			],
		});
	}

	/** Marks a name as default */
	setDefault(name: string) {
		if (!isValidSuiNSName(name)) throw new Error('Invalid SuiNS name');
		if (!this.suinsClient.config.suins) throw new Error('SuiNS Object ID not found');
		if (!this.suinsClient.config.utils?.packageId) throw new Error('Utils package ID not found');

		this.transaction.moveCall({
			target: `${this.suinsClient.config.utils?.packageId}::direct_setup::set_reverse_lookup`, // Update this
			arguments: [
				this.transaction.object(this.suinsClient.config.suins),
				this.transaction.pure.string(normalizeSuiNSName(name, 'dot')),
			],
		});
	}

	editSetup({
		parentNft,
		name,
		allowChildCreation,
		allowTimeExtension,
	}: {
		parentNft: ObjectArgument;
		name: string;
		allowChildCreation: boolean;
		allowTimeExtension: boolean;
	}) {
		if (!isValidSuiNSName(name)) throw new Error('Invalid SuiNS name');
		const isParentSubdomain = isNestedSubName(name);
		if (!this.suinsClient.config.suins) throw new Error('SuiNS Object ID not found');
		if (!isParentSubdomain && !this.suinsClient.config.subNamesPackageId)
			throw new Error('Subnames package ID not found');
		if (isParentSubdomain && !this.suinsClient.config.tempSubdomainsProxyPackageId)
			throw new Error('Subnames proxy package ID not found');

		this.transaction.moveCall({
			target: isParentSubdomain
				? `${this.suinsClient.config.tempSubdomainsProxyPackageId}::subdomain_proxy::edit_setup`
				: `${this.suinsClient.config.subNamesPackageId}::subdomains::edit_setup`,
			arguments: [
				this.transaction.object(this.suinsClient.config.suins),
				this.transaction.object(parentNft),
				this.transaction.object(SUI_CLOCK_OBJECT_ID),
				this.transaction.pure.string(normalizeSuiNSName(name, 'dot')),
				this.transaction.pure.bool(!!allowChildCreation),
				this.transaction.pure.bool(!!allowTimeExtension),
			],
		});
	}

	extendExpiration({
		nft,
		expirationTimestampMs,
	}: {
		nft: ObjectArgument;
		expirationTimestampMs: number;
	}) {
		if (!this.suinsClient.config.suins) throw new Error('SuiNS Object ID not found');
		if (!this.suinsClient.config.subNamesPackageId)
			throw new Error('Subnames package ID not found');

		this.transaction.moveCall({
			target: `${this.suinsClient.config.subNamesPackageId}::subdomains::extend_expiration`,
			arguments: [
				this.transaction.object(this.suinsClient.config.suins),
				this.transaction.object(nft),
				this.transaction.pure.u64(expirationTimestampMs),
			],
		});
	}

	setUserData({
		nft,
		value,
		key,
		isSubname,
	}: {
		nft: any;
		value: string;
		key: string;
		isSubname?: boolean;
	}) {
		if (!this.suinsClient.config.suins) throw new Error('SuiNS Object ID not found');
		if (!isSubname && !this.suinsClient.config.utils?.packageId)
			throw new Error('Utils package ID not found');
		if (isSubname && !this.suinsClient.config.tempSubdomainsProxyPackageId)
			throw new Error('Subnames proxy package ID not found');

		const nftObject = typeof nft === 'string' ? this.transaction.object(nft) : nft;

		if (!Object.values(ALLOWED_METADATA).some((x) => x === key)) throw new Error('Invalid key');

		this.transaction.moveCall({
			target: isSubname
				? `${this.suinsClient.config.tempSubdomainsProxyPackageId}::subdomain_proxy::set_user_data`
				: `${this.suinsClient.config.utils?.packageId}::direct_setup::set_user_data`, // Update this
			arguments: [
				this.transaction.object(this.suinsClient.config.suins),
				nftObject,
				this.transaction.pure.string(key),
				this.transaction.pure.string(value),
				this.transaction.object(SUI_CLOCK_OBJECT_ID),
			],
		});
	}

	/**
	 * Burns an expired NFT to collect storage rebates.
	 */
	burnExpired({ nft, isSubname }: { nft: ObjectArgument; isSubname?: boolean }) {
		if (!this.suinsClient.config.suins) throw new Error('SuiNS Object ID not found');
		if (!this.suinsClient.config.utils?.packageId) throw new Error('Utils package ID not found');

		this.transaction.moveCall({
			target: `${this.suinsClient.config.utils.packageId}::direct_setup::${
				isSubname ? 'burn_expired_subname' : 'burn_expired'
			}`, // Update this
			arguments: [
				this.transaction.object(this.suinsClient.config.suins),
				this.transaction.object(nft),
				this.transaction.object(SUI_CLOCK_OBJECT_ID),
			],
		});
	}
}
