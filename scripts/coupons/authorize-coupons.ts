import { TransactionBlock } from "@mysten/sui.js";
import { Network, mainPackage } from "../config/constants";
import { executeTx, prepareSigner } from "../airdrop/helper";

export const authorizeCouponsApp = async (network: Network): Promise<TransactionBlock | void> => {

    const config = mainPackage[network];
    const txb = new TransactionBlock();

    txb.moveCall({
        target: `${config.packageId}::suins::authorize_app`,
        arguments: [
          txb.object(config.adminCap),
          txb.object(config.suins),
        ],
        typeArguments: [`${config.coupons.packageId}::coupons::CouponsApp`],
    });
}
