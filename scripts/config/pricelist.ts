import { TransactionBlock } from "@mysten/sui.js";
import { PackageInfo } from "./constants";

export const updatePriceList = (
    txb: TransactionBlock,
    prices: { three: bigint; four: bigint; fivePlus: bigint; },
    config: PackageInfo
) => {

    // remove the old config
    txb.moveCall({
        target: `${config.packageId}::suins::remove_config`,
        arguments: [
            txb.object(config.adminCap),
            txb.object(config.suins),
        ],
        typeArguments: [
            `${config.packageId}::config::Config`
        ]
    })

    // create the new config
    const newConfig = txb.moveCall({
        target: `${config.packageId}::config::new`,
        arguments: [
            txb.pure(config.publicKey, 'vector<u8>'),
            txb.pure(prices.three),
            txb.pure(prices.four),
            txb.pure(prices.fivePlus)
        ]
    });

    // add it
    txb.moveCall({
        target: `${config.packageId}::suins::add_config`,
        arguments: [
            txb.object(config.adminCap),
            txb.object(config.suins),
            newConfig
        ],
        typeArguments: [
            `${config.packageId}::config::Config`
        ]
    });
}
