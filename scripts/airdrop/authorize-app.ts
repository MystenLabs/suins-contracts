import { TransactionBlock } from "@mysten/sui.js/transactions";
import { executeTx, prepareSigner } from "./helper";
import { addressConfig, mainnetConfig } from "../config/day_one";
import { Network, mainPackage } from "../config/constants";

export const authorizeBogoApp = async (network: Network): Promise<TransactionBlock | void> => {

    const suinsPackageConfig = mainPackage[network];
    const airdropConfig = network === 'mainnet' ? mainnetConfig : addressConfig;
    const tx = new TransactionBlock();

    tx.moveCall({
        target: `${suinsPackageConfig.packageId}::suins::authorize_app`,
        arguments: [
          tx.object(suinsPackageConfig.adminCap),
          tx.object(suinsPackageConfig.suins),
        ],
        typeArguments: [`${airdropConfig.packageId}::bogo::BogoApp`],
    });
    
    // return if we're on multisig execution.
    if(airdropConfig.isMainnet) return tx;

    await executeTx(prepareSigner(), tx, mainPackage[network].client);
}


/* 
    uncomment any of these when running locally.
 */

// authorizeBogoApp('mainnet');
