import { JsonRpcProvider, TransactionBlock, testnetConnection } from "@mysten/sui.js";
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
            new Uint8Array([...Buffer.from(member.discord_id), ...member.roles])
        );

        member.addressSignature = await signMessage(
            new Uint8Array([...Buffer.from(member.discord_id), ...addressToBytes(address)])
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

// authorize(localDiscordConfig, 'testnet');
// prepareContract(localDiscordConfig);
// addSomeDummyDiscordMembers(localDiscordConfig);
// getDiscordMembers('0x015767b8cab58894c86dd4e381c6945efabf5aa0d70981db228ad6b64883cd95')

// claim('discord_usr_15', 90, localDiscordConfig);



// coupons:
// 0aff0b32753a8c90d694d44bf0f31949f8b3344883c87d53a428382f22873819
// 668f524ae868c7787439a20a77a73c76ff55bb46a278eebedbbeb48eaa15bd39

