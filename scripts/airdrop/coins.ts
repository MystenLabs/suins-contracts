import { TransactionBlock } from "@mysten/sui.js/transactions";
import {executeTx } from "./helper";
import { AirdropConfig } from "../config/day_one";
import { Ed25519Keypair } from "@mysten/sui.js/keypairs/ed25519";
import { SuiClient } from "@mysten/sui.js/client";

// Merges all other coins to the coin defined in the config.
export const cleanUpCoins = async (signer: Ed25519Keypair, config: AirdropConfig, client: SuiClient) => {
    let hasNextPage = true;
    let cursor = undefined;
    let coins = [];

    while (hasNextPage) {
        const data = await client.getAllCoins({
            owner: config.massMintingAddress,
            cursor,
            limit: 50
        });
        // save coins in a consumable way.
        coins.push(...data.data.map(coin => ({
            objectId: coin.coinObjectId,
            version: coin.version,
            digest: coin.digest
        })));

        hasNextPage = data.hasNextPage;
        cursor = data.nextCursor
    }

    if (coins.length === 1) throw new Error("Only got a single coin!");

    let count = coins.length;
    const STEP = 50;

    while (count > 1) {
        // get the base gas coin from the provider
        const { data } = await client.getObject({
            id: config.baseCoinObjectId
        });

        if (!data) throw new Error("failed to find `main` gas object.");
        // repeat a process of squashing.
        const tx = new TransactionBlock();
        // get the 50 items.
        let mergeAbleCoins = coins.splice(0, STEP);

        // make sure we don't try to merge the main coin.
        mergeAbleCoins = mergeAbleCoins.filter(x => x.objectId !== config.baseCoinObjectId);

        if(mergeAbleCoins.length < 2) break;
        console.log(mergeAbleCoins[0])
        // pay gas with the 0 coin.
        tx.setGasPayment([mergeAbleCoins[0]]);

        tx.mergeCoins(tx.objectRef({
            objectId: data.objectId,
            version: data.version,
            digest: data.digest
        }), [
            ...mergeAbleCoins.slice(1).map(x => 
                tx.objectRef({
                    objectId: x.objectId,
                    version: x.version,
                    digest: x.digest
                }))
        ]);

        const res = await executeTx(signer, tx, client);
        if(res) count = count - mergeAbleCoins.length -1;
    }
}
