import { SuiClient, type SuiTransactionBlockResponse, type SuiTransactionBlockResponseOptions } from "@mysten/sui/client";
import { type Transaction } from "@mysten/sui/transactions";
import { decodeSuiPrivateKey, Keypair } from "@mysten/sui/cryptography";
import { Ed25519Keypair } from "@mysten/sui/keypairs/ed25519";
import { Secp256k1Keypair } from "@mysten/sui/keypairs/secp256k1";
import { Secp256r1Keypair } from "@mysten/sui/keypairs/secp256r1";

/** Get a new mainnet client. */
export function newSuiClient(): SuiClient {
    return new SuiClient({
        url: "https://suins-rpc.mainnet.sui.io:443",
    });
}

/** Remove the `0x` prefix from a Sui address / object ID. */
export function remove0x(address: string): string {
    return address.startsWith("0x") ? address.slice(2) : address;
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
