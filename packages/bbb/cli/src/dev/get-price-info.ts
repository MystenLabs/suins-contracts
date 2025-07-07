import { Transaction } from "@mysten/sui/transactions";

import { cnf } from "../config.js";
import { getPriceInfoObject, logJson } from "../utils.js";

// === CLI ===

if (require.main === module) {
    const tx = new Transaction();
    const infos = await Promise.all([
        getPriceInfoObject(tx, cnf.coins.SUI.pyth_feed),
        getPriceInfoObject(tx, cnf.coins.NS.pyth_feed),
        getPriceInfoObject(tx, cnf.coins.USDC.pyth_feed),
    ]);
    logJson({
        SUI: infos[0],
        NS: infos[1],
        USDC: infos[2],
    });
}
