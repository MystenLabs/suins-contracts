import type {
    Transaction,
    TransactionObjectInput,
    TransactionResult,
} from "@mysten/sui/transactions";
import { fromHex } from "@mysten/sui/utils";

export const bbb_aftermath_registry = {
    // === public functions ===
    get: (arg: {
        tx: Transaction;
        packageId: string;
        coinInType: string;
        coinOutType: string;
        aftermathRegistryObj: TransactionObjectInput;
    }): TransactionResult => {
        const { tx, packageId } = arg;
        return tx.moveCall({
            target: `${packageId}::bbb_aftermath_registry::get`,
            typeArguments: [arg.coinInType, arg.coinOutType],
            arguments: [tx.object(arg.aftermathRegistryObj)],
        });
    },
    // === admin functions ===
    add: (arg: {
        tx: Transaction;
        packageId: string;
        aftermathRegistryObj: TransactionObjectInput;
        adminCapObj: TransactionObjectInput;
        afSwapObj: TransactionObjectInput;
    }): TransactionResult => {
        const { tx, packageId } = arg;
        return tx.moveCall({
            target: `${packageId}::bbb_aftermath_registry::add`,
            arguments: [
                tx.object(arg.aftermathRegistryObj),
                tx.object(arg.adminCapObj),
                tx.object(arg.afSwapObj),
            ],
        });
    },
    remove: (arg: {
        tx: Transaction;
        packageId: string;
        coinInType: string;
        coinOutType: string;
        aftermathRegistryObj: TransactionObjectInput;
        adminCapObj: TransactionObjectInput;
    }): TransactionResult => {
        const { tx, packageId } = arg;
        return tx.moveCall({
            target: `${packageId}::bbb_aftermath_registry::remove`,
            typeArguments: [arg.coinInType, arg.coinOutType],
            arguments: [tx.object(arg.aftermathRegistryObj), tx.object(arg.adminCapObj)],
        });
    },
    remove_all: (arg: {
        tx: Transaction;
        packageId: string;
        aftermathRegistryObj: TransactionObjectInput;
        adminCapObj: TransactionObjectInput;
    }): TransactionResult => {
        const { tx, packageId } = arg;
        return tx.moveCall({
            target: `${packageId}::bbb_aftermath_registry::remove_all`,
            arguments: [tx.object(arg.aftermathRegistryObj), tx.object(arg.adminCapObj)],
        });
    },
} as const;

export const bbb_aftermath_swap = {
    // === public functions ===
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
        const { tx, packageId } = arg;
        return tx.moveCall({
            target: `${packageId}::bbb_aftermath_swap::swap`,
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
        const { tx, packageId } = arg;
        return tx.moveCall({
            target: `${packageId}::bbb_aftermath_swap::new`,
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

export const bbb_cetus_registry = {
    // === public functions ===
    get: (arg: {
        tx: Transaction;
        packageId: string;
        coinInType: string;
        coinOutType: string;
        cetusRegistryObj: TransactionObjectInput;
    }): TransactionResult => {
        const { tx, packageId } = arg;
        return tx.moveCall({
            target: `${packageId}::bbb_cetus_registry::get`,
            typeArguments: [arg.coinInType, arg.coinOutType],
            arguments: [tx.object(arg.cetusRegistryObj)],
        });
    },
    // === admin functions ===
    add: (arg: {
        tx: Transaction;
        packageId: string;
        cetusRegistryObj: TransactionObjectInput;
        adminCapObj: TransactionObjectInput;
        cetusSwapObj: TransactionObjectInput;
    }): TransactionResult => {
        const { tx, packageId } = arg;
        return tx.moveCall({
            target: `${packageId}::bbb_cetus_registry::add`,
            arguments: [
                tx.object(arg.cetusRegistryObj),
                tx.object(arg.adminCapObj),
                tx.object(arg.cetusSwapObj),
            ],
        });
    },
    remove: (arg: {
        tx: Transaction;
        packageId: string;
        coinInType: string;
        coinOutType: string;
        cetusRegistryObj: TransactionObjectInput;
        adminCapObj: TransactionObjectInput;
    }): TransactionResult => {
        const { tx, packageId } = arg;
        return tx.moveCall({
            target: `${packageId}::bbb_cetus_registry::remove`,
            typeArguments: [arg.coinInType, arg.coinOutType],
            arguments: [tx.object(arg.cetusRegistryObj), tx.object(arg.adminCapObj)],
        });
    },
    remove_all: (arg: {
        tx: Transaction;
        packageId: string;
        cetusRegistryObj: TransactionObjectInput;
        adminCapObj: TransactionObjectInput;
    }): TransactionResult => {
        const { tx, packageId } = arg;
        return tx.moveCall({
            target: `${packageId}::bbb_cetus_registry::remove_all`,
            arguments: [tx.object(arg.cetusRegistryObj), tx.object(arg.adminCapObj)],
        });
    },
} as const;

export const bbb_cetus_swap = {
    // === public functions ===
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
        cetusRegistryObj: TransactionObjectInput;
        cetusPoolObj: TransactionObjectInput;
    }): TransactionResult => {
        const { tx, packageId } = arg;
        return tx.moveCall({
            target: `${packageId}::bbb_cetus_swap::swap`,
            typeArguments: [arg.coinAType, arg.coinBType],
            arguments: [
                // ours
                tx.object(arg.cetusSwapObj),
                tx.object(arg.bbbVaultObj),
                // pyth
                tx.object(arg.pythInfoObjA),
                tx.object(arg.pythInfoObjB),
                // cetus
                tx.object(arg.cetusRegistryObj),
                tx.object(arg.cetusPoolObj),
                // sui
                tx.object.clock(),
            ],
        });
    },
    // === admin functions ===
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
        const { tx, packageId } = arg;
        return tx.moveCall({
            target: `${packageId}::bbb_cetus_swap::new`,
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

export const bbb_burn_registry = {
    // === public functions ===
    get: (arg: {
        tx: Transaction;
        packageId: string;
        coinType: string;
        burnRegistryObj: TransactionObjectInput;
    }): TransactionResult => {
        const { tx, packageId } = arg;
        return tx.moveCall({
            target: `${packageId}::bbb_burn_registry::get`,
            typeArguments: [arg.coinType],
            arguments: [tx.object(arg.burnRegistryObj)],
        });
    },
    // === admin functions ===
    add: (arg: {
        tx: Transaction;
        packageId: string;
        burnRegistryObj: TransactionObjectInput;
        adminCapObj: TransactionObjectInput;
        burnObj: TransactionObjectInput;
    }): TransactionResult => {
        const { tx, packageId } = arg;
        return tx.moveCall({
            target: `${packageId}::bbb_burn_registry::add`,
            arguments: [
                tx.object(arg.burnRegistryObj),
                tx.object(arg.adminCapObj),
                tx.object(arg.burnObj),
            ],
        });
    },
    remove: (arg: {
        tx: Transaction;
        packageId: string;
        coinType: string;
        burnRegistryObj: TransactionObjectInput;
        adminCapObj: TransactionObjectInput;
    }): TransactionResult => {
        const { tx, packageId } = arg;
        return tx.moveCall({
            target: `${packageId}::bbb_burn_registry::remove`,
            typeArguments: [arg.coinType],
            arguments: [tx.object(arg.burnRegistryObj), tx.object(arg.adminCapObj)],
        });
    },
    remove_all: (arg: {
        tx: Transaction;
        packageId: string;
        burnRegistryObj: TransactionObjectInput;
        adminCapObj: TransactionObjectInput;
    }): TransactionResult => {
        const { tx, packageId } = arg;
        return tx.moveCall({
            target: `${packageId}::bbb_burn_registry::remove_all`,
            arguments: [tx.object(arg.burnRegistryObj), tx.object(arg.adminCapObj)],
        });
    },
} as const;

export const bbb_burn = {
    // === public functions ===
    burn: (arg: {
        tx: Transaction;
        packageId: string;
        coinType: string;
        burnObj: TransactionObjectInput;
        bbbVaultObj: TransactionObjectInput;
    }): TransactionResult => {
        const { tx, packageId } = arg;
        return tx.moveCall({
            target: `${packageId}::bbb_burn::burn`,
            typeArguments: [arg.coinType],
            arguments: [tx.object(arg.burnObj), tx.object(arg.bbbVaultObj)],
        });
    },
    // === admin functions ===
    new: (arg: {
        tx: Transaction;
        packageId: string;
        coinType: string;
        adminCapObj: TransactionObjectInput;
    }): TransactionResult => {
        const { tx, packageId } = arg;
        return tx.moveCall({
            target: `${packageId}::bbb_burn::new`,
            typeArguments: [arg.coinType],
            arguments: [tx.object(arg.adminCapObj)],
        });
    },
} as const;

export const bbb_vault = {
    // === public functions ===
    deposit: (arg: {
        tx: Transaction;
        packageId: string;
        coinType: string;
        bbbVaultObj: TransactionObjectInput;
        coinObj: TransactionObjectInput;
    }): TransactionResult => {
        const { tx, packageId } = arg;
        return tx.moveCall({
            target: `${packageId}::bbb_vault::deposit`,
            typeArguments: [arg.coinType],
            arguments: [tx.object(arg.bbbVaultObj), tx.object(arg.coinObj)],
        });
    },
} as const;
