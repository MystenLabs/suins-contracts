// Copyright (c) 2023, Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import dotenv from "dotenv";
dotenv.config();
import { setupAirdrop } from "../airdrop/airdrop-setup";
import { csvToBatches, prepareMultisigTx, readAddressesFromFile } from "../airdrop/helper";

const ADDRESSES_PATH = process.env.ADDRESSES_PATH || './tx/mainnet_airdrop.txt';

const setupMints = async () => {
    // read addresses from file
    const addresses = readAddressesFromFile(ADDRESSES_PATH);
    // convert to batches.
    const batches = csvToBatches(addresses);

    console.log("Total addresses in file: " + addresses.length);
    console.log("First address in file: " + addresses[0]);

    const tx = await setupAirdrop(batches, 'mainnet');

    if(!tx) throw new Error("failed to get TX");

    prepareMultisigTx(tx, 'mainnet');
}

setupMints();
