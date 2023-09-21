import { TransactionBlock } from "@mysten/sui.js";
import { executeTx, prepareSigner } from "./helper";
import { addressConfig, mainnetConfig } from "../config/day_one";
import { Network, mainPackage } from "../config/constants";

export const deauthorizeBogoApp = async (network: Network): Promise<TransactionBlock | void> => {

    const suinsPackageConfig = mainPackage[network];
    const airdropConfig = network === 'mainnet' ? mainnetConfig : addressConfig;
    const tx = new TransactionBlock();

    tx.moveCall({
        target: `${suinsPackageConfig.packageId}::suins::deauthorize_app`,
        arguments: [
          tx.object(suinsPackageConfig.adminCap),
          tx.object(suinsPackageConfig.suins),
        ],
        typeArguments: [`${airdropConfig.packageId}::bogo::BogoApp`],
    });
    
    // return if we're on multisig execution.
    if(airdropConfig.isMainnet) return tx;

    const signer = prepareSigner(mainPackage[network].provider);
    await executeTx(signer, tx);
}


/* 
    uncomment any of these when running locally.
 */

// deauthorizeBogoApp('mainnet');