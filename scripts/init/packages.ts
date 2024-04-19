import { SuiTransactionBlockResponse } from "@mysten/sui.js/client";
import { SuiNS, SuiNSDependentPackages, TempSubdomainProxy } from "./manifests";
import { TransactionBlock } from "@mysten/sui.js/transactions";
import { setupApp } from "../transactions/authorization";

export type Network = 'mainnet' | 'testnet' | 'devnet' | 'localnet';

const parseCorePackageObjects = (data: SuiTransactionBlockResponse) => {
    const packageId = data.objectChanges!.find(x => x.type === 'published');
    if (!packageId || packageId.type !== 'published') throw new Error('Expected Published object');
    const upgradeCap = parseCreatedObject(data, '0x2::package::UpgradeCap');

    return {
        packageId: packageId.packageId,
        upgradeCap: upgradeCap,
    }
}

const parseCreatedObject = (data: SuiTransactionBlockResponse, objectType: string) => {
    const obj = data.objectChanges!.find(x => x.type === 'created' && x.objectType === objectType);
    if (!obj || obj.type !== 'created') throw new Error(`Expected ${objectType} object`);

    return obj.objectId;
}

export const Packages = (network: Network) =>  {
    const rev = network === 'localnet' ? 'main' : `framework/${network}`;
    const subdomainExtraDependencies = `denylist = { local = "../denylist" }`;

    return {
        SuiNS: {
            order: 1,
            folder: 'suins',
            manifest: SuiNS(rev),
            processPublish: (data: SuiTransactionBlockResponse) => {
                const { packageId, upgradeCap } = parseCorePackageObjects(data);
                const publisher = parseCreatedObject(data, '0x2::package::Publisher');
                const suins = parseCreatedObject(data, `${packageId}::suins::SuiNS`);
                const adminCap = parseCreatedObject(data, `${packageId}::suins::AdminCap`);

                return {
                    packageId,
                    upgradeCap,
                    publisher,
                    suins,
                    adminCap
                }
            },
        },
        Utils: {
            order: 2,
            folder: 'utils',
            manifest: SuiNSDependentPackages(rev, 'utils'),
            processPublish: (data: SuiTransactionBlockResponse) => {
                const { packageId, upgradeCap } = parseCorePackageObjects(data);

                return {
                    packageId,
                    upgradeCap,
                    authorizationType: `${packageId}::direct_setup::DirectSetup`,
                }
            }
        },
        DenyList: {
            order: 2,
            folder: 'denylist',
            manifest: SuiNSDependentPackages(rev, 'denylist'),
            processPublish: (data: SuiTransactionBlockResponse) => {
                const { packageId, upgradeCap } = parseCorePackageObjects(data);

                return {
                    packageId,
                    upgradeCap,
                    authorizationType: `${packageId}::denylist::DenyListAuth`,
                }
            },
            setupFunction: (txb: TransactionBlock, packageId: string, adminCap: string, suins: string) => {
                setupApp({ txb, adminCap, suins, target: `${packageId}::denylist` });
            }
        },
        Registration: {
            order: 2,
            folder: 'registration',
            manifest: SuiNSDependentPackages(rev, 'registration'),
            processPublish: (data: SuiTransactionBlockResponse) => {
                const { packageId, upgradeCap } = parseCorePackageObjects(data);

                return {
                    packageId,
                    upgradeCap,
                    authorizationType: `${packageId}::register::Register`,
                }
            }
        },
        Renewal: {
            order: 2,
            folder: 'renewal',
            manifest: SuiNSDependentPackages(rev, 'renewal'),
            processPublish: (data: SuiTransactionBlockResponse) => {
                const { packageId, upgradeCap } = parseCorePackageObjects(data);

                return {
                    packageId,
                    upgradeCap,
                    authorizationType: `${packageId}::renew::Renew`,
                }
            }
        },
        DayOne: {
            order: 2,
            folder: 'day_one',
            manifest: SuiNSDependentPackages(rev, 'day_one'),
            processPublish: (data: SuiTransactionBlockResponse) => {
                const { packageId, upgradeCap } = parseCorePackageObjects(data);

                return {
                    packageId,
                    upgradeCap,
                    authorizationType: `${packageId}::bogo::BogoApp`,
                }
            }
        },
        Subdomains: {
            order: 3,
            folder: 'subdomains',
            manifest: SuiNSDependentPackages(rev, 'subdomains', subdomainExtraDependencies),
            processPublish: (data: SuiTransactionBlockResponse) => {
                const { packageId, upgradeCap } = parseCorePackageObjects(data);

                return {
                    packageId,
                    upgradeCap,
                    authorizationType: `${packageId}::subdomains::SubDomains`,
                }
            },
            setupFunction: (txb: TransactionBlock, packageId: string, adminCap: string, suins: string) => {
                setupApp({ txb, adminCap, suins, target: `${packageId}::subdomains` });
            }
        },
        // Discounts: {
        //     order: 3,
        //     folder: 'discounts',
        //     manifest: SuiNSDependentPackages(rev, 'discounts', 'day_one = { local = "../day_one" }'),
        // },
        TempSubdomainProxy: {
            order: 3,
            folder: 'temp_subdomain_proxy',
            manifest: TempSubdomainProxy(rev),
            processPublish: (data: SuiTransactionBlockResponse) => {
                const { packageId, upgradeCap } = parseCorePackageObjects(data);
                return {
                    packageId,
                    upgradeCap,
                }
            },
        },
    }
}
