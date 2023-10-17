import { JsonRpcProvider, TransactionBlock, bcs, testnetConnection } from "@mysten/sui.js";
import { executeTx, prepareSigner } from "../airdrop/helper";
import * as secp from "@noble/secp256k1";
import { addressToBytes, getPrivateKeyHex, signMessage } from "./crypto";
import { discordRoles } from "./constants";
import { addDiscordRole, authorizeDiscordApp, setPublicKey } from "./transactions/admin_actions";
import { DiscordConfig, localDiscordConfig } from "./discord_config";
import { attachRoles, claimCoupon, setAddress } from "./transactions/user_actions";
import { Network, mainPackage } from "../config/constants";



const authorize = async (discordConfig: DiscordConfig, network: Network) => {
    const signer = prepareSigner(new JsonRpcProvider(testnetConnection));

    const config = mainPackage[network];

    const txb = new TransactionBlock();

    authorizeDiscordApp(txb, config, discordConfig);

    await executeTx(signer, txb);
}


const prepareContract = async (config: DiscordConfig) => {
    const signer = prepareSigner(new JsonRpcProvider(testnetConnection));
    const publicKey = secp.getPublicKey(getPrivateKeyHex());

    const tx = new TransactionBlock();

    for(let role of Object.values(discordRoles)){
        addDiscordRole(tx, role, config);
    }

    setPublicKey(tx, publicKey, config);

    await executeTx(signer, tx);
}


const addSomeDummyDiscordMembers = async (config: DiscordConfig) => {
    const signer = prepareSigner(new JsonRpcProvider(testnetConnection));
    let address = await signer.getAddress();
    // let address = '0xc14621a1a24e9bf23dd219cd2c343348baa9199b62d71ac175cc91ca087d4795';

    const discord_members = Array.from({length: 10}).map((elem, index)=> ({
        discord_id: `discord_usr_${index+12}`,
        roles: [discordRoles.master.id, discordRoles.earlyTester.id],
        rolesSignature: new Uint8Array(),
        addressSignature: new Uint8Array()
    }));

    for(let member of discord_members){
        member.rolesSignature = await signMessage(
            new Uint8Array([...Buffer.from("roles_"), ...Buffer.from(member.discord_id), ...member.roles])
        );

        member.addressSignature = await signMessage(
            new Uint8Array([...Buffer.from("address_"), ...bcs.ser('u32', 0), ...Buffer.from(member.discord_id), ...addressToBytes(address)])
        );
    }

    for(let member of discord_members){

        const tx = new TransactionBlock();

        attachRoles(tx, member.discord_id, member.roles, member.rolesSignature, config);
        setAddress(tx, member.discord_id, address, member.addressSignature, config);

        tx.setGasBudget(1_000_000_000);

        await executeTx(signer, tx);

    }
    // console.log(discord_members);
}


// Simple getter of all members.
const getDiscordMembers = async (tableId: string) => {
    const signer = prepareSigner(new JsonRpcProvider(testnetConnection));
    signer.provider.getDynamicFields({
        parentId: tableId
    }).then(res=>{

        signer.provider.multiGetObjects({
            ids: res.data.map(x => x.objectId),
            options:{
                showContent: true
            }
        }).then(res=>{
            console.dir(res, {depth: null});
        })
    }).catch(e=>{})
}

const claim = async (discord_id: string, amount: number, config: DiscordConfig) => {
    const signer = prepareSigner(new JsonRpcProvider(testnetConnection));
    
    const tx = new TransactionBlock();
    claimCoupon(tx, discord_id, amount, config);

    await executeTx(signer, tx);
    
}

const authorizeCouponsForTesting = async (network: Network) => {
    const config = mainPackage[network];
    const txb = new TransactionBlock();

    txb.moveCall({
        target: `${config.packageId}::suins::authorize_app`,
        arguments: [
          txb.object(config.adminCap),
          txb.object(config.suins),
        ],
        typeArguments: [`0x86f392790aa609b76e5a4ee25be96153effc3c82f7394a928083059fc8fdf491::coupons::CouponsApp`],
    });
    const signer = prepareSigner(new JsonRpcProvider(testnetConnection));
    await executeTx(signer, txb);
}

// authorize(localDiscordConfig, 'testnet');
// prepareContract(localDiscordConfig);
// addSomeDummyDiscordMembers(localDiscordConfig);
// getDiscordMembers('0x015767b8cab58894c86dd4e381c6945efabf5aa0d70981db228ad6b64883cd95')

// authorizeCouponsForTesting('testnet');
// claim('discord_usr_15', 90, localDiscordConfig);



// coupons:
// 0aff0b32753a8c90d694d44bf0f31949f8b3344883c87d53a428382f22873819
// 668f524ae868c7787439a20a77a73c76ff55bb46a278eebedbbeb48eaa15bd39



const recreateTestingSigs = async () => {

    const sig_1 = await signMessage(
        new Uint8Array([
            ...Buffer.from("roles_"),
            ...Buffer.from('discord_id_1'), 
            ...[0,1]
        ])
    );

    const sig_2 = await signMessage(
        new Uint8Array([...Buffer.from("roles_"),...Buffer.from('discord_id_1'), ...[1,3]])
    );

    const sig_3 = await signMessage(
        new Uint8Array([      ...Buffer.from("roles_"),...Buffer.from('discord_id_2'), ...[2,3]])
    );

    const sig_4 = await signMessage(
        new Uint8Array([...Buffer.from("roles_"), ...Buffer.from('discord_id_2'), ...[5]])
    );

    const addr_sig_1 = await signMessage(
        new Uint8Array([
            ...Buffer.from("address_"),
            ...bcs.ser('u32', 0).toBytes(),
            ...Buffer.from('discord_id_1'), ...addressToBytes('0x5')
        ])
    );

    console.log(...bcs.ser('u32', 0));
    const addr_sig_2 = await signMessage(
        new Uint8Array([
            ...Buffer.from("address_"),
            ...bcs.ser('u32', 0).toBytes(), 
         ...Buffer.from('discord_id_2'), 
         ...addressToBytes('0x6')])
    );

    console.log(sig_1);
    console.log(sig_2);
    console.log(sig_3);
    console.log(sig_4);
    console.log(addr_sig_1);
    console.log(addr_sig_2);

}

// recreateTestingSigs();
