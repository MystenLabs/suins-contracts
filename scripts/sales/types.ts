import fs from "fs";

export type Sale = {
    sender: string;
    day: number;
    month: number;
    year: number;
    nftId: string[];
    nameRecordIds: string[];
    txDigest: string;
}

export type ExtendedSale = Sale & {
    totalSui: number;
    labels: string[];
}


export const writeToFile = (name: string, data: object | string, isCsv?: boolean) => {
    fs.writeFileSync(`${__dirname}/data/${name}.${isCsv ? 'csv' : 'json'}`, typeof data === 'object' ? JSON.stringify(data) : data);
}
