import { JsonRpcProvider, PaginatedTransactionResponse, TransactionFilter } from "@mysten/sui.js";
import { PackageInfo, mainPackage } from "../config/constants";
import fs from "fs";
import { Sale, writeToFile } from "./types";

const processRegularSales = (blocks: PaginatedTransactionResponse) => {
    const sales: Sale[] = [];

    for(const block of blocks.data){
        const date = new Date((+block.timestampMs!));
        sales.push({
            txDigest: block.digest,
            day: date.getDate(),
            month: date.getMonth() +1,
            year: date.getFullYear(),
            // @ts-ignore-next-line
            sender: block.objectChanges[0].sender,
            // @ts-ignore-next-line
            nftId: block.objectChanges?.filter(x => x.objectType.endsWith('::suins_registration::SuinsRegistration'))?.map(x => x.objectId),
            // @ts-ignore-next-line
            nameRecordIds: block.objectChanges?.filter(x => x.objectType.endsWith('::name_record::NameRecord>'))?.map(x => x.objectId)
        });
    }
    return sales;
}

const processDiscountSales = (blocks: PaginatedTransactionResponse) => {
    const sales: Sale[] = [];

    for(const block of blocks.data){
        const date = new Date((+block.timestampMs!));
        sales.push({
            txDigest: block.digest,
            day: date.getDate(),
            month: date.getMonth() +1,
            year: date.getFullYear(),
            // @ts-ignore-next-line
            sender: block.objectChanges[0].sender,
            // @ts-ignore-next-line
            nftId: block.objectChanges?.filter(x => x.objectType.endsWith('::suins_registration::SuinsRegistration'))?.map(x => x.objectId),
            // @ts-ignore-next-line
            nameRecordIds: block.objectChanges?.filter(x => x.objectType.endsWith('::name_record::NameRecord>'))?.map(x => x.objectId)
        });
    }
    return sales;
}


export const loopTransactionBlocks = async (
    provider: JsonRpcProvider,
    filter: TransactionFilter,
    processFunction: (blocks: PaginatedTransactionResponse) => any[],
) => {
    const aggregatedData = [];
    let totalPages = 0;

    let firstCursor = undefined;
    let hasNextPage = true;
    let cursor = undefined;

    while (hasNextPage) {
        const blocks = await provider.queryTransactionBlocks({
            filter,
            options: {
                showEffects: true,
                showInput: true,
                showObjectChanges: true,
                showBalanceChanges: true,
            },
            cursor
        });
        aggregatedData.push(...processFunction(blocks));
        hasNextPage = blocks.hasNextPage;
        cursor = blocks.nextCursor;

        if (totalPages === 0) firstCursor = cursor;
        console.log(`Processed page ${++totalPages}`);
    }

    return {
        aggregatedData,
        firstCursor,
        lastCursor: cursor
    }
}

export const execute = async () => {
    // const data = await loopTransactionBlocks(
    //     mainPackage.mainnet.provider,
    //     {
    //         MoveFunction: {
    //             package: mainPackage.mainnet.registrationPackageId,
    //             module: 'register',
    //             function: 'register'
    //         }
    //     },
    //     processRegularSales
    // );
    // writeToFile('direct-sales', data);

    const suifrensDiscountData = await loopTransactionBlocks(
        mainPackage.mainnet.provider,
        {
            MoveFunction: {
                package: mainPackage.mainnet.discountsPackage.packageId,
                module: 'discounts',
                function: 'register'
            }
        },
        processDiscountSales
    );
    writeToFile('suifrens-discounts', suifrensDiscountData);

    const dayOneNFTDiscountData = await loopTransactionBlocks(
        mainPackage.mainnet.provider,
        {
            MoveFunction: {
                package: mainPackage.mainnet.discountsPackage.packageId,
                module: 'discounts',
                function: 'register_with_day_one'
            }
        },
        processDiscountSales
    );
    writeToFile('day-one-nft-discounts', dayOneNFTDiscountData);
}

execute();
