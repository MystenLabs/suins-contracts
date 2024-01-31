import { Connection, Ed25519Keypair, ExportedKeypair, JsonRpcProvider, ObjectId, RawSigner, SuiAddress, SuiTransactionBlockResponse, TransactionArgument, TransactionBlock, bcs, fromExportedKeypair, getExecutionStatus, getExecutionStatusGasSummary, getExecutionStatusType, isValidSuiAddress, normalizeSuiAddress, testnetConnection, toB64 }
    from "@mysten/sui.js";

import * as blake2 from 'blake2';
import fs from "fs";
import { AirdropConfig, addressConfig, mainnetConfig } from "../config/day_one";
import { Network, mainPackage } from "../config/constants";
import { execSync } from 'child_process';
import { fromHEX } from "@mysten/bcs";

export const MAX_MINTS_PER_TRANSACTION = 2_000;
export const TOTAL_RANDOM_ADDRESSES = 48 * MAX_MINTS_PER_TRANSACTION; // attempt with 95K.


/* executes the transaction */
export const executeTx = async (signer: RawSigner, tx: TransactionBlock, options?: {
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
    return signer
        .signAndExecuteTransactionBlock({
            transactionBlock: tx,
            options: requestOptions,
        })
        .then(function (res) {
            if (!(options?.isAirdropExecution)) {
                console.dir(res)
                console.log(getExecutionStatus(res));
                console.log(getExecutionStatusGasSummary(res));
            }

            if (options?.isAirdropExecution) {
                if (getExecutionStatus(res)?.status === 'success') console.log(`Success of chunk: ${options?.chunkNum}`);
                else {
                    options.failedChunks.push(options?.chunkNum);
                    console.log(`Failure of chunk: ${options?.chunkNum}`);
                }
            }

            return res;
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
        });
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

    return blake2
        .createHash('blake2b', { digestLength: 32 })
        .update(bytes)
        .digest('hex')
}


export const prepareSigner = (provider: JsonRpcProvider): RawSigner => {
    const phrase = process.env.ADMIN_PHRASE || '';
    if (!phrase) throw new Error(`ERROR: Admin mnemonic is not exported! Please run 'export ADMIN_PHRASE="<mnemonic>"'`);
    const keypair = Ed25519Keypair.deriveKeypair(phrase!);

    return new RawSigner(keypair, provider);
}

export const prepareSignerFromPrivateKey = (network: Network) => {
    const privateKey = process.env.PRIVATE_KEY || '';
    if (!privateKey) throw new Error(`ERROR: Private key not exported or exported wrong! Please run 'export PRIVATE_KEY="<mnemonic>"'`);
    const keyPair: ExportedKeypair = {
        schema: 'ED25519',
        privateKey: toB64(fromHEX(privateKey)),
    };

    const config = mainPackage[network];
    return new RawSigner(fromExportedKeypair(keyPair), config.provider);
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
    if(gasObjectId) await setupGasPayment(tx, gasObjectId, config.provider);

    // first do a dryRun, to make sure we are getting a success.
    const dryRun = await inspectTransaction(tx, config.provider, network);    

    if(!dryRun) throw new Error("This transaction failed.");

    tx.build({
        provider: config.provider
    }).then((bytes) => {
        let serializedBase64 = toB64(bytes);

        const output_location = process.env.NODE_ENV === 'development' ? './tx-data-local.txt' : '$PWD/tx/tx-data.txt';
        execSync(`echo ${serializedBase64} > ${output_location}`);
    });
}

/*
    Fetch the gas Object and setup the payment for the tx.
*/
const setupGasPayment = async (tx: TransactionBlock, gasObjectId: string, provider: JsonRpcProvider) => {
    const gasObject = await provider.getObject({
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
export const inspectTransaction = async (tx: TransactionBlock, provider: JsonRpcProvider, network: Network) => {

    const config = mainPackage[network];

    const result = await provider.dryRunTransactionBlock({
        transactionBlock: await tx.build({
            provider
        })
    });
    // log the result.
    console.dir(result, { depth: null }); 

    return getExecutionStatusType(result as SuiTransactionBlockResponse) === "success";
}
