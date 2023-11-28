import { Connection, JsonRpcProvider, ObjectId, SuiAddress, testnetConnection } from "@mysten/sui.js"

export type Network = 'mainnet' | 'testnet'

export type Config = Record<Network, PackageInfo>

export type PackageInfo = {
    packageId: string;
    registrationPackageId: string;
    upgradeCap?: string;
    publisherId: string;
    adminAddress: SuiAddress;
    provider: JsonRpcProvider;
    adminCap: string;
    suins: string;
    displayObject?: string;
    directSetupPackageId: string;
    subdomainsPackageId: string;
    tempSubdomainProxyPackageId: string;
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
        displayObject: '0x866fbd8e51b6637c25f0e811ece9a85eb417f3987ecdfefb80f15d1192d72b4c',
        provider: new JsonRpcProvider(new Connection({
            fullnode: 'https://suins-rpc.mainnet.sui.io'
        })),
        directSetupPackageId: '0xdac22652eb400beb1f5e2126459cae8eedc116b73b8ad60b71e3e8d7fdb317e2',
        subdomainsPackageId: 'TODO: Fill this in',
        tempSubdomainProxyPackageId: 'TODO: Fill this in'
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
        directSetupPackageId: '0x9af70a4cb6d7144e68fd972eef672a74c7fe41aa5c0bb67ba40d7d1ae87bfb19',
        subdomainsPackageId: '0x948089208e8f8ec32af2477d6d1e69375224164c8c16b2ccc0c1a5c522003e1a',
        tempSubdomainProxyPackageId: '0xe5ddb8bf3435a31cf64efb53164d35ca58d066a2447aaa6e76414141d2750a6e'
    }
}
