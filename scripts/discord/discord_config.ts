import { SharedObjectRef } from "@mysten/sui.js";

export type DiscordConfig  = {
    packageId: string;
    discordCap: string;
    discord: SharedObjectRef,
}

export const localDiscordConfig: DiscordConfig = {
    packageId: '0x2351c4b276766b38dfffdece41e7e72e538ba6ce999a0acf582e93c21d7b880f',
    discordCap: '0xf4018e67edc1701cc97b7c21b325192e90c1d3076789ca6f2016d13bcc9ffd10',
    discord: {
        objectId: '0x3b8f48660de038a2f93644e88bddeb5d097c41caa7b72edc55b60cd0d185df12',
        initialSharedVersion: '10771048',
        mutable: true
    }
}
