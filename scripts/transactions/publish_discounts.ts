// Copyright (c) 2023, Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import dotenv from "dotenv";
dotenv.config();
import { execSync } from 'child_process';

const gasObject = process.env.GAS_OBJECT;

const publish = async () => {
    if(!gasObject) throw new Error("Gas Object not supplied for a mainnet transaction");

    // on GH Action, the sui binary is located on root. Referencing that as `/` doesn't work.
    const suiFolder = process.env.ORIGIN === 'gh_action' ? '../../sui' : 'sui';
    const publishCall = `${suiFolder} client publish --gas-budget 3000000000 --gas ${gasObject} --serialize-unsigned-transaction`

    // to suins/..(packages)/..(base)/scripts/tx/tx-data.txt
    execSync(`cd $PWD/../packages/discounts && ${publishCall} > $PWD/../../scripts/tx/tx-data.txt`);
}

publish();
