import type {
    Transaction,
    TransactionObjectInput,
    TransactionResult,
} from "@mysten/sui/transactions";
import { fromHex } from "@mysten/sui/utils";

export const bbb_aftermath_config = {
    // === public functions ===
    get: (arg: {
        tx: Transaction;
        packageId: string;
        aftermathConfigObj: TransactionObjectInput;
        coinType: string;
    }): TransactionResult => {
        return arg.tx.moveCall({
            target: `${arg.packageId}::bbb_aftermath_config::get`,
            typeArguments: [arg.coinType],
            arguments: [arg.tx.object(arg.aftermathConfigObj)],
        });
    },
    // === admin functions ===
    new: (arg: {
        tx: Transaction;
        packageId: string;
        adminCapObj: TransactionObjectInput;
    }): TransactionResult => {
        return arg.tx.moveCall({
            target: `${arg.packageId}::bbb_aftermath_config::new`,
            arguments: [arg.tx.object(arg.adminCapObj)],
        });
    },
    add: (arg: {
        tx: Transaction;
        packageId: string;
        aftermathConfigObj: TransactionObjectInput;
        adminCapObj: TransactionObjectInput;
        afSwapObj: TransactionObjectInput;
    }): TransactionResult => {
        return arg.tx.moveCall({
            target: `${arg.packageId}::bbb_aftermath_config::add`,
            arguments: [
                arg.tx.object(arg.aftermathConfigObj),
                arg.tx.object(arg.adminCapObj),
                arg.tx.object(arg.afSwapObj),
            ],
        });
    },
    remove: (arg: {
        tx: Transaction;
        packageId: string;
        aftermathConfigObj: TransactionObjectInput;
        adminCapObj: TransactionObjectInput;
        coinInType: string;
    }): TransactionResult => {
        return arg.tx.moveCall({
            target: `${arg.packageId}::bbb_aftermath_config::remove`,
            typeArguments: [arg.coinInType],
            arguments: [arg.tx.object(arg.aftermathConfigObj), arg.tx.object(arg.adminCapObj)],
        });
    },
    remove_all: (arg: {
        tx: Transaction;
        packageId: string;
        aftermathConfigObj: TransactionObjectInput;
        adminCapObj: TransactionObjectInput;
    }): TransactionResult => {
        return arg.tx.moveCall({
            target: `${arg.packageId}::bbb_aftermath_config::remove_all`,
            arguments: [arg.tx.object(arg.aftermathConfigObj), arg.tx.object(arg.adminCapObj)],
        });
    },
    destroy: (arg: {
        tx: Transaction;
        packageId: string;
        aftermathConfigObj: TransactionObjectInput;
        adminCapObj: TransactionObjectInput;
    }): TransactionResult => {
        return arg.tx.moveCall({
            target: `${arg.packageId}::bbb_aftermath_config::destroy`,
            arguments: [arg.tx.object(arg.aftermathConfigObj), arg.tx.object(arg.adminCapObj)],
        });
    },
} as const;

export const bbb_aftermath_swap = {
    new: (arg: {
        tx: Transaction;
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
    }): TransactionResult => {
        return arg.tx.moveCall({
            target: `${arg.packageId}::bbb_aftermath_swap::new`,
            typeArguments: [arg.pool.lpType, arg.coinIn.type, arg.coinOut.type],
            arguments: [
                arg.tx.object(arg.adminCapObj),
                arg.tx.pure.u8(arg.coinIn.decimals),
                arg.tx.pure.u8(arg.coinOut.decimals),
                arg.tx.pure.vector("u8", fromHex(arg.coinIn.pyth_feed)),
                arg.tx.pure.vector("u8", fromHex(arg.coinOut.pyth_feed)),
                arg.tx.object(arg.pool.id),
                arg.tx.pure.u64(arg.slippage),
                arg.tx.pure.u64(arg.maxAgeSecs),
            ],
        });
    },
    swap: (arg: {
        tx: Transaction;
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
    }): TransactionResult => {
        return arg.tx.moveCall({
            target: `${arg.packageId}::bbb_aftermath_swap::swap`,
            typeArguments: [arg.afPoolType, arg.coinInType, arg.coinOutType],
            arguments: [
                // ours
                arg.tx.object(arg.afSwapObj),
                arg.tx.object(arg.bbbVaultObj),
                // pyth
                arg.tx.object(arg.pythInfoObjIn),
                arg.tx.object(arg.pythInfoObjOut),
                // aftermath
                arg.tx.object(arg.afPoolObj),
                arg.tx.object(arg.afPoolRegistryObj),
                arg.tx.object(arg.afProtocolFeeVaultObj),
                arg.tx.object(arg.afTreasuryObj),
                arg.tx.object(arg.afInsuranceFundObj),
                arg.tx.object(arg.afReferralVaultObj),
                // sui
                arg.tx.object.clock(),
            ],
        });
    },
} as const;

export const bbb_cetus_config = {
    // === public functions ===
    get: (arg: {
        tx: Transaction;
        packageId: string;
        cetusConfigObj: TransactionObjectInput;
        coinInType: string;
    }): TransactionResult => {
        return arg.tx.moveCall({
            target: `${arg.packageId}::bbb_cetus_config::get`,
            typeArguments: [arg.coinInType],
            arguments: [arg.tx.object(arg.cetusConfigObj)],
        });
    },
    // === admin functions ===
    new: (arg: {
        tx: Transaction;
        packageId: string;
        adminCapObj: TransactionObjectInput;
    }): TransactionResult => {
        return arg.tx.moveCall({
            target: `${arg.packageId}::bbb_cetus_config::new`,
            arguments: [arg.tx.object(arg.adminCapObj)],
        });
    },
    add: (arg: {
        tx: Transaction;
        packageId: string;
        cetusConfigObj: TransactionObjectInput;
        adminCapObj: TransactionObjectInput;
        cetusSwapObj: TransactionObjectInput;
    }): TransactionResult => {
        return arg.tx.moveCall({
            target: `${arg.packageId}::bbb_cetus_config::add`,
            arguments: [
                arg.tx.object(arg.cetusConfigObj),
                arg.tx.object(arg.adminCapObj),
                arg.tx.object(arg.cetusSwapObj),
            ],
        });
    },
    remove: (arg: {
        tx: Transaction;
        packageId: string;
        cetusConfigObj: TransactionObjectInput;
        adminCapObj: TransactionObjectInput;
        coinInType: string;
    }): TransactionResult => {
        return arg.tx.moveCall({
            target: `${arg.packageId}::bbb_cetus_config::remove`,
            typeArguments: [arg.coinInType],
            arguments: [arg.tx.object(arg.cetusConfigObj), arg.tx.object(arg.adminCapObj)],
        });
    },
    remove_all: (arg: {
        tx: Transaction;
        packageId: string;
        cetusConfigObj: TransactionObjectInput;
        adminCapObj: TransactionObjectInput;
    }): TransactionResult => {
        return arg.tx.moveCall({
            target: `${arg.packageId}::bbb_cetus_config::remove_all`,
            arguments: [arg.tx.object(arg.cetusConfigObj), arg.tx.object(arg.adminCapObj)],
        });
    },
    destroy: (arg: {
        tx: Transaction;
        packageId: string;
        cetusConfigObj: TransactionObjectInput;
        adminCapObj: TransactionObjectInput;
    }): TransactionResult => {
        return arg.tx.moveCall({
            target: `${arg.packageId}::bbb_cetus_config::destroy`,
            arguments: [arg.tx.object(arg.cetusConfigObj), arg.tx.object(arg.adminCapObj)],
        });
    },
} as const;

export const bbb_cetus_swap = {
    new: (arg: {
        tx: Transaction;
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
    }): TransactionResult => {
        return arg.tx.moveCall({
            target: `${arg.packageId}::bbb_cetus_swap::new`,
            typeArguments: [arg.coinAType, arg.coinBType],
            arguments: [
                arg.tx.object(arg.adminCapObj),
                arg.tx.pure.bool(arg.a2b),
                arg.tx.pure.u8(arg.decimalsA),
                arg.tx.pure.u8(arg.decimalsB),
                arg.tx.pure.vector("u8", fromHex(arg.feedA)),
                arg.tx.pure.vector("u8", fromHex(arg.feedB)),
                arg.tx.object(arg.pool.id),
                arg.tx.pure.u64(arg.slippage),
                arg.tx.pure.u64(arg.maxAgeSecs),
            ],
        });
    },
    swap: (arg: {
        tx: Transaction;
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
    }): TransactionResult => {
        return arg.tx.moveCall({
            target: `${arg.packageId}::bbb_cetus_swap::swap`,
            typeArguments: [arg.coinAType, arg.coinBType],
            arguments: [
                // ours
                arg.tx.object(arg.cetusSwapObj),
                arg.tx.object(arg.bbbVaultObj),
                // pyth
                arg.tx.object(arg.pythInfoObjA),
                arg.tx.object(arg.pythInfoObjB),
                // cetus
                arg.tx.object(arg.cetusConfigObj),
                arg.tx.object(arg.cetusPoolObj),
                // sui
                arg.tx.object.clock(),
            ],
        });
    },
} as const;

export const bbb_burn_config = {
    // === public functions ===
    get: (arg: {
        tx: Transaction;
        packageId: string;
        burnConfigObj: TransactionObjectInput;
        coinType: string;
    }): TransactionResult => {
        return arg.tx.moveCall({
            target: `${arg.packageId}::bbb_burn_config::get`,
            typeArguments: [arg.coinType],
            arguments: [arg.tx.object(arg.burnConfigObj)],
        });
    },
    // === admin functions ===
    new: (arg: {
        tx: Transaction;
        packageId: string;
        adminCapObj: TransactionObjectInput;
    }): TransactionResult => {
        return arg.tx.moveCall({
            target: `${arg.packageId}::bbb_burn_config::new`,
            arguments: [arg.tx.object(arg.adminCapObj)],
        });
    },
    add: (arg: {
        tx: Transaction;
        packageId: string;
        burnConfigObj: TransactionObjectInput;
        adminCapObj: TransactionObjectInput;
        burnObj: TransactionObjectInput;
    }): TransactionResult => {
        return arg.tx.moveCall({
            target: `${arg.packageId}::bbb_burn_config::add`,
            arguments: [
                arg.tx.object(arg.burnConfigObj),
                arg.tx.object(arg.adminCapObj),
                arg.tx.object(arg.burnObj),
            ],
        });
    },
    remove: (arg: {
        tx: Transaction;
        packageId: string;
        burnConfigObj: TransactionObjectInput;
        adminCapObj: TransactionObjectInput;
        coinType: string;
    }): TransactionResult => {
        return arg.tx.moveCall({
            target: `${arg.packageId}::bbb_burn_config::remove`,
            typeArguments: [arg.coinType],
            arguments: [arg.tx.object(arg.burnConfigObj), arg.tx.object(arg.adminCapObj)],
        });
    },
    remove_all: (arg: {
        tx: Transaction;
        packageId: string;
        burnConfigObj: TransactionObjectInput;
        adminCapObj: TransactionObjectInput;
    }): TransactionResult => {
        return arg.tx.moveCall({
            target: `${arg.packageId}::bbb_burn_config::remove_all`,
            arguments: [arg.tx.object(arg.burnConfigObj), arg.tx.object(arg.adminCapObj)],
        });
    },
    destroy: (arg: {
        tx: Transaction;
        packageId: string;
        burnConfigObj: TransactionObjectInput;
        adminCapObj: TransactionObjectInput;
    }): TransactionResult => {
        return arg.tx.moveCall({
            target: `${arg.packageId}::bbb_burn_config::destroy`,
            arguments: [arg.tx.object(arg.burnConfigObj), arg.tx.object(arg.adminCapObj)],
        });
    },
} as const;

export const bbb_burn = {
    new: (arg: {
        tx: Transaction;
        packageId: string;
        adminCapObj: TransactionObjectInput;
        coinType: string;
    }): TransactionResult => {
        return arg.tx.moveCall({
            target: `${arg.packageId}::bbb_burn::new`,
            typeArguments: [arg.coinType],
            arguments: [arg.tx.object(arg.adminCapObj)],
        });
    },
    burn: (arg: {
        tx: Transaction;
        packageId: string;
        coinType: string;
        burnObj: TransactionObjectInput;
        bbbVaultObj: TransactionObjectInput;
    }): TransactionResult => {
        return arg.tx.moveCall({
            target: `${arg.packageId}::bbb_burn::burn`,
            typeArguments: [arg.coinType],
            arguments: [arg.tx.object(arg.burnObj), arg.tx.object(arg.bbbVaultObj)],
        });
    },
} as const;

export const bbb_vault = {
    deposit: (arg: {
        tx: Transaction;
        packageId: string;
        coinType: string;
        bbbVaultObj: TransactionObjectInput;
        coinObj: TransactionObjectInput;
    }): TransactionResult => {
        return arg.tx.moveCall({
            target: `${arg.packageId}::bbb_vault::deposit`,
            typeArguments: [arg.coinType],
            arguments: [arg.tx.object(arg.bbbVaultObj), arg.tx.object(arg.coinObj)],
        });
    },
} as const;
