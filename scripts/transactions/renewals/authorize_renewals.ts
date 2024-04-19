// Copyright (c) 2023, Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import dotenv from "dotenv";
dotenv.config();
import { MIST_PER_SUI } from "@mysten/sui.js/utils";
import { Network, mainPackage } from "../../config/constants";
import { TransactionBlock } from "@mysten/sui.js/transactions";
import { prepareMultisigTx, signAndExecute } from "../../utils/utils";

export const authorize = async (network: Network) => {
    const txb = new TransactionBlock();

    const config = mainPackage[network];
    txb.moveCall({
        target: `${config.packageId}::suins::authorize_app`,
        arguments: [
          txb.object(config.adminCap),
          txb.object(config.suins),
        ],
        typeArguments: [`${config.renewalsPackageId}::renew::Renew`],
      });
    
      const configuration = txb.moveCall({
        target: `${config.packageId}::config::new`,
        arguments: [
          txb.pure([...Array(33).keys()]),
          txb.pure(50n * MIST_PER_SUI),
          txb.pure(10n * MIST_PER_SUI),
          txb.pure(2n * MIST_PER_SUI),
        ],
      });

      txb.moveCall({
        target: `${config.renewalsPackageId}::renew::setup`,
        arguments: [
          txb.object(config.adminCap),
          txb.object(config.suins),
          configuration,
        ],
        typeArguments: [],
      });
    
    // for mainnet, we just prepare multisig TX
    if(network === 'mainnet') return prepareMultisigTx(txb, 'mainnet');

    return signAndExecute(txb, network)
}

authorize("mainnet");
