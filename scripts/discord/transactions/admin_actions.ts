import { TransactionBlock } from "@mysten/sui.js";
import { PackageInfo } from "../../config/constants";
import { DiscordConfig } from "../discord_config";

// Authorize discord app to coupons system.
export const authorizeDiscordApp = (
    txb: TransactionBlock,
    config: PackageInfo,
    discordConfig: DiscordConfig
) => {
    txb.moveCall({
        // TODO: Refactor to not have a default here.
        //@ts-ignore-next-line : This will be valid once coupon's PR is merged.
        target: `${config.coupons?.packageId || '0x86f392790aa609b76e5a4ee25be96153effc3c82f7394a928083059fc8fdf491'}::coupons::authorize_app`,
        arguments: [
            txb.object(config.adminCap),
            // TODO: Replace with coupon constants once merged in.
            txb.sharedObjectRef(
                // @ts-ignore-next-line until we merge the coupons PR.
                config.coupons?.couponHouse ?? {
                    objectId: '0x60a54b20a17beff0311963c1c775995572552e1c6b46955d87bdb021e9dac1e3',
                    initialSharedVersion: '10771047',
                    mutable: true,
            }),
        ],
        typeArguments: [`${discordConfig.packageId}::discord::DiscordApp`]
    })
}

// add role to discord.
export const addDiscordRole = (
    txb: TransactionBlock,
    role: {
        id: number,
        percentage: number
    },
    config: DiscordConfig,
) => { 
    txb.moveCall({
        target: `${config.packageId}::discord::add_discord_role`,
        arguments: [
            txb.object(config.discordCap),
            txb.sharedObjectRef(config.discord),
            txb.pure(role.id, 'u8'),
            txb.pure(role.percentage, 'u8')
        ]
    });
}

export const setPublicKey = async (
    txb: TransactionBlock,
    pubKey: Uint8Array,
    config: DiscordConfig
) => {
    if(!pubKey || pubKey.length === 0) throw new Error("Invalid Public Key on configuration");

    txb.moveCall({
        target: `${config.packageId}::discord::set_public_key`,
        arguments: [
            txb.object(config.discordCap),
            txb.sharedObjectRef(config.discord),
            txb.pure([...pubKey])
        ]
    });
}

