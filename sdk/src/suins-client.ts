// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
import { SuiClient } from '@mysten/sui/client';
import { isValidSuiNSName, normalizeSuiNSName } from '@mysten/sui/utils';

import {
	getConfigType,
	getDomainType,
	getPricelistConfigType,
	getRenewalPricelistConfigType,
	MAINNET_CONFIG,
	TESTNET_CONFIG,
} from './constants.js';
import { isSubName, validateYears } from './helpers.js';
import type { Constants, NameRecord, SuinsClientConfig, SuinsPriceList } from './types.js';

/// The SuinsClient is the main entry point for the Suins SDK.
/// It allows you to interact with SuiNS.
export class SuinsClient {
	#client: SuiClient;
	constants: Constants = {};

	constructor(config: SuinsClientConfig) {
		this.#client = config.client;
		const network = config.network || 'mainnet';

		if (network === 'mainnet') {
			this.constants = MAINNET_CONFIG;
		}

		if (network === 'testnet') {
			this.constants = TESTNET_CONFIG;
		}

		if (config.packageIds) {
			this.constants = { ...(this.constants || {}), ...config.packageIds };
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
		if (!this.constants.suinsObjectId) throw new Error('Suins object ID is not set');
		if (!this.constants.suinsPackageId) throw new Error('Price list config not found');

		const priceList = await this.#client.getDynamicFieldObject({
			parentId: this.constants.suinsObjectId,
			name: {
				type: getConfigType(
					this.constants.suinsPackageId.latest,
					getPricelistConfigType(this.constants.suinsPackageId.latest),
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
		if (!this.constants.suinsObjectId) throw new Error('Suins object ID is not set');
		if (!this.constants.suinsPackageId) throw new Error('Price list config not found');

		const priceList = await this.#client.getDynamicFieldObject({
			parentId: this.constants.suinsObjectId,
			name: {
				type: getConfigType(
					this.constants.suinsPackageId.v1,
					getRenewalPricelistConfigType(this.constants.suinsPackageId.latest),
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

	// async getNameRecord(name: string): Promise<any> {
	// 	if (!isValidSuiNSName(name)) throw new Error('Invalid SuiNS name');
	// 	if (!this.constants.suinsPackageId) throw new Error('Suins package ID is not set');

	// 	const nameRecord = await this.#client.getDynamicFieldObject({
	// 		parentId: this.constants.suinsObjectId!,
	// 		name: {
	// 			type: getDomainType(this.constants.suinsPackageId.v1),
	// 			value: normalizeSuiNSName(name, 'dot').split('.').reverse(),
	// 		},
	// 	});

	// 	return nameRecord;
	// 	// const fields = nameRecord.data?.content;

	// 	// // in case the name record is not found, return null
	// 	// if (nameRecord.error?.code === 'dynamicFieldNotFound') return null;

	// 	// if (nameRecord.error || !fields || fields.dataType !== 'moveObject')
	// 	// 	throw new Error('Name record not found. This domain is not registered.');
	// 	// const content = fields.fields as Record<string, any>;

	// 	// const data: Record<string, string> = {};
	// 	// content.value.fields.data.fields.contents.forEach((item: any) => {
	// 	// 	// @ts-ignore-next-line
	// 	// 	data[item.fields.key as string] = item.fields.value;
	// 	// });

	// 	// return {
	// 	// 	name,
	// 	// 	nftId: content.value.fields?.nft_id,
	// 	// 	targetAddress: content.value.fields?.target_address!,
	// 	// 	expirationTimestampMs: content.value.fields?.expiration_timestamp_ms,
	// 	// 	data,
	// 	// 	avatar: data.avatar,
	// 	// 	contentHash: data.content_hash,
	// 	// };
	// }

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
	calculatePrice({
		name,
		years,
		priceList,
	}: {
		name: string;
		years: number;
		priceList: SuinsPriceList;
	}) {
		if (!isValidSuiNSName(name)) {
			throw new Error('Invalid SuiNS name');
		}
		validateYears(years);

		if (isSubName(name)) {
			throw new Error('Subdomains do not have a registration fee');
		}

		const length = normalizeSuiNSName(name, 'dot').split('.')[0].length;

		for (const [[minLength, maxLength], pricePerYear] of priceList.entries()) {
			if (length >= minLength && length <= maxLength) {
				return years * pricePerYear;
			}
		}

		// If no matching range is found, throw an error
		throw new Error('No price available for the given name length');
	}
}

// // Initialize and execute the SuinsClient to fetch the renewal price list
// (async () => {
// 	// Step 1: Create a SuiClient instance
// 	const suiClient = new SuiClient({
// 		url: 'https://fullnode.testnet.sui.io', // Sui testnet endpoint
// 	});

// 	// Step 2: Create a SuinsClient instance using TESTNET_CONFIG
// 	const suinsClient = new SuinsClient({
// 		client: suiClient,
// 		network: 'testnet',
// 		packageIds: TESTNET_CONFIG, // Use predefined TESTNET_CONFIG
// 	});

// 	// Step 3: Fetch and log the renewal price list
// 	const renewalPriceList = await suinsClient.getPriceList();
// 	const price = suinsClient.calculatePrice({
// 		name: 'example.sui',
// 		years: 2,
// 		priceList: renewalPriceList,
// 	});
// 	console.log(price);
// })();
