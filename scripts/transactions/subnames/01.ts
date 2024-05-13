// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { writeFileSync } from 'fs';
import path from 'path';
import { TransactionBlock } from '@mysten/sui.js/transactions';

import { mainPackage } from '../../config/constants';
import { prepareMultisigTx, publishPackage, upgradePackage } from '../../utils/utils';

const UPGRADE_MANIFEST = `[package]
name = "suins"
version = "0.0.2"
#mainnet
published-at="0xb7004c7914308557f7afbaf0dca8dd258e18e306cb7a45b28019f3d0a693f162"
edition = "2024.beta"

[dependencies]
Sui = { git = "https://github.com/MystenLabs/sui.git", subdir = "crates/sui-framework/packages/sui-framework", rev = "framework/mainnet" }

[addresses]
#mainnet
suins = "0x0"
`;

// SPDX-License-Identifier: Apache-2.0
export const firstTransaction = async () => {
	const constants = mainPackage.mainnet;
	const contractsFolder = path.resolve(__dirname + '../../../../packages');
	const txb = new TransactionBlock();

	// // Prepares the manifest file for a `suins` package upgrade.
	writeFileSync(contractsFolder + '/suins/Move.toml', UPGRADE_MANIFEST);
	// upgrade the `suins` package.
	upgradePackage(
		txb,
		contractsFolder + '/suins',
		'0xb7004c7914308557f7afbaf0dca8dd258e18e306cb7a45b28019f3d0a693f162',
		constants.upgradeCap!,
	);

	await prepareMultisigTx(txb, constants.adminAddress, 'mainnet');
};

firstTransaction();
