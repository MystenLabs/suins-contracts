import { TransactionBlock } from "@mysten/sui.js";
import { Config, Network } from "../../config/constants";
import { DiscordConfig } from "../discord_config";

// add role to discord.
export const addDiscordRole = (
    tx: TransactionBlock,
    role: {
        id: number,
        percentage: number
    },
    config: DiscordConfig,
) => { 
    tx.moveCall({
        target: `${config.packageId}::discord::add_discord_role`,
        arguments: [
            tx.object(config.discordCap),
            tx.sharedObjectRef(config.discord),
            tx.pure(role.id, 'u8'),
            tx.pure(role.percentage, 'u8')
        ]
    });
}

export const setPublicKey = async (
    tx: TransactionBlock,
    pubKey: Uint8Array,
    config: DiscordConfig
) => {
    if(!pubKey || pubKey.length === 0) throw new Error("Invalid Public Key on configuration");

    tx.moveCall({
        target: `${config.packageId}::discord::set_public_key`,
        arguments: [
            tx.object(config.discordCap),
            tx.sharedObjectRef(config.discord),
            tx.pure([...pubKey])
        ]
    });
}

