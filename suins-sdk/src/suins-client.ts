import { SuiClient } from "@mysten/sui.js/client";
import { Constants, NameRecord, SuinsClientConfig, SuinsPriceList } from "./types";
import { MAINNET_CONFIG, TESTNET_CONFIG, getConfigType, getDomainType, getPricelistConfigType } from "./constants";
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
        if (!this.constants.suinsPackageV1) throw new Error('Price list config not found');

        const priceList = await this.#client.getDynamicFieldObject({
            parentId: this.constants.suinsObjectId,
            name: {
                type: getConfigType(this.constants.suinsPackageV1, getPricelistConfigType(this.constants.suinsPackageV1)),
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

    async getNameRecord(name: string): Promise<NameRecord> {
        validateName(name);
        if (!this.constants.suinsPackageV1) throw new Error('Suins package ID is not set');
        if (!this.constants.registryTableId) throw new Error('Registry table ID is not set');

        const nameRecord = await this.#client.getDynamicFieldObject({
            parentId: this.constants.registryTableId,
            name: {
                type: getDomainType(this.constants.suinsPackageV1),
                value: name.split('.').reverse()
            }
        });
        const fields = nameRecord.data?.content;

        if (nameRecord.error || !fields || fields.dataType !== 'moveObject') throw new Error('Name record not found. This domain is not registered.');
        const content = fields.fields as Record<string, any>;

        const data: Record<string, string> = {};
        content.value.fields.data.fields.contents.forEach((item: any) => {
            // @ts-ignore-next-line 
            data[item.fields.key as string] = item.fields.value;
        });

        return {
            name,
            nftId: content.value.fields?.nft_id,
            targetAddress: content.value.fields?.target_address!,
            data,
            avatarObjectId: data.avatar
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
