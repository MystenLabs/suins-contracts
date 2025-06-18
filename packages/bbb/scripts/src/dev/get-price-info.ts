import { Transaction } from "@mysten/sui/transactions";
import { SuiPriceServiceConnection, SuiPythClient } from '../pyth/pyth.js';

import { cnf, newSuiClient } from "../config.js";

async function getPriceInfoObject(
    tx: Transaction,
    feed: string,
): Promise<string[]> {
    // Initialize connection to the Sui Price Service
    const connection = new SuiPriceServiceConnection(cnf.pyth.endpoint);

    // List of price feed IDs
    const priceIDs = [
        feed, // ASSET/USD price ID
    ];

    // Fetch price feed update data
    const priceUpdateData = await connection.getPriceFeedsUpdateData(priceIDs);

    // Initialize Sui Client and Pyth Client
    const suiClient = newSuiClient();
    const pythClient = new SuiPythClient(suiClient, cnf.pyth.stateObj, cnf.wormhole.stateObj);

    return await pythClient.updatePriceFeeds(tx, priceUpdateData, priceIDs); // returns priceInfoObjectIds
}

// === CLI ===

if (require.main === module) {
    const tx = new Transaction();
    const infos = await Promise.all([
        getPriceInfoObject(tx, cnf.coins.SUI.feed),
        getPriceInfoObject(tx, cnf.coins.NS.feed),
        getPriceInfoObject(tx, cnf.coins.USDC.feed),
    ]);
    console.log("SUI: ", infos[0][0]);
    console.log("NS:  ", infos[1][0]);
    console.log("USDC:", infos[2][0]);
}
