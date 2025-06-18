import { cnf, newSuiClient } from "./common";

const client = newSuiClient();

let txDigests: string[] = [];

// while (txDigests.length === 0) {
    let cursor: string | null | undefined = null;
    const txs = await client.queryTransactionBlocks({
        filter: {
            MoveFunction: {
                package: cnf.aftermathAmmPkgId,
                module: "swap",
                function: "swap_exact_in",
            },
        },
        options: {
            showEffects: true,
        },
        cursor,
    });
    cursor = txs.nextCursor;
    txDigests = txs.data
        // .filter((tx) => tx.effects?.status.status === "success")
        .map((tx) => tx.digest);
//     if (txDigests.length === 0) {
//         console.debug(`No txs found, fetching next page...`);
//     }
// }

console.log(txDigests);
