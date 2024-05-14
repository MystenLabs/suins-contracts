// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import path from 'path';
import { KioskClient, Network, TransferPolicyTransaction } from '@mysten/kiosk';
import { getFullnodeUrl, SuiClient } from '@mysten/sui.js/client';
import { TransactionBlock } from '@mysten/sui.js/transactions';

import { mainPackage } from '../../config/constants';
import { authorizeApp } from '../../init/authorization';
import { Packages } from '../../init/packages';
import { prepareMultisigTx, publishPackage } from '../../utils/utils';
import curseWords from './names.json';

export const secondTransaction = async () => {
	const constants = mainPackage.mainnet;
	const contractsFolder = path.resolve(__dirname + '../../../../packages');
	const txb = new TransactionBlock();

	const denylistPackageId = 'ADD DENYLIST PACKAGE ID AFTER PUBLISH';

	// Publish subdomains package.
	publishPackage(txb, contractsFolder + '/subdomains');

	// Authorize denylist package.
	authorizeApp({
		txb,
		adminCap: constants.adminCap,
		suins: constants.suins,
		type: Packages('mainnet').DenyList.authorizationType(denylistPackageId),
		suinsPackageIdV1: constants.packageId,
	});

	// setup denylist package.
	Packages('mainnet').DenyList.setupFunction(
		txb,
		denylistPackageId,
		constants.adminCap,
		constants.suins,
	);

	// Add the blocked names. Let's see if we can do it in one call.
	txb.moveCall({
		target: `${denylistPackageId}::denylist::add_blocked_names`,
		arguments: [txb.object(constants.suins), txb.object(constants.adminCap), txb.pure(curseWords)],
	});

	// Create TransferPolicy.
	const transferPolicyTx = new TransferPolicyTransaction({
		kioskClient: new KioskClient({
			client: new SuiClient({
				url: getFullnodeUrl('mainnet'),
			}),
			network: Network.MAINNET,
		}),
		transactionBlock: txb,
	});

	// Create a transferPolicy for subdomain registration object.
	await transferPolicyTx.createAndShare({
		type: `0x00c2f85e07181b90c140b15c5ce27d863f93c4d9159d2a4e7bdaeb40e286d6f5::subdomain_registration::SubDomainRegistration`,
		publisher: constants.publisherId,
		address: constants.adminAddress,
	});

	await prepareMultisigTx(txb, constants.adminAddress, 'mainnet');
};

secondTransaction();
