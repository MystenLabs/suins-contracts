import { Connection, JsonRpcProvider, type SharedObjectRef } from "@mysten/sui.js"

export type Network = 'mainnet' | 'testnet'

export type Config = Record<Network, PackageInfo>

export type PackageInfo = {
    packageId: string;
    registrationPackageId: string;
    upgradeCap?: string;
    publisherId: string;
    adminAddress: string;
    provider: JsonRpcProvider;
    adminCap: string;
    suins: string;
    coupons: {
        packageId: string;
        couponHouse: SharedObjectRef;
        tableId: string;
    };
}

export const mainPackage: Config = {
    mainnet: {
        packageId: '0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0',
        registrationPackageId: '0x9d451fa0139fef8f7c1f0bd5d7e45b7fa9dbb84c2e63c2819c7abd0a7f7d749d',
        upgradeCap: '0x9cda28244a0d0de294d2b271e772a9c33eb47d316c59913d7369b545b4af098c',
        publisherId: '0x7339f23f06df3601167d67a31752781d307136fd18304c48c928778e752caae1',
        adminAddress: '0xa81a2328b7bbf70ab196d6aca400b5b0721dec7615bf272d95e0b0df04517e72',
        adminCap: '0x3f8d702d90c572b60ac692fb5074f7a7ac350b80d9c59eab4f6b7692786cae0a',
        suins: '0x6e0ddefc0ad98889c04bab9639e512c21766c5e6366f89e696956d9be6952871',
        provider: new JsonRpcProvider(new Connection({
            fullnode: 'https://suins-rpc.mainnet.sui.io'
        })),
        coupons: {
            packageId: 'TODO: Fill in when published',
            couponHouse: {
                objectId: 'TODO: Fill in when published',
                initialSharedVersion: 'TODO: Fill in when',
                mutable: true
            },
            tableId: 'TODO: Fill it in when published'
        }
    },
    testnet: {
        packageId: '0x701b8ca1c40f11288a1ed2de0a9a2713e972524fbab748a7e6c137225361653f',
        registrationPackageId: 'TODO: Fill this in',
        publisherId: '0xd12afb9b5e4a8dc875d22fc927e78952dc9bd84730b33c02e9fd30949c100e38',
        adminAddress: '0x7bdfc33239bd05af27d6989cee5455da4bc69ed4cfab5d178434a96ff412514a',
        adminCap: '0xadc8b4c3fa0cc022e995968e06fca1d4a47f782f7bb0e88c52730eca77cdae03',
        suins: '0xedc672fadedee348108618da7555f771d4fec8d3331779a8411ff8184aded726',
        provider: new JsonRpcProvider(new Connection({
            fullnode: 'https://suins-rpc.testnet.sui.io:443'
        })),
        coupons: {
            packageId: '0xa9e5c66ffa31fe4529acd94fe821a494f945cc6f34d7a82610fe36e8c8173442',
            couponHouse: {
                objectId: '0x936e27aecf271e628689fd93b088bee165e85eb944232006f7877a1a1642f73d',
                initialSharedVersion: '8425952',
                mutable: true
            },
            tableId: '0xc489181d54624f327cc6ea670d10ce6fa9e0a669c22ecd4792b350cb65821773'
        }
    }
}
