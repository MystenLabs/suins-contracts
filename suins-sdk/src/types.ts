import { TransactionObjectArgument } from "@mysten/sui.js/dist/cjs/builder";
import { SuiClient } from "@mysten/sui.js/dist/cjs/client";


/** You can pass in a TransactionArgument OR an objectId by string. */
export type ObjectArgument = string | TransactionObjectArgument;

export type Network = 'mainnet' | 'testnet' | 'custom';

// A list of constants
export type Constants = {
    suinsObjectId?: string;
    utilsPackageId?: string;
    registrationPackageId?: string;
    renewalPackageId?: string;
    subNamesPackageId?: string;
    tempSubNamesProxyPackageId?: string;
    priceListConfigType?: string;
    getConfig?: (innerType: string) => string;
}

// The config for the SuinsClient.
export type SuinsClientConfig = {
    client: SuiClient;
    // we can optionally pass in the network or the default packageIds
    network?: Network;
    packageIds?: Constants;
}


/**
 * The price list for SuiNS names.
 */
export type SuinsPriceList = {
    threeLetters: number;
    fourLetters: number;
    fivePlusLetters: number;
}
