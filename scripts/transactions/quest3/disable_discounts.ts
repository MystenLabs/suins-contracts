// Copyright (c) 2023, Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import dotenv from "dotenv";
dotenv.config();
import { executeTx, prepareMultisigTx, prepareSigner } from "../../airdrop/helper";
import { Network, mainPackage } from "../../config/constants";
import { TransactionBlock } from "@mysten/sui.js/transactions";
import { DAY_ONE_TYPE, SUIFREN_BULLSHARK_TYPE, SUIFREN_CAPY_TYPE, removeDiscountForType } from "../../config/discounts";

const execute = async (network: Network) => {
    const setup = mainPackage[network];

    const txb = new TransactionBlock();

    removeDiscountForType(txb, setup, SUIFREN_BULLSHARK_TYPE[network]);
    removeDiscountForType(txb, setup, SUIFREN_CAPY_TYPE[network]);
    removeDiscountForType(txb, setup, DAY_ONE_TYPE[network]);

    // for mainnet, we prepare the multi-sig tx.
    if(network === 'mainnet') return prepareMultisigTx(txb, 'mainnet');

    // For testnet, we execute the TX directly.
    return executeTx(prepareSigner(), txb, setup.client);
}

if(process.env.NETWORK === 'mainnet') execute('mainnet')
else execute('testnet');


