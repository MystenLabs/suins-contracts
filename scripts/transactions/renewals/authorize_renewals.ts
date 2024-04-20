// Copyright (c) 2023, Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import dotenv from "dotenv";
dotenv.config();
import { MIST_PER_SUI } from "@mysten/sui.js/utils";
import { Network, mainPackage } from "../../config/constants";
import { TransactionBlock } from "@mysten/sui.js/transactions";
import { prepareMultisigTx, signAndExecute } from "../../utils/utils";
import { Packages } from "../../init/packages";

export const authorize = async (network: Network) => {
    const txb = new TransactionBlock();
    const config = mainPackage[network];

    Packages('mainnet').Renewal.setupFunction({
      txb,
      adminCap: config.adminCap,
      suins: config.suins,
      packageId: config.renewalsPackageId,
      suinsPackageIdV1: config.packageId,
      priceList: {
          three: 50 * Number(MIST_PER_SUI),
          four: 10 * Number(MIST_PER_SUI),
          fivePlus: 2 * Number(MIST_PER_SUI)
      }
  });
    
    // for mainnet, we just prepare multisig TX
    if(network === 'mainnet') return prepareMultisigTx(txb, 'mainnet');

    return signAndExecute(txb, network)
}

authorize("mainnet");
