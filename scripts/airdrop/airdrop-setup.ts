import { TransactionBlock } from "@mysten/sui.js/src/transactions";
import { batchToHash, executeTx, prepareSigner } from "./helper";
import { addressConfig, mainnetConfig } from "../config/day_one";
import { createDayOneDisplay, createDayOneTransferPolicy } from "../day_one/setup";
import { Network, mainPackage } from "../config/constants";

export const setupAirdrop = async (batches: string[][], network: Network): Promise<TransactionBlock | void> => {

    const suinsPackageConfig = mainPackage[network];
    const airdropConfig = network === 'mainnet' ? mainnetConfig : addressConfig;

    const hashes = [];

    if(batches.length > 1000) 
        throw new Error("This need to run in more than 2 runs. Pleas re-design the script :)");

    for (let batch of batches) hashes.push(batchToHash(batch));

    console.log("Total hashes generated: " + hashes.length);

    // hashes are done, now to setup. We can only do 16KB at a time per argument,
    // that means that a single vector of addresses (each address is 32 bytes)
    // can't be longer than 512 bytes.
    const tx = new TransactionBlock();

    tx.moveCall({
        target: `${airdropConfig.packageId}::day_one::setup`,
        arguments: [
            tx.sharedObjectRef(airdropConfig.dropListObj),
            tx.object(airdropConfig.setupCap),
            tx.pure(hashes, 'vector<address>')
        ]
    });

    // add the DayOne Display.
    createDayOneDisplay(tx, network);
    // attach TransferPolicy to make it tradeable.
    await createDayOneTransferPolicy(tx, network);
    
    // return if we're on multisig execution.
    if(airdropConfig.isMainnet) return tx;

    const signer = prepareSigner(mainPackage[network].client);
    await executeTx(signer, tx);
}


/* 
    uncomment any of these when running locally.
 */

// setupAirdrop(generateRandomBatches(), addressConfig);
