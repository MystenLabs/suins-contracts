// Copyright (c) 2023, Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import dotenv from "dotenv";
dotenv.config();
import { executeTx, prepareMultisigTx, prepareSigner } from "../airdrop/helper";
import { Network, PackageInfo, mainPackage } from "../config/constants";
import { MIST_PER_SUI } from '@mysten/sui.js/utils';
import { TransactionBlock } from "@mysten/sui.js/transactions";
import { DAY_ONE_TYPE, Discount, SUIFREN_BULLSHARK_TYPE, SUIFREN_CAPY_TYPE, removeDiscountForType, setupDiscountForType } from "../config/discounts";

// Setup Quests 3.
const setup = async (network: Network) => {
    const setup = mainPackage[network];

    const txb = new TransactionBlock();

    // // authorize `discount` package to claim names
    // txb.moveCall({
    //     target: `${setup.packageId}::suins::authorize_app`,
    //     arguments: [
    //       txb.object(setup.adminCap),
    //       txb.object(setup.suins),
    //     ],
    //     typeArguments: [`${setup.discountsPackage.packageId}::house::DiscountHouseApp`],
    // });

    // setup `discount` both for free-claims & discounts by presenting type.
    // 3 chars -> 250 | 4 chars -> 50 | 5 chars+ -> 10
    const priceList: Discount = {
        threeCharacterPrice: 450n * MIST_PER_SUI,
        fourCharacterPrice: 90n * MIST_PER_SUI,
        fivePlusCharacterPrice: 10n * MIST_PER_SUI
    };

    // /// deauthorize. uplaod fixed
    // removeDiscountForType(txb, setup, SUIFREN_BULLSHARK_TYPE[network]);
    // removeDiscountForType(txb, setup, SUIFREN_CAPY_TYPE[network]);
    // removeDiscountForType(txb, setup, DAY_ONE_TYPE[network]);

    // /// authorize the discounts package to allow name registrations.
    // setupDiscountForType(txb, setup, SUIFREN_BULLSHARK_TYPE[network], priceList);
    // setupDiscountForType(txb, setup, SUIFREN_CAPY_TYPE[network], priceList);
    // setupDiscountForType(txb, setup, DAY_ONE_TYPE[network], priceList);

    // authorize the free claims to allow free claiming for 10+ names.
    // setupFreeClaimsForType(txb, setup, SUIFREN_BULLSHARK_TYPE[network], { from: 10, to: 63 });
    // setupFreeClaimsForType(txb, setup, SUIFREN_CAPY_TYPE[network], { from: 10, to: 63 });
    // setupFreeClaimsForType(txb, setup, DAY_ONE_TYPE[network], { from: 10, to: 63 });

    // for mainnet, we prepare the multi-sig tx.
    if(network === 'mainnet') return prepareMultisigTx(txb, 'mainnet');

    // For testnet, we execute the TX directly.
    return executeTx(prepareSigner(), txb, setup.client);
}

if(process.env.NETWORK === 'mainnet') setup('mainnet')
else setup('testnet');


