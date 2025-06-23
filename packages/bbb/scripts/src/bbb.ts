import { Transaction, type TransactionResult } from "@mysten/sui/transactions";
import { fromHex } from "@mysten/sui/utils";
import { Command } from "commander";
import {
    type AftermathPool,
    type AftermathSwap,
    af_swaps,
    cnf,
} from "./config.js";
import {
    getPriceInfoObject,
    newSuiClient,
    type ObjectInput,
    objectArg,
    signAndExecuteTx,
} from "./utils.js";

if (require.main === module) {
    const program = new Command();
    const client = newSuiClient();
    const packageId = cnf.bbb.package;
    const adminCapObj = cnf.bbb.adminCapObj;

    program
        .name("bbb")
        .description("Buy Back & Burn CLI tool")
        .version("1.0.0");

    program
        .command("get-config")
        .description("Fetch the BBBConfig object")
        .action(async () => {
            const config = await client.getObject({
                id: cnf.bbb.configObj,
                options: {
                    showContent: true,
                },
            });
            console.log(JSON.stringify(config, null, 2));
        });

    program
        .command("init") // TODO add burn config
        .description("Initialize the BBBConfig object (one-off)")
        .action(async () => {
            console.debug("initializing BBBConfig object...");
            const tx = new Transaction();
            burn_new({
                tx,
                packageId,
                adminCapObj,
                coinType: cnf.coins.NS.type,
            });
            for (const swap of af_swaps) {
                aftermath_swap_new({ tx, packageId, adminCapObj, swap });
            }
            const resp = await signAndExecuteTx({ tx, dryRun: true });
            console.debug("tx status:", resp.effects?.status.status);
            console.debug("tx digest:", resp.digest);
        });

    program
        .command("swap-and-burn")
        .description("Swap and burn coins")
        .action(async () => {
            console.debug("initiating swap and burn...");

            console.debug("fetching price info objects...");
            const tx = new Transaction();
            const [infoSui, infoNs] = await Promise.all([
                getPriceInfoObject(tx, cnf.coins.SUI.feed),
                getPriceInfoObject(tx, cnf.coins.NS.feed),
                // getPriceInfoObject(tx, cnf.coins.USDC.feed),
            ]);

            const swap_cnf = af_swaps[1]!; // TODO
            const swap_obj = aftermath_swap_new({
                tx,
                packageId,
                adminCapObj,
                swap: swap_cnf,
            });
            aftermath_swap_swap({
                tx,
                packageId,
                coinIn: swap_cnf.coin_in.type,
                coinOut: swap_cnf.coin_out.type,
                bbbSwap: swap_obj,
                bbbVault: cnf.bbb.vaultObj,
                pythInfoIn: infoSui[0]!, // TODO
                pythInfoOut: infoNs[0]!, // TODO
                afPool: swap_cnf.pool,
                afPoolRegistry: cnf.aftermath.poolRegistry,
                afProtocolFeeVault: cnf.aftermath.protocolFeeVault,
                afTreasury: cnf.aftermath.treasury,
                afInsuranceFund: cnf.aftermath.insuranceFund,
                afReferralVault: cnf.aftermath.referralVault,
            });
            const resp = await signAndExecuteTx({ tx, dryRun: true });
            console.debug("tx status:", resp.effects?.status.status);
            console.debug("tx digest:", resp.digest);
        });

    program.parse();
}

// === tx commands ===

function aftermath_swap_new({
    tx,
    packageId,
    adminCapObj,
    swap,
}: {
    tx: Transaction;
    packageId: string;
    adminCapObj: ObjectInput;
    swap: AftermathSwap;
}): TransactionResult {
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
}

function aftermath_swap_swap({
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
}): TransactionResult {
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
}

function burn_new({
    tx,
    packageId,
    adminCapObj,
    coinType,
}: {
    tx: Transaction;
    packageId: string;
    adminCapObj: ObjectInput;
    coinType: string;
}): TransactionResult {
    return tx.moveCall({
        target: `${packageId}::bbb_burn::new`,
        typeArguments: [coinType],
        arguments: [objectArg(tx, adminCapObj)],
    });
}
