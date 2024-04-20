import { TransactionBlock } from "@mysten/sui.js/transactions";
import { Network, Packages } from "./packages";
import { authorizeApp } from "./authorization";
import packageInfo from "../published.json";
import { signAndExecute } from "../utils/utils";
import { PackageInfo } from "./types";
import { MIST_PER_SUI } from "@mysten/sui.js/utils";

export const setup = async (packageInfo: PackageInfo, network: Network) => {
    const packages = Packages(network);

    const txb = new TransactionBlock();

    for(const pkg of Object.values(packageInfo)) {
        if ('authorizationType' in pkg && pkg.authorizationType) {
            authorizeApp({
                txb,
                adminCap: packageInfo.SuiNS.adminCap,
                suins: packageInfo.SuiNS.suins,
                type: pkg.authorizationType,
                suinsPackageIdV1: packageInfo.SuiNS.packageId
            });
        }
    }
    // Call setup functions for our packages.
    packages.Subdomains.setupFunction(txb, packageInfo.Subdomains.packageId, packageInfo.SuiNS.adminCap, packageInfo.SuiNS.suins);
    packages.DenyList.setupFunction(txb, packageInfo.DenyList.packageId, packageInfo.SuiNS.adminCap, packageInfo.SuiNS.suins);
    packages.SuiNS.setupFunction(txb, packageInfo.SuiNS.packageId, packageInfo.SuiNS.adminCap, packageInfo.SuiNS.suins, packageInfo.SuiNS.publisher);
    packages.Renewal.setupFunction({
            txb,
            adminCap: packageInfo.SuiNS.adminCap,
            suins: packageInfo.SuiNS.suins,
            packageId: packageInfo.Renewal.packageId,
            suinsPackageIdV1: packageInfo.SuiNS.packageId,
            priceList: {
                three: 2 * Number(MIST_PER_SUI),
                four: 1 * Number(MIST_PER_SUI),
                fivePlus: 0.2 * Number(MIST_PER_SUI)
            }
    });

    try{
        await signAndExecute(txb, network);
        console.log("******* Packages set up successfully *******");
    
    }catch(e) {
        console.error("Something went wrong!");
        console.dir(e, { depth: null })
    }
}
