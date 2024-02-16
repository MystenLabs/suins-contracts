
import sales from "./data/direct-sales.json";
import suifrensDiscounts from "./data/suifrens-discounts.json";
import dayOneNFTDiscounts from "./data/day-one-nft-discounts.json";
import generalSaleObjects from "./data/general-sale-objects.json";
import { PackageInfo, mainPackage } from "../config/constants";
import { writeFileSync } from "fs";
import { ExtendedSale, Sale, writeToFile } from "./types";


const createBatches = (objectIds: string[], batchSize: number) => {
    const batches: string[][] = [];
    for (let i = 0; i < objectIds.length; i += batchSize) {
        batches.push(objectIds.slice(i, i + batchSize));
    }
    return batches;
}


// Parses name record objects and returns a map in the format of { objectId: domain }
const multiGetPaginatedObjects = async (packageInfo: PackageInfo, objectIds: string[]): Promise<Record<string, string>> => {
    const results: Record<string, string> = {};
    const batches = createBatches(objectIds, 50); // create batches of 50 (limit for multi_get);

    for(const batch of batches) {

        const data = await packageInfo.provider.multiGetObjects({
            ids: batch,
            options: {
                showContent: true
            }
        });
        data.forEach(x => {
            if (!x.data) throw new Error("unexpected");

            if(x.data.content?.dataType !== 'moveObject') throw new Error("invalid type");

            const content = x.data.content.fields;
            // console.log(content..fields);
            const domain = content.name.fields.labels.reverse().join('.');
            results[x.data.objectId] = domain;
        });
        console.log('processed batch');
    }
    return results;
}

const fetchAllNameRecords = async () => {

    const results = {
        ...await multiGetPaginatedObjects(mainPackage.mainnet, sales.aggregatedData.flatMap(x => x.nameRecordIds)),
        ...await multiGetPaginatedObjects(mainPackage.mainnet, suifrensDiscounts.aggregatedData.flatMap(x => x.nameRecordIds)),
        ...await multiGetPaginatedObjects(mainPackage.mainnet, dayOneNFTDiscounts.aggregatedData.flatMap(x => x.nameRecordIds))
    }

    writeToFile('general-sale-objects', results);
}

const saleToExtendedSale = (sale: Sale, isDiscount: boolean) => {
    // @ts-ignore-next-line
    const domainNames = sale.nameRecordIds.map(x => generalSaleObjects[x]);
    return {
        ...sale,
        labels: domainNames,
        totalSui: getDomainsPrice(domainNames, isDiscount),
    };

}
const analyzeSales = async () => {

    const extendedSales: ExtendedSale[] = [];

    sales.aggregatedData.forEach(sale => {
        extendedSales.push(saleToExtendedSale(sale, false));
    });

    suifrensDiscounts.aggregatedData.forEach(sale => {
        extendedSales.push(saleToExtendedSale(sale, true));
    });
    dayOneNFTDiscounts.aggregatedData.forEach(sale => {
        extendedSales.push(saleToExtendedSale(sale, true));
    });

    saveToCsv(extendedSales);

    // console.dir(extendedSales, { depth: null });
}

const getDomainsPrice = (domains: string[], isDiscount: boolean) => {
    let price = 0;
    // base prices.
    const prices = {
        3: 500,
        4: 100,
        else: 20
    }

    // discount prices with dayone + suifrens
    const discountPrices = {
        3: 450,
        4: 90,
        else: 10
    }

    for(const domain of domains) {
        const labels = domain.split('.');
        const sld = labels[labels.length - 2];
        const sldLength = sld.length === 3 ? 3 : sld.length === 4 ? 4 : 'else';

        price += isDiscount ? discountPrices[sldLength] : prices[sldLength];
    }

    return price;
}

function saveToCsv(sales: ExtendedSale[]) {
    const keys = Object.keys(sales[0]);

    // Create header row
    let csvContent = keys.join(';') + '\n';

    // Create data rows
    sales.forEach(item => {
        //@ts-ignore-next-line
        const values = keys.map(key => item[key]);
        csvContent += values.join(';') + '\n';
    });

    writeToFile('sales', csvContent, true);
}

analyzeSales();
