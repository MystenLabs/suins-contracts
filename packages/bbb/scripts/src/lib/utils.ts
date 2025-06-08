import { getFullnodeUrl, SuiClient } from "@mysten/sui/client";

export const SUPPORTED_NETWORKS = ["mainnet", "testnet", "devnet", "localnet"] as const;

export type SupportedNetwork = (typeof SUPPORTED_NETWORKS)[number];

export const RPC_ENDPOINTS: Record<SupportedNetwork, string> = {
    mainnet: "https://suins-rpc.mainnet.sui.io:443",
    testnet: "https://suins-rpc.testnet.sui.io:443",
    devnet: getFullnodeUrl("devnet"),
    localnet: "http://127.0.0.1:9000",
  };

export function getNetwork(): SupportedNetwork {
    return "mainnet";
}

export function getSender(): string {
    return "0x777";
}

export function newSuiClient(network = getNetwork()): SuiClient {
    return new SuiClient({
        url: RPC_ENDPOINTS[network],
    });
}

export function getAftermathAmmPkgId(network = getNetwork()): string {
    if (network === "mainnet") {
        return "0xefe170ec0be4d762196bedecd7a065816576198a6527c99282a2551aaa7da38c";
    }
    throw new Error(`Unsupported network: ${network}`);
}
