// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { normalizeSuiNSName } from '@mysten/sui.js/utils';

export function isSubName(name: string): boolean {
	return normalizeSuiNSName(name, 'dot').split('.').length > 2;
}

/**
 * Checks if a name is a nested subname.
 * A nested subdomain is a subdomain that is a subdomain of another subdomain.
 * @param name The name to check (e.g test.example.sub.sui)
 */
export function isNestedSubName(name: string): boolean {
	return normalizeSuiNSName(name, 'dot').split('.').length > 3;
}

/**
 * The years must be between 1 and 5.
 */
export function validateYears(years: number) {
	if (!(years > 0 && years < 6)) throw new Error('Years must be between 1 and 5');
}

/**
 * A helper to parse the price list from the config object.
 */
export function parsePriceListFromConfig(contents: Record<string, any>) {
	return {
		threeLetters: Number(contents?.fields?.three_char_price),
		fourLetters: Number(contents?.fields?.four_char_price),
		fivePlusLetters: Number(contents?.fields?.five_plus_char_price),
	};
}
