// Copyright (c) 2023, Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { execSync } from 'child_process';
import dotenv from 'dotenv';

import { mainPackage, Network } from '../config/constants';

dotenv.config();

const gasObject = process.env.GAS_OBJECT;
const network = (process.env.NETWORK as Network) || 'mainnet';

// Active env of sui has to be the same with the env we're publishing to.
// if upgradeCap & gasObject is on mainnet, it has to be on mainnet.
// Github actions are always on mainnet.
const mainPackageUpgrade = async () => {
	if (!gasObject) throw new Error('Gas Object not supplied for a mainnet transaction');

	// on GH Action, the sui binary is located on root. Referencing that as `/` doesn't work.
	const suiFolder = process.env.ORIGIN === 'gh_action' ? '../../sui' : 'sui';
	const upgradeCall = `${suiFolder} client upgrade --upgrade-capability ${mainPackage[network].upgradeCap} --gas-budget 3000000000 --gas ${gasObject} --serialize-unsigned-transaction`;

	// we execute this on `setup/package.json` so we go one level back, access packages folder -> suins -> upgrade.
	// we go from scripts/(base)/packages/suins, we run the upgrade and then we save the transaction data
	// to suins/..(packages)/..(base)/scripts/tx/tx-data.txt
	execSync(`cd $PWD/../packages/suins && ${upgradeCall} > $PWD/../../scripts/tx/tx-data.txt`);
};

mainPackageUpgrade();
