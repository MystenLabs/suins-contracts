import { SuiObjectResponse, TransactionBlock, isValidSuiAddress } from "@mysten/sui.js";
import fs from "fs";
import { prepareMultisigTx } from "../airdrop/helper";

// A {name: address} map
const domains: Record<string, string> = {};
// A {recipient, uniqueObjectIds} map
const recipients: Record<string, Set<string>> = {};

type TransferObject = {
    name: string;
    address: string;
    domain: string;
    domainObjectId?: string;
}

type DomainData = {
    objectId: string;
    name: string;
}

// Reads the owned objects + formats them in a `name: objectId` format.
const parseOwnedObjects = () => {
    const ownedObjects = JSON.parse(fs.readFileSync('./reserved-names/owned-objects.json').toString()) as SuiObjectResponse[];

    const names: DomainData[] = ownedObjects.map(({ data }) => ({
        objectId: data?.objectId || '',
        //@ts-ignore-next-line
        name: data?.content!.fields!.domain_name || ''
    }));

    // Map the names as `name: address`.
    for(let name of names) {
        domains[name.name] = name.objectId
    }
}

// Parses the combined CSV 
const parseCsvFile = () => {

    fs.readFileSync('./reserved-names/data/transfers-v3.csv')
        .toString()
        .split('\n')
        .map(x => x.split(','))
        .filter(x => !!x && !!x[0])
        .map( ([domain, address]) => ({
            address,
            domain: domain.toLowerCase()
        } as TransferObject))
        .filter(x => {
            const isValid = isValidSuiAddress(x.address)
            if(!isValid) console.info(`Invalid address: ${x.address} | ${x.name} | ${x.domain}`)
            return isValid
        })
        .map(x => {
            x.domain = x.domain.endsWith('.sui') ? x.domain : `${x.domain}.sui`
            return x
        })
        .map(x => {
            if(!domains[x.domain]) console.info(`Couldn't find objectId for name ${x.domain}`);
            x.domainObjectId = domains[x.domain];
            return x;
            // lets find the objectId for that domain.
        }).forEach(recipient => {
            if(!recipients[recipient.address]) recipients[recipient.address] = new Set();
            recipients[recipient.address].add(recipient.domainObjectId!)
        });

    // recipients -> address -> [] objects it receives
    // console.log(recipients);
}

const prepareTx = () => {

    const txb = new TransactionBlock();

    for (let recipient of Object.keys(recipients)) {
        const objects = [...recipients[recipient]].filter(x => !!x);
        txb.transferObjects([...objects.map(x => txb.object(x))], txb.pure(recipient));
    }

    return prepareMultisigTx(txb, 'mainnet');
}

// parses all owned OBjects from `json` file. 
// If you want to refresh the owned data for the SuiNS admin, re-run `ts-node objects.ts`.
parseOwnedObjects();
// Parses the `transfers.csv` file, and creates the list of object transfers
parseCsvFile();

// Prepares the TXB for that and saves it in tx-data.
prepareTx();
