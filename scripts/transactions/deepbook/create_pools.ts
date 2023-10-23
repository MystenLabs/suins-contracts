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

// List of deepbook pools today
// data: [
//     { BTC / USDC pool
//       poolId: '0xf0f663cf87f1eb124da2fc9be813e0ce262146f3df60bc2052d738eb41a25899',
//       baseAsset: '0xbc3a676894871284b3ccfb2eec66f428612000e2a6e6d23f592ce8833c27c973::coin::COIN',
//       quoteAsset: '0x5d4b302506645c37ff133b98c4b50a5ae14841659738d6d733d59d0d217a93bf::coin::COIN'
//   tick: 1000000
//   lot: 1000
//     },
//     WETH / USDC POOL
//     {
//       poolId: '0xd9e45ab5440d61cc52e3b2bd915cdd643146f7593d587c715bc7bfa48311d826',
//       baseAsset: '0xaf8cd5edc19c4512f4259f0bee101a40d41ebed738ade5874359610ef8eeced5::coin::COIN',
//       quoteAsset: '0x5d4b302506645c37ff133b98c4b50a5ae14841659738d6d733d59d0d217a93bf::coin::COIN'
//       tick: 1000000,
//       lot: 10000
//     },
//     { // USDT / USDC POOL
//       poolId: '0x5deafda22b6b86127ea4299503362638bea0ca33bb212ea3a67b029356b8b955',
//       baseAsset: '0xc060006111016b8a020ad5b33834984a437aaa7d3c74c18e09a95d48aceab08c::coin::COIN',
//       quoteAsset: '0x5d4b302506645c37ff133b98c4b50a5ae14841659738d6d733d59d0d217a93bf::coin::COIN'
//       tick: 100000
//       lot: 100000
//     },
//     { SUI / USDC POOL (This one is the one in Kriya)
//       poolId: '0x7f526b1263c4b91b43c9e646419b5696f424de28dda3c1e6658cc0a54558baa7',
//       baseAsset: '0x0000000000000000000000000000000000000000000000000000000000000002::sui::SUI',
//       quoteAsset: '0x5d4b302506645c37ff133b98c4b50a5ae14841659738d6d733d59d0d217a93bf::coin::COIN'
//       tick: 100
//       lot: 100000000
//     },
//     {
//       poolId: '0x18d871e3c3da99046dfc0d3de612c5d88859bc03b8f0568bd127d0e70dbc58be',
//       baseAsset: '0x0000000000000000000000000000000000000000000000000000000000000002::sui::SUI',
//       quoteAsset: '0x5d4b302506645c37ff133b98c4b50a5ae14841659738d6d733d59d0d217a93bf::coin::COIN'
//       tick: 10000,
//       lot: 100000000
//     }
//   ],

// Setup Deepbook Pool.
const setup = async (network: Network) => {
  const setup = mainPackage[network];

  const txb = new TransactionBlock();
  txb.mergeCoins(txb.gas, [
    txb.object(
      "0xbb210191c48a3acbe8c306ef836037c7dc0e5920c7337d569755b52e38120554"
    ),
  ]);
  const [coin] = txb.splitCoins(txb.gas, [txb.pure(CREATION_FEE)]);

  // Create SUI/ USDC
  txb.moveCall({
    typeArguments: [SUI, WUSDCETH],
    target: `${PACKAGE_ID}::${MODULE_CLOB}::create_customized_pool`,
    arguments: [
      txb.pure(100),
      txb.pure(100000000),
      txb.pure(DEFAULT_TAKER_FEE),
      txb.pure(DEFAULT_MAKER_FEE),
      coin,
    ],
  });

  const [coin2] = txb.splitCoins(txb.gas, [txb.pure(CREATION_FEE)]);

  // Create USDT / USDC
  txb.moveCall({
    typeArguments: [USDT, WUSDCETH],
    target: `${PACKAGE_ID}::${MODULE_CLOB}::create_customized_pool`,
    arguments: [
      txb.pure(100000),
      txb.pure(100000),
      txb.pure(DEFAULT_STABLE_TAKER_FEE),
      txb.pure(DEFAULT_STABLE_MAKER_FEE),
      coin2,
    ],
  });

  const [coin3] = txb.splitCoins(txb.gas, [txb.pure(CREATION_FEE)]);

  // Create WETH / USDC
  txb.moveCall({
    typeArguments: [WETH, WUSDCETH],
    target: `${PACKAGE_ID}::${MODULE_CLOB}::create_customized_pool`,
    arguments: [
      txb.pure(1000000),
      txb.pure(10000),
      txb.pure(DEFAULT_STABLE_TAKER_FEE),
      txb.pure(DEFAULT_STABLE_MAKER_FEE),
      coin3,
    ],
  });
  const [coin4] = txb.splitCoins(txb.gas, [txb.pure(CREATION_FEE)]);

  // Create WBTC / USDC
  txb.moveCall({
    typeArguments: [WBTC, WUSDCETH],
    target: `${PACKAGE_ID}::${MODULE_CLOB}::create_customized_pool`,
    arguments: [
      txb.pure(1000000),
      txb.pure(1000),
      txb.pure(DEFAULT_STABLE_TAKER_FEE),
      txb.pure(DEFAULT_STABLE_MAKER_FEE),
      coin4,
    ],
  });

  // for mainnet, we prepare the multi-sig tx.
  if (network === "mainnet") return prepareMultisigTx(txb, "mainnet");

  // For testnet, we execute the TX directly.
  return executeTx(prepareSigner(setup.provider), txb);
};

if (process.env.NETWORK === "mainnet") setup("mainnet");
else setup("testnet");
