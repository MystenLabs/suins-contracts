import { ExportedKeypair, JsonRpcProvider, RawSigner, SUI_CLOCK_OBJECT_ID, TransactionArgument, TransactionBlock, fromB64, fromExportedKeypair, localnetConnection, normalizeSuiAddress, testnetConnection, toB64 } from "@mysten/sui.js";
import { execSync } from "child_process";
import dotenv from "dotenv";
import { readFileSync } from "fs";
import { homedir } from "os";
import path from "path";
import { executeTx } from "./airdrop/helper";
dotenv.config({ path: `.env.local`, override: true });

const config = {
  packageId: process.env.PACKAGE_ADDRESS as string,
  suins: process.env.SUINS as string,
  adminCap: process.env.ADMIN_CAP_ID as string,
  utilsPackageId: process.env.UTILS_PACKAGE_ADDRESS as string,
  registrationPackageId: process.env.REGISTRATION_PACKAGE_ADDRESS as string,
  subdomainsPackageId: process.env.SUBDOMAINS_PACKAGE_ADDRESS as string,
  denylistPackageId: process.env.DENYLIST_PACKAGE_ADDRESS as string,
  publisher: process.env.PUBLISHER_ID as string,
}
const client = new JsonRpcProvider(localnetConnection);

const getActiveAddress = () => {
  return execSync(`sui client active-address`, { encoding: 'utf8' }).trim();
}

/// Returns a signer based on the active address of system's sui.
export const getSigner = () => {
  const sender = getActiveAddress();

  const keystore = JSON.parse(
    readFileSync(
      path.join(homedir(), '.sui', 'sui_config', 'sui.keystore'),
      'utf8',
    )
  );

  for (const priv of keystore) {
    const raw = fromB64(priv);
    if (raw[0] !== 0) {
      continue;
    }

    const keyPair: ExportedKeypair = {
      schema: 'ED25519',
      privateKey: toB64(raw.slice(1)),
    };

    const keypair = fromExportedKeypair(keyPair);

    if (keypair.getPublicKey().toSuiAddress() === sender) {
      return new RawSigner(keypair, client);
    }
  }

  throw new Error(`keypair not found for sender: ${sender}`);
}

console.log(config);
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

  const signer = await getSigner();

  const txb = new TransactionBlock();

  const configuration = txb.moveCall({
    target: `${config.packageId}::config::new`,
    arguments: [
      txb.pure([...Array(33).keys()]),
      txb.pure(0),
      txb.pure(0),
      txb.pure(0),
    ],
  });
  txb.moveCall({
    target: `${config.packageId}::suins::add_config`,
    arguments: [
      txb.object(config.adminCap),
      txb.object(config.suins),
      configuration,
    ],
    typeArguments: [`${config.packageId}::config::Config`],
  });
  const registry = txb.moveCall({
    target: `${config.packageId}::registry::new`,
    arguments: [txb.object(config.adminCap)],
  });
  txb.moveCall({
    target: `${config.packageId}::suins::add_registry`,
    arguments: [
      txb.object(config.adminCap),
      txb.object(config.suins),
      registry,
    ],
    typeArguments: [`${config.packageId}::registry::Registry`],
  });


  // AUTHORIZE APPS
  txb.moveCall({
    target: `${config.packageId}::admin::authorize`,
    arguments: [
      txb.object(config.adminCap),
      txb.object(config.suins),
    ],
  });
  txb.moveCall({
    target: `${config.packageId}::suins::authorize_app`,
    arguments: [
      txb.object(config.adminCap),
      txb.object(config.suins),
    ],
    typeArguments: [`${config.registrationPackageId}::register::Register`],
  });

  txb.moveCall({
    target: `${config.packageId}::suins::authorize_app`,
    arguments: [
      txb.object(config.adminCap),
      txb.object(config.suins),
    ],
    typeArguments: [`${config.utilsPackageId}::direct_setup::DirectSetup`],
  });

  txb.moveCall({
    target: `${config.denylistPackageId}::denylist::setup`,
    arguments: [
      txb.object(config.suins),
      txb.object(config.adminCap),
    ],
  });

  txb.moveCall({
    target: `${config.packageId}::suins::authorize_app`,
    arguments: [
      txb.object(config.adminCap),
      txb.object(config.suins),
    ],
    typeArguments: [`${config.subdomainsPackageId}::subdomains::SubDomains`],
  });

  txb.moveCall({
    target: `${config.subdomainsPackageId}::subdomains::setup`,
    arguments: [
      txb.object(config.suins),
      txb.object(config.adminCap),
    ],
  });

  const addr = await signer.getAddress();

  createDisplay(txb, addr);
  createDisplay(txb, addr, true);

  await executeTx(signer, txb);

  console.log(config);
}


// register a name and transfer to the sender.
const registerNameAndSomeSubnames = async (name: string) => {

  const signer = getSigner();
  const txb = new TransactionBlock();

  const nft = txb.moveCall({
    target: `${config.registrationPackageId}::register::register`,
    arguments: [
      txb.object(config.suins),
      txb.pure(name),
      txb.pure(1),
      txb.splitCoins(txb.gas, [txb.pure(0)]),
      txb.object(SUI_CLOCK_OBJECT_ID),
    ],
  });
  txb.moveCall({
    target: `${config.utilsPackageId}::direct_setup::set_target_address`,
    arguments: [
      txb.object(config.suins),
      nft,
      txb.pure(normalizeSuiAddress('0x3')),
      txb.object(SUI_CLOCK_OBJECT_ID)
    ]
  });

  txb.moveCall({
    target: `${config.utilsPackageId}::direct_setup::set_target_address`,
    arguments: [
      txb.object(config.suins),
      nft,
      txb.pure(normalizeSuiAddress('0x3')),
      txb.object(SUI_CLOCK_OBJECT_ID)
    ]
  });

  txb.moveCall({
    target: `${config.utilsPackageId}::direct_setup::set_target_address`,
    arguments: [
      txb.object(config.suins),
      nft,
      txb.pure(await signer.getAddress()),
      txb.object(SUI_CLOCK_OBJECT_ID)
    ]
  });

  createLeafSubdomain(txb, nft, 'leaf.' + name);
  removeLeafSubdomain(txb, nft, 'leaf.' + name);
  // createLeafSubdomain(txb, nft, 'leaf.' + name);
  const sub = createNodeSubdomain(txb, nft, 'node.' + name);

  txb.transferObjects([nft, sub], txb.pure(await signer.getAddress()));


  await executeTx(signer, txb);
}

const directSetupSubdomainContract = async () => {
  const txb = new TransactionBlock();

  txb.moveCall({
    target: `${config.packageId}::suins::authorize_app`,
    arguments: [
      txb.object(config.adminCap),
      txb.object(config.suins),
    ],
    typeArguments: [`${config.subdomainsPackageId}::subdomains::SubDomains`],
  });

  txb.moveCall({
    target: `${config.subdomainsPackageId}::subdomains::setup`,
    arguments: [
      txb.object(config.suins),
      txb.object(config.adminCap),
    ],
  });

  await executeTx(getSigner(), txb);
}

const getNameRecords = async (registryId: string) => {
  client.getDynamicFields({
    parentId: registryId
  }).then(async res => {
    console.log(res);

    for (const item of res.data) {
      const data = await client.getObject({
        id: item.objectId,
        options: {
          showContent: true
        }
      });
      console.dir(data.data, { depth: null });
    }
  });
}

// const getNameRecordForDomain = async (registryId: string, domain: string) => {

//     const res = await client.getDynamicFieldObject({
//         parentId: MAIN_REGISTRY_TABLE_ID,
//         name: {
//             type: `${config.packageId}::domain::Domain`,
//             value: {
//                 labels: domain.split('.').reverse()
//             }
//         }
//     });

//     // @ts-ignore-next-line
//     const fields = res.data?.content?.fields?.value?.fields;
//     // @ts-ignore-next-line
//     const metadata = fields?.data?.fields?.contents?.map((item: any) => {
//         return {
//             key: item.fields?.key,
//             value: item.fields?.value
//         }
//     })

//     return {
//         nft_id: fields.nft_id,
//         expiration_timestamp_ms: fields.expiration_timestamp_ms,
//         target_address: fields.target_address,
//         metadata
//     };
// }

const createLeafSubdomain = async (txb: TransactionBlock, parentNameRecord: any, subdomain: string) => {

  txb.moveCall({
    target: `${config.subdomainsPackageId}::subdomains::new_leaf`,
    arguments: [
      txb.object(config.suins),
      parentNameRecord,
      txb.object(SUI_CLOCK_OBJECT_ID),
      txb.pure(subdomain),
      txb.pure(normalizeSuiAddress('0x2')),
    ],
  });
}

const removeLeafSubdomain = async (txb: TransactionBlock, parentNameRecord: any, subdomain: string) => {

  txb.moveCall({
    target: `${config.subdomainsPackageId}::subdomains::remove_leaf`,
    arguments: [
      txb.object(config.suins),
      parentNameRecord,
      txb.object(SUI_CLOCK_OBJECT_ID),
      txb.pure(subdomain),
    ],
  });
}

const createNodeSubdomain = (txb: TransactionBlock, parentNameRecord: any, subdomain: string): TransactionArgument => {

  const subNft = txb.moveCall({
    target: `${config.subdomainsPackageId}::subdomains::new`,
    arguments: [
      txb.object(config.suins),
      parentNameRecord,
      txb.object(SUI_CLOCK_OBJECT_ID),
      txb.pure(subdomain),
      txb.pure('1736275700' + '000'),
      txb.pure(false),
      txb.pure(false),
    ],
  });

  return subNft;
}
const run = async () => {
  // await setupMainContract();
  // console.log(config);
  // await directSetupSubdomainContract();
  // await registerNameAndSomeSubnames('example.sui');
  // console.log(SUI_CLOCK_OBJECT_ID);
  // await registerNameAndSomeSubnames('test.sui');
  // await registerNameAndSomeSubnames('manos.sui');
  const txb = new TransactionBlock();

  // // removeLeafSubdomain(txb, txb.object('0xa4891f3754b203ef230a5e2a08822c835c808eab71e2bc6ca33a73cec9728376'), 'new.test.sui');

  // const node = createNodeSubdomain(txb, txb.object('0xa4891f3754b203ef230a5e2a08822c835c808eab71e2bc6ca33a73cec9728376'), 'bug.test.sui');

  // txb.transferObjects([node], txb.pure(getActiveAddress()));
  // // // createLeafSubdomain(txb, txb.object('0xa4891f3754b203ef230a5e2a08822c835c808eab71e2bc6ca33a73cec9728376'), 'new.test.sui');

  // // // createNodeSubdomain(txb, txb.object('0xa4891f3754b203ef230a5e2a08822c835c808eab71e2bc6ca33a73cec9728376'), 'leaf.test.sui');

  await executeTx(getSigner(), txb);
  // await registerNameAndSomeSubnames('manos.sui');
  // const sldNameRecord = await getNameRecordForDomain(MAIN_REGISTRY_TABLE_ID, 'test.sui');

  // console.log(sldNameRecord);
  // await createLeafSubdomain(sldNameRecord, 'test.test.sui');
  // await createNodeSubdomain(sldNameRecord, 'test2.test.sui');
};

run();

