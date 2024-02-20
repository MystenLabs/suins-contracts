import { SuiClient } from "@mysten/sui.js/dist/cjs/client";
import { Constants, Network, SuinsClientConfig } from "./types";
import { MAINNET_CONFIG, TESTNET_CONFIG } from "./constants";

/// The SuinsClient is the main entry point for the Suins SDK.
/// It allows you to interact with SuiNS.
export class SuinsClient {
    #client: SuiClient;
    #network?: Network;
    constants: Constants;

    constructor(config: SuinsClientConfig) {
        this.#client = config.client;
        if (config.network) {
            if (config.network === Network.Mainnet) {
                this.constants = MAINNET_CONFIG;
            }
            if (config.network === Network.Testnet) {
                this.constants = TESTNET_CONFIG;
            }
            this.#network = config.network;
        }

        if (config.packageIds) {
            this.constants = {...(this.constants || {}), ...config.packageIds};
        }
    }

    async getPrices() {
        // todo: get the price list from the blockchain
    }

    async calculateRegistrationPrice() {
        // todo: calculate the registration price
    }

    async calculateRenewalPrice() {
        // todo: calculate the renewal price
    }
}
