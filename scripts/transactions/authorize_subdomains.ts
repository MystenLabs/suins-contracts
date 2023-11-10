// Copyright (c) 2023, Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import dotenv from "dotenv";
dotenv.config();
import { executeTx, prepareMultisigTx, prepareSigner, prepareSignerFromPrivateKey } from "../airdrop/helper";
import { TransactionBlock } from "@mysten/sui.js";
import { Network, mainPackage } from "../config/constants";

export const authorizeSubdomains = async (network: Network) => {
    const tx = new TransactionBlock();

    const config = mainPackage[network];

    tx.moveCall({
        target: `${config.packageId}::suins::authorize_app`,
        arguments: [
          tx.object(config.adminCap),
          tx.object(config.suins),
        ],
        typeArguments: [`${config.subdomainsPackageId}::subdomains::SubDomains`],
    });
    
    tx.moveCall({
      target: `${config.subdomainsPackageId}::subdomains::setup`,
      arguments: [
        tx.object(config.suins),
        tx.object(config.adminCap),
      ]
    });

    // for mainnet, we just prepare multisig TX
    if(network === 'mainnet') return prepareMultisigTx(tx, 'mainnet');

    return executeTx(prepareSignerFromPrivateKey('testnet'), tx);
    // prepare tx data.
    
}

authorizeSubdomains("testnet");
// authorizeDirectSetupApp("testnet");
