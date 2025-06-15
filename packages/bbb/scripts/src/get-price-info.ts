import { Transaction } from "@mysten/sui/transactions";
import { SuiPriceServiceConnection, SuiPythClient } from './pyth/pyth.js';

import { getConfig, getPythEndpoint, newSuiClient } from "./common";

async function getPriceInfoObject(
    tx: Transaction,
    feed: string,
): Promise<string[]> {
    // Initialize connection to the Sui Price Service
    const connection = new SuiPriceServiceConnection(getPythEndpoint());

    // List of price feed IDs
    const priceIDs = [
        feed, // ASSET/USD price ID
    ];

    // Fetch price feed update data
    const priceUpdateData = await connection.getPriceFeedsUpdateData(priceIDs);

    // Initialize Sui Client and Pyth Client
    const conf = getConfig();
    const suiClient = newSuiClient();
    const pythClient = new SuiPythClient(suiClient, conf.pythStateObjId, conf.wormholeStateObjId);

    return await pythClient.updatePriceFeeds(tx, priceUpdateData, priceIDs); // returns priceInfoObjectIds
}

// === CLI ===

if (require.main === module) {
    const conf = getConfig();
    const tx = new Transaction();
    const infos = await Promise.all([
        getPriceInfoObject(tx, conf.coins.SUI.feed),
        getPriceInfoObject(tx, conf.coins.NS.feed),
        getPriceInfoObject(tx, conf.coins.USDC.feed),
    ]);
    console.log("SUI: ", infos[0][0]);
    console.log("NS:  ", infos[1][0]);
    console.log("USDC:", infos[2][0]);
}
