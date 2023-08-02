import { SharedObjectRef } from "@mysten/sui.js";

export type DiscordConfig  = {
    packageId: string;
    discordCap: string;
    discord: SharedObjectRef,
}

export const localDiscordConfig: DiscordConfig = {
    packageId: '0x0608505919accb2627b94ba91a2d4dfac7d1afa5e48137bfc84bf423d054b908',
    discordCap: '0x49bc084e6370bfea62578879b60c5531f32b8df4c0c4a6f403f746fadbaaf6d8',
    discord: {
        objectId: '0x453c218ec23464fd867af648072eced5850721c42ea6b3a343ff7e28db0f628c',
        initialSharedVersion: '6931850',
        mutable: true
    }
}
