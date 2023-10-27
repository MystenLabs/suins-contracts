import { SUI_CLOCK_OBJECT_ID, TransactionBlock } from "@mysten/sui.js";
import { executeTx, prepareSignerFromPrivateKey } from "../airdrop/helper";

const CAP_ID = `0x14365cd1de96cf14ae4d88f911fb47899c3bb9001ac956a8b450663d233f1f5c`;
const D3_PACKAGE_ID = `0x505b8a434a3457994e81c569bb46a2640c7ee5327e2ebf0b85675de2aafefe6a`;
const SUINS_ID = `0xedc672fadedee348108618da7555f771d4fec8d3331779a8411ff8184aded726`;
// A function to register a name using D3Cap.
const registerWithD3CapTx = (target: string) => {

    const txb = new TransactionBlock();

    const name = txb.moveCall({
        target: `${D3_PACKAGE_ID}::d3::create_name`,
        arguments: [
            txb.object(SUINS_ID),
            txb.pure('d3test.sui'), // name (including TLD .sui)
            txb.pure(1), // years to register [1,5]
            txb.object(SUI_CLOCK_OBJECT_ID), // clock
            txb.object(CAP_ID), // the D3Cap to use.
        ]
    });

    // transfer the NAME to the user's wallet.
    txb.transferObjects([name], txb.pure(target));

    return txb;
}

const TARGET_ADDRESS = `0x940e95911f7cb5e17e77993fd0334c2f003dd01b6590a289e2b2880a807f68f3`;

const claim = async () => {

    const txb = registerWithD3CapTx(TARGET_ADDRESS);

    await executeTx(prepareSignerFromPrivateKey('testnet'), txb);

}

claim();
