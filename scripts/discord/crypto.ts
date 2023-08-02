// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import * as secp from "@noble/secp256k1";
import dotenv from "dotenv";
import { readEnvAndReplaceTableId } from "./utils";
import { bcs } from "@mysten/sui.js";

dotenv.config();

export const getPrivateKeyHex = () => {
    const key = process.env['PRIVATE_KEY'] as string;
    //@ts-ignore-next-line
    return secp.utils.bytesToHex(new Uint8Array(key.split(",")));
}

// Converts address to serialized version, similar to how the SC processes it.
export const addressToBytes = (address: string): Uint8Array => {
    return bcs.ser('address', address).toBytes();
}

// Signs a message that allows funds claiming for a specific address.
export const signMessage = async (bytes: Uint8Array) => {

    console.log(secp.utils.bytesToHex(bytes));
    const signature = await secp.sign(
        await secp.utils.sha256(bytes),
        getPrivateKeyHex(),
        { der: false },
    );

    return signature;
}

export const verifyForAddress = async (address: string) => {
    const isValid = secp.verify(
        await signMessage(Buffer.from('0xfe09cf0b3d77678b99250572624bf74fe3b12af915c5db95f0ed5d755612eb68')),
        await secp.utils.sha256(Buffer.from('0xfe09cf0b3d77678b99250572624bf74fe3b12af915c5db95f0ed5d755612eb68')), 
        secp.getPublicKey(getPrivateKeyHex()));
    console.log(isValid);
}



export const generateKeyPair = async () => {

    let privateKey = secp.utils.randomPrivateKey();
    let publicKey = secp.getPublicKey(privateKey);

    readEnvAndReplaceTableId('PRIVATE_KEY', privateKey.toString());
    readEnvAndReplaceTableId('PUBLIC_KEY', publicKey.toString());

}
