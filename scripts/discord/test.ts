import { JsonRpcProvider, TransactionBlock, testnetConnection } from "@mysten/sui.js";
import { executeTx, prepareSigner } from "../airdrop/helper";
import * as secp from "@noble/secp256k1";
import { addressToBytes, getPrivateKeyHex, signMessage } from "./crypto";
import { discordRoles } from "./constants";
import { addDiscordRole, setPublicKey } from "./transactions/admin_actions";
import { DiscordConfig, localDiscordConfig } from "./discord_config";
import { attachRoles, claimCoupon, setAddress } from "./transactions/user_actions";




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

    const discord_members = Array.from({length: 10}).map((elem, index)=> ({
        discord_id: `discord_usr_${index}`,
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
// prepareContract(localDiscordConfig);
// addSomeDummyDiscordMembers(localDiscordConfig);
// getDiscordMembers('0x334624aacdc7add6b63da4d800bb4401b8b459bbda322252eb83114cd2f9615a')

// claim('discord_usr_1', 20, localDiscordConfig);





