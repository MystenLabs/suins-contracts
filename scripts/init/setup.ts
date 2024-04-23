// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
import { TransactionBlock } from '@mysten/sui.js/transactions';
import { MIST_PER_SUI } from '@mysten/sui.js/utils';

import { signAndExecute } from '../utils/utils';
import { authorizeApp } from './authorization';
import { Network, Packages } from './packages';
import { PackageInfo } from './types';

export const setup = async (packageInfo: PackageInfo, network: Network) => {
	const packages = Packages(network);

	const txb = new TransactionBlock();

	for (const [key, pkg] of Object.entries(packageInfo)) {
		const data = packages[key as keyof typeof packages];
		if (data && 'authorizationType' in data) {
			authorizeApp({
				txb,
				adminCap: packageInfo.SuiNS.adminCap,
				suins: packageInfo.SuiNS.suins,
				type: data.authorizationType(pkg.packageId),
				suinsPackageIdV1: packageInfo.SuiNS.packageId,
			});
		}
	}
	// Call setup functions for our packages.
	packages.Subdomains.setupFunction(
		txb,
		packageInfo.Subdomains.packageId,
		packageInfo.SuiNS.adminCap,
		packageInfo.SuiNS.suins,
	);
	packages.DenyList.setupFunction(
		txb,
		packageInfo.DenyList.packageId,
		packageInfo.SuiNS.adminCap,
		packageInfo.SuiNS.suins,
	);
	packages.SuiNS.setupFunction(
		txb,
		packageInfo.SuiNS.packageId,
		packageInfo.SuiNS.adminCap,
		packageInfo.SuiNS.suins,
		packageInfo.SuiNS.publisher,
	);
	packages.Renewal.setupFunction({
		txb,
		adminCap: packageInfo.SuiNS.adminCap,
		suins: packageInfo.SuiNS.suins,
		packageId: packageInfo.Renewal.packageId,
		suinsPackageIdV1: packageInfo.SuiNS.packageId,
		priceList: {
			three: 2 * Number(MIST_PER_SUI),
			four: 1 * Number(MIST_PER_SUI),
			fivePlus: 0.2 * Number(MIST_PER_SUI),
		},
	});

	try {
		await signAndExecute(txb, network);
		console.log('******* Packages set up successfully *******');
	} catch (e) {
		console.error('Something went wrong!');
		console.dir(e, { depth: null });
	}
};
