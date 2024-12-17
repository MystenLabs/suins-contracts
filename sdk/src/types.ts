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

export type DiscordConfig = {
	packageId: string;
	discordCap: string;
	discordObjectId: string;
	discordTableId: string;
};

export type PackageInfo = {
	packageId: string;
	registrationPackageId: string;
	upgradeCap?: string;
	publisherId: string;
	adminAddress: string;
	adminCap: string;
	suins: string;
	displayObject?: string;
	directSetupPackageId: string;
	discountsPackage: {
		packageId: string;
		discountHouseId: string;
	};
	renewalsPackageId: string;
	subNamesPackageId: string;
	tempSubdomainsProxyPackageId: string;
	discord: DiscordConfig | undefined;
	coupons: {
		packageId: string;
	};
	treasuryAddress?: string;
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
		[key: string]: {
			type: string;
			metadataID: string;
			feed: string;
		};
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
};
