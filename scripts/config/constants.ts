import { Connection, JsonRpcProvider, ObjectId, SuiAddress, testnetConnection } from "@mysten/sui.js"

export type Network = 'mainnet' | 'testnet'

export type Config = Record<Network, PackageInfo>

export type PackageInfo = {
    packageId: ObjectId;
    registrationPackageId: string;
    upgradeCap?: ObjectId;
    publisherId:ObjectId;
    adminAddress: SuiAddress;
    provider: JsonRpcProvider;
    adminCap: ObjectId;
    suins: ObjectId;
}

export const mainPackage: Config = {
    mainnet: {
        packageId: '0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0',
        registrationPackageId: 'TODO: Fill this in after publishing',
        upgradeCap: '0x9cda28244a0d0de294d2b271e772a9c33eb47d316c59913d7369b545b4af098c',
        publisherId: '0x7339f23f06df3601167d67a31752781d307136fd18304c48c928778e752caae1',
        adminAddress: '0xa81a2328b7bbf70ab196d6aca400b5b0721dec7615bf272d95e0b0df04517e72',
        adminCap: '0x3f8d702d90c572b60ac692fb5074f7a7ac350b80d9c59eab4f6b7692786cae0a',
        suins: '0x6e0ddefc0ad98889c04bab9639e512c21766c5e6366f89e696956d9be6952871',
        provider: new JsonRpcProvider(new Connection({
            fullnode: 'https://suins-rpc.mainnet.sui.io'
        }))

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
        }))
    }
}




