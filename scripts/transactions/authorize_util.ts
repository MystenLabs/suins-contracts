// Copyright (c) 2023, Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import dotenv from "dotenv";
dotenv.config();
import { TransactionBlock } from "@mysten/sui.js/transactions";
import { Network, mainPackage } from "../config/constants";
import { prepareMultisigTx, signAndExecute } from "../utils/utils";

export const authorize = async (authorize: boolean, network: Network) => {
    const type = process.env.TYPE
    if (!type) throw new Error("TYPE is required");
    const tx = new TransactionBlock();

    const config = mainPackage[network];
    const auth = authorize ? "authorize_app" : "deauthorize_app"

    // authorize the direct setup app.
    tx.moveCall({
        target: `${config.packageId}::suins::${auth}`,
        arguments: [
          tx.object(config.adminCap),
          tx.object(config.suins),
        ],
        typeArguments: [type],
    });

    // for mainnet, we just prepare multisig TX
    if(network === 'mainnet') return prepareMultisigTx(tx, 'mainnet');

    return signAndExecute(tx, network)
}