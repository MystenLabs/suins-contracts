// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
export function isSubName(name: string): boolean {
	return name.split('.').length > 2;
}

/**
 * Checks if a name is a nested subname.
 * A nested subdomain is a subdomain that is a subdomain of another subdomain.
 * @param name The name to check (e.g test.example.sub.sui)
 */
export function isNestedSubName(name: string): boolean {
	return name.split('.').length > 3;
}

/**
 * Validates a SuiNS name.
 *
 * 1. Lowercase letters, numbers or hyphens
 * 2. Each part must be between 3 and 63 characters
 * 3. Must end with '.sui'
 *
 * @@TODO: Replace with TS SDK validation.
 *
 * @param name The name to validate (e.g example.sui)
 */
export function validateName(name: string) {
	const parts = name.split('.');
	if (parts.some((x) => !x.match(/^[a-z0-9-]+$/)))
		throw new Error('Invalid SuiNS name (only lowercase letters, numbers and hyphens are allowed)');
	if (parts.some((x) => x.length < 3 || x.length > 63))
		throw new Error('Invalid SuiNS name (each part must be between 3 and 63 characters)');
	if (!name.endsWith('.sui')) throw new Error('Invalid SuiNS name');
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
