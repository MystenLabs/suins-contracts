// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
import { writeFileSync } from 'fs';
import path from 'path';
import { TransactionBlock } from '@mysten/sui.js/transactions';

import { publishPackage, signAndExecute } from '../utils/utils';
import { Network, Packages } from './packages';
import { PackageInfo } from './types';

export const publishPackages = async (network: Network, isCiJob = false) => {
	const packages = Packages(isCiJob ? 'mainnet' : network);
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
			publishPackage(txb, packageFolder);
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
	const data = results as PackageInfo;

	// Export the constants based on the SDK's format so SDK can be easily tested.
	writeFileSync(
		path.resolve(path.resolve(__dirname, '../'), 'constants.sdk.json'),
		JSON.stringify(
			{
				suinsPackageId: {
					latest: data.SuiNS.packageId,
					v1: data.SuiNS.packageId,
				},
				suinsObjectId: data.SuiNS.suins,
				utilsPackageId: data.Utils.packageId,
				registrationPackageId: data.Registration.packageId,
				renewalPackageId: data.Renewal.packageId,
				subNamesPackageId: data.Subdomains.packageId,
				tempSubNamesProxyPackageId: data.TempSubdomainProxy.packageId,
			},
			null,
			2,
		),
	);

	return data;
};
