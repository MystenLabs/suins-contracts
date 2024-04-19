import { readFileSync } from "fs";
import { homedir } from "os";
import path from "path";
import fs from "fs";

import { getFullnodeUrl, ExecutionStatus, GasCostSummary, SuiClient, SuiTransactionBlockResponse } from '@mysten/sui.js/client';
import { Ed25519Keypair } from '@mysten/sui.js/keypairs/ed25519';
import { TransactionArgument, TransactionBlock } from '@mysten/sui.js/transactions';
import { fromB64 } from '@mysten/sui.js/utils';
import { execSync } from "child_process";
import { toB64 } from "@mysten/sui.js/utils";

export type Network = 'mainnet' | 'testnet' | 'devnet' | 'localnet'

const SUI = `sui`;

export const getActiveAddress = () => {
    return execSync(`${SUI} client active-address`, { encoding: 'utf8' }).trim();
}

/// Returns a signer based on the active address of system's sui.
export const getSigner = () => {
    const sender = getActiveAddress();

    const keystore = JSON.parse(
        readFileSync(
            path.join(homedir(), '.sui', 'sui_config', 'sui.keystore'),
            'utf8',
        )
    );

    for (const priv of keystore) {
        const raw = fromB64(priv);
        if (raw[0] !== 0) {
            continue;
        }

        const pair = Ed25519Keypair.fromSecretKey(raw.slice(1));
        if (pair.getPublicKey().toSuiAddress() === sender) {
            return pair;
        }
    }

    throw new Error(`keypair not found for sender: ${sender}`);
}

/// Get the client for the specified network.
export const getClient = (network: Network) => {
    return new SuiClient({ url: getFullnodeUrl(network) });
}

/// A helper to sign & execute a transaction.
export const signAndExecute = async (txb: TransactionBlock, network: Network) => {
    const client = getClient(network);
    const signer = getSigner();

    return client.signAndExecuteTransactionBlock({
        transactionBlock: txb,
        signer,
        options: {
            showEffects: true,
            showObjectChanges: true,
        }
    })
}

/// Builds a transaction (unsigned) and saves it on `setup/tx/tx-data.txt` (on production)
/// or `setup/src/tx-data.local.txt` on mainnet.
export const prepareMultisigTx = async (
    tx: TransactionBlock,
    network: Network
) => {
    const adminAddress = getActiveAddress();
    const client = getClient(network);
    const gasObjectId = process.env.GAS_OBJECT;

    // enabling the gas Object check only on mainnet, to allow testnet multisig tests.
    if(!gasObjectId) throw new Error("No gas object supplied for a mainnet transaction");

    // set the gas budget.
    tx.setGasBudget(2_000_000_000);

    // set the sender to be the admin address from config.
    tx.setSenderIfNotSet(adminAddress as string);

    // setting up gas object for the multi-sig transaction
    if(gasObjectId) await setupGasPayment(tx, gasObjectId, client);

    // first do a dryRun, to make sure we are getting a success.
    const dryRun = await inspectTransaction(tx, client);

    if(!dryRun) throw new Error("This transaction failed.");

    tx.build({
        client: client
    }).then((bytes) => {
        let serializedBase64 = toB64(bytes);

        const output_location = process.env.NODE_ENV === 'development' ? './tx/tx-data-local.txt' : './tx/tx-data.txt';

        fs.writeFileSync(output_location, serializedBase64);
    });
}

/// Fetch the gas Object and setup the payment for the tx.
async function setupGasPayment(tx: TransactionBlock, gasObjectId: string, client: SuiClient) {
    const gasObject = await client.getObject({
        id: gasObjectId
    });

    if(!gasObject.data) throw new Error("Invalid Gas Object supplied.");

    // set the gas payment.
    tx.setGasPayment([{
        objectId: gasObject.data.objectId,
        version: gasObject.data.version,
        digest: gasObject.data.digest
    }])
}

/// A helper to dev inspect a transaction.
async function inspectTransaction(tx: TransactionBlock, client: SuiClient) {
    const result = await client.dryRunTransactionBlock(
        {
            transactionBlock: await tx.build({client: client})
        }
    );
    // log the result.
    console.dir(result, { depth: null }); 

    return result.effects.status.status === 'success'
}