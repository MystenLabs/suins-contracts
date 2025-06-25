/** Mainnet configuration. */
export const cnf = {
    bbb: { // TODO: update values for prod
        packageId: "0x76f24ad1015376527db2319ed2c5d87b0605bb18a5d1ad514138444ead23eb17", // dev-only
        upgradeCapObj: "0x669f915fb9271de2ea1dae2caa4b7518d56352cc7110415e24ee8062a84e135c", // dev-only
        adminCapObj: "0x9ae1edc33d0b34b7a6e317d70b1feb1b71146b994c4e752cbb155b6e06cfbf2b", // dev-only
        vaultObj: "0x3e4075ff437932f691c678845f3afd94d4318331550dadb8bc35822031685685", // dev-only
        configObj: "0x840586b363bb7730cc6ef75bbeca5b05a318f3f7b4199ca5316fc6754e243f28", // dev-only
    },
    coins: {
        SUI: {
            type: "0x0000000000000000000000000000000000000000000000000000000000000002::sui::SUI",
            pyth_feed: "0x23d7315113f5b1d3ba7a83604c44b94d79f4fd69af77f804fc7f920a6dc65744",
            decimals: 9,
        },
        NS: {
            type: "0x5145494a5f5100e645e4b0aa950fa6b68f614e8c59e17bc5ded3495123a79178::ns::NS",
            pyth_feed: "0xbb5ff26e47a3a6cc7ec2fce1db996c2a145300edc5acaabe43bf9ff7c5dd5d32",
            decimals: 6,
        },
        USDC: {
            type: "0xdba34672e30cb065b1f93e3ab55318768fd6fef66c15942c9f7cb846e2f900e7::usdc::USDC",
            pyth_feed: "0xeaa020c61cc479712813461ce153894a96a6c00b21ed0cfc2798d1f9a9e9c94a",
            decimals: 6,
        },
    },
    wormhole: {
        stateObj: "0xaeab97f96cf9877fee2883315d459552b2b921edc16d7ceac6eab944dd88919c",
    },
    pyth: {
        endpoint: "https://hermes.pyth.network",
        stateObj: "0x1f9310238ee9298fb703c3419030b35b22bb1cc37113e3bb5007c99aec79e5b8",
        /** How stale a Pyth price can be, in seconds. */
        defaultMaxAgeSecs: 60n,
    },
    aftermath: {
        ammPackage: "0xc4049b2d1cc0f6e017fda8260e4377cecd236bd7f56a54fee120816e72e2e0dd", // v2
        // aftermathAmmPkgId: "0xefe170ec0be4d762196bedecd7a065816576198a6527c99282a2551aaa7da38c", // v1
        // aftermathAmmPkgId: "0xf948935b111990c2b604900c9b2eeb8f24dcf9868a45d1ea1653a5f282c10e29", // v3
        pools: {
            sui_usdc: {
                id: "0xb0cc4ce941a6c6ac0ca6d8e6875ae5d86edbec392c3333d008ca88f377e5e181",
                lpType: "0xd1a3eab6e9659407cb2a5a529d13b4102e498619466fc2d01cb0a6547bbdb376::af_lp::AF_LP",
            },
            sui_ns: {
                id: "0xee7a281296e0a316eff84e7ea0d5f3eb19d1860c2d4ed598c086ceaa9bf78c75",
                lpType: "0xf847c541b3076eea83cbaddcc244d25415b7c6828c1542cae4ab152d809896b6::af_lp::AF_LP",
            },
        },
        poolRegistry: "0xfcc774493db2c45c79f688f88d28023a3e7d98e4ee9f48bbf5c7990f651577ae",
        protocolFeeVault: "0xf194d9b1bcad972e45a7dd67dd49b3ee1e3357a00a50850c52cd51bb450e13b4",
        treasury: "0x28e499dff5e864a2eafe476269a4f5035f1c16f338da7be18b103499abf271ce",
        insuranceFund: "0xf0c40d67b078000e18032334c3325c47b9ec9f3d9ae4128be820d54663d14e3b",
        referralVault: "0x35d35b0e5b177593d8c3a801462485572fc30861e6ce96a55af6dc4730709278",
        /** Swap slippage tolerance as `1 - slippage` in 18-decimal fixed point. */
        defaultSlippage: 975_000_000_000_000_000n, // 2.5%
    },
} as const;

/** Coin types that can be burned. */
export const burnTypes = {
    NS: cnf.coins.NS.type,
} as const;

/** Aftermath swap configurations. */
export const afSwaps = {
    USDC: { // -> SUI
        coinIn: cnf.coins.USDC,
        coinOut: cnf.coins.SUI,
        pool: cnf.aftermath.pools.sui_usdc,
        slippage: cnf.aftermath.defaultSlippage,
        maxAgeSecs: cnf.pyth.defaultMaxAgeSecs,
    },
    SUI: { // -> NS
        coinIn: cnf.coins.SUI,
        coinOut: cnf.coins.NS,
        pool: cnf.aftermath.pools.sui_ns,
        slippage: cnf.aftermath.defaultSlippage,
        maxAgeSecs: cnf.pyth.defaultMaxAgeSecs,
    },
} as const;
