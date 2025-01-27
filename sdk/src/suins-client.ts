// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
import { SuiClient } from '@mysten/sui/client';
import { Transaction } from '@mysten/sui/transactions';
import { isValidSuiNSName, normalizeSuiNSName } from '@mysten/sui/utils';

import { SuiPriceServiceConnection, SuiPythClient } from '../src/pyth/pyth';
import {
	getCoinDiscountConfigType,
	getConfigType,
	getDomainType,
	getPricelistConfigType,
	getRenewalPricelistConfigType,
	mainPackage,
} from './constants.js';
import { isSubName, validateYears } from './helpers.js';
import type {
	CoinTypeDiscount,
	NameRecord,
	PackageInfo,
	SuinsClientConfig,
	SuinsPriceList,
} from './types.js';
import { Network } from './types.js';

/// The SuinsClient is the main entry point for the Suins SDK.
/// It allows you to interact with SuiNS.
export class SuinsClient {
	client: SuiClient;
	network: Network;
	config: PackageInfo;

	constructor(config: SuinsClientConfig) {
		this.client = config.client;
		this.network = config.network || 'mainnet';

		if (this.network === 'mainnet') {
			this.config = mainPackage.mainnet;
		} else if (this.network === 'testnet') {
			this.config = mainPackage.testnet;
		} else {
			throw new Error('Invalid network');
		}
	}

	/**
	 * Returns the price list for SuiNS names in the base asset.
	 */

	// Format:
	// {
	// 	[ 3, 3 ] => 500000000,
	// 	[ 4, 4 ] => 100000000,
	// 	[ 5, 63 ] => 20000000
	// }
	async getPriceList(): Promise<SuinsPriceList> {
		if (!this.config.suins) throw new Error('Suins object ID is not set');
		if (!this.config.packageId) throw new Error('Price list config not found');

		const priceList = await this.client.getDynamicFieldObject({
			parentId: this.config.suins,
			name: {
				type: getConfigType(
					this.config.packageIdV1,
					getPricelistConfigType(this.config.packageIdPricing),
				),
				value: { dummy_field: false },
			},
		});

		// Ensure the content exists and is a MoveStruct with expected fields
		if (
			!priceList?.data?.content ||
			priceList.data.content.dataType !== 'moveObject' ||
			!('fields' in priceList.data.content)
		) {
			throw new Error('Price list not found or content is invalid');
		}

		// Safely extract fields
		const fields = priceList.data.content.fields as Record<string, any>;
		if (!fields.value || !fields.value.fields || !fields.value.fields.pricing) {
			throw new Error('Pricing fields not found in the price list');
		}

		const contentArray = fields.value.fields.pricing.fields.contents;
		const priceMap = new Map();

		for (const entry of contentArray) {
			const keyFields = entry.fields.key.fields;
			const key = [Number(keyFields.pos0), Number(keyFields.pos1)]; // Convert keys to numbers
			const value = Number(entry.fields.value); // Convert value to a number

			priceMap.set(key, value);
		}

		return priceMap;
	}

	/**
	 * Returns the renewal price list for SuiNS names in the base asset.
	 */

	// Format:
	// {
	// 	[ 3, 3 ] => 500000000,
	// 	[ 4, 4 ] => 100000000,
	// 	[ 5, 63 ] => 20000000
	// }
	async getRenewalPriceList(): Promise<SuinsPriceList> {
		if (!this.config.suins) throw new Error('Suins object ID is not set');
		if (!this.config.packageId) throw new Error('Price list config not found');

		const priceList = await this.client.getDynamicFieldObject({
			parentId: this.config.suins,
			name: {
				type: getConfigType(
					this.config.packageIdV1,
					getRenewalPricelistConfigType(this.config.packageIdPricing),
				),
				value: { dummy_field: false },
			},
		});

		if (
			!priceList ||
			!priceList.data ||
			!priceList.data.content ||
			priceList.data.content.dataType !== 'moveObject' ||
			!('fields' in priceList.data.content)
		) {
			throw new Error('Price list not found or content structure is invalid');
		}

		// Safely extract fields
		const fields = priceList.data.content.fields as Record<string, any>;
		if (
			!fields.value ||
			!fields.value.fields ||
			!fields.value.fields.config ||
			!fields.value.fields.config.fields.pricing ||
			!fields.value.fields.config.fields.pricing.fields.contents
		) {
			throw new Error('Pricing fields not found in the price list');
		}

		const contentArray = fields.value.fields.config.fields.pricing.fields.contents;
		const priceMap = new Map();

		for (const entry of contentArray) {
			const keyFields = entry.fields.key.fields;
			const key = [Number(keyFields.pos0), Number(keyFields.pos1)]; // Convert keys to numbers
			const value = Number(entry.fields.value); // Convert value to a number

			priceMap.set(key, value);
		}

		return priceMap;
	}

	/**
	 * Returns the coin discount list for SuiNS names.
	 */

	// Format:
	// {
	// 	'b48aac3f53bab328e1eb4c5b3c34f55e760f2fb3f2305ee1a474878d80f650f0::TESTUSDC::TESTUSDC' => 0,
	// 	'0000000000000000000000000000000000000000000000000000000000000002::sui::SUI' => 0,
	// 	'b48aac3f53bab328e1eb4c5b3c34f55e760f2fb3f2305ee1a474878d80f650f0::TESTNS::TESTNS' => 25
	// }
	async getCoinTypeDiscount(): Promise<CoinTypeDiscount> {
		if (!this.config.suins) throw new Error('Suins object ID is not set');
		if (!this.config.packageId) throw new Error('Price list config not found');

		const dfValue = await this.client.getDynamicFieldObject({
			parentId: this.config.suins,
			name: {
				type: getConfigType(
					this.config.packageIdV1,
					getCoinDiscountConfigType(this.config.payments.packageId),
				),
				value: { dummy_field: false },
			},
		});

		if (
			!dfValue ||
			!dfValue.data ||
			!dfValue.data.content ||
			dfValue.data.content.dataType !== 'moveObject' ||
			!('fields' in dfValue.data.content)
		) {
			throw new Error('dfValue not found or content structure is invalid');
		}

		// Safely extract fields
		const fields = dfValue.data.content.fields as Record<string, any>;
		if (
			!fields.value ||
			!fields.value.fields ||
			!fields.value.fields.base_currency ||
			!fields.value.fields.base_currency.fields ||
			!fields.value.fields.base_currency.fields.name ||
			!fields.value.fields.currencies ||
			!fields.value.fields.currencies.fields ||
			!fields.value.fields.currencies.fields.contents
		) {
			throw new Error('Required fields are missing in dfValue');
		}

		// Safely extract content
		const content = fields.value.fields;
		const currencyDiscounts = content.currencies.fields.contents;
		const discountMap = new Map();

		for (const entry of currencyDiscounts) {
			const key = entry.fields.key.fields.name;
			const value = Number(entry.fields.value.fields.discount_percentage);

			discountMap.set(key, value);
		}

		return discountMap;
	}

	async getNameRecord(name: string): Promise<NameRecord | null> {
		if (!isValidSuiNSName(name)) throw new Error('Invalid SuiNS name');
		if (!this.config.registryTableId) throw new Error('Suins package ID is not set');

		const nameRecord = await this.client.getDynamicFieldObject({
			parentId: this.config.registryTableId,
			name: {
				type: getDomainType(this.config.packageIdV1),
				value: normalizeSuiNSName(name, 'dot').split('.').reverse(),
			},
		});

		const fields = nameRecord.data?.content;

		// in case the name record is not found, return null
		if (nameRecord.error?.code === 'dynamicFieldNotFound') return null;

		if (nameRecord.error || !fields || fields.dataType !== 'moveObject')
			throw new Error('Name record not found. This domain is not registered.');
		const content = fields.fields as Record<string, any>;

		const data: Record<string, string> = {};
		content.value.fields.data.fields.contents.forEach((item: any) => {
			// @ts-ignore-next-line
			data[item.fields.key as string] = item.fields.value;
		});

		return {
			name,
			nftId: content.value.fields?.nft_id,
			targetAddress: content.value.fields?.target_address!,
			expirationTimestampMs: content.value.fields?.expiration_timestamp_ms,
			data,
			avatar: data.avatar,
			contentHash: data.content_hash,
			walrusSiteId: data.walrus_site_id,
		};
	}

	/**
	 * Calculates the registration or renewal price for an SLD (Second Level Domain).
	 * It expects a domain name, the number of years and a `SuinsPriceList` object,
	 * as returned from `suinsClient.getPriceList()` function, or `suins.getRenewalPriceList()` function.
	 *
	 * It throws an error:
	 * 1. if the name is a subdomain
	 * 2. if the name is not a valid SuiNS name
	 * 3. if the years are not between 1 and 5
	 */
	async calculatePrice({
		name,
		years,
		isRegistration = true,
	}: {
		name: string;
		years: number;
		isRegistration: boolean;
	}) {
		if (!isValidSuiNSName(name)) {
			throw new Error('Invalid SuiNS name');
		}
		validateYears(years);

		if (isSubName(name)) {
			throw new Error('Subdomains do not have a registration fee');
		}

		const length = normalizeSuiNSName(name, 'dot').split('.')[0].length;
		const priceList = await this.getPriceList();
		const renewalPriceList = await this.getRenewalPriceList();
		let yearsRemain = years;
		let price = 0;

		if (isRegistration) {
			for (const [[minLength, maxLength], pricePerYear] of priceList.entries()) {
				if (length >= minLength && length <= maxLength) {
					price += pricePerYear; // Registration is always 1 year
					yearsRemain -= 1;
					break;
				}
			}
		}

		for (const [[minLength, maxLength], pricePerYear] of renewalPriceList.entries()) {
			if (length >= minLength && length <= maxLength) {
				price += yearsRemain * pricePerYear;
				break;
			}
		}

		return price;
	}

	async getPriceInfoObject(tx: Transaction, feed: string) {
		// Initialize connection to the Sui Price Service
		const endpoint =
			this.network === 'testnet'
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
		const wormholeStateId = this.config.pyth.wormholeStateId;
		const pythStateId = this.config.pyth.pythStateId;

		const client = new SuiPythClient(this.client, pythStateId, wormholeStateId);

		return await client.updatePriceFeeds(tx, priceUpdateData, priceIDs); // returns priceInfoObjectIds
	}

	async getObjectType(objectId: string) {
		// Fetch the object details from the Sui client
		const objectResponse = await this.client.getObject({
			id: objectId,
			options: { showType: true },
		});

		// Extract and return the type if available
		if (objectResponse && objectResponse.data && objectResponse.data.type) {
			return objectResponse.data.type;
		}

		// Throw an error if the type is not found
		throw new Error(`Type information not found for object ID: ${objectId}`);
	}
}
