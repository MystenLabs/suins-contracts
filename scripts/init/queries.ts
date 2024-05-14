// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
import { SuiClient } from '@mysten/sui.js/client';

export const queryRegistryTable = async (
	client: SuiClient,
	suins: string,
	suinsPackageId: string,
) => {
	const table = await client.getDynamicFieldObject({
		parentId: suins,
		name: {
			type: `${suinsPackageId}::suins::RegistryKey<${suinsPackageId}::registry::Registry>`,
			value: {
				dummy_field: false,
			},
		},
	});

	if (table.data?.content?.dataType !== 'moveObject') throw new Error('Invalid data');

	const data = table.data?.content.fields as Record<string, any>;
	return data.value.fields.registry.fields.id.id;
};
