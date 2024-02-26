import { SuiClient } from "@mysten/sui.js/dist/cjs/client";
import { Constants, Network, SuinsClientConfig, SuinsPriceList } from "./types";
import { MAINNET_CONFIG, TESTNET_CONFIG } from "./constants";

/// The SuinsClient is the main entry point for the Suins SDK.
/// It allows you to interact with SuiNS.
export class SuinsClient {
    #client: SuiClient;
    constants: Constants = {};

    constructor(config: SuinsClientConfig) {
        this.#client = config.client;
        if (config.network) {
            if (config.network === 'mainnet') {
                this.constants = MAINNET_CONFIG;
            }
            if (config.network === 'testnet') {
                this.constants = TESTNET_CONFIG;
            }
        }

        if (config.packageIds) {
            this.constants = {...(this.constants || {}), ...config.packageIds};
        }
    }

    /**
     * Returns the price list for SuiNS names.
     */
    async getPriceList(): Promise<SuinsPriceList> {
        if (!this.constants.suinsObjectId) throw new Error('Suins object ID is not set');
        if (!this.constants.getConfig || !this.constants.priceListConfigType) throw new Error('Price list config not found');

        const priceList = await this.#client.getDynamicFieldObject({
            parentId: this.constants.suinsObjectId,
            name: {
                type: this.constants.getConfig(this.constants.priceListConfigType),
                value: { dummy_field: false }
            }
        });

        if (!priceList || !priceList.data || !priceList.data.content
            || priceList.data.content.dataType !== 'moveObject'
            || !('value' in priceList.data.content.fields)
            ) throw new Error("Price list not found");

        const contents = priceList.data.content.fields.value as Record<string, any>;

        return {
            threeLetters: +(contents?.fields?.three_char_price),
            fourLetters: +(contents?.fields?.four_char_price),
            fivePlusLetters: +(contents?.fields?.five_plus_char_price)
        }
    }

    async calculateRegistrationPrice() {
        // todo: calculate the registration price
    }

    async calculateRenewalPrice() {
        // todo: calculate the renewal price
    }
}
