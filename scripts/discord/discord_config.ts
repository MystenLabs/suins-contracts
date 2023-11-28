import { SharedObjectRef } from "@mysten/sui.js";

export type DiscordConfig  = {
    packageId: string;
    discordCap: string;
    discord: SharedObjectRef,
}

export const localDiscordConfig: DiscordConfig = {
    packageId: '0x980458dfbdd7c04e331bcd8968e1e8fc90509e158432f40ad49d797d1a78703a',
    discordCap: '0xfbe226bae36f4b28912a9bd66032ae44a2db020791d1406549e521d070707799',
    discord: {
        objectId: '0x1eccf38086ffa59fc78c3bfaf7ab3d8b86298009b51223d1638a9dc8725cbc00',
        initialSharedVersion: '17191327',
        mutable: true
    }
}
