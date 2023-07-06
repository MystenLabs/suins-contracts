import { ObjectId, SuiAddress } from "@mysten/sui.js";

export type AirdropConfig = {
    isMainnet?: boolean;
    packageId: string;
    dropListObj: {
        objectId: ObjectId,
        initialSharedVersion: string;
        mutable: boolean;
    },
    setupCap: ObjectId;
    massMintingAddress: SuiAddress;
    baseCoinObjectId: ObjectId;
    publisher: ObjectId;
    bufferPackageId: ObjectId;
}

export const mainnetConfig: AirdropConfig = {
    isMainnet: true,
    packageId: '0xbf1431324a4a6eadd70e0ac6c5a16f36492f255ed4d011978b2cf34ad738efe6',
    dropListObj: {
        objectId: '0xde761c5e1bd3bdece2fd8d57be72b7a85f09d44438cafc731a693fc856ccff28',
        initialSharedVersion: '3854467',
        mutable: true
    },
    publisher: '0x7b9fa20eb51210af6060f88fd1468b405d6306f6518deecf93c5ab1955165ce0',
    setupCap: '0x3ac4499e0d0da8b4902691131bc6d63143e065a8182db23ee033533d00efe22a',
    // these are static. 
    massMintingAddress: '0x245937f348ad9cd4f0478b9766a611d8c16cf3c4d08045d6168ef5a356cb3eb9',
    baseCoinObjectId: '0x0021765dfb6569a5a8e52bacdd81fe0ae9169d264b416e924ece14edac64b6fa',

    // the buffer package to help setup the amount of addresses.
    bufferPackageId: '0xfeecbb29272d34b78c402b894ea63b48cff4a717dafc96df8aa205edca89610c'
}

// The latest testnet test run.
export const addressConfig: AirdropConfig = {
    packageId: '0x71c2dc2ce8a3cde0f7fa6638519c64f24b1b7bc20e8272d2ca0690ffbbfabc4a',
    dropListObj: {
        objectId: '0x51a8f7949f55acfd9c75bcaa2a76c473a1be8ef02538f5c6b975e6e44cd20a04',
        initialSharedVersion: '6430469',
        mutable: true
    },
    publisher: '0xf70aa88ab83f47bbc9809baebe13d8107f23100d2a01807ca91e1d8078d4f3bf',
    setupCap: '0x206eb1dc4dd76cbad883b33f54574030447e6ad29b9f60e894566cbdf5d9e578',

    // these are static. 
    massMintingAddress: '0xfe09cf0b3d77678b99250572624bf74fe3b12af915c5db95f0ed5d755612eb68',
    baseCoinObjectId: '0x000351d8ef91bcb5a6750f7ecd218fab600a07d2f11e8dab4fa2941b6e91ee73',

    // a static buffer package id.
    bufferPackageId: '0x06bf34f13caae7a08f8864ccae73bca987b937446bd2b345a46b3d4ef6300da8'
}
