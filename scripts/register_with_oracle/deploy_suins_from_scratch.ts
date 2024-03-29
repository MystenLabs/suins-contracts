import { SuiClient } from "@mysten/sui.js/client";
import { execSync } from "child_process";
import { TransactionBlock } from "@mysten/sui.js/transactions";
import dotenv from "dotenv";
import { prepareSigner } from "../airdrop/helper";
dotenv.config({ path: `.env.local`, override: true });

const config = {
    packageId: process.env.PACKAGE_ADDRESS!,
    suins: process.env.SUINS!,
    adminCap: process.env.ADMIN_CAP_ID!,
    adminAddress: process.env.ADMIN_ADDRESS!,
    publisherId: process.env.PUBLISHER_ID!,
}

const client = new SuiClient({
    url: "https://mysten-rpc.testnet.sui.io:443"
});

const getActiveAddress = () => {
    return execSync(`sui client active-address`, { encoding: 'utf8' }).trim();
}

const setupMainContract = async () => {
    const signer = prepareSigner();
    const txb = new TransactionBlock();
    const configuration = txb.moveCall({
        target: `${config.packageId}::config::new`,
        arguments: [
            txb.pure([...Array(33).keys()]),
            txb.pure(0),
            txb.pure(0),
            txb.pure(0),
        ],
    });
    txb.moveCall({
        target: `${config.packageId}::suins::add_config`,
        arguments: [
            txb.object(config.adminCap),
            txb.object(config.suins),
            configuration,
        ],
        typeArguments: [`${config.packageId}::config::Config`],
    });
}

const publish = async () => {
    const txb = new TransactionBlock();
    

}

const run = async () => {
    console.log(getActiveAddress());
}

run();