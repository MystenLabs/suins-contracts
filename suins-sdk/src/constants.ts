import { Constants } from "./types";

export const MAINNET_CONFIG: Constants = {
    suinsObjectId: '0x6e0ddefc0ad98889c04bab9639e512c21766c5e6366f89e696956d9be6952871',
    utilsPackageId: '0xdac22652eb400beb1f5e2126459cae8eedc116b73b8ad60b71e3e8d7fdb317e2',
    registrationPackageId: '0x9d451fa0139fef8f7c1f0bd5d7e45b7fa9dbb84c2e63c2819c7abd0a7f7d749d',
    renewalPackageId: 'renewal',
    subdomainsPackageId: 'subdomains',
    tempSubdomainsProxyPackageId: 'temp-subdomains-proxy',
    priceListConfigType: '0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0::config::Config',
    getConfig: (innerType: string) => `0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0::suins::ConfigKey<${innerType}>`
}

export const TESTNET_CONFIG: Constants = {
    suinsObjectId: '0x300369e8909b9a6464da265b9a5a9ab6fe2158a040e84e808628cde7a07ee5a3',
    utilsPackageId: '0x6ed81fd808a23eae2da488052334d50478b36527474fc99707c1aed0e43104b1',
    registrationPackageId: '0x4255184a0143c0ce4394a3f16a6f5aa5d64507269e54e51ea396d569fe8f1ba5',
    renewalPackageId: 'renewal',
    subdomainsPackageId: '0x3c272bc45f9157b7818ece4f7411bdfa8af46303b071aca4e18c03119c9ff636',
    tempSubdomainsProxyPackageId: '0x3489ab5dcd346afee8b681267bcab2583a5eba9855680ec9931355e50e21c148',
    priceListConfigType: '0x22fa05f21b1ad71442491220bb9338f7b7095fe35000ef88d5400d28523bdd93::config::Config',
    getConfig: (innerType: string) => `0x22fa05f21b1ad71442491220bb9338f7b7095fe35000ef88d5400d28523bdd93::suins::ConfigKey<${innerType}>`
};
