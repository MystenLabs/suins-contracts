import type {
    Transaction,
    TransactionObjectInput,
    TransactionResult,
} from "@mysten/sui/transactions";
import { fromHex } from "@mysten/sui/utils";

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

export const bbb_config = {
    // === public functions ===
    get_burn: ({
        tx,
        packageId,
        bbbBurnConfigObj,
        coinType,
    }: {
        tx: Transaction;
        packageId: string;
        bbbBurnConfigObj: TransactionObjectInput;
        coinType: string;
    }): TransactionResult => {
        return tx.moveCall({
            target: `${packageId}::bbb_config::get_burn`,
            typeArguments: [coinType],
            arguments: [tx.object(bbbBurnConfigObj)],
        });
    },
    get_aftermath_swap: ({
        tx,
        packageId,
        bbbAftermathConfigObj,
        coinType,
    }: {
        tx: Transaction;
        packageId: string;
        bbbAftermathConfigObj: TransactionObjectInput;
        coinType: string;
    }): TransactionResult => {
        return tx.moveCall({
            target: `${packageId}::bbb_config::get_aftermath_swap`,
            typeArguments: [coinType],
            arguments: [tx.object(bbbAftermathConfigObj)],
        });
    },
    // === admin functions ===
    new_burn_config: ({
        tx,
        packageId,
        adminCapObj,
    }: {
        tx: Transaction;
        packageId: string;
        adminCapObj: TransactionObjectInput;
    }): TransactionResult => {
        return tx.moveCall({
            target: `${packageId}::bbb_config::new_burn_config`,
            arguments: [tx.object(adminCapObj)],
        });
    },
    new_aftermath_config: ({
        tx,
        packageId,
        adminCapObj,
    }: {
        tx: Transaction;
        packageId: string;
        adminCapObj: TransactionObjectInput;
    }): TransactionResult => {
        return tx.moveCall({
            target: `${packageId}::bbb_config::new_aftermath_config`,
            arguments: [tx.object(adminCapObj)],
        });
    },
    add_burn_type: ({
        tx,
        packageId,
        bbbBurnConfigObj,
        adminCapObj,
        burnObj,
    }: {
        tx: Transaction;
        packageId: string;
        bbbBurnConfigObj: TransactionObjectInput;
        adminCapObj: TransactionObjectInput;
        burnObj: TransactionObjectInput;
    }): TransactionResult => {
        return tx.moveCall({
            target: `${packageId}::bbb_config::add_burn_type`,
            arguments: [
                tx.object(bbbBurnConfigObj),
                tx.object(adminCapObj),
                tx.object(burnObj),
            ],
        });
    },
    add_aftermath_swap: ({
        tx,
        packageId,
        bbbAftermathConfigObj,
        adminCapObj,
        afSwapObj,
    }: {
        tx: Transaction;
        packageId: string;
        bbbAftermathConfigObj: TransactionObjectInput;
        adminCapObj: TransactionObjectInput;
        afSwapObj: TransactionObjectInput;
    }): TransactionResult => {
        return tx.moveCall({
            target: `${packageId}::bbb_config::add_aftermath_swap`,
            arguments: [
                tx.object(bbbAftermathConfigObj),
                tx.object(adminCapObj),
                tx.object(afSwapObj),
            ],
        });
    },
    remove_burn_type: ({
        tx,
        packageId,
        bbbBurnConfigObj,
        adminCapObj,
        coinType,
    }: {
        tx: Transaction;
        packageId: string;
        bbbBurnConfigObj: TransactionObjectInput;
        adminCapObj: TransactionObjectInput;
        coinType: string;
    }): TransactionResult => {
        return tx.moveCall({
            target: `${packageId}::bbb_config::remove_burn_type`,
            typeArguments: [coinType],
            arguments: [tx.object(bbbBurnConfigObj), tx.object(adminCapObj)],
        });
    },
    remove_aftermath_swap: ({
        tx,
        packageId,
        bbbAftermathConfigObj,
        adminCapObj,
        coinInType,
    }: {
        tx: Transaction;
        packageId: string;
        bbbAftermathConfigObj: TransactionObjectInput;
        adminCapObj: TransactionObjectInput;
        coinInType: string;
    }): TransactionResult => {
        return tx.moveCall({
            target: `${packageId}::bbb_config::remove_aftermath_swap`,
            typeArguments: [coinInType],
            arguments: [tx.object(bbbAftermathConfigObj), tx.object(adminCapObj)],
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
