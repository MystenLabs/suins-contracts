// TESTNET VERSION HERE. WILL CLEAN UP.
import { SuiObjectData, SuiObjectRef, SuiTransactionBlockResponse, TransactionBlock, getExecutionStatusType } from "@mysten/sui.js";

import { MAX_MINTS_PER_TRANSACTION, addressesToBuffer, csvToBatches, executeTx, readAddressesFromFile }
    from './helper';
import { prepareSigner } from "./helper";
import { addressConfig } from "../config/day_one";
import { mainPackage } from "../config/constants";

const SUI_COIN_TYPE = '0x2::coin::Coin<0x2::sui::SUI>';

const network = 'testnet' // change to mainnet when running it.

const signer = prepareSigner(mainPackage[network].provider);

const config = addressConfig;
const usedCoinObjects = new Set();

const millisToMinutesAndSeconds = (millis: number) => {
    var minutes = Math.floor(millis / 60000);
    var seconds = +((millis % 60000) / 1000).toFixed(0);
    return minutes + ":" + (seconds < 10 ? '0' : '') + seconds;
}

/* get X amount of chunks of Coins based on amount per tx. */
const prepareCoinObjects = async (chunks: number) => {
    const tx = new TransactionBlock();

    // get the base gas coin from the provider
    const { data } = await signer.provider.getObject({
        id: config.baseCoinObjectId
    });

    if (!data) return false;

    // set is to be the gas payment.
    // Doing this manually to verify we don't get any locks.
    // Had a run that locked an object, and I am terrified we might face a base-coin lock.
    tx.setGasPayment([data]);

    const coinsSplitted = [];

    for (let i = 0; i < chunks; i++) {
        const coin = tx.splitCoins(
            tx.gas,
            [tx.pure(3_100_000_000, 'u64')]
        );
        coinsSplitted.push(coin);
    }

    tx.transferObjects(coinsSplitted, tx.pure(config.massMintingAddress, 'address'));
    const res = await executeTx(signer, tx);

    //@ts-ignore
    return res?.objectChanges?.filter(x => x.type === 'created' && x.objectType === SUI_COIN_TYPE).map((x: SuiObjectData) => (
        {
            objectId: x.objectId,
            version: x.version,
            digest: x.digest
        }
    ));
}

/** 
 * Mints a batch of bullsharks. 
 * */
const mintDayOne = async ({
    id,
    batch,
    coinObject,
    failedChunks
}: { id: number, batch: string[], coinObject: SuiObjectRef, failedChunks: number[] }) => {

    // add a small check to verify we don't use the same coin object twice at any chance.
    // to prevent equivocation.
    if (usedCoinObjects.has(coinObject.objectId)) {
        failedChunks.push(id);
        console.log(`Failure of chunk: ${id}`);
        return false;
    }
    usedCoinObjects.add(coinObject.objectId);

    const tx = new TransactionBlock();

    const buffer = addressesToBuffer(tx, batch, config);

    tx.moveCall({
        target: `${config.packageId}::day_one::mint`,
        arguments: [
            tx.sharedObjectRef(config.dropListObj),
            buffer,
        ]
    });

    // attach the coin for the execution.
    tx.setGasPayment([coinObject]);
    tx.setGasBudget(2_900_000_000);


    let res = await executeTx(signer, tx, {
        isAirdropExecution: true,
        chunkNum: id,
        failedChunks
    });
    //@ts-ignore
    return getExecutionStatusType(res as SuiTransactionBlockResponse) === 'success';
}

const executeMintsForBatches = async (batches: string[][], initialBatch = 0) => {

    const MAX_BATCH_SIZE = 50; //  The current airdrop is doable in 48 hashes. 50 batches will be running concurrently.
    let start = Date.now(); // time we started the mint process.

    let currentSliceStart = initialBatch;
    let success = 0;
    let fail = 0;
    const failedChunks: number[] = [];

    while (currentSliceStart < batches.length) {
        const batchToExecute = batches.slice(currentSliceStart, currentSliceStart + MAX_BATCH_SIZE);

        const results = await executeConcurrently(
            batchToExecute,
            {
                sliceStart: currentSliceStart,
                failedChunks,
            }
        );

        // something went wrong, let's move to the next chunks.
        if (!results) {
            if (!failedChunks.includes(currentSliceStart)) {
                failedChunks.push(currentSliceStart);
            }
            fail += MAX_BATCH_SIZE;
            currentSliceStart += MAX_BATCH_SIZE;
            continue;
        };

        success += results.filter(x => !!x).length;
        fail += results.filter(x => !x).length;
        currentSliceStart += MAX_BATCH_SIZE;
    }

    let timeTaken = Date.now() - start;
    console.log(`Completed in ${millisToMinutesAndSeconds(timeTaken)}.`);
    console.log(`Successfully run ${success} batches, minting ${success * MAX_MINTS_PER_TRANSACTION} DayOne objects.`);
    console.log(failedChunks);
    console.log(`Failed to execute ${failedChunks.length} or ${failedChunks.length * MAX_MINTS_PER_TRANSACTION} mints.`)

}


const executeConcurrently = async (slicedBatches: string[][], options: {
    sliceStart: number;
    failedChunks: number[];
}) => {

    const coins = await prepareCoinObjects(slicedBatches.length + 1); // does the splitting of coins with some extra space.

    if (!coins) {
        console.error("Failed to prepare coins on slice: " + options.sliceStart);
        return false;
    }

    return await Promise.all(
        slicedBatches.map((slice, index) =>
            mintDayOne({
                id: options.sliceStart + index,
                batch: slice,
                coinObject: coins[index],
                failedChunks: options.failedChunks
            })
        ));
}

// Run this in the end or if we have any split issues. 
// It will start merging the coins.
/* Should uncomment this when executing. */
// executeMintsForBatches(generateRandomBatches());

const ADDRESSES_PATH = '../tx/mainnet_airdrop.txt';
const mainnetAirdropAddresses = csvToBatches(readAddressesFromFile(ADDRESSES_PATH));


// THE TRIGGER. RUN export PRIVATE_KEY beforehand.
// executeMintsForBatches(mainnetAirdropAddresses);

// executeMintsForBatches()
// cleanUpCoins();
