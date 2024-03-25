// Copyright (c) 2023, Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import dotenv from "dotenv";
dotenv.config();
import { executeTx, prepareMultisigTx, prepareSigner } from "../../airdrop/helper";
import { Network, mainPackage } from "../../config/constants";
import { TransactionBlock } from "@mysten/sui.js/src/transactions";
import { DAY_ONE_TYPE, SUIFREN_BULLSHARK_TYPE, SUIFREN_CAPY_TYPE, removeFreeClaimsForType, setupDiscountForType } from "../../config/discounts";

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
    return executeTx(prepareSigner(setup.client), txb);
}

if(process.env.NETWORK === 'mainnet') setup('mainnet')
else setup('testnet');


