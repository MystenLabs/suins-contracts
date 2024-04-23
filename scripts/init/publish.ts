// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
import { writeFileSync } from 'fs';
import path from 'path';
import { TransactionBlock } from '@mysten/sui.js/transactions';

import { publishPackage, signAndExecute } from '../utils/utils';
import { Network, Packages } from './packages';
import { PackageInfo } from './types';

export const publishPackages = async (network: Network) => {
	const packages = Packages(network);
	const contractsPath = path.resolve(__dirname, '../../packages');
	const results: Record<string, Record<string, string>> = {};

	// split by ordering, and publish in batch.
	const orderings = [...new Set([...Object.values(packages).map((x) => x.order)])];

	// We do the publishing in batches, because some
	for (const ordering of orderings) {
		const list = Object.entries(packages).filter((x) => x[1].order === ordering);

		for (const [key, pkg] of list) {
			const packageFolder = path.resolve(contractsPath, pkg.folder);
			const manifestFile = path.resolve(packageFolder + '/Move.toml');
			writeFileSync(manifestFile, pkg.manifest()); // save the manifest as is.

			const txb = new TransactionBlock();
			publishPackage(txb, packageFolder, network);
			const res = await signAndExecute(txb, network);

			// @ts-ignore-next-line
			const data = pkg.processPublish(res);
			results[key] = data;

			writeFileSync(manifestFile, pkg.manifest(data.packageId)); // update the manifest with the published-at field.
		}
	}
	writeFileSync(
		path.resolve(path.resolve(__dirname, '../'), 'published.json'),
		JSON.stringify(results, null, 2),
	);
	console.log('******* Packages published successfully *******');
	return results as PackageInfo;
};
