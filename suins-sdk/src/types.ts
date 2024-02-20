import { TransactionObjectArgument } from "@mysten/sui.js/dist/cjs/builder";
import { SuiClient } from "@mysten/sui.js/dist/cjs/client";


/** You can pass in a TransactionArgument OR an objectId by string. */
export type ObjectArgument = string | TransactionObjectArgument;

export enum Network {
    Mainnet = 'mainnet',
    Testnet = 'testnet',
    Custom = 'custom'
}

// A list of constants
export type Constants = {
    suinsObjectId?: string;
    suinsPackageId?: string;
    utilsPackageId?: string;
    registrationPackageId?: string;
    renewalPackageId?: string;
    subdomainsPackageId?: string;
    tempSubdomainsProxyPackageId?: string;
}

// The config for the SuinsClient.
export type SuinsClientConfig = {
    client: SuiClient;
    // we can optionally pass in the network or the default packageIds
    network?: Network;
    packageIds?: Constants;
}
