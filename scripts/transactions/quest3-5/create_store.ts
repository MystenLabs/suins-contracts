import dotenv from "dotenv";
dotenv.config();
import {
  executeTx,
  prepareMultisigTx,
  prepareSigner,
} from "../../airdrop/helper";
import { Network, mainPackage } from "../../config/constants";
import { TransactionBlock } from "@mysten/sui.js/";

export const TESTNET_OPEN_STORE =
  "0xbc8eac559fab7a8b9a49477eee5ccf8b8fbaad1fcc94d7ea2aebea929424f367::game::stock_store";

export const MAINNET_STORE_STOCK_CAP =
  "0x30681da69cd6c25272e88f0645a48c7efbc3d8dace0140b617470b5fa9498db4";

export const TESTNET_STORE_STOCK_CAP =
  "0x30681da69cd6c25272e88f0645a48c7efbc3d8dace0140b617470b5fa9498db4";

export const MAINNET_OPEN_STORE =
  "0xbc8eac559fab7a8b9a49477eee5ccf8b8fbaad1fcc94d7ea2aebea929424f367::game::open_store";
export const TESTNET_STORE =
  "0x6bc71e59a0284474c06a3fa1668093d5b86a639ddb038dd60ae3f529b18bf628";
export const MAINNET_STORE =
  "0x6bc71e59a0284474c06a3fa1668093d5b86a639ddb038dd60ae3f529b18bf628";

export const SUI_COIN_TYPE = "0x2::sui::SUI";
export const MAX_PLAYERS_IN_LEADERBOARD = 10;
const SUI_SCALING = 1_000_000_000;

// For setup we need to determine which address will run the randomness
// We can host and sign with a different account but still need the blsPublicKey from the
// account which we will utilize.
//
// 1. Determine the sidecar address so this address receives the store_cap to create tickets.
// 2. Send an associate store cap to the randomness bls signing address.
// 3. Fill the store with funds that can utilize these funds.
// Setup Quest 3.5
const setup = async (network: Network) => {
  const setup = mainPackage[network];

  let txb = new TransactionBlock();

  let prizes = [774400, 222006, 2000, 930, 420, 200, 90, 10, 1];
  let amount = [
    10000000,
    1 * SUI_SCALING,
    10 * SUI_SCALING,
    25 * SUI_SCALING,
    100 * SUI_SCALING,
    200 * SUI_SCALING,
    500 * SUI_SCALING,
    5000 * SUI_SCALING,
    50000 * SUI_SCALING,
  ];
  let target_amount = prizes
    .map((prize, index) => prize * amount[index])
    .reduce((a, b) => a + b, 0);

  let target_gas = txb.splitCoins(txb.gas, [txb.pure(target_amount, "u64")]);
  txb.moveCall({
    target: network === "mainnet" ? MAINNET_OPEN_STORE : TESTNET_OPEN_STORE,
    typeArguments: [SUI_COIN_TYPE],
    arguments: [
      txb.object("mainnet" ? MAINNET_STORE_STOCK_CAP : TESTNET_STORE_STOCK_CAP),
      txb.object("mainnet" ? MAINNET_STORE : TESTNET_STORE),
      target_gas,
      txb.pure(Array.from(prizes), "vector<u64>"),
      txb.pure(Array.from(amount), "vector<u64>"),
      txb.pure(
        Array.from([
          136, 69, 75, 13, 202, 187, 202, 204, 184, 112, 146, 111, 102, 190,
          136, 123, 94, 248, 253, 66, 239, 3, 228, 208, 94, 234, 101, 4, 255,
          242, 101, 12, 0, 69, 15, 158, 244, 110, 66, 17, 30, 187, 158, 246, 0,
          123, 7, 14,
        ]),
        "vector<u8>"
      ),
      txb.pure(MAX_PLAYERS_IN_LEADERBOARD),
    ],
  });

  // for mainnet, we prepare the multi-sig tx.
  if (network === "mainnet") return prepareMultisigTx(txb, "mainnet");

  // For testnet, we execute the TX directly.
  return executeTx(prepareSigner(setup.provider), txb);
};

if (process.env.NETWORK === "mainnet") setup("mainnet");
else setup("testnet");
