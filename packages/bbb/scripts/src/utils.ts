import { SuiClient, type SuiTransactionBlockResponse } from "@mysten/sui/client";
import { decodeSuiPrivateKey, type Keypair } from "@mysten/sui/cryptography";
import { Ed25519Keypair } from "@mysten/sui/keypairs/ed25519";
import { Secp256k1Keypair } from "@mysten/sui/keypairs/secp256k1";
import { Secp256r1Keypair } from "@mysten/sui/keypairs/secp256r1";
import type { Transaction } from "@mysten/sui/transactions";
import { cnf } from "./config.js";
import { SuiPriceServiceConnection, SuiPythClient } from "./pyth/pyth.js";

// === sui ===

/** Get a new mainnet client */
export function newSuiClient(): SuiClient {
    return new SuiClient({
        url: "https://suins-rpc.mainnet.sui.io:443",
    });
}

/** Sign and execute a transaction using the `PRIVATE_KEY` environment variable */
export async function signAndExecuteTx({
    tx,
    dryRun = true,
    waitForTx = false,
}: {
    tx: Transaction;
    dryRun?: boolean;
    waitForTx?: boolean;
}): Promise<SuiTransactionBlockResponse> {
    const signer = getSigner();
    tx.setSender(signer.toSuiAddress());

    const suiClient = newSuiClient();

    if (dryRun) {
        const result = await suiClient.devInspectTransactionBlock({
            sender: signer.toSuiAddress(),
            transactionBlock: tx,
        });
        if (result.effects.status.status !== "success") {
            throw new Error(`devInspect failed: ${result.effects.status.error}`);
        }
        return { digest: "", ...result };
    }

    const txBytes = await tx.build({ client: suiClient });
    const signedTx = await signer.signTransaction(txBytes);

    const resp = await suiClient.executeTransactionBlock({
        transactionBlock: signedTx.bytes,
        signature: signedTx.signature,
        options: {
            showEffects: true,
            showEvents: true,
            showObjectChanges: true,
        },
    });

    if (resp.effects?.status.status !== "success") {
        throw new Error(`transaction failed: ${resp.effects?.status.error}`);
    }

    if (waitForTx) {
        await suiClient.waitForTransaction({
            digest: resp.digest,
            pollInterval: 250,
        });
    }

    return resp;
}

/** Build a `Keypair` from the `PRIVATE_KEY` environment variable */
function getSigner(): Keypair {
    if (!process.env.PRIVATE_KEY) {
        throw new Error("PRIVATE_KEY environment variable is not set");
    }
    return pairFromSecretKey(process.env.PRIVATE_KEY);
}

/** Build a `Keypair` from a secret key string like `suiprivkey1...` */
function pairFromSecretKey(secretKey: string): Keypair {
    const pair = decodeSuiPrivateKey(secretKey);

    if (pair.scheme === "ED25519") {
        return Ed25519Keypair.fromSecretKey(pair.secretKey);
    }
    if (pair.scheme === "Secp256k1") {
        return Secp256k1Keypair.fromSecretKey(pair.secretKey);
    }
    if (pair.scheme === "Secp256r1") {
        return Secp256r1Keypair.fromSecretKey(pair.secretKey);
    }

    throw new Error(`Unrecognized keypair schema: ${pair.schema}`);
}

// === pyth ===

export async function getPriceInfoObject(tx: Transaction, feed: string): Promise<string> {
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
    const pythClient = new SuiPythClient(
        suiClient,
        cnf.pyth.stateObj,
        cnf.wormhole.stateObj,
    );

    const objIds = await pythClient.updatePriceFeeds(tx, priceUpdateData, priceIDs);
    return objIds[0]!;
}

// === logging ===

export function logJson(obj: unknown) {
    console.log(JSON.stringify(obj, null, 2));
}

export function logTxResp(resp: SuiTransactionBlockResponse) {
    logJson({
        tx_status: resp.effects?.status.status,
        tx_digest: resp.digest,
    });
}
