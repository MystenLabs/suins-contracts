// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
import { SuiClient } from '@mysten/sui/client';

export const queryRegistryTable = async (
	client: SuiClient,
	suins: string,
	suinsPackageId: string,
) => {
	const allFields = await client.getDynamicFields({
		parentId: suins,
	});

	// just for testing..
	console.log(allFields);
	const table = await client.getDynamicFieldObject({
		parentId: suins,
		name: {
			type: `${suinsPackageId}::suins::RegistryKey<${suinsPackageId}::registry::Registry>`,
			value: {
				dummy_field: false,
			},
		},
	});

	console.log(table);
	console.log(suins);

	if (table.data?.content?.dataType !== 'moveObject')
		throw new Error(`Invalid data ${suinsPackageId}`);

	const data = table.data?.content.fields as Record<string, any>;
	return data.value.fields.registry.fields.id.id;
};
