// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
import { existsSync, unlinkSync, writeFileSync } from 'fs';
import path from 'path';
import { Transaction } from '@mysten/sui/transactions';

import { getClient, publishPackage, signAndExecute } from '../utils/utils';
import { Network, Packages } from './packages';
import { PackageInfo } from './types';

export const publishPackages = async (network: Network, isCiJob = false, configPath?: string) => {
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
			// remove the lockfile on CI to allow fresh flows.
			if (isCiJob) {
				console.info('Removing lock file for CI job');
				const lockFile = path.resolve(packageFolder + '/Move.lock');
				if (existsSync(lockFile)) {
					unlinkSync(lockFile);
					console.info('Lock file removed');
				}
			}

			// writeFileSync(manifestFile, pkg.manifest()); // save the manifest as is.

			const txb = new Transaction();
			publishPackage(txb, packageFolder, configPath);
			const res = await signAndExecute(txb, network);

			await getClient(network).waitForTransaction({
				digest: res.digest,
			});

			// @ts-ignore-next-line
			const data = pkg.processPublish(res);
			results[key] = data;

			console.info(`Published ${key} with packageId: ${data.packageId}`);

			// writeFileSync(manifestFile, pkg.manifest(data.packageId)); // update the manifest with the published-at field.
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
