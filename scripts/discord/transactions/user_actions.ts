import { SUI_CLOCK_OBJECT_ID, TransactionBlock } from "@mysten/sui.js";
import { DiscordConfig } from "../discord_config";

// add role to discord.
export const attachRoles = (
    tx: TransactionBlock,
    discordId: string,
    roles: number[],
    signature: Uint8Array,
    config: DiscordConfig,
) => { 
    tx.moveCall({
        target: `${config.packageId}::discord::attach_roles`,
        arguments: [
            tx.sharedObjectRef(config.discord),
            tx.pure([...signature], 'vector<u8>'),
            tx.pure(discordId),
            tx.pure([...roles], 'vector<u8>')
        ]
    });
}


/** Set the address of a discord_id */
export const setAddress = (
    tx: TransactionBlock,
    discordId: string,
    address: string,
    signature: Uint8Array,
    config: DiscordConfig,
) => { 
    tx.moveCall({
        target: `${config.packageId}::discord::set_address`,
        arguments: [
            tx.sharedObjectRef(config.discord),
            tx.pure([...signature], 'vector<u8>'),
            tx.pure(discordId),
            tx.pure(address, 'address')
        ]
    });
}


/** Set the address of a discord_id */
// NOTE (02/08/2023): On the current testnet version, this doesn't create any coupons. 
// It just consumes the point.
export const claimCoupon = (
    tx: TransactionBlock,
    discordId: string,
    amount: number,
    config: DiscordConfig,
) => {
    tx.moveCall({
        target: `${config.packageId}::discord::claim_coupon`,
        arguments: [
            tx.sharedObjectRef(config.discord),
            tx.pure(discordId),
            tx.pure(amount, 'u8'),
            tx.object(SUI_CLOCK_OBJECT_ID)
        ]
    });
}
