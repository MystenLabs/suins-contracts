import type { Transaction, TransactionResult } from "@mysten/sui/transactions";
import { fromHex } from "@mysten/sui/utils";
import type { AftermathPool, AftermathSwap } from "./config.js";
import { type ObjectInput, objectArg } from "./utils.js";

export const bbb_aftermath_swap = {
    new: ({
        tx,
        packageId,
        adminCapObj,
        swap,
    }: {
        tx: Transaction;
        packageId: string;
        adminCapObj: ObjectInput;
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
                objectArg(tx, adminCapObj),
                tx.pure.u8(swap.coin_in.decimals),
                tx.pure.u8(swap.coin_out.decimals),
                tx.pure.vector("u8", fromHex(swap.coin_in.feed)),
                tx.pure.vector("u8", fromHex(swap.coin_out.feed)),
                objectArg(tx, swap.pool.id),
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
        bbbSwap: ObjectInput;
        bbbVault: ObjectInput;
        // pyth
        pythInfoIn: ObjectInput;
        pythInfoOut: ObjectInput;
        // aftermath
        afPool: AftermathPool;
        afPoolRegistry: ObjectInput;
        afProtocolFeeVault: ObjectInput;
        afTreasury: ObjectInput;
        afInsuranceFund: ObjectInput;
        afReferralVault: ObjectInput;
    }): TransactionResult => {
        return tx.moveCall({
            target: `${packageId}::bbb_aftermath_swap::swap`,
            typeArguments: [afPool.lp_type, coinIn, coinOut],
            arguments: [
                // ours
                objectArg(tx, bbbSwap),
                objectArg(tx, bbbVault),
                // pyth
                objectArg(tx, pythInfoIn),
                objectArg(tx, pythInfoOut),
                // aftermath
                objectArg(tx, afPool.id),
                objectArg(tx, afPoolRegistry),
                objectArg(tx, afProtocolFeeVault),
                objectArg(tx, afTreasury),
                objectArg(tx, afInsuranceFund),
                objectArg(tx, afReferralVault),
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
        adminCapObj: ObjectInput;
        coinType: string;
    }): TransactionResult => {
        return tx.moveCall({
            target: `${packageId}::bbb_burn::new`,
            typeArguments: [coinType],
            arguments: [objectArg(tx, adminCapObj)],
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
        configObj: ObjectInput;
        adminCapObj: ObjectInput;
        afSwapObj: ObjectInput;
    }): TransactionResult => {
        return tx.moveCall({
            target: `${packageId}::bbb_config::add_aftermath_swap`,
            arguments: [
                objectArg(tx, configObj),
                objectArg(tx, adminCapObj),
                objectArg(tx, afSwapObj),
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
        configObj: ObjectInput;
        adminCapObj: ObjectInput;
        burnObj: ObjectInput;
    }): TransactionResult => {
        return tx.moveCall({
            target: `${packageId}::bbb_config::add_burn_type`,
            arguments: [
                objectArg(tx, configObj),
                objectArg(tx, adminCapObj),
                objectArg(tx, burnObj),
            ],
        });
    },
} as const;
