import { newSuiClient } from "../utils.js";

// const ammPackage = "0xefe170ec0be4d762196bedecd7a065816576198a6527c99282a2551aaa7da38c"; // v1
const ammPackage = "0xc4049b2d1cc0f6e017fda8260e4377cecd236bd7f56a54fee120816e72e2e0dd"; // v2
// const ammPackage = "0xf948935b111990c2b604900c9b2eeb8f24dcf9868a45d1ea1653a5f282c10e29"; // v3

const client = newSuiClient();

let txDigests: string[] = [];

// while (txDigests.length === 0) {
let cursor: string | null | undefined = null;
const txs = await client.queryTransactionBlocks({
    filter: {
        MoveFunction: {
            package: ammPackage,
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
//         console.log(`No txs found, fetching next page...`);
//     }
// }

console.log(txDigests);
