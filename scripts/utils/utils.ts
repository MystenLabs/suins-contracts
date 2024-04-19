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

/// Executes a `sui move build --dump-bytecode-as-base64` for the specified path.
export const getUpgradeDigest = (path_name: string) => {
    return JSON.parse(
        execSync(
            `${SUI} move build --dump-bytecode-as-base64 --path ${path_name}`,
            { encoding: 'utf-8'},
        ),
    );
}

/// Get the client for the specified network.
export const getClient = (network: Network) => {
    return new SuiClient({ url: getFullnodeUrl(network) });
}

/// Construct a VecSet of addresses.
export const prepareAddressVecSet = (txb: TransactionBlock, voters: string[]): TransactionArgument => {
    const vecSet = txb.moveCall({
        target: `0x2::vec_set::empty`,
        typeArguments: ['address']
    });

    for(let voter of voters) {
        txb.moveCall({
            target: `0x2::vec_set::insert`,
            arguments: [
                vecSet,
                txb.pure.address(voter)
            ],
            typeArguments: ['address']
        });
    }

    return vecSet;
}

/// Construct a VecMap of (string, vector<u8>) key-value pairs.
export const prepareMetadataVecMap = (txb: TransactionBlock, metadata: { [key: string]: string }): TransactionArgument => {
    const vecMap = txb.moveCall({
        target: `0x2::vec_map::empty`,
        typeArguments: ['0x1::string::String', '0x1::string::String']
    });

    Object.entries(metadata).forEach(([key, value]) => {
        txb.moveCall({
            target: `0x2::vec_map::insert`,
            arguments: [
                vecMap,
                txb.pure.string(key),
                txb.pure.string(value),
            ],
            typeArguments: ['0x1::string::String', '0x1::string::String']
        });
    });
    return vecMap;
}

/// A helper to sign & execute a transaction.
export const signAndExecute = async (txb: TransactionBlock, network: Network, options?: {
    isAirdropExecution: boolean,
    chunkNum: number,
    failedChunks: number[]
}) => {
    const client = getClient(network);
    const signer = getSigner();

    return client.signAndExecuteTransactionBlock({
        transactionBlock: txb,
        signer,
        options: {
            showEffects: true,
            showObjectChanges: true,
        }
    }).then(function(res) {
        if (options?.isAirdropExecution) {
            if (getExecutionStatus(res)?.status === 'success') console.log(`Success of chunk: ${options?.chunkNum}`);
            else {
                options.failedChunks.push(options?.chunkNum);
                console.log(`Failure of chunk: ${options?.chunkNum}`);
            }
        } else {
            console.dir(res)
            console.log(getExecutionStatus(res));
            console.log(getExecutionStatusGasSummary(res));
        }
    }).catch(e => {
        console.dir(e, { depth: null });
        if (!options) {
            console.log(e);
            return false;
        }
        options.failedChunks.push(options.chunkNum);
        console.log(e);
        console.log(`Failure of chunk: ${options?.chunkNum}`);
        return false;
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

function getExecutionStatus(res: SuiTransactionBlockResponse): ExecutionStatus | undefined {
    return res.effects?.status;
}

function getExecutionStatusGasSummary(res: SuiTransactionBlockResponse): GasCostSummary | undefined {
    return res.effects?.gasUsed;
}