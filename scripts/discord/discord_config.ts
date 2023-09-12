import { SharedObjectRef } from "@mysten/sui.js";

export type DiscordConfig  = {
    packageId: string;
    discordCap: string;
    discord: SharedObjectRef,
}

export const localDiscordConfig: DiscordConfig = {
    packageId: '0xd38f4360ba8633e15bb4273e3ce04e6138c5aca28a4912cf4e6e885915cd185a',
    discordCap: '0x9b0ae20b64a55f7aca3eb86633a7dea4605225475ccad17224ca9f8d268014b2',
    discord: {
        objectId: '0x704e87361ae0aaeba13f9a61d63cd866a6759c2e199eb3acc145926128ea5dae',
        initialSharedVersion: '10240250',
        mutable: true
    }
}
