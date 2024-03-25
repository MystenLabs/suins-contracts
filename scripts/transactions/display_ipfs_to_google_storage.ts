// Copyright (c) 2023, Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import dotenv from "dotenv";
dotenv.config();
import { prepareMultisigTx } from "../airdrop/helper";
import { authorizeBogoApp } from "../airdrop/authorize-app";
import { TransactionBlock } from "@mysten/sui.js/transactions";
import { mainPackage } from "../config/constants";

const run = async () => {
    // read addresses from file
    // convert to batches.
    const setup = mainPackage.mainnet;
    const txb = new TransactionBlock();

    if(!setup.displayObject) throw new Error("Display object not defined");

    txb.moveCall({
        target: '0x2::display::edit',
        arguments: [
            txb.object(setup.displayObject),
            txb.pure('image_url', 'string'),
            txb.pure('https://storage.googleapis.com/suins-nft-images/{image_url}.png', 'string')
        ],
        typeArguments: [
            `${setup.packageId}::suins_registration::SuinsRegistration`
        ]
    });

    txb.moveCall({
        target: `0x2::display::update_version`,
        arguments: [
            txb.object(setup.displayObject)
        ],
        typeArguments: [
            `${setup.packageId}::suins_registration::SuinsRegistration`
        ]
    })

    prepareMultisigTx(txb, 'mainnet');
}

run();
