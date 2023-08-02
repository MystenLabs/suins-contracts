import { normalizeSuiAddress } from "@mysten/sui.js";
import { addressToBytes, generateKeyPair, signMessage } from "./crypto";
import { readEnvAndReplaceTableId } from "./utils";



// generateKeyPair();



const discordIds = ["discord_id_1", "discord_id_2"];

const prepareSignatures = async () => {

    signAndSaveRoles(discordIds[0], [0,1], 1);
    signAndSaveRoles(discordIds[0], [1,3], 2)
    signAndSaveRoles(discordIds[1], [2,3], 3);
    signAndSaveRoles(discordIds[1], [5], 4);

    signAndSaveAddresses(discordIds[0], normalizeSuiAddress('0x5'), 1);
    signAndSaveAddresses(discordIds[1], normalizeSuiAddress('0x6'), 2);
}



const signAndSaveRoles = async (discordId: string, roles: number[], id: number) => {
    let bytes = new Uint8Array([...Buffer.from(discordId), ...roles]);
    let msg = await signMessage(bytes);
    readEnvAndReplaceTableId('ROLES_SIG_'+id, msg.toString())
}

const signAndSaveAddresses = async (discordId: string, address: string, id:number) => {
    let bytes = new Uint8Array([...Buffer.from(discordId), ...addressToBytes(address)]);
    let msg = await signMessage(bytes);
    readEnvAndReplaceTableId('ADDR_SIG_'+id, msg.toString());
}

prepareSignatures();
