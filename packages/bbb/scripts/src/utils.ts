import { SuiClient, type SuiObjectRef, type SuiTransactionBlockResponse, type SuiTransactionBlockResponseOptions } from "@mysten/sui/client";
import { type Transaction, type TransactionObjectInput } from "@mysten/sui/transactions";
import { decodeSuiPrivateKey, Keypair } from "@mysten/sui/cryptography";
import { Ed25519Keypair } from "@mysten/sui/keypairs/ed25519";
import { Secp256k1Keypair } from "@mysten/sui/keypairs/secp256k1";
import { Secp256r1Keypair } from "@mysten/sui/keypairs/secp256r1";
import { SuiPriceServiceConnection, SuiPythClient } from "./pyth/pyth.js";
import { cnf } from "./config.js";

// === sui ===

/** Get a new mainnet client. */
export function newSuiClient(): SuiClient {
    return new SuiClient({
        url: "https://suins-rpc.mainnet.sui.io:443",
    });
}

/** Sign and execute a transaction using the `PRIVATE_KEY` environment variable. */
export async function signAndExecuteTx({
    tx,
    dryRun = true,
    waitForTx = false,
}: {
    tx: Transaction;
    dryRun?: boolean;
    waitForTx?: boolean;
}): Promise<SuiTransactionBlockResponse> {
    if (!process.env.PRIVATE_KEY) {
        throw new Error("PRIVATE_KEY environment variable is not set");
    }
    const signer = pairFromSecretKey(process.env.PRIVATE_KEY);
    tx.setSender(signer.toSuiAddress());

    const suiClient = newSuiClient();

    if (dryRun) {
        const result = await suiClient.devInspectTransactionBlock({
            sender: signer.toSuiAddress(),
            transactionBlock: tx,
        });
        if (result.effects?.status.status !== "success") {
            throw new Error("devInspect failed: " + JSON.stringify(result, null, 2));
        }
        return { digest: "", ...result };
    }

    const txBytes = await tx.build({ client: suiClient });
    const signedTx = await signer.signTransaction(txBytes)

    const resp = await suiClient.executeTransactionBlock({
      transactionBlock: signedTx.bytes,
      signature: signedTx.signature,
      options: {
        showEffects: true,
        showEvents: true,
      },
    });

    if (waitForTx) {
        await suiClient.waitForTransaction({
            digest: resp.digest,
            pollInterval: 200,
        });
    }

    return resp;
}

/**
 * Build a `Keypair` from a secret key string like `suiprivkey1...`.
 */
function pairFromSecretKey(secretKey: string): Keypair
{
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

/**
 * Either a `TransactionObjectInput` or a `SuiObjectRef`.
 */
export type ObjectInput = TransactionObjectInput | SuiObjectRef;

/**
 * Transform an `ObjectInput` into an argument for `Transaction.moveCall()`.
 */
export function objectArg(
    tx: Transaction,
    obj: ObjectInput,
) {
    return isSuiObjectRef(obj)
        ? tx.objectRef(obj)
        : tx.object(obj);
}

/** Type guard to check if an object is a `SuiObjectRef`. */
export function isSuiObjectRef(obj: unknown): obj is SuiObjectRef {
    return typeof obj === "object" && obj !== null
        && "objectId" in obj
        && "version" in obj
        && "digest" in obj;
}

export async function getPriceInfoObject(
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

// === misc ===

/** Remove the `0x` prefix from a Sui address / object ID. */
export function remove0x(address: string): string {
    return address.startsWith("0x") ? address.slice(2) : address;
}
