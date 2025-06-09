import { getFullnodeUrl, SuiClient } from "@mysten/sui/client";
import { Transaction } from "@mysten/sui/transactions";

const network = "mainnet";

const client = new SuiClient({
    url: getFullnodeUrl(network),
});

const sender = "0x777";

const tx = new Transaction();
