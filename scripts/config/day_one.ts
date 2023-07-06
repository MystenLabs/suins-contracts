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
    packageId: 'TBD',
    dropListObj: {
        objectId: 'TBD',
        initialSharedVersion: 'TBD',
        mutable: true
    },
    publisher: 'TBD',
    setupCap: 'TBD',
    // these are static. 
    massMintingAddress: 'TBD',
    baseCoinObjectId: 'TBD',

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
