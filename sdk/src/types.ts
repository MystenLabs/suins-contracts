// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
import type { SuiClient } from '@mysten/sui/client';
import type { TransactionObjectArgument } from '@mysten/sui/transactions';

/** You can pass in a TransactionArgument OR an objectId by string. */
export type ObjectArgument = string | TransactionObjectArgument;

export type Network = 'mainnet' | 'testnet' | 'custom';

export type VersionedPackageId = {
	latest: string;
	v1: string;
	[key: string]: string;
};

export type Config = Record<'mainnet' | 'testnet', PackageInfo>;

export type CoinConfigType = {
	type: string;
	feed: string;
};

export type DiscountInfo = {
	discountNft: ObjectArgument;
	type: string;
	isFreeClaim?: boolean;
};

export type BaseParams = {
	years: number;
	coinConfig: CoinConfigType;
	coin?: ObjectArgument;
	couponCode?: string;
	discountInfo?: DiscountInfo;
	maxAmount?: bigint;
	priceInfoObjectId?: string | null;
};

export type RegistrationParams = BaseParams & {
	domain: string;
};

export type RenewalParams = BaseParams & {
	nft: ObjectArgument;
};

export type ReceiptParams = {
	paymentIntent: TransactionObjectArgument;
	priceAfterDiscount: TransactionObjectArgument;
	coinConfig: CoinConfigType;
	coin?: ObjectArgument;
	maxAmount?: bigint;
	priceInfoObjectId?: string | null;
};

export type PackageInfo = {
	packageId: string;
	packageIdV1: string;
	packageIdPricing: string;
	suins: string;
	displayObject?: string;
	discountsPackage: {
		packageId: string;
		discountHouseId: string;
	};
	subNamesPackageId: string;
	tempSubdomainsProxyPackageId: string;
	coupons: {
		packageId: string;
	};
	payments: {
		packageId: string;
	};
	registryTableId?: string;
	pyth: {
		pythStateId: string;
		wormholeStateId: string;
	};
	utils?: {
		packageId: string;
	};
	coins: {
		[key: string]: CoinConfigType;
	};
};

// The config for the SuinsClient.
export type SuinsClientConfig = {
	client: SuiClient;
	/**
	 * The network to use. Defaults to mainnet.
	 */
	network?: Network;
	/**
	 * We can pass in custom PackageIds if we want this to
	 * be functional on localnet, devnet, or any other deployment.
	 */
	config?: Config;
};

/**
 * The price list for SuiNS names.
 */
export type SuinsPriceList = Map<[number, number], number>;

/**
 * The coin type and discount for SuiNS names.
 */
export type CoinTypeDiscount = Map<string, number>;

/**
 * A NameRecord entry of SuiNS Names.
 */
export type NameRecord = {
	name: string;
	nftId: string;
	targetAddress: string;
	expirationTimestampMs: number;
	data: Record<string, string>;
	avatar?: string;
	contentHash?: string;
	walrusSiteId?: string;
};
