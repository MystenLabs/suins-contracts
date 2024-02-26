import { SuiClient, getFullnodeUrl } from "@mysten/sui.js/client"
import { SuinsClient } from "../src/suins-client"
import { SuinsTransaction } from "../src/suins-transaction";
import { TransactionBlock } from "@mysten/sui.js/transactions";
import { normalizeSuiAddress } from "@mysten/sui.js/utils";

const client = new SuiClient({
    url: getFullnodeUrl('testnet')
});

const suinsClient = new SuinsClient({
    network: 'testnet',
    client
});

const dryRun = async (txb: TransactionBlock) => {
    const res = await client.dryRunTransactionBlock({
        transactionBlock: await txb.build({
            client
        }),
    });
    console.dir(res, { depth: null });
}

// Some samples on how to use the SDK for registration.
const sampleNameRegistration = async () => {

    const txb = new TransactionBlock();
    const suinsTx = new SuinsTransaction(suinsClient, txb);

    const name = 'sdk.sui';
    const years = 1;

    const priceList = await suinsClient.getPriceList();

    const nft = suinsTx.register({
        name,
        price: suinsClient.calculateRegistrationPrice({name, years, priceList}),
        years
    });

    // set target address
    suinsTx.setTargetAddress({
        nft,
        address: '0x2'
    });

    // make default
    suinsTx.setDefault({name})

    suinsTx.transactionBlock.transferObjects([nft], suinsTx.transactionBlock.pure.address(normalizeSuiAddress('0x2')));

    suinsTx.transactionBlock.setSender(normalizeSuiAddress('0x2'));

    await dryRun(suinsTx.transactionBlock);
}

sampleNameRegistration();



