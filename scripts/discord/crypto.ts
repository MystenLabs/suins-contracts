// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import * as secp from "@noble/secp256k1";
import "dotenv/config";
import { readEnvAndReplaceKey } from "../config/utils";
import { bcs, normalizeSuiAddress } from "@mysten/sui.js";


export const getPrivateKeyHex = () => {
    const key = process.env['CONTRACT_PRIVATE_KEY'] as string;
    //@ts-ignore-next-line
    return secp.utils.bytesToHex(new Uint8Array(key.split(",")));
}

// Converts address to serialized version, similar to how the SC processes it.
export const addressToBytes = (address: string): Uint8Array => {
    return bcs.ser('address', normalizeSuiAddress(address)).toBytes();
}

// Signs a message that allows funds claiming for a specific address.
export const signMessage = async (bytes: Uint8Array) => {
    const signature = await secp.sign(
        await secp.utils.sha256(bytes),
        getPrivateKeyHex(),
        { der: false },
    );

    return signature;
}

export const generateKeyPair = async () => {

    let privateKey = secp.utils.randomPrivateKey();
    let publicKey = secp.getPublicKey(privateKey);

    readEnvAndReplaceKey('CONTRACT_PRIVATE_KEY', privateKey.toString());
    readEnvAndReplaceKey('CONTRACT_PUBLIC_KEY', publicKey.toString());
}
