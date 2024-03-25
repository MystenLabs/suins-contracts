// Copyright (c) 2023, Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import dotenv from "dotenv";
dotenv.config();
import { executeTx, prepareMultisigTx, prepareSigner } from "../airdrop/helper";
import { TransactionBlock } from "@mysten/sui.js/transactions";
import { Network, mainPackage } from "../config/constants";

export const authorizeDirectSetupApp = async (network: Network) => {
    const tx = new TransactionBlock();

    const config = mainPackage[network];

    // authorize the direct setup app.
    tx.moveCall({
        target: `${config.packageId}::suins::authorize_app`,
        arguments: [
          tx.object(config.adminCap),
          tx.object(config.suins),
        ],
        typeArguments: [`${config.directSetupPackageId}::direct_setup::DirectSetup`],
    });

    // for mainnet, we just prepare multisig TX
    if(network === 'mainnet') return prepareMultisigTx(tx, 'mainnet');

    return executeTx(prepareSigner(config.client), tx);
    // prepare tx data.
    
}

authorizeDirectSetupApp("mainnet");
// authorizeDirectSetupApp("testnet");
