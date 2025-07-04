import type {
    Transaction,
    TransactionObjectInput,
    TransactionResult,
} from "@mysten/sui/transactions";
import { fromHex } from "@mysten/sui/utils";

export const bbb_aftermath_config = {
    // === public functions ===
    get: ({
        tx,
        packageId,
        aftermathConfigObj,
        coinType,
    }: {
        tx: Transaction;
        packageId: string;
        aftermathConfigObj: TransactionObjectInput;
        coinType: string;
    }): TransactionResult => {
        return tx.moveCall({
            target: `${packageId}::bbb_aftermath_config::get`,
            typeArguments: [coinType],
            arguments: [tx.object(aftermathConfigObj)],
        });
    },
    // === admin functions ===
    new: ({
        tx,
        packageId,
        adminCapObj,
    }: {
        tx: Transaction;
        packageId: string;
        adminCapObj: TransactionObjectInput;
    }): TransactionResult => {
        return tx.moveCall({
            target: `${packageId}::bbb_aftermath_config::new`,
            arguments: [tx.object(adminCapObj)],
        });
    },
    add: ({
        tx,
        packageId,
        aftermathConfigObj,
        adminCapObj,
        afSwapObj,
    }: {
        tx: Transaction;
        packageId: string;
        aftermathConfigObj: TransactionObjectInput;
        adminCapObj: TransactionObjectInput;
        afSwapObj: TransactionObjectInput;
    }): TransactionResult => {
        return tx.moveCall({
            target: `${packageId}::bbb_aftermath_config::add`,
            arguments: [
                tx.object(aftermathConfigObj),
                tx.object(adminCapObj),
                tx.object(afSwapObj),
            ],
        });
    },
    remove: ({
        tx,
        packageId,
        aftermathConfigObj,
        adminCapObj,
        coinInType,
    }: {
        tx: Transaction;
        packageId: string;
        aftermathConfigObj: TransactionObjectInput;
        adminCapObj: TransactionObjectInput;
        coinInType: string;
    }): TransactionResult => {
        return tx.moveCall({
            target: `${packageId}::bbb_aftermath_config::remove`,
            typeArguments: [coinInType],
            arguments: [tx.object(aftermathConfigObj), tx.object(adminCapObj)],
        });
    },
    remove_all: ({
        tx,
        packageId,
        aftermathConfigObj,
        adminCapObj,
    }: {
        tx: Transaction;
        packageId: string;
        aftermathConfigObj: TransactionObjectInput;
        adminCapObj: TransactionObjectInput;
    }): TransactionResult => {
        return tx.moveCall({
            target: `${packageId}::bbb_aftermath_config::remove_all`,
            arguments: [tx.object(aftermathConfigObj), tx.object(adminCapObj)],
        });
    },
    destroy: ({
        tx,
        packageId,
        aftermathConfigObj,
        adminCapObj,
    }: {
        tx: Transaction;
        packageId: string;
        aftermathConfigObj: TransactionObjectInput;
        adminCapObj: TransactionObjectInput;
    }): TransactionResult => {
        return tx.moveCall({
            target: `${packageId}::bbb_aftermath_config::destroy`,
            arguments: [tx.object(aftermathConfigObj), tx.object(adminCapObj)],
        });
    },
} as const;

export const bbb_aftermath_swap = {
    new: ({
        tx,
        packageId,
        adminCapObj,
        coinIn,
        coinOut,
        pool,
        slippage,
        maxAgeSecs,
    }: {
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
        return tx.moveCall({
            target: `${packageId}::bbb_aftermath_swap::new`,
            typeArguments: [pool.lpType, coinIn.type, coinOut.type],
            arguments: [
                tx.object(adminCapObj),
                tx.pure.u8(coinIn.decimals),
                tx.pure.u8(coinOut.decimals),
                tx.pure.vector("u8", fromHex(coinIn.pyth_feed)),
                tx.pure.vector("u8", fromHex(coinOut.pyth_feed)),
                tx.object(pool.id),
                tx.pure.u64(slippage),
                tx.pure.u64(maxAgeSecs),
            ],
        });
    },
    swap: ({
        tx,
        packageId,
        // ours
        coinInType,
        coinOutType,
        afSwapObj,
        bbbVaultObj,
        // pyth
        pythInfoObjIn,
        pythInfoObjOut,
        // aftermath
        afPoolType,
        afPoolObj,
        afPoolRegistryObj,
        afProtocolFeeVaultObj,
        afTreasuryObj,
        afInsuranceFundObj,
        afReferralVaultObj,
    }: {
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
        return tx.moveCall({
            target: `${packageId}::bbb_aftermath_swap::swap`,
            typeArguments: [afPoolType, coinInType, coinOutType],
            arguments: [
                // ours
                tx.object(afSwapObj),
                tx.object(bbbVaultObj),
                // pyth
                tx.object(pythInfoObjIn),
                tx.object(pythInfoObjOut),
                // aftermath
                tx.object(afPoolObj),
                tx.object(afPoolRegistryObj),
                tx.object(afProtocolFeeVaultObj),
                tx.object(afTreasuryObj),
                tx.object(afInsuranceFundObj),
                tx.object(afReferralVaultObj),
                // sui
                tx.object.clock(),
            ],
        });
    },
} as const;

export const bbb_cetus_config = {
    // === public functions ===
    get: ({
        tx,
        packageId,
        cetusConfigObj,
        coinInType,
    }: {
        tx: Transaction;
        packageId: string;
        cetusConfigObj: TransactionObjectInput;
        coinInType: string;
    }): TransactionResult => {
        return tx.moveCall({
            target: `${packageId}::bbb_cetus_config::get`,
            typeArguments: [coinInType],
            arguments: [tx.object(cetusConfigObj)],
        });
    },
    // === admin functions ===
    new: ({
        tx,
        packageId,
        adminCapObj,
    }: {
        tx: Transaction;
        packageId: string;
        adminCapObj: TransactionObjectInput;
    }): TransactionResult => {
        return tx.moveCall({
            target: `${packageId}::bbb_cetus_config::new`,
            arguments: [tx.object(adminCapObj)],
        });
    },
    add: ({
        tx,
        packageId,
        cetusConfigObj,
        adminCapObj,
        cetusSwapObj,
    }: {
        tx: Transaction;
        packageId: string;
        cetusConfigObj: TransactionObjectInput;
        adminCapObj: TransactionObjectInput;
        cetusSwapObj: TransactionObjectInput;
    }): TransactionResult => {
        return tx.moveCall({
            target: `${packageId}::bbb_cetus_config::add`,
            arguments: [
                tx.object(cetusConfigObj),
                tx.object(adminCapObj),
                tx.object(cetusSwapObj),
            ],
        });
    },
    remove: ({
        tx,
        packageId,
        cetusConfigObj,
        adminCapObj,
        coinInType,
    }: {
        tx: Transaction;
        packageId: string;
        cetusConfigObj: TransactionObjectInput;
        adminCapObj: TransactionObjectInput;
        coinInType: string;
    }): TransactionResult => {
        return tx.moveCall({
            target: `${packageId}::bbb_cetus_config::remove`,
            typeArguments: [coinInType],
            arguments: [tx.object(cetusConfigObj), tx.object(adminCapObj)],
        });
    },
    remove_all: ({
        tx,
        packageId,
        cetusConfigObj,
        adminCapObj,
    }: {
        tx: Transaction;
        packageId: string;
        cetusConfigObj: TransactionObjectInput;
        adminCapObj: TransactionObjectInput;
    }): TransactionResult => {
        return tx.moveCall({
            target: `${packageId}::bbb_cetus_config::remove_all`,
            arguments: [tx.object(cetusConfigObj), tx.object(adminCapObj)],
        });
    },
    destroy: ({
        tx,
        packageId,
        cetusConfigObj,
        adminCapObj,
    }: {
        tx: Transaction;
        packageId: string;
        cetusConfigObj: TransactionObjectInput;
        adminCapObj: TransactionObjectInput;
    }): TransactionResult => {
        return tx.moveCall({
            target: `${packageId}::bbb_cetus_config::destroy`,
            arguments: [tx.object(cetusConfigObj), tx.object(adminCapObj)],
        });
    },
} as const;

export const bbb_cetus_swap = {
    new: ({
        tx,
        packageId,
        coinAType,
        coinBType,
        adminCapObj,
        a2b,
        decimalsA,
        decimalsB,
        feedA,
        feedB,
        pool,
        slippage,
        maxAgeSecs,
    }: {
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
        return tx.moveCall({
            target: `${packageId}::bbb_cetus_swap::new`,
            typeArguments: [coinAType, coinBType],
            arguments: [
                tx.object(adminCapObj),
                tx.pure.bool(a2b),
                tx.pure.u8(decimalsA),
                tx.pure.u8(decimalsB),
                tx.pure.vector("u8", fromHex(feedA)),
                tx.pure.vector("u8", fromHex(feedB)),
                tx.object(pool.id),
                tx.pure.u64(slippage),
                tx.pure.u64(maxAgeSecs),
            ],
        });
    },
    swap: ({
        tx,
        packageId,
        // ours
        coinAType,
        coinBType,
        cetusSwapObj,
        bbbVaultObj,
        // pyth
        pythInfoObjA,
        pythInfoObjB,
        // cetus
        cetusConfigObj,
        cetusPoolObj,
    }: {
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
        return tx.moveCall({
            target: `${packageId}::bbb_cetus_swap::swap`,
            typeArguments: [coinAType, coinBType],
            arguments: [
                // ours
                tx.object(cetusSwapObj),
                tx.object(bbbVaultObj),
                // pyth
                tx.object(pythInfoObjA),
                tx.object(pythInfoObjB),
                // cetus
                tx.object(cetusConfigObj),
                tx.object(cetusPoolObj),
                // sui
                tx.object.clock(),
            ],
        });
    },
} as const;

export const bbb_burn_config = {
    // === public functions ===
    get: ({
        tx,
        packageId,
        burnConfigObj,
        coinType,
    }: {
        tx: Transaction;
        packageId: string;
        burnConfigObj: TransactionObjectInput;
        coinType: string;
    }): TransactionResult => {
        return tx.moveCall({
            target: `${packageId}::bbb_burn_config::get`,
            typeArguments: [coinType],
            arguments: [tx.object(burnConfigObj)],
        });
    },
    // === admin functions ===
    new: ({
        tx,
        packageId,
        adminCapObj,
    }: {
        tx: Transaction;
        packageId: string;
        adminCapObj: TransactionObjectInput;
    }): TransactionResult => {
        return tx.moveCall({
            target: `${packageId}::bbb_burn_config::new`,
            arguments: [tx.object(adminCapObj)],
        });
    },
    add: ({
        tx,
        packageId,
        burnConfigObj,
        adminCapObj,
        burnObj,
    }: {
        tx: Transaction;
        packageId: string;
        burnConfigObj: TransactionObjectInput;
        adminCapObj: TransactionObjectInput;
        burnObj: TransactionObjectInput;
    }): TransactionResult => {
        return tx.moveCall({
            target: `${packageId}::bbb_burn_config::add`,
            arguments: [
                tx.object(burnConfigObj),
                tx.object(adminCapObj),
                tx.object(burnObj),
            ],
        });
    },
    remove: ({
        tx,
        packageId,
        burnConfigObj,
        adminCapObj,
        coinType,
    }: {
        tx: Transaction;
        packageId: string;
        burnConfigObj: TransactionObjectInput;
        adminCapObj: TransactionObjectInput;
        coinType: string;
    }): TransactionResult => {
        return tx.moveCall({
            target: `${packageId}::bbb_burn_config::remove`,
            typeArguments: [coinType],
            arguments: [tx.object(burnConfigObj), tx.object(adminCapObj)],
        });
    },
    remove_all: ({
        tx,
        packageId,
        burnConfigObj,
        adminCapObj,
    }: {
        tx: Transaction;
        packageId: string;
        burnConfigObj: TransactionObjectInput;
        adminCapObj: TransactionObjectInput;
    }): TransactionResult => {
        return tx.moveCall({
            target: `${packageId}::bbb_burn_config::remove_all`,
            arguments: [tx.object(burnConfigObj), tx.object(adminCapObj)],
        });
    },
    destroy: ({
        tx,
        packageId,
        burnConfigObj,
        adminCapObj,
    }: {
        tx: Transaction;
        packageId: string;
        burnConfigObj: TransactionObjectInput;
        adminCapObj: TransactionObjectInput;
    }): TransactionResult => {
        return tx.moveCall({
            target: `${packageId}::bbb_burn_config::destroy`,
            arguments: [tx.object(burnConfigObj), tx.object(adminCapObj)],
        });
    },
} as const;

export const bbb_burn = {
    new: ({
        tx,
        packageId,
        adminCapObj,
        coinType,
    }: {
        tx: Transaction;
        packageId: string;
        adminCapObj: TransactionObjectInput;
        coinType: string;
    }): TransactionResult => {
        return tx.moveCall({
            target: `${packageId}::bbb_burn::new`,
            typeArguments: [coinType],
            arguments: [tx.object(adminCapObj)],
        });
    },
    burn: ({
        tx,
        packageId,
        coinType,
        burnObj,
        bbbVaultObj,
    }: {
        tx: Transaction;
        packageId: string;
        coinType: string;
        burnObj: TransactionObjectInput;
        bbbVaultObj: TransactionObjectInput;
    }): TransactionResult => {
        return tx.moveCall({
            target: `${packageId}::bbb_burn::burn`,
            typeArguments: [coinType],
            arguments: [tx.object(burnObj), tx.object(bbbVaultObj)],
        });
    },
} as const;

export const bbb_vault = {
    deposit: ({
        tx,
        packageId,
        coinType,
        bbbVaultObj,
        coinObj,
    }: {
        tx: Transaction;
        packageId: string;
        coinType: string;
        bbbVaultObj: TransactionObjectInput;
        coinObj: TransactionObjectInput;
    }): TransactionResult => {
        return tx.moveCall({
            target: `${packageId}::bbb_vault::deposit`,
            typeArguments: [coinType],
            arguments: [tx.object(bbbVaultObj), tx.object(coinObj)],
        });
    },
} as const;
