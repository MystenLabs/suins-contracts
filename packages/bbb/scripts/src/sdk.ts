import type {
    Transaction,
    TransactionObjectInput,
    TransactionResult,
} from "@mysten/sui/transactions";
import { fromHex } from "@mysten/sui/utils";

export const bbb_aftermath_config = {
    // === public functions ===
    get: (arg: {
        packageId: string;
        coinType: string;
        aftermathConfigObj: TransactionObjectInput;
    }): ((tx: Transaction) => TransactionResult) => {
        return (tx: Transaction) =>
            tx.moveCall({
                target: `${arg.packageId}::bbb_aftermath_config::get`,
                typeArguments: [arg.coinType],
                arguments: [tx.object(arg.aftermathConfigObj)],
            });
    },
    // === admin functions ===
    new: (arg: {
        packageId: string;
        adminCapObj: TransactionObjectInput;
    }): ((tx: Transaction) => TransactionResult) => {
        return (tx: Transaction) =>
            tx.moveCall({
                target: `${arg.packageId}::bbb_aftermath_config::new`,
                arguments: [tx.object(arg.adminCapObj)],
            });
    },
    add: (arg: {
        packageId: string;
        aftermathConfigObj: TransactionObjectInput;
        adminCapObj: TransactionObjectInput;
        afSwapObj: TransactionObjectInput;
    }): ((tx: Transaction) => TransactionResult) => {
        return (tx: Transaction) =>
            tx.moveCall({
                target: `${arg.packageId}::bbb_aftermath_config::add`,
                arguments: [
                    tx.object(arg.aftermathConfigObj),
                    tx.object(arg.adminCapObj),
                    tx.object(arg.afSwapObj),
                ],
            });
    },
    remove: (arg: {
        packageId: string;
        coinInType: string;
        aftermathConfigObj: TransactionObjectInput;
        adminCapObj: TransactionObjectInput;
    }): ((tx: Transaction) => TransactionResult) => {
        return (tx: Transaction) =>
            tx.moveCall({
                target: `${arg.packageId}::bbb_aftermath_config::remove`,
                typeArguments: [arg.coinInType],
                arguments: [
                    tx.object(arg.aftermathConfigObj),
                    tx.object(arg.adminCapObj),
                ],
            });
    },
    remove_all: (arg: {
        packageId: string;
        aftermathConfigObj: TransactionObjectInput;
        adminCapObj: TransactionObjectInput;
    }): ((tx: Transaction) => TransactionResult) => {
        return (tx: Transaction) =>
            tx.moveCall({
                target: `${arg.packageId}::bbb_aftermath_config::remove_all`,
                arguments: [
                    tx.object(arg.aftermathConfigObj),
                    tx.object(arg.adminCapObj),
                ],
            });
    },
    destroy: (arg: {
        packageId: string;
        aftermathConfigObj: TransactionObjectInput;
        adminCapObj: TransactionObjectInput;
    }): ((tx: Transaction) => TransactionResult) => {
        return (tx: Transaction) =>
            tx.moveCall({
                target: `${arg.packageId}::bbb_aftermath_config::destroy`,
                arguments: [
                    tx.object(arg.aftermathConfigObj),
                    tx.object(arg.adminCapObj),
                ],
            });
    },
    // === framework functions ===
    share: (arg: {
        packageId: string;
        obj: TransactionObjectInput;
    }): ((tx: Transaction) => TransactionResult) => {
        return (tx: Transaction) =>
            tx.moveCall({
                target: "0x2::transfer::public_share_object",
                typeArguments: [
                    `${arg.packageId}::bbb_aftermath_config::AftermathConfig`,
                ],
                arguments: [tx.object(arg.obj)],
            });
    },
} as const;

export const bbb_aftermath_swap = {
    // === public functions ===
    swap: (arg: {
        packageId: string;
        // ours
        coinInType: string;
        coinOutType: string;
        afSwapObj: TransactionObjectInput;
        bbbVaultObj: TransactionObjectInput;
        // pyth
        pythInfoObjIn: TransactionObjectInput;
        pythInfoObjOut: TransactionObjectInput;
        // aftermath
        afPoolType: string;
        afPoolObj: TransactionObjectInput;
        afPoolRegistryObj: TransactionObjectInput;
        afProtocolFeeVaultObj: TransactionObjectInput;
        afTreasuryObj: TransactionObjectInput;
        afInsuranceFundObj: TransactionObjectInput;
        afReferralVaultObj: TransactionObjectInput;
    }): ((tx: Transaction) => TransactionResult) => {
        return (tx: Transaction) =>
            tx.moveCall({
                target: `${arg.packageId}::bbb_aftermath_swap::swap`,
                typeArguments: [arg.afPoolType, arg.coinInType, arg.coinOutType],
                arguments: [
                    // ours
                    tx.object(arg.afSwapObj),
                    tx.object(arg.bbbVaultObj),
                    // pyth
                    tx.object(arg.pythInfoObjIn),
                    tx.object(arg.pythInfoObjOut),
                    // aftermath
                    tx.object(arg.afPoolObj),
                    tx.object(arg.afPoolRegistryObj),
                    tx.object(arg.afProtocolFeeVaultObj),
                    tx.object(arg.afTreasuryObj),
                    tx.object(arg.afInsuranceFundObj),
                    tx.object(arg.afReferralVaultObj),
                    // sui
                    tx.object.clock(),
                ],
            });
    },
    // === admin functions ===
    new: (arg: {
        packageId: string;
        adminCapObj: TransactionObjectInput;
        coinIn: {
            type: string;
            decimals: number;
            pyth_feed: string;
        };
        coinOut: {
            type: string;
            decimals: number;
            pyth_feed: string;
        };
        pool: {
            id: string;
            lpType: string;
        };
        slippage: bigint;
        maxAgeSecs: bigint;
    }): ((tx: Transaction) => TransactionResult) => {
        return (tx: Transaction) =>
            tx.moveCall({
                target: `${arg.packageId}::bbb_aftermath_swap::new`,
                typeArguments: [arg.pool.lpType, arg.coinIn.type, arg.coinOut.type],
                arguments: [
                    tx.object(arg.adminCapObj),
                    tx.pure.u8(arg.coinIn.decimals),
                    tx.pure.u8(arg.coinOut.decimals),
                    tx.pure.vector("u8", fromHex(arg.coinIn.pyth_feed)),
                    tx.pure.vector("u8", fromHex(arg.coinOut.pyth_feed)),
                    tx.object(arg.pool.id),
                    tx.pure.u64(arg.slippage),
                    tx.pure.u64(arg.maxAgeSecs),
                ],
            });
    },
} as const;

export const bbb_cetus_config = {
    // === public functions ===
    get: (arg: {
        packageId: string;
        coinInType: string;
        cetusConfigObj: TransactionObjectInput;
    }): ((tx: Transaction) => TransactionResult) => {
        return (tx: Transaction) =>
            tx.moveCall({
                target: `${arg.packageId}::bbb_cetus_config::get`,
                typeArguments: [arg.coinInType],
                arguments: [tx.object(arg.cetusConfigObj)],
            });
    },
    // === admin functions ===
    new: (arg: {
        packageId: string;
        adminCapObj: TransactionObjectInput;
    }): ((tx: Transaction) => TransactionResult) => {
        return (tx: Transaction) =>
            tx.moveCall({
                target: `${arg.packageId}::bbb_cetus_config::new`,
                arguments: [tx.object(arg.adminCapObj)],
            });
    },
    add: (arg: {
        packageId: string;
        cetusConfigObj: TransactionObjectInput;
        adminCapObj: TransactionObjectInput;
        cetusSwapObj: TransactionObjectInput;
    }): ((tx: Transaction) => TransactionResult) => {
        return (tx: Transaction) =>
            tx.moveCall({
                target: `${arg.packageId}::bbb_cetus_config::add`,
                arguments: [
                    tx.object(arg.cetusConfigObj),
                    tx.object(arg.adminCapObj),
                    tx.object(arg.cetusSwapObj),
                ],
            });
    },
    remove: (arg: {
        packageId: string;
        coinInType: string;
        cetusConfigObj: TransactionObjectInput;
        adminCapObj: TransactionObjectInput;
    }): ((tx: Transaction) => TransactionResult) => {
        return (tx: Transaction) =>
            tx.moveCall({
                target: `${arg.packageId}::bbb_cetus_config::remove`,
                typeArguments: [arg.coinInType],
                arguments: [tx.object(arg.cetusConfigObj), tx.object(arg.adminCapObj)],
            });
    },
    remove_all: (arg: {
        packageId: string;
        cetusConfigObj: TransactionObjectInput;
        adminCapObj: TransactionObjectInput;
    }): ((tx: Transaction) => TransactionResult) => {
        return (tx: Transaction) =>
            tx.moveCall({
                target: `${arg.packageId}::bbb_cetus_config::remove_all`,
                arguments: [tx.object(arg.cetusConfigObj), tx.object(arg.adminCapObj)],
            });
    },
    destroy: (arg: {
        packageId: string;
        cetusConfigObj: TransactionObjectInput;
        adminCapObj: TransactionObjectInput;
    }): ((tx: Transaction) => TransactionResult) => {
        return (tx: Transaction) =>
            tx.moveCall({
                target: `${arg.packageId}::bbb_cetus_config::destroy`,
                arguments: [tx.object(arg.cetusConfigObj), tx.object(arg.adminCapObj)],
            });
    },
    // === framework functions ===
    share: (arg: {
        packageId: string;
        obj: TransactionObjectInput;
    }): ((tx: Transaction) => TransactionResult) => {
        return (tx: Transaction) =>
            tx.moveCall({
                target: "0x2::transfer::public_share_object",
                typeArguments: [`${arg.packageId}::bbb_cetus_config::CetusConfig`],
                arguments: [tx.object(arg.obj)],
            });
    },
} as const;

export const bbb_cetus_swap = {
    // === public functions ===
    swap: (arg: {
        packageId: string;
        // ours
        coinAType: string;
        coinBType: string;
        cetusSwapObj: TransactionObjectInput;
        bbbVaultObj: TransactionObjectInput;
        // pyth
        pythInfoObjA: TransactionObjectInput;
        pythInfoObjB: TransactionObjectInput;
        // cetus
        cetusConfigObj: TransactionObjectInput;
        cetusPoolObj: TransactionObjectInput;
    }): ((tx: Transaction) => TransactionResult) => {
        return (tx: Transaction) =>
            tx.moveCall({
                target: `${arg.packageId}::bbb_cetus_swap::swap`,
                typeArguments: [arg.coinAType, arg.coinBType],
                arguments: [
                    // ours
                    tx.object(arg.cetusSwapObj),
                    tx.object(arg.bbbVaultObj),
                    // pyth
                    tx.object(arg.pythInfoObjA),
                    tx.object(arg.pythInfoObjB),
                    // cetus
                    tx.object(arg.cetusConfigObj),
                    tx.object(arg.cetusPoolObj),
                    // sui
                    tx.object.clock(),
                ],
            });
    },
    // === admin functions ===
    new: (arg: {
        packageId: string;
        coinAType: string;
        coinBType: string;
        adminCapObj: TransactionObjectInput;
        a2b: boolean;
        decimalsA: number;
        decimalsB: number;
        feedA: string;
        feedB: string;
        pool: {
            id: string;
        };
        slippage: bigint;
        maxAgeSecs: bigint;
    }): ((tx: Transaction) => TransactionResult) => {
        return (tx: Transaction) =>
            tx.moveCall({
                target: `${arg.packageId}::bbb_cetus_swap::new`,
                typeArguments: [arg.coinAType, arg.coinBType],
                arguments: [
                    tx.object(arg.adminCapObj),
                    tx.pure.bool(arg.a2b),
                    tx.pure.u8(arg.decimalsA),
                    tx.pure.u8(arg.decimalsB),
                    tx.pure.vector("u8", fromHex(arg.feedA)),
                    tx.pure.vector("u8", fromHex(arg.feedB)),
                    tx.object(arg.pool.id),
                    tx.pure.u64(arg.slippage),
                    tx.pure.u64(arg.maxAgeSecs),
                ],
            });
    },
} as const;

export const bbb_burn_config = {
    // === public functions ===
    get: (arg: {
        packageId: string;
        coinType: string;
        burnConfigObj: TransactionObjectInput;
    }): ((tx: Transaction) => TransactionResult) => {
        return (tx: Transaction) =>
            tx.moveCall({
                target: `${arg.packageId}::bbb_burn_config::get`,
                typeArguments: [arg.coinType],
                arguments: [tx.object(arg.burnConfigObj)],
            });
    },
    // === admin functions ===
    new: (arg: {
        packageId: string;
        adminCapObj: TransactionObjectInput;
    }): ((tx: Transaction) => TransactionResult) => {
        return (tx: Transaction) =>
            tx.moveCall({
                target: `${arg.packageId}::bbb_burn_config::new`,
                arguments: [tx.object(arg.adminCapObj)],
            });
    },
    add: (arg: {
        packageId: string;
        burnConfigObj: TransactionObjectInput;
        adminCapObj: TransactionObjectInput;
        burnObj: TransactionObjectInput;
    }): ((tx: Transaction) => TransactionResult) => {
        return (tx: Transaction) =>
            tx.moveCall({
                target: `${arg.packageId}::bbb_burn_config::add`,
                arguments: [
                    tx.object(arg.burnConfigObj),
                    tx.object(arg.adminCapObj),
                    tx.object(arg.burnObj),
                ],
            });
    },
    remove: (arg: {
        packageId: string;
        coinType: string;
        burnConfigObj: TransactionObjectInput;
        adminCapObj: TransactionObjectInput;
    }): ((tx: Transaction) => TransactionResult) => {
        return (tx: Transaction) =>
            tx.moveCall({
                target: `${arg.packageId}::bbb_burn_config::remove`,
                typeArguments: [arg.coinType],
                arguments: [tx.object(arg.burnConfigObj), tx.object(arg.adminCapObj)],
            });
    },
    remove_all: (arg: {
        packageId: string;
        burnConfigObj: TransactionObjectInput;
        adminCapObj: TransactionObjectInput;
    }): ((tx: Transaction) => TransactionResult) => {
        return (tx: Transaction) =>
            tx.moveCall({
                target: `${arg.packageId}::bbb_burn_config::remove_all`,
                arguments: [tx.object(arg.burnConfigObj), tx.object(arg.adminCapObj)],
            });
    },
    destroy: (arg: {
        packageId: string;
        burnConfigObj: TransactionObjectInput;
        adminCapObj: TransactionObjectInput;
    }): ((tx: Transaction) => TransactionResult) => {
        return (tx: Transaction) =>
            tx.moveCall({
                target: `${arg.packageId}::bbb_burn_config::destroy`,
                arguments: [tx.object(arg.burnConfigObj), tx.object(arg.adminCapObj)],
            });
    },
    // === framework functions ===
    share: (arg: {
        packageId: string;
        obj: TransactionObjectInput;
    }): ((tx: Transaction) => TransactionResult) => {
        return (tx: Transaction) =>
            tx.moveCall({
                target: "0x2::transfer::public_share_object",
                typeArguments: [`${arg.packageId}::bbb_burn_config::BBBConfig`],
                arguments: [tx.object(arg.obj)],
            });
    },
} as const;

export const bbb_burn = {
    // === public functions ===
    burn: (arg: {
        packageId: string;
        coinType: string;
        burnObj: TransactionObjectInput;
        bbbVaultObj: TransactionObjectInput;
    }): ((tx: Transaction) => TransactionResult) => {
        return (tx: Transaction) =>
            tx.moveCall({
                target: `${arg.packageId}::bbb_burn::burn`,
                typeArguments: [arg.coinType],
                arguments: [tx.object(arg.burnObj), tx.object(arg.bbbVaultObj)],
            });
    },
    // === admin functions ===
    new: (arg: {
        packageId: string;
        coinType: string;
        adminCapObj: TransactionObjectInput;
    }): ((tx: Transaction) => TransactionResult) => {
        return (tx: Transaction) =>
            tx.moveCall({
                target: `${arg.packageId}::bbb_burn::new`,
                typeArguments: [arg.coinType],
                arguments: [tx.object(arg.adminCapObj)],
            });
    },
} as const;

export const bbb_vault = {
    // === public functions ===
    deposit: (arg: {
        packageId: string;
        coinType: string;
        bbbVaultObj: TransactionObjectInput;
        coinObj: TransactionObjectInput;
    }): ((tx: Transaction) => TransactionResult) => {
        return (tx: Transaction) =>
            tx.moveCall({
                target: `${arg.packageId}::bbb_vault::deposit`,
                typeArguments: [arg.coinType],
                arguments: [tx.object(arg.bbbVaultObj), tx.object(arg.coinObj)],
            });
    },
} as const;
