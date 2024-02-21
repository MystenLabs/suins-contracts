import { Constants } from "./types";

export const MAINNET_CONFIG: Constants = {
    suinsObjectId: 'suins',
    suinsPackageId: 'suins',
    utilsPackageId: 'utils',
    registrationPackageId: 'registration',
    renewalPackageId: 'renewal',
    subdomainsPackageId: 'subdomains',
    tempSubdomainsProxyPackageId: 'temp-subdomains-proxy'
}

export const TESTNET_CONFIG: Constants = {
    suinsObjectId: '0x300369e8909b9a6464da265b9a5a9ab6fe2158a040e84e808628cde7a07ee5a3',
    suinsPackageId: '0x22fa05f21b1ad71442491220bb9338f7b7095fe35000ef88d5400d28523bdd93',
    utilsPackageId: '0x6ed81fd808a23eae2da488052334d50478b36527474fc99707c1aed0e43104b1',
    registrationPackageId: '0x4255184a0143c0ce4394a3f16a6f5aa5d64507269e54e51ea396d569fe8f1ba5',
    renewalPackageId: 'renewal',
    subdomainsPackageId: '0x3c272bc45f9157b7818ece4f7411bdfa8af46303b071aca4e18c03119c9ff636',
    tempSubdomainsProxyPackageId: '0x3489ab5dcd346afee8b681267bcab2583a5eba9855680ec9931355e50e21c148',
    priceListConfigType: '0x22fa05f21b1ad71442491220bb9338f7b7095fe35000ef88d5400d28523bdd93::config::Config'
};
