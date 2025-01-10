// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { SuiClient } from '@mysten/sui/client';
import { normalizeSuiNSName } from '@mysten/sui/utils';

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

export const getObjectType = async (suiClient: SuiClient, objectId: string): Promise<string> => {
	const objectResponse = await suiClient.getObject({
		id: objectId,
		options: { showType: true },
	});
	if (objectResponse && objectResponse.data && objectResponse.data.type) {
		return objectResponse.data.type;
	}
	throw new Error('Object data not found');
};
