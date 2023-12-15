// Copyright (c) 2023, Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import dotenv from "dotenv";
dotenv.config();
import {
  executeTx,
  prepareMultisigTx,
  prepareSigner,
} from "../../airdrop/helper";
import { Network, mainPackage } from "../../config/constants";
import { TransactionBlock } from "@mysten/sui.js";

const SUI =
  "0x0000000000000000000000000000000000000000000000000000000000000002::sui::SUI";
const WUSDCETH =
  "0x5d4b302506645c37ff133b98c4b50a5ae14841659738d6d733d59d0d217a93bf::coin::COIN";
const WBTC =
  "0xbc3a676894871284b3ccfb2eec66f428612000e2a6e6d23f592ce8833c27c973::coin::COIN";
const WETH =
  "0xaf8cd5edc19c4512f4259f0bee101a40d41ebed738ade5874359610ef8eeced5::coin::COIN";
const USDT =
  "0xc060006111016b8a020ad5b33834984a437aaa7d3c74c18e09a95d48aceab08c::coin::COIN";
const TESTNET_COIN =
  "0x0c5f16ebb22a354ccb8f4dc163df0e729d0d37b565b4178046ea342ea0a93391::gold::GOLD";
export const CREATION_FEE = 100 * 1e9;
export const PACKAGE_ID = "0xdee9";
export const MODULE_CLOB = "clob_v2";

// 2 - 2 for fees on the more volatile assets
const DEFAULT_MAKER_FEE = 200000;
const DEFAULT_TAKER_FEE = 200000;

// 1 - 1 for fees
const DEFAULT_STABLE_MAKER_FEE = 100000;
const DEFAULT_STABLE_TAKER_FEE = 100000;
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
// Setup Deepbook Pool.
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
