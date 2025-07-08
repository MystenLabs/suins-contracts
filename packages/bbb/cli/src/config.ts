/** Buy Back & Burn IDs */
const bbb = { // TODO: update values for prod
    package: "0x1a1d67691a07353f01d7bf8072ce5e103e348016e483c6806ede191fe9b5bf6a", // dev-only
    upgradeCapObj: "0x7acd287999ecaa0dba0c5095e0d8f5b62de103e6ca210b9429ff5b3c78f2ee4d", // dev-only
    adminCapObj: "0x722e44f27e50cb9da0cb3969b14c549231106a61d761e3be0e0d51d78b5be008", // dev-only
    vaultObj: "0xb628d9fcf7e49ffc72797b55ce364fc6044722039f20ff607940331fc305285d", // dev-only
    burnRegistryObj: "0x4bedaf5827cb871a1ff88ea126977ec0c1b7afe3a9699ab33489da24334b8d8e", // dev-only
    aftermathRegistryObj: "0xa125a7b7360fff1f9d7bd114f7e41c86ee66bd90cff45ed0c5c617f191c64239", // dev-only
    cetusRegistryObj: "0x2bb93168196283f0470ac08743af077c0aaa57ac8970137e0ad7d50c52094e65", // dev-only
} as const;

/** Wormhole IDs */
const wormhole = {
    stateObj: "0xaeab97f96cf9877fee2883315d459552b2b921edc16d7ceac6eab944dd88919c",
} as const;

/** Pyth IDs */
const pyth = {
    endpoint: "https://hermes.pyth.network",
    stateObj: "0x1f9310238ee9298fb703c3419030b35b22bb1cc37113e3bb5007c99aec79e5b8",
} as const;

/** Aftermath IDs */
const aftermath = {
    poolRegistry: "0xfcc774493db2c45c79f688f88d28023a3e7d98e4ee9f48bbf5c7990f651577ae",
    protocolFeeVault: "0xf194d9b1bcad972e45a7dd67dd49b3ee1e3357a00a50850c52cd51bb450e13b4",
    treasury: "0x28e499dff5e864a2eafe476269a4f5035f1c16f338da7be18b103499abf271ce",
    insuranceFund: "0xf0c40d67b078000e18032334c3325c47b9ec9f3d9ae4128be820d54663d14e3b",
    referralVault: "0x35d35b0e5b177593d8c3a801462485572fc30861e6ce96a55af6dc4730709278",
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
} as const;

/** Cetus IDs */
const cetus = {
    globalConfigObjId: "0xdaa46292632c3c4d8f31f23ea0f9b36a28ff3677e9684980e4438403a67a3d8f",
    pools: {
        usdc_sui: {
            id: "0x51e883ba7c0b566a26cbc8a94cd33eb0abd418a77cc1e60ad22fd9b1f29cd2ab",
        },
        ns_sui: {
            id: "0x763f63cbada3a932c46972c6c6dcf1abd8a9a73331908a1d7ef24c2232d85520",
        },
    }
} as const;

/** All supported coins */
const coins = {
    USDC: {
        type: "0xdba34672e30cb065b1f93e3ab55318768fd6fef66c15942c9f7cb846e2f900e7::usdc::USDC",
        pythFeed: "0xeaa020c61cc479712813461ce153894a96a6c00b21ed0cfc2798d1f9a9e9c94a",
        decimals: 6,
    },
    SUI: {
        type: "0x0000000000000000000000000000000000000000000000000000000000000002::sui::SUI",
        pythFeed: "0x23d7315113f5b1d3ba7a83604c44b94d79f4fd69af77f804fc7f920a6dc65744",
        decimals: 9,
    },
    NS: {
        type: "0x5145494a5f5100e645e4b0aa950fa6b68f614e8c59e17bc5ded3495123a79178::ns::NS",
        pythFeed: "0xbb5ff26e47a3a6cc7ec2fce1db996c2a145300edc5acaabe43bf9ff7c5dd5d32",
        decimals: 6,
    },
} as const;

/** Mainnet configuration */
export const cnf = {
    /** Object and package IDs */
    ids: {
        bbb,
        wormhole,
        pyth,
        aftermath,
        cetus,
    },
    coins,
    /** Coin types that can be burned */
    burnTypes: {
        NS: coins.NS.type,
    },
    /** Aftermath swaps in the order they should be executed */
    afSwaps: {
        USDC: { // -> SUI
            coinIn: coins.USDC,
            coinOut: coins.SUI,
            pool: aftermath.pools.sui_usdc,
        },
        SUI: { // -> NS
            coinIn: coins.SUI,
            coinOut: coins.NS,
            pool: aftermath.pools.sui_ns,
        },
    },
    /** Cetus swaps in the order they should be executed */
    cetusSwaps: {
        USDC: { // -> SUI
            coinA: coins.USDC,
            coinB: coins.SUI,
            pool: cetus.pools.usdc_sui,
            a2b: true,
        },
        SUI: { // -> NS
            coinA: coins.NS,
            coinB: coins.SUI,
            pool: cetus.pools.ns_sui,
            a2b: false,
        },
    },
    /**
     * `swap-and-burn` executes the tx only if `BBBVault` contains
     * at least the minimum balance for ANY ONE of these coins.
     */
    minimumBalances: { // TODO: uncomment for prod
        // USDC: 1_000_000n,
        // SUI: 1_000_000_000n,
        // NS: 1_000_000n,
        USDC: 1n,
        SUI: 1n,
        NS: 1n,
    },
    /** Swap slippage tolerance as `1 - slippage` in 18-decimal fixed point */
    defaultSlippage: 975_000_000_000_000_000n, // 2.5%
    /** How stale a Pyth price can be, in seconds */
    defaultMaxAgeSecs: 60n,
} as const;
