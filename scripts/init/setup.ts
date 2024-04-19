import { TransactionBlock } from "@mysten/sui.js/transactions";
import { Network, Packages } from "./packages";
import { authorizeApp } from "../transactions/authorization";
import published from "../published.json";
import { signAndExecute } from "../utils/utils";

const setup = async (network: Network) => {
    const packages = Packages(network);

    const txb = new TransactionBlock();

    for(const pkg of Object.values(published)) {
        if ('authorizationType' in pkg) {
            authorizeApp({
                txb,
                adminCap: published.SuiNS.adminCap,
                suins: published.SuiNS.suins,
                type: pkg.authorizationType,
                suinsPackageIdV1: published.SuiNS.packageId
            });
        }
    }

    // call setup for any function needed.
    packages.Subdomains.setupFunction(txb, published.Subdomains.packageId, published.SuiNS.adminCap, published.SuiNS.suins);
    packages.DenyList.setupFunction(txb, published.DenyList.packageId, published.SuiNS.adminCap, published.SuiNS.suins);

    const res = await signAndExecute(txb, network).catch(e=>{
        console.dir(e, { depth: null })
    });
    console.dir(res, { depth: null });
}

setup('testnet');
