import { SuiClient } from "@mysten/sui/client";

export function newSuiClient(): SuiClient {
    return new SuiClient({
        url: "https://suins-rpc.mainnet.sui.io:443",
    });
}

/** Remove the `0x` prefix from a Sui address / object ID. */
export function remove0x(address: string): string {
    return address.startsWith("0x") ? address.slice(2) : address;
}
