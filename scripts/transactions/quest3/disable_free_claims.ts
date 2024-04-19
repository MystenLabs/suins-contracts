// Copyright (c) 2023, Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import dotenv from "dotenv";
dotenv.config();
import { Network, mainPackage } from "../../config/constants";
import { TransactionBlock } from "@mysten/sui.js/transactions";
import { DAY_ONE_TYPE, SUIFREN_BULLSHARK_TYPE, SUIFREN_CAPY_TYPE, removeFreeClaimsForType } from "../../config/discounts";
import { prepareMultisigTx, signAndExecute } from "../../utils/utils";

// Setup Quests 3.
const setup = async (network: Network) => {
    const setup = mainPackage[network];

    const txb = new TransactionBlock();

    removeFreeClaimsForType(txb, setup, SUIFREN_BULLSHARK_TYPE[network]);
    removeFreeClaimsForType(txb, setup, SUIFREN_CAPY_TYPE[network]);
    removeFreeClaimsForType(txb, setup, DAY_ONE_TYPE[network]);

    // for mainnet, we prepare the multi-sig tx.
    if(network === 'mainnet') return prepareMultisigTx(txb, 'mainnet');

    // For testnet, we execute the TX directly.
    return signAndExecute(txb, network);
}

if(process.env.NETWORK === 'mainnet') setup('mainnet')
else setup('testnet');


