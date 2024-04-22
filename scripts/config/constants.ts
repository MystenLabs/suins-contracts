import { normalizeSuiAddress } from "@mysten/sui.js/utils";

export type Network = 'mainnet' | 'testnet'

export type Config = Record<'mainnet' | 'testnet', PackageInfo>

export type PackageInfo = {
    packageId: string;
    registrationPackageId: string;
    upgradeCap?: string;
    publisherId: string;
    adminAddress: string;
    adminCap: string;
    suins: string;
    displayObject?: string;
    directSetupPackageId: string;
    discountsPackage: {
        packageId: string;
        discountHouseId: string;
    },
    renewalsPackageId: string;
    subNamesPackageId: string;
    tempSubdomainsProxyPackageId: string;
}

export const mainPackage: Config = {
    mainnet: {
        packageId: '0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0',
        registrationPackageId: '0x9d451fa0139fef8f7c1f0bd5d7e45b7fa9dbb84c2e63c2819c7abd0a7f7d749d',
        upgradeCap: '0x9cda28244a0d0de294d2b271e772a9c33eb47d316c59913d7369b545b4af098c',
        publisherId: '0x7339f23f06df3601167d67a31752781d307136fd18304c48c928778e752caae1',
        adminAddress: normalizeSuiAddress('0xa81a2328b7bbf70ab196d6aca400b5b0721dec7615bf272d95e0b0df04517e72'),
        adminCap: '0x3f8d702d90c572b60ac692fb5074f7a7ac350b80d9c59eab4f6b7692786cae0a',
        suins: '0x6e0ddefc0ad98889c04bab9639e512c21766c5e6366f89e696956d9be6952871',
        displayObject: '0x866fbd8e51b6637c25f0e811ece9a85eb417f3987ecdfefb80f15d1192d72b4c',
        discountsPackage: {
            packageId: '0x6a6ea140e095ddd82f7c745905054b3203129dd04a09d0375416c31161932d2d',
            discountHouseId: '0x7fdd883c0b7427f18cdb498c4c87a4a79d6bec4783cb3f21aa3816bbc64ce8ef',
        },
        directSetupPackageId: '0xdac22652eb400beb1f5e2126459cae8eedc116b73b8ad60b71e3e8d7fdb317e2',
        renewalsPackageId: '0xd5e5f74126e7934e35991643b0111c3361827fc0564c83fa810668837c6f0b0f',
        subNamesPackageId: 'TODO: Fill this in...',
        tempSubdomainsProxyPackageId: 'TODO: Fill this in...'
    },
    testnet: {
        packageId: '0x22fa05f21b1ad71442491220bb9338f7b7095fe35000ef88d5400d28523bdd93',
        registrationPackageId: '0x4255184a0143c0ce4394a3f16a6f5aa5d64507269e54e51ea396d569fe8f1ba5',
        publisherId: '0x62d9690d7e6234bfd57170a89c9c8ec54604ea31cefaa3869e8be4912ee1a4ab',
        adminAddress: '0xfe09cf0b3d77678b99250572624bf74fe3b12af915c5db95f0ed5d755612eb68',
        adminCap: normalizeSuiAddress('0x5def5bd9dc94b7d418d081a91c533ec619fb4350e6c4e4602aea96fd49331b15'),
        suins: '0x300369e8909b9a6464da265b9a5a9ab6fe2158a040e84e808628cde7a07ee5a3',
        directSetupPackageId: '0x6ed81fd808a23eae2da488052334d50478b36527474fc99707c1aed0e43104b1',
        discountsPackage: {
            packageId: 'TODO: Fill this in...',
            discountHouseId: 'TODO: Fill this in...',
        },
        renewalsPackageId: '0x54800ebb4606fd0c03b4554976264373b3374eeb3fd63e7ff69f31cac786ba8c',
        subNamesPackageId: '0x3c272bc45f9157b7818ece4f7411bdfa8af46303b071aca4e18c03119c9ff636',
        tempSubdomainsProxyPackageId: '0x3489ab5dcd346afee8b681267bcab2583a5eba9855680ec9931355e50e21c148'
    }
}




