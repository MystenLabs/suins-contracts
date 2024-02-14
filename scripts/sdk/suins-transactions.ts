import { SUI_CLOCK_OBJECT_ID, TransactionBlock } from "@mysten/sui.js";
import { PackageInfo } from "../config/constants";

export class SuinsTransaction {
    #config: PackageInfo;
    transactionBlock: TransactionBlock;

    // TODO: Add a dynamic method for fetching the price list.
    priceList: Record<string | number, string> = {
        3: '10000000000',
        4: '5000000000',
        default: '1000000000'
    }

    constructor(config: PackageInfo, transactionBlock: TransactionBlock) {
        this.#config = config;
        this.transactionBlock = transactionBlock;
    }

    /**
     * Register...
     * TBD: We need to:
     * - Support registration using a coupon
     * - Support registration using a discount (by presenting an object)
     * - Support resellers
     */
    register(name: String, years: number) {
        this.#validateYears(years);

    }

    /**
     * Constructs the transaction to renew a name.
     * Expects the nftId and the number of years to renew for.
     *      suins: &mut SuiNS,
        nft: &mut SuinsRegistration,
        no_years: u8,
        payment: Coin<SUI>,
        clock: &Clock
     */
    renew(nftId: string, length: number,  years: number) {
        this.#validateYears(years);

        const price = 'length' in this.priceList ? this.priceList[length] : this.priceList.default;

        this.transactionBlock.moveCall({
            target: `${this.#config.renewalsPackageId}::renew::renew`,
            arguments: [
                this.transactionBlock.object(this.#config.suins),
                this.transactionBlock.object(nftId),
                this.transactionBlock.pure(years),
                this.transactionBlock.splitCoins(this.transactionBlock.gas, [this.transactionBlock.pure(
                    price
                )]),
                this.transactionBlock.object(SUI_CLOCK_OBJECT_ID),
            ],
        })
    }

    #validateYears(years: number) {
        if (!(years > 0 && years < 6)) throw new Error("Years must be between 1 and 5");
    }
}
