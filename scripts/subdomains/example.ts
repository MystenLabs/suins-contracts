import { SUI_CLOCK_OBJECT_ID, TransactionBlock, normalizeSuiAddress } from "@mysten/sui.js"
import { PackageInfo, mainPackage } from "../config/constants";
import { executeTx, prepareSignerFromPrivateKey } from "../airdrop/helper";

// `manos.sui` base object
export const MANOS_SUI_OBJECT_ID = `0x8af1c43c1ffe0350796d78f80d1963d3c3bf70664f64b06ed92e8bf5ccf91df5`;

// a function to create a subdomain
export const createNodeSubdomain = async (name: String, parent: string, isSubDomainParent: boolean) => {

    const txb = new TransactionBlock();

    const config = mainPackage.testnet;

    const signer = prepareSignerFromPrivateKey('testnet');

    // create a node subdomain
    let node = txb.moveCall({
        target: isSubDomainParent ? `${config.tempSubdomainProxyPackageId}::subdomain_proxy::create_subdomain` : `${config.subdomainsPackageId}::subdomains::create`,
        arguments: [
            txb.object(config.suins), // SuiNS object
            txb.object(parent), // parent name's object ID
            txb.object(SUI_CLOCK_OBJECT_ID), // Clock
            txb.pure(name, 'string'), // Subdomain `(e.g. example.manos.sui)
            txb.pure(1716669320691), // expiration of subdomain. Must be <= parent's.
            txb.pure(false), // allow creating children?
            txb.pure(false), // allow extending time on its own? (if parent renews or expiration is less than parent's expiration?)
        ]
    });

    txb.moveCall({
        target: `${config.tempSubdomainProxyPackageId}::subdomain_proxy::set_target_address`,
        arguments: [
            txb.object(config.suins),
            node,
            txb.pure(await signer.getAddress(), 'address'),
            txb.object(SUI_CLOCK_OBJECT_ID),
        ],
    });

    txb.transferObjects([node], txb.pure(await signer.getAddress()));

    await executeTx(signer, txb);
}


export const createLeafSubdomainTx = (txb: TransactionBlock, name: string, parent: string, config: PackageInfo, isSubDomainParent: boolean) => {
   // create a leaf subdomain
   txb.moveCall({
    target: isSubDomainParent ? `${config.tempSubdomainProxyPackageId}::subdomain_proxy::create_leaf` : `${config.subdomainsPackageId}::subdomains::create_leaf`,
    arguments: [
        txb.object(config.suins), // suins Object
        txb.object(parent), // parent object id
        txb.object(SUI_CLOCK_OBJECT_ID), // clock
        txb.pure(name, 'string'), // subdomain name (eg `example.manos.sui`)
        txb.pure(normalizeSuiAddress('0x2'), 'address') // target address (where does this leaf subdomain point to?)
    ]
});

}

export const createLeafSubdomain = async (name: string, parent: string) => {
    const txb = new TransactionBlock();

    const config = mainPackage.testnet;
    const signer = prepareSignerFromPrivateKey('testnet');

    createLeafSubdomainTx(txb, name, parent, config, false);
 
    await executeTx(signer, txb);
}

export const removeLeafSubdomain = async (name: string, parent: string, isSubDomainParent: boolean) => {
    const txb = new TransactionBlock();

    const config = mainPackage.testnet;

    const signer = prepareSignerFromPrivateKey('testnet');

    // create a leaf subdomain
    txb.moveCall({
        target: isSubDomainParent ? `${config.tempSubdomainProxyPackageId}::subdomain_proxy::remove_leaf` : `${config.subdomainsPackageId}::subdomains::remove_leaf`,
        arguments: [
            txb.object(config.suins),
            txb.object(parent),
            txb.object(SUI_CLOCK_OBJECT_ID),
            txb.pure(name, 'string'),
        ]
    });

    await executeTx(signer, txb);
}

export const queryNameRecord = async (name: String) => {

    const config = mainPackage.testnet;

    const res = await config.provider.getDynamicFieldObject({
        parentId: `0x79e2d4d1f6a07a3da4fde61592ebd28d13a5b12e4f7928972610ac70b1476f71`,
        name: {
            value: name.split('.').reverse(),
            type: `${config.packageId}::domain::Domain`,
        },
    });

    console.dir(res, { depth: null });
}

const prepareManyNamesForTesting = async (startInt=0) => {

    const config = mainPackage.testnet;
    const signer = prepareSignerFromPrivateKey('testnet');
    const txb = new TransactionBlock();

    for(let i = startInt;i<startInt + 900; i++){
        const name = `leaf${i}.manos.sui`;
        createLeafSubdomainTx(txb, name, MANOS_SUI_OBJECT_ID, config, false);
    }

    await executeTx(signer, txb);

}

// prepareManyNamesForTesting(1000);
// queryNameRecord('leaf.manos.sui');
createNodeSubdomain('nested.manos.sui', MANOS_SUI_OBJECT_ID, false);
// createLeafSubdomain('leaf.manos.sui', MANOS_SUI_OBJECT_ID);
// removeLeafSubdomain('leaf.manos.sui', MANOS_SUI_OBJECT_ID);
