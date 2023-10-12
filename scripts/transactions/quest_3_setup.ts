// Copyright (c) 2023, Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import dotenv from "dotenv";
dotenv.config();
import { executeTx, prepareMultisigTx, prepareSigner } from "../airdrop/helper";
import { Network, PackageInfo, mainPackage } from "../config/constants";
import { MIST_PER_SUI, TransactionBlock } from "@mysten/sui.js";

const SUIFREN_BULLSHARK_TYPE: Record<Network, string> = {
    mainnet: '0xee496a0cc04d06a345982ba6697c90c619020de9e274408c7819f787ff66e1a1::suifrens::SuiFren<0x8894fa02fc6f36cbc485ae9145d05f247a78e220814fb8419ab261bd81f08f32::bullshark::Bullshark>',
    testnet: '0x80d7de9c4a56194087e0ba0bf59492aa8e6a5ee881606226930827085ddf2332::suifrens::SuiFren<0x297d8afb6ede450529d347cf9254caeea2b685c8baef67b084122291ebaefb38::bullshark::Bullshark>'
};

const SUIFREN_CAPY_TYPE: Record<Network, string> = {
    mainnet: '0xee496a0cc04d06a345982ba6697c90c619020de9e274408c7819f787ff66e1a1::suifrens::SuiFren<0xee496a0cc04d06a345982ba6697c90c619020de9e274408c7819f787ff66e1a1::capy::Capy>',
    testnet: '0x80d7de9c4a56194087e0ba0bf59492aa8e6a5ee881606226930827085ddf2332::suifrens::SuiFren<0x80d7de9c4a56194087e0ba0bf59492aa8e6a5ee881606226930827085ddf2332::capy::Capy>'
};

const DAY_ONE_TYPE: Record<Network, string> = {
    mainnet: '0xbf1431324a4a6eadd70e0ac6c5a16f36492f255ed4d011978b2cf34ad738efe6::day_one::DayOne',
    testnet: '0x71c2dc2ce8a3cde0f7fa6638519c64f24b1b7bc20e8272d2ca0690ffbbfabc4a::day_one::DayOne'
};

// Discount setup. (Final pricing)
export type Discount = {
    threeCharacterPrice: bigint;
    fourCharacterPrice: bigint;
    fivePlusCharacterPrice: bigint;
}
// A char range available for free claims.
export type Range = {
    from: number;
    to: number;
}

// remove discount for type
const removeDiscountForType = (txb: TransactionBlock, setup: PackageInfo, type: string) => {
    txb.moveCall({
        target: `${setup.discountsPackage.packageId}::discounts::deauthorize_type`,
        arguments: [
            txb.object(setup.adminCap),
            txb.object(setup.discountsPackage.discountHouseId),
        ],
        typeArguments: [type]
    });
}

// Sets up discount prices for type.
const setupDiscountForType = (txb: TransactionBlock, setup: PackageInfo, type: string, prices: Discount) => {
    txb.moveCall({
        target: `${setup.discountsPackage.packageId}::discounts::authorize_type`,
        arguments: [
            txb.object(setup.adminCap),
            txb.object(setup.discountsPackage.discountHouseId),
            txb.pure(prices.threeCharacterPrice, 'u64'),
            txb.pure(prices.fourCharacterPrice, 'u64'),
            txb.pure(prices.fivePlusCharacterPrice, 'u64'),
        ],
        typeArguments: [type]
    });
}

// Sets up free claims for type.
const setupFreeClaimsForType = (txb: TransactionBlock, setup: PackageInfo, type: string, characters: Range) => {
    txb.moveCall({
        target: `${setup.discountsPackage.packageId}::free_claims::authorize_type`,
        arguments: [
            txb.object(setup.adminCap),
            txb.object(setup.discountsPackage.discountHouseId),
            txb.pure([characters.from, characters.to], 'vector<u8>')
        ],
        typeArguments: [type]
    });
}

// Setup Quests 3.
const setup = async (network: Network) => {
    const setup = mainPackage[network];

    const txb = new TransactionBlock();

    // authorize `discount` package to claim names
    txb.moveCall({
        target: `${setup.packageId}::suins::authorize_app`,
        arguments: [
          txb.object(setup.adminCap),
          txb.object(setup.suins),
        ],
        typeArguments: [`${setup.discountsPackage.packageId}::house::DiscountHouseApp`],
    });

    // setup `discount` both for free-claims & discounts by presenting type.
    // 3 chars -> 250 | 4 chars -> 50 | 5 chars+ -> 10
    const priceList: Discount = {
        threeCharacterPrice: 450n * MIST_PER_SUI,
        fourCharacterPrice: 90n * MIST_PER_SUI,
        fivePlusCharacterPrice: 10n * MIST_PER_SUI
    };

    /// deauthorize. uplaod fixed
    removeDiscountForType(txb, setup, SUIFREN_BULLSHARK_TYPE[network]);
    removeDiscountForType(txb, setup, SUIFREN_CAPY_TYPE[network]);
    removeDiscountForType(txb, setup, DAY_ONE_TYPE[network]);

    /// authorize the discounts package to allow name registrations.
    setupDiscountForType(txb, setup, SUIFREN_BULLSHARK_TYPE[network], priceList);
    setupDiscountForType(txb, setup, SUIFREN_CAPY_TYPE[network], priceList);
    setupDiscountForType(txb, setup, DAY_ONE_TYPE[network], priceList);

    // authorize the free claims to allow free claiming for 10+ names.
    // setupFreeClaimsForType(txb, setup, SUIFREN_BULLSHARK_TYPE[network], { from: 10, to: 63 });
    // setupFreeClaimsForType(txb, setup, SUIFREN_CAPY_TYPE[network], { from: 10, to: 63 });
    // setupFreeClaimsForType(txb, setup, DAY_ONE_TYPE[network], { from: 10, to: 63 });

    // for mainnet, we prepare the multi-sig tx.
    if(network === 'mainnet') return prepareMultisigTx(txb, 'mainnet');

    // For testnet, we execute the TX directly.
    return executeTx(prepareSigner(setup.provider), txb);
}

if(process.env.NETWORK === 'mainnet') setup('mainnet')
else setup('testnet');


