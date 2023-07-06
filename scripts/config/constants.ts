import { Connection, JsonRpcProvider, ObjectId, SuiAddress } from "@mysten/sui.js"

export type Network = 'mainnet' | 'testnet'

export type Config = Record<Network, PackageInfo>

export type PackageInfo = {
    packageId: ObjectId;
    upgradeCap?: ObjectId;
    publisherId:ObjectId;
    adminAddress: SuiAddress;
    provider: JsonRpcProvider;
}

export const mainPackage: Config = {
    mainnet: {
        packageId: '0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0',
        upgradeCap: '0x9cda28244a0d0de294d2b271e772a9c33eb47d316c59913d7369b545b4af098c',
        publisherId: '0x7339f23f06df3601167d67a31752781d307136fd18304c48c928778e752caae1',
        adminAddress: '0xa81a2328b7bbf70ab196d6aca400b5b0721dec7615bf272d95e0b0df04517e72',
        provider: new JsonRpcProvider(new Connection({
            fullnode: 'https://suins-rpc.mainnet.sui.io'
        }))

    },
    testnet: {
        packageId: '0x48380438a54490534efcd9bea3c48038faf7f386f5a80b647314972a177a242a',
        publisherId: '0xf9953e8250dc19d5455e037bbe40a21ecb605871442af23f7b0399076d90bc53',
        adminAddress: '0xfe09cf0b3d77678b99250572624bf74fe3b12af915c5db95f0ed5d755612eb68',
        provider: new JsonRpcProvider(new Connection({
            fullnode: 'https://suins-rpc.testnet.sui.io:443'
        }))
    }
}




