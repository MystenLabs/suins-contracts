import type {
    Transaction,
    TransactionObjectInput,
    TransactionResult,
} from "@mysten/sui/transactions";
import { fromHex } from "@mysten/sui/utils";
import type { AftermathPool, AftermathSwap } from "./config.js";

export const bbb_aftermath_swap = {
    new: ({
        tx,
        packageId,
        adminCapObj,
        swap,
    }: {
        tx: Transaction;
        packageId: string;
        adminCapObj: TransactionObjectInput;
        swap: AftermathSwap;
    }): TransactionResult => {
        return tx.moveCall({
            target: `${packageId}::bbb_aftermath_swap::new`,
            typeArguments: [
                swap.coin_in.type,
                swap.coin_out.type,
                swap.pool.lp_type,
            ],
            arguments: [
                tx.object(adminCapObj),
                tx.pure.u8(swap.coin_in.decimals),
                tx.pure.u8(swap.coin_out.decimals),
                tx.pure.vector("u8", fromHex(swap.coin_in.feed)),
                tx.pure.vector("u8", fromHex(swap.coin_out.feed)),
                tx.object(swap.pool.id),
                tx.pure.u64(swap.slippage),
                tx.pure.u64(swap.max_age_secs),
            ],
        });
    },

    swap: ({
        tx,
        packageId,
        // ours
        coinIn,
        coinOut,
        bbbSwap,
        bbbVault,
        // pyth
        pythInfoIn,
        pythInfoOut,
        // aftermath
        afPool,
        afPoolRegistry,
        afProtocolFeeVault,
        afTreasury,
        afInsuranceFund,
        afReferralVault,
    }: {
        tx: Transaction;
        packageId: string;
        // ours
        coinIn: string;
        coinOut: string;
        bbbSwap: TransactionObjectInput;
        bbbVault: TransactionObjectInput;
        // pyth
        pythInfoIn: TransactionObjectInput;
        pythInfoOut: TransactionObjectInput;
        // aftermath
        afPool: AftermathPool;
        afPoolRegistry: TransactionObjectInput;
        afProtocolFeeVault: TransactionObjectInput;
        afTreasury: TransactionObjectInput;
        afInsuranceFund: TransactionObjectInput;
        afReferralVault: TransactionObjectInput;
    }): TransactionResult => {
        return tx.moveCall({
            target: `${packageId}::bbb_aftermath_swap::swap`,
            typeArguments: [afPool.lp_type, coinIn, coinOut],
            arguments: [
                // ours
                tx.object(bbbSwap),
                tx.object(bbbVault),
                // pyth
                tx.object(pythInfoIn),
                tx.object(pythInfoOut),
                // aftermath
                tx.object(afPool.id),
                tx.object(afPoolRegistry),
                tx.object(afProtocolFeeVault),
                tx.object(afTreasury),
                tx.object(afInsuranceFund),
                tx.object(afReferralVault),
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
} as const;

export const bbb_config = {
    add_aftermath_swap: ({
        tx,
        packageId,
        configObj,
        adminCapObj,
        afSwapObj,
    }: {
        tx: Transaction;
        packageId: string;
        configObj: TransactionObjectInput;
        adminCapObj: TransactionObjectInput;
        afSwapObj: TransactionObjectInput;
    }): TransactionResult => {
        return tx.moveCall({
            target: `${packageId}::bbb_config::add_aftermath_swap`,
            arguments: [
                tx.object(configObj),
                tx.object(adminCapObj),
                tx.object(afSwapObj),
            ],
        });
    },
    add_burn_type: ({
        tx,
        packageId,
        configObj,
        adminCapObj,
        burnObj,
    }: {
        tx: Transaction;
        packageId: string;
        configObj: TransactionObjectInput;
        adminCapObj: TransactionObjectInput;
        burnObj: TransactionObjectInput;
    }): TransactionResult => {
        return tx.moveCall({
            target: `${packageId}::bbb_config::add_burn_type`,
            arguments: [
                tx.object(configObj),
                tx.object(adminCapObj),
                tx.object(burnObj),
            ],
        });
    },
} as const;
