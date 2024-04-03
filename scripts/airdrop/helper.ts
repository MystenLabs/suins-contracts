import { TransactionArgument, TransactionBlock } from "@mysten/sui.js/transactions";
import { Ed25519Keypair } from '@mysten/sui.js/keypairs/ed25519';
import { blake2b } from '@noble/hashes/blake2b';
import fs from "fs";
import { AirdropConfig, addressConfig, mainnetConfig } from "../config/day_one";
import { Network, mainPackage } from "../config/constants";
import { isValidSuiAddress, normalizeSuiAddress, toB64 } from "@mysten/sui.js/utils";
import { ExecutionStatus, GasCostSummary, SuiClient, SuiTransactionBlockResponse } from "@mysten/sui.js/client";
import { bcs } from "@mysten/sui.js/bcs";
import dotenv from "dotenv";
dotenv.config();

export const MAX_MINTS_PER_TRANSACTION = 2_000;
export const TOTAL_RANDOM_ADDRESSES = 48 * MAX_MINTS_PER_TRANSACTION; // attempt with 95K.


/* executes the transaction */
export const executeTx = async (keypair: Ed25519Keypair, tx: TransactionBlock, client: SuiClient, options?: {
    isAirdropExecution: boolean,
    chunkNum: number,
    failedChunks: number[]
}) => {

    const requestOptions = options?.isAirdropExecution ? {
        showEffects: true
    } : {
        showObjectChanges: true,
        showEffects: true
    }

    return client.signAndExecuteTransactionBlock({
        transactionBlock: tx,
        signer: keypair,
        options: requestOptions
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
    }).catch (e => {
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


export const readAddressesFromFile = (fileNameWithPath: string = 'airdrop_addresses.txt'): string[] => {
    const addresses: string[] = [];
    const fileContent = fs.readFileSync(fileNameWithPath, 'utf-8');
    fileContent.split(/\r?\n/).forEach((address: string) => {
        if (isValidSuiAddress(address)) addresses.push(normalizeSuiAddress(address));
    });
    return addresses;
}

/** Reads a CSV list with addresses and splits it into batches */
export const csvToBatches = (
    csvAddressList: string[]
): string[][] => {

    // clean up any empty data.
    csvAddressList = csvAddressList.filter(x => !!x);

    // deduplicate here too, just to be on the safe side.
    const cleanList = [...new Set(csvAddressList)];

    let batches = [];

    for (let i = 0; i < cleanList.length; i += MAX_MINTS_PER_TRANSACTION) {
        const addresses: string[] = [];
        for (let j = 0; j < MAX_MINTS_PER_TRANSACTION; j++) {
            let address = cleanList[i + j];
            if (address) addresses.push(normalizeSuiAddress(address));
        }
        batches.push(addresses);
    }
    return batches;
}

/** Generates a list of random addresses for testing */
export const generateRandomBatches = (): string[][] => {
    let batches = [];
    let initialAddressNum = 500;
    for (let i = 0; i < TOTAL_RANDOM_ADDRESSES; i += MAX_MINTS_PER_TRANSACTION) {
        const addresses = [];
        for (let j = 0; j < MAX_MINTS_PER_TRANSACTION; j++) {
            addresses.push(normalizeSuiAddress('0x' + initialAddressNum++));
        }
        batches.push(addresses)
    }
    return batches;
}

export const serializeBatchToBytes = (batch: string[]) => {
    return bcs.ser(['vector', 'address'], batch, { size: (batch.length * 32) + 2 }).toBytes();
}

export const batchToHash = (batch: string[]) => {
    const bytes = Buffer.from(serializeBatchToBytes(batch));
    const digest = blake2b(bytes, { dkLen: 32});

    return Buffer.from(digest).toString('hex');
}

export const prepareSigner = (): Ed25519Keypair => {
    const phrase = process.env.ADMIN_PHRASE || '';
    if (!phrase) throw new Error(`ERROR: Admin mnemonic is not exported! Please run 'export ADMIN_PHRASE="<mnemonic>"'`);
    return Ed25519Keypair.deriveKeypair(phrase!);
}

// converts an array of addresses to a buffer using the `buffer` module.
export const addressesToBuffer = (tx: TransactionBlock, 
    batch: string[], config: AirdropConfig): TransactionArgument => {
    
    const buffer = tx.moveCall({
        target: `${config.bufferPackageId}::buffer::new`,
        typeArguments: [ 'address' ],
        arguments: [ tx.pure(batch.length, 'u64') ]
      });

      const MAX_STEP = 511;
      
      for(let i=0; i< batch.length; i += 511) {
        tx.moveCall({
            target: `${config.bufferPackageId}::buffer::append`,
            typeArguments: [ 'address' ],
            arguments: [ buffer, tx.pure(serializeBatchToBytes(batch.slice(i, i+MAX_STEP)) )]
          });
      }

      return tx.moveCall({
        target: `${config.bufferPackageId}::buffer::unwrap`,
        typeArguments: [ 'address' ],
        arguments: [ buffer ]
      });
}



/*
    Builds a transaction (unsigned) and saves it on `setup/tx/tx-data.txt` (on production)
    or `setup/src/tx-data.local.txt` on mainnet.
*/
export const prepareMultisigTx = async (
    tx: TransactionBlock,
    network: Network
) => {
    const config = mainPackage[network];
    const gasObjectId = process.env.GAS_OBJECT;

    // enabling the gas Object check only on mainnet, to allow testnet multisig tests.
    if(!gasObjectId) throw new Error("No gas object supplied for a mainnet transaction");

    // set the gas budget.
    tx.setGasBudget(2_000_000_000);

    // set the sender to be the admin address from config.
    tx.setSenderIfNotSet(config.adminAddress as string);

    // setting up gas object for the multi-sig transaction
    if(gasObjectId) await setupGasPayment(tx, gasObjectId, config.client);

    // first do a dryRun, to make sure we are getting a success.
    const dryRun = await inspectTransaction(tx, config.client, network);

    if(!dryRun) throw new Error("This transaction failed.");

    tx.build({
        client: config.client
    }).then((bytes) => {
        let serializedBase64 = toB64(bytes);

        const output_location = process.env.NODE_ENV === 'development' ? './tx/tx-data-local.txt' : './tx/tx-data.txt';

        fs.writeFileSync(output_location, serializedBase64);
    });
}

/*
    Fetch the gas Object and setup the payment for the tx.
*/
const setupGasPayment = async (tx: TransactionBlock, gasObjectId: string, client: SuiClient) => {
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

/*
    A helper to dev inspect a transaction.
*/
export const inspectTransaction = async (tx: TransactionBlock, client: SuiClient, network: Network) => {

    const config = mainPackage[network];
    const result = await client.dryRunTransactionBlock(
        {
            transactionBlock: await tx.build({client: config.client})
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
