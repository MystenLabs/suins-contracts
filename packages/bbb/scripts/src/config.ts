/** Mainnet configuration. */
export const cnf = {
    wormhole: {
        stateObj: "0xaeab97f96cf9877fee2883315d459552b2b921edc16d7ceac6eab944dd88919c",
    },
    pyth: {
        endpoint: "https://hermes.pyth.network",
        stateObj: "0x1f9310238ee9298fb703c3419030b35b22bb1cc37113e3bb5007c99aec79e5b8",
        /** How stale the Pyth price can be, in seconds. */
        default_max_age_secs: 60n,
    },
    aftermath: {
        ammPackage: "0xc4049b2d1cc0f6e017fda8260e4377cecd236bd7f56a54fee120816e72e2e0dd", // v2
        // aftermathAmmPkgId: "0xefe170ec0be4d762196bedecd7a065816576198a6527c99282a2551aaa7da38c", // v1
        // aftermathAmmPkgId: "0xf948935b111990c2b604900c9b2eeb8f24dcf9868a45d1ea1653a5f282c10e29", // v3
        pools: {
            sui_usdc: {
                id: "0xb0cc4ce941a6c6ac0ca6d8e6875ae5d86edbec392c3333d008ca88f377e5e181",
                lp_type: "0xd1a3eab6e9659407cb2a5a529d13b4102e498619466fc2d01cb0a6547bbdb376::af_lp::AF_LP",
            },
            sui_ns: {
                id: "0xee7a281296e0a316eff84e7ea0d5f3eb19d1860c2d4ed598c086ceaa9bf78c75",
                lp_type: "0xf847c541b3076eea83cbaddcc244d25415b7c6828c1542cae4ab152d809896b6::af_lp::AF_LP",
            },
        },
        poolRegistry: "0xfcc774493db2c45c79f688f88d28023a3e7d98e4ee9f48bbf5c7990f651577ae",
        protocolFeeVault: "0xf194d9b1bcad972e45a7dd67dd49b3ee1e3357a00a50850c52cd51bb450e13b4",
        treasury: "0x28e499dff5e864a2eafe476269a4f5035f1c16f338da7be18b103499abf271ce",
        insuranceFund: "0xf0c40d67b078000e18032334c3325c47b9ec9f3d9ae4128be820d54663d14e3b",
        referralVault: "0x35d35b0e5b177593d8c3a801462485572fc30861e6ce96a55af6dc4730709278",
        /** Swap slippage tolerance as `1 - slippage` in 18-decimal fixed point. */
        default_slippage: 980_000_000_000_000_000n, // 2%
    },
    bbb: { // TODO: update values for prod
        packageId: "0x2ec3309b921aa1f819ff566d66bcb3bd045dbaf1fbe58f3141ac6e8f7a9e5d51", // dev-only
        upgradeCapObj: "0x05d6b63f19b67efb1f9834dbf1537ff9780e2c607cff3878dcdb284ab68ca54d", // dev-only
        adminCapObj: "0x1a99fd768f5666426972040ac1a2f56c5a1798afac08257b336f9b2eba5f6be7", // dev-only
        vaultObj: "0xba4ebdd68cf195b040bcdae3fd88c53a0b47c059c630470197121dd4301326ed", // dev-only
        configObj: "0xef249ee56957f473dcefe2a6d8336a0a5d7f213ff69d1db1aca9bd2f54613116", // dev-only
    },
    coins: {
        SUI: {
            type: "0x0000000000000000000000000000000000000000000000000000000000000002::sui::SUI",
            feed: "0x23d7315113f5b1d3ba7a83604c44b94d79f4fd69af77f804fc7f920a6dc65744",
            decimals: 9,
        },
        NS: {
            type: "0x5145494a5f5100e645e4b0aa950fa6b68f614e8c59e17bc5ded3495123a79178::ns::NS",
            feed: "0xbb5ff26e47a3a6cc7ec2fce1db996c2a145300edc5acaabe43bf9ff7c5dd5d32",
            decimals: 6,
        },
        USDC: {
            type: "0xdba34672e30cb065b1f93e3ab55318768fd6fef66c15942c9f7cb846e2f900e7::usdc::USDC",
            feed: "0xeaa020c61cc479712813461ce153894a96a6c00b21ed0cfc2798d1f9a9e9c94a",
            decimals: 6,
        },
    },
} as const;

/** Aftermath swap configurations. */
export const af_swaps: AftermathSwap[] = [
    {   // USDC -> SUI
        coin_in: cnf.coins.USDC,
        coin_out: cnf.coins.SUI,
        pool: cnf.aftermath.pools.sui_usdc,
        slippage: cnf.aftermath.default_slippage,
        max_age_secs: cnf.pyth.default_max_age_secs,
    },
    {   // SUI -> NS
        coin_in: cnf.coins.SUI,
        coin_out: cnf.coins.NS,
        pool: cnf.aftermath.pools.sui_ns,
        slippage: cnf.aftermath.default_slippage,
        max_age_secs: cnf.pyth.default_max_age_secs,
    },
    {   // NS -> SUI // dev-only // TODO: remove
        coin_in: cnf.coins.NS,
        coin_out: cnf.coins.SUI,
        pool: cnf.aftermath.pools.sui_ns,
        slippage: cnf.aftermath.default_slippage,
        max_age_secs: cnf.pyth.default_max_age_secs,
    },
] as const;

/** Aftermath swap configuration. */
export type AftermathSwap = {
    /** The coin to be swapped into `coin_out` */
    coin_in: CoinInfo,
    /** The coin to be received from the swap */
    coin_out: CoinInfo,
    /** Aftermath `Pool` object */
    pool: AftermathPool,
    /** Swap slippage tolerance as `1 - slippage` in 18-decimal fixed point. */
    slippage: bigint,
    /** How stale the Pyth price can be, in seconds. */
    max_age_secs: bigint,
}

export type CoinInfo = {
    /** The `T` in `Coin<T>` */
    type: string,
    /** Number of decimals */
    decimals: number,
    /** Pyth feed ID */
    feed: string,
}

/** Aftermath `Pool` object. */
export type AftermathPool = {
    /** Object ID */
    id: string,
    /** LP token type */
    lp_type: string,
}
