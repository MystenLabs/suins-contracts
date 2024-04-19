// Copyright (c) 2023, Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import dotenv from "dotenv";
dotenv.config();
import { Network, PackageInfo, mainPackage } from "../config/constants";
import { MIST_PER_SUI } from '@mysten/sui.js/utils';
import { TransactionBlock } from "@mysten/sui.js/transactions";
import { DAY_ONE_TYPE, Discount, SUIFREN_BULLSHARK_TYPE, SUIFREN_CAPY_TYPE, removeDiscountForType, setupDiscountForType } from "../config/discounts";
import { prepareMultisigTx, signAndExecute } from "../utils/utils";

// Setup Quests 3.
const setup = async (network: Network) => {
    const txb = new TransactionBlock();

    // setup `discount` both for free-claims & discounts by presenting type.
    // 3 chars -> 250 | 4 chars -> 50 | 5 chars+ -> 10
    const priceList: Discount = {
        threeCharacterPrice: 450n * MIST_PER_SUI,
        fourCharacterPrice: 90n * MIST_PER_SUI,
        fivePlusCharacterPrice: 10n * MIST_PER_SUI
    };

    // for mainnet, we prepare the multi-sig tx.
    if(network === 'mainnet') return prepareMultisigTx(txb, 'mainnet');

    // For testnet, we execute the TX directly.
    return signAndExecute(txb, network);
}

if(process.env.NETWORK === 'mainnet') setup('mainnet')
else setup('testnet');


