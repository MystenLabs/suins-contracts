import { Transaction } from "@mysten/sui/transactions";

import { cnf } from "../config.js";
import { getPriceInfoObject } from "../utils.js";

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
