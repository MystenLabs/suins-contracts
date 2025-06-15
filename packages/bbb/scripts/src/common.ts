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

export function getPythEndpoint(network = getNetwork()) {
    switch (network) {
        case "mainnet":
            return "https://hermes.pyth.network";
        case "testnet":
            return "https://hermes-beta.pyth.network";
        default:
            throw new Error(`Unsupported network: ${network}`);
    }
}

export function getConfig(network = getNetwork()) {
    if (network !== "mainnet") {
        throw new Error(`Unsupported network: ${network}`);
    }
    return {
        // aftermathAmmPkgId: "0xefe170ec0be4d762196bedecd7a065816576198a6527c99282a2551aaa7da38c", // v1
        // aftermathAmmPkgId: "0xf948935b111990c2b604900c9b2eeb8f24dcf9868a45d1ea1653a5f282c10e29", // v3
        aftermathAmmPkgId: "0xc4049b2d1cc0f6e017fda8260e4377cecd236bd7f56a54fee120816e72e2e0dd", // v2
        pythStateObjId: "0x1f9310238ee9298fb703c3419030b35b22bb1cc37113e3bb5007c99aec79e5b8",
        wormholeStateObjId: "0xaeab97f96cf9877fee2883315d459552b2b921edc16d7ceac6eab944dd88919c",
		coins: {
			SUI: {
				type: "0x0000000000000000000000000000000000000000000000000000000000000002::sui::SUI",
				feed: "0x23d7315113f5b1d3ba7a83604c44b94d79f4fd69af77f804fc7f920a6dc65744",
			},
			NS: {
				type: "0x5145494a5f5100e645e4b0aa950fa6b68f614e8c59e17bc5ded3495123a79178::ns::NS",
				feed: "0xbb5ff26e47a3a6cc7ec2fce1db996c2a145300edc5acaabe43bf9ff7c5dd5d32",
			},
			USDC: {
				type: "0xdba34672e30cb065b1f93e3ab55318768fd6fef66c15942c9f7cb846e2f900e7::usdc::USDC",
				feed: "0xeaa020c61cc479712813461ce153894a96a6c00b21ed0cfc2798d1f9a9e9c94a",
			},
		},
    };
}
