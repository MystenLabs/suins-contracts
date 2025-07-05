import { SuiClient, type SuiTransactionBlockResponse } from "@mysten/sui/client";
import { decodeSuiPrivateKey, type Keypair } from "@mysten/sui/cryptography";
import { Ed25519Keypair } from "@mysten/sui/keypairs/ed25519";
import { Secp256k1Keypair } from "@mysten/sui/keypairs/secp256k1";
import { Secp256r1Keypair } from "@mysten/sui/keypairs/secp256r1";
import type { Transaction } from "@mysten/sui/transactions";
import { cnf } from "./config.js";
import { SuiPriceServiceConnection, SuiPythClient } from "./pyth/pyth.js";

// === sui ===

/** Get a new mainnet client. */
export function newSuiClient(): SuiClient {
    return new SuiClient({
        url: "https://suins-rpc.mainnet.sui.io:443",
    });
}

export function getSigner(): Keypair {
    if (!process.env.PRIVATE_KEY) {
        throw new Error("PRIVATE_KEY environment variable is not set");
    }
    return pairFromSecretKey(process.env.PRIVATE_KEY);
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
    const signer = getSigner();
    tx.setSender(signer.toSuiAddress());

    const suiClient = newSuiClient();

    if (dryRun) {
        const result = await suiClient.devInspectTransactionBlock({
            sender: signer.toSuiAddress(),
            transactionBlock: tx,
        });
        if (result.effects.status.status !== "success") {
            throw new Error(
                `devInspect failed: ${result.effects.status.error}`,
            );
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
            pollInterval: 200,
        });
    }

    return resp;
}

/**
 * Build a `Keypair` from a secret key string like `suiprivkey1...`.
 */
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

/**
 * Abbreviate a Sui address for display purposes (lossy). Default format is '0x1234…5678',
 * given an address like '0x1234000000000000000000000000000000000000000000000000000000005678'.
 */
export function shortenAddress(
    text: string | null | undefined,
    start = 4,
    end = 4,
    separator = "…",
    prefix = "0x",
): string {
    if (!text) return "";

    const addressRegex = /\b0[xX][0-9a-fA-F]{1,64}\b/g;

    return text.replace(addressRegex, (match) => {
        // check if the address is too short to be abbreviated
        if (match.length - prefix.length <= start + end) {
            return match;
        }
        // otherwise, abbreviate the address
        return prefix + match.slice(2, 2 + start) + separator + match.slice(-end);
    });
}

export function logJson(obj: unknown) {
    console.log(JSON.stringify(obj, null, 2));
}

export function logTxResp(resp: SuiTransactionBlockResponse) {
    logJson({
        tx_status: resp.effects?.status.status,
        tx_digest: resp.digest,
    });
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
    // biome-ignore lint/style/noNonNullAssertion: does exist
    return objIds[0]!;
}
