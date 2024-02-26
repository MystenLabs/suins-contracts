import { SuiClient } from "@mysten/sui.js/client";
import { Constants, SuinsClientConfig, SuinsPriceList } from "./types";
import { MAINNET_CONFIG, TESTNET_CONFIG } from "./constants";
import { isSubName, validateName, validateYears } from "./helpers";

/// The SuinsClient is the main entry point for the Suins SDK.
/// It allows you to interact with SuiNS.
export class SuinsClient {
    #client: SuiClient;
    constants: Constants = {};

    constructor(config: SuinsClientConfig) {
        this.#client = config.client;
        const network = config.network || 'mainnet';

        if (network === 'mainnet') {
            this.constants = MAINNET_CONFIG;
        }

        if (network === 'testnet') {
            this.constants = TESTNET_CONFIG;
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

    /**
     * Calculates the registration price for an SLD (Second Level Domain).
     * It expects a domain name, the number of years and a `SuinsPriceList` object,
     * as returned from `suinsClient.getPriceList()` function.
     * 
     * It throws an error:
     * 1. if the name is a subdomain
     * 2. if the name is not a valid SuiNS name
     * 3. if the years are not between 1 and 5
     */
    calculateRegistrationPrice({
        name,
        years,
        priceList
    }: {name: string, years: number, priceList: SuinsPriceList}) {
        validateName(name);
        validateYears(years);
        if (isSubName(name)) throw new Error('Subdomains do not have a registration fee');

        const length = name.split('.')[0].length;
        if (length === 3) return years * priceList.threeLetters;
        if (length === 4) return years * priceList.fourLetters;
        return years * priceList.fivePlusLetters;
    }

    /**
     * Calculate the renewal price for an SLD (Second Level Domain).
     * It expects a domain name, the number of years and a `SuinsPriceList` object,
     * as returned from `suinsClient.getPriceList()` function.
     * 
     * It throws an error:
     * 1. if the name is a subdomain
     * 2. if the name is not a valid SuiNS name
     * 3. if the years are not between 1 and 5
     * @param param0 
     * @returns 
     */
    calculateRenewalPrice({
        name,
        years,
        priceList
    }: {name: string, years: number, priceList: SuinsPriceList}) {
        validateName(name);
        validateYears(years);
        if (isSubName(name)) throw new Error('Subdomains do not have a registration fee');

        const length = name.split('.')[0].length;
        if (length === 3) return years * priceList.threeLetters;
        if (length === 4) return years * priceList.fourLetters;
        return years * priceList.fivePlusLetters;
    }
}
