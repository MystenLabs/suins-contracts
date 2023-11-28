// Copyright (c) 2023, Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import dotenv from "dotenv";
dotenv.config();
import { executeTx, prepareMultisigTx, prepareSignerFromPrivateKey } from "../airdrop/helper";
import { TransactionBlock } from "@mysten/sui.js";
import { Network, mainPackage } from "../config/constants";

const SUBDOMAIN_DISPLAY: Record<string, string> = {
    name: '{nft.domain_name}',
    link: 'https://{nft.domain_name}.id',
    image_url: 'ipfs://{nft.image_url}',
    description: 'SuiNS - Sculpt Your Identity',
    project_url: 'https://suins.io',
}

const SUBDOMAIN_TYPE: Record<Network, string> = {
    testnet: '0x8ea50d1974a257d3ed8e94fbe4f280d8df1a0a9b1eb511773e74d613d2c2afe3::subdomain_registration::SubDomainRegistration',
    mainnet: 'TODO:Fill this in.'
}

export const prepareSubdomainDisplay = async (txb: TransactionBlock, network: Network) => {
    const config = mainPackage[network];

    // Create a new Display object using the publisher object and the fields.
    const display = txb.moveCall({
        target: '0x2::display::new_with_fields',
        arguments: [txb.object(config.publisherId), txb.pure(Object.keys(SUBDOMAIN_DISPLAY)), txb.pure(Object.values(SUBDOMAIN_DISPLAY))],
        typeArguments: [SUBDOMAIN_TYPE[network]],
    });
    
    // Bump the version. This causes the Display to update on-chain (so all objects of type T will be fetched with this configuration).
    txb.moveCall({
        target: '0x2::display::update_version',
        arguments: [display],
        typeArguments: [SUBDOMAIN_TYPE[network]],
    });
    
    // Transfer the Display object back to the owner.
    txb.transferObjects([display], txb.pure(config.adminAddress));
}

export const authorizeSubdomains = async (network: Network) => {
    const txb = new TransactionBlock();

    const config = mainPackage[network];

    prepareSubdomainDisplay(txb, network);

    txb.moveCall({
        target: `${config.packageId}::suins::authorize_app`,
        arguments: [
            txb.object(config.adminCap),
            txb.object(config.suins),
        ],
        typeArguments: [`${config.subdomainsPackageId}::subdomains::SubDomains`],
    });
    
    txb.moveCall({
      target: `${config.subdomainsPackageId}::subdomains::setup`,
      arguments: [
        txb.object(config.suins),
        txb.object(config.adminCap),
      ]
    });

    // for mainnet, we just prepare multisig TX
    if(network === 'mainnet') return prepareMultisigTx(txb, 'mainnet');

    return executeTx(prepareSignerFromPrivateKey('testnet'), txb);
    // prepare tx data.
}

// authorizeSubdomains("testnet");
