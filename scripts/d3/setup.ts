import { MIST_PER_SUI, TransactionBlock } from "@mysten/sui.js"
import { executeTx, prepareMultisigTx, prepareSignerFromPrivateKey } from "../airdrop/helper"
import { PackageInfo, mainPackage } from "../config/constants";
import "dotenv/config";

const IS_MAINNET = process.env.NETWORK === 'mainnet';

export const mintD3Cap = (txb: TransactionBlock, address: string, config: PackageInfo) => {
    txb.moveCall({
        target: `${config.d3PackageId}::auth::mint_cap`,
        arguments: [
            txb.object(config.suins),
            txb.object(config.adminCap),
            txb.pure(address),
        ]
    });
}

export const authorizeD3 = (txb: TransactionBlock, config: PackageInfo) => {
    // authorize the direct setup app.
    txb.moveCall({
        target: `${config.packageId}::suins::authorize_app`,
        arguments: [
            txb.object(config.adminCap),
            txb.object(config.suins),
        ],
        typeArguments: [`${config.d3PackageId}::auth::DThreeApp`],
    });
}

export const setupD3 = async (address: string) => {
    const txb = new TransactionBlock();

    const config = mainPackage[IS_MAINNET ? 'mainnet' : 'testnet'];

    // authorize D3 contract
    authorizeD3(txb, config);

    // run setup that creates the configuration DF
    txb.moveCall({
        target: `${config.d3PackageId}::auth::setup`,
        arguments: [
            txb.object(config.suins),
            txb.object(config.adminCap)
        ]
    });

    // Mint a D3 cap for testing.
    mintD3Cap(txb, address, config)

    if(IS_MAINNET) return prepareMultisigTx(txb, 'mainnet')
    
    await executeTx(prepareSignerFromPrivateKey('testnet'), txb);
}

setupD3('0xe0b97bff42fcef320b5f148db69033b9f689555348b2e90f1da72b0644fa37d0');
