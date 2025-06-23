import { Transaction } from "@mysten/sui/transactions";
import { Command } from "commander";
import { af_swaps, cnf } from "./config.js";
import * as sdk from "./sdk.js";
import { getPriceInfoObject, newSuiClient, signAndExecuteTx } from "./utils.js";

if (require.main === module) {
    const program = new Command();
    const client = newSuiClient();
    const packageId = cnf.bbb.packageId;
    const adminCapObj = cnf.bbb.adminCapObj;
    const bbbVault = cnf.bbb.vaultObj;
    const configObj = cnf.bbb.configObj;

    program
        .name("bbb")
        .description("Buy Back & Burn CLI tool")
        .version("1.0.0");

    program
        .command("get-config")
        .description("Fetch the BBBConfig object")
        .action(async () => {
            const config = await client.getObject({
                id: configObj,
                options: {
                    showContent: true,
                },
            });
            console.log(JSON.stringify(config, null, 2));
        });

    program
        .command("init")
        .description("Initialize the BBBConfig object (one-off)")
        .action(async () => {
            console.debug("initializing BBBConfig object...");
            const tx = new Transaction();
            // add NS burn config
            const burnObj = sdk.bbb_burn.new({
                tx,
                packageId,
                adminCapObj,
                coinType: cnf.coins.NS.type,
            });
            sdk.bbb_config.add_burn_type({
                tx,
                packageId,
                configObj,
                adminCapObj,
                burnObj,
            });
            // add swap configs
            for (const swap of af_swaps) {
                const swapObj = sdk.bbb_aftermath_swap.new({
                    tx,
                    packageId,
                    adminCapObj,
                    swap,
                });
                sdk.bbb_config.add_aftermath_swap({
                    tx,
                    packageId,
                    configObj,
                    adminCapObj,
                    afSwapObj: swapObj,
                });
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
            const swap_obj = sdk.bbb_aftermath_swap.new({
                tx,
                packageId,
                adminCapObj,
                swap: swap_cnf,
            });
            sdk.bbb_aftermath_swap.swap({
                tx,
                packageId,
                coinIn: swap_cnf.coin_in.type,
                coinOut: swap_cnf.coin_out.type,
                bbbSwap: swap_obj,
                bbbVault,
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
