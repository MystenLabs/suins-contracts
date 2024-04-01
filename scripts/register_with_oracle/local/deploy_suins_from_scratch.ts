import { SuiClient } from "@mysten/sui.js/client";
import { execSync } from "child_process";
import { TransactionBlock } from "@mysten/sui.js/transactions";
import dotenv from "dotenv";
import { executeTx, prepareSigner } from "../../airdrop/helper";
dotenv.config({ path: `register_with_oracle/.env.local`, override: true });

const config = {
    packageId: process.env.PACKAGE_ADDRESS!,
    suins: process.env.SUINS!,
    adminCap: process.env.ADMIN_CAP_ID!,
    utilsPackageId: process.env.UTILS_PACKAGE_ADDRESS!,
    registrationPackageId: process.env.REGISTRATION!,
    newRegistrationPackageId: process.env.NEW_REGISTRATION!,
    adminAddress: process.env.ADMIN_ADDRESS!,
    publisher: process.env.PUBLISHER_ID!,
    denylistPackageId: process.env.DENYLIST_PACKAGE_ADDRESS!,
    subdomainsPackageId: process.env.SUBDOMAINS_PACKAGE_ADDRESS!,
}

const client = new SuiClient({
    url: "https://mysten-rpc.testnet.sui.io:443"
});

const getActiveAddress = () => {
    return execSync(`sui client active-address`, { encoding: 'utf8' }).trim();
}

const createDisplay = (txb: TransactionBlock, admin: string, isSubdomain: boolean = false) => {
    const display = txb.moveCall({
      target: `0x2::display::new`,
      arguments: [txb.object(config.publisher)],
      typeArguments: [
        isSubdomain ? `${config.packageId}::subdomain_registration::SubDomainRegistration` :
          `${config.packageId}::suins_registration::SuinsRegistration`,
      ],
    });
    txb.moveCall({
      target: `0x2::display::add_multiple`,
      arguments: [
        display,
        txb.pure(['name', 'link', 'image_url', 'description', 'project_url']),
        txb.pure([
          `{${isSubdomain ? 'nft.' : ''}domain_name}`,
          `https://{${isSubdomain ? 'nft.' : ''}domain_name}.id`,
          `https://storage.googleapis.com/suins-nft-images/{${isSubdomain ? 'nft.' : ''}image_url}.png`,
          'SuiNS - Sculpt Your Identity',
          'https://suins.io',
        ]),
      ],
      typeArguments: [
        isSubdomain ? `${config.packageId}::subdomain_registration::SubDomainRegistration` :
          `${config.packageId}::suins_registration::SuinsRegistration`,
      ],
    });
    txb.moveCall({
      target: `0x2::display::update_version`,
      arguments: [display],
      typeArguments: [
        isSubdomain ? `${config.packageId}::subdomain_registration::SubDomainRegistration` :
          `${config.packageId}::suins_registration::SuinsRegistration`,
      ],
    });
  
    txb.transferObjects([display], txb.pure(admin));
  }

const setupMainContract = async () => {
    const signer = prepareSigner();
    const txb = new TransactionBlock();
    console.log(config);
    
    // txb.moveCall({
    //     target: `${config.packageId}::suins::remove_config`,
    //     arguments: [
    //         txb.object(config.adminCap),
    //         txb.object(config.suins),
    //     ],
    //     typeArguments: [`${config.packageId}::config::Config`],
    // });
    // const configuration = txb.moveCall({
    //     target: `${config.packageId}::config::new`,
    //     arguments: [
    //         txb.pure([...Array(33).keys()]),
    //         txb.pure(100000000000),
    //         txb.pure(50000000000),
    //         txb.pure(20000000000),
    //     ],
    // });
    // txb.moveCall({
    //     target: `${config.packageId}::suins::add_config`,
    //     arguments: [
    //         txb.object(config.adminCap),
    //         txb.object(config.suins),
    //         configuration,
    //     ],
    //     typeArguments: [`${config.packageId}::config::Config`],
    // });
    // const registry = txb.moveCall({
    //     target: `${config.packageId}::registry::new`,
    //     arguments: [txb.object(config.adminCap)],
    // });
    // txb.moveCall({
    //     target: `${config.packageId}::suins::add_registry`,
    //     arguments: [
    //         txb.object(config.adminCap),
    //         txb.object(config.suins),
    //         registry,
    //     ],
    //     typeArguments: [`${config.packageId}::registry::Registry`],
    // });

    // txb.moveCall({
    //     target: `${config.packageId}::admin::authorize`,
    //     arguments: [
    //         txb.object(config.adminCap),
    //         txb.object(config.suins),
    //     ],
    // });
    txb.moveCall({
        target: `${config.packageId}::suins::authorize_app`,
        arguments: [
            txb.object(config.adminCap),
            txb.object(config.suins),
        ],
        typeArguments: [`${config.newRegistrationPackageId}::register::Register`],
    });
    // txb.moveCall({
    //     target: `${config.packageId}::suins::authorize_app`,
    //     arguments: [
    //       txb.object(config.adminCap),
    //       txb.object(config.suins),
    //     ],
    //     typeArguments: [`${config.utilsPackageId}::direct_setup::DirectSetup`],
    // });
    
    // txb.moveCall({
    //     target: `${config.denylistPackageId}::denylist::setup`,
    //     arguments: [
    //         txb.object(config.suins),
    //         txb.object(config.adminCap),
    //     ],
    // });
    
    // txb.moveCall({
    //     target: `${config.packageId}::suins::authorize_app`,
    //     arguments: [
    //         txb.object(config.adminCap),
    //         txb.object(config.suins),
    //     ],
    //     typeArguments: [`${config.subdomainsPackageId}::subdomains::SubDomains`],
    // });

    // txb.moveCall({
    //     target: `${config.subdomainsPackageId}::subdomains::setup`,
    //     arguments: [
    //         txb.object(config.suins),
    //         txb.object(config.adminCap),
    //     ],
    // });

    await executeTx(signer, txb, client);
}

const publish = async () => {
    const txb = new TransactionBlock();
    

}

const run = async () => {
    await setupMainContract();
}

run();