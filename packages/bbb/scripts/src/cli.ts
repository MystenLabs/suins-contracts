import { Transaction } from "@mysten/sui/transactions";
import { Command } from "commander";
import { af_swaps, cnf } from "./config.js";
import { BBBConfigSchema } from "./schema/bbb_config.js";
import * as sdk from "./sdk.js";
import {
    getPriceInfoObject,
    newSuiClient,
    shortenAddress,
    signAndExecuteTx,
} from "./utils.js";

if (require.main === module) {
    const program = new Command();
    const client = newSuiClient();
    const packageId = cnf.bbb.packageId;
    const adminCapObj = cnf.bbb.adminCapObj;
    const bbbVaultObj = cnf.bbb.vaultObj;
    const bbbConfigObj = cnf.bbb.configObj;

    program
        .name("bbb")
        .description("Buy Back & Burn CLI tool")
        .version("1.0.0");

    program
        .command("get-config")
        .description("Fetch the BBBConfig object")
        .action(async () => {
            const resp = await client.getObject({
                id: bbbConfigObj,
                options: { showContent: true },
            });
            const obj = BBBConfigSchema.parse(resp);
            console.log(JSON.stringify(obj, null, 2));
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
                bbbConfigObj,
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
                    bbbConfigObj,
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
            console.debug("fetching price info objects...");
            const tx = new Transaction();

            const pythPriceInfoIds = await Promise.all(
                Object.values(cnf.coins).map(async (coin) => ({
                    coinType: coin.type,
                    priceInfo: await getPriceInfoObject(tx, coin.feed),
                })),
            );

            for (const swapCnf of af_swaps) {
                const pythInfoObjIn = pythPriceInfoIds.find(
                    (info) => info.coinType === swapCnf.coin_in.type,
                )?.priceInfo;
                if (!pythInfoObjIn) {
                    throw new Error(
                        `No Pyth PriceInfoObject found for ${swapCnf.coin_in.type}`,
                    );
                }
                const pythInfoObjOut = pythPriceInfoIds.find(
                    (info) => info.coinType === swapCnf.coin_out.type,
                )?.priceInfo;
                if (!pythInfoObjOut) {
                    throw new Error(
                        `No Pyth PriceInfoObject found for ${swapCnf.coin_out.type}`,
                    );
                }
                console.log(
                    "swapping ",
                    shortenAddress(swapCnf.coin_in.type).padEnd(24),
                    "for ",
                    shortenAddress(swapCnf.coin_out.type),
                );
                const afSwapObj = sdk.bbb_config.get_aftermath_swap({
                    tx,
                    packageId,
                    bbbConfigObj,
                    coinType: swapCnf.coin_in.type,
                });

                sdk.bbb_aftermath_swap.swap({
                    tx,
                    packageId,
                    // ours
                    coinInType: swapCnf.coin_in.type,
                    coinOutType: swapCnf.coin_out.type,
                    afSwapObj,
                    bbbVaultObj,
                    // pyth
                    pythInfoObjIn,
                    pythInfoObjOut,
                    // aftermath
                    afPoolType: swapCnf.pool.lp_type,
                    afPoolObj: swapCnf.pool.id,
                    afPoolRegistryObj: cnf.aftermath.poolRegistry,
                    afProtocolFeeVaultObj: cnf.aftermath.protocolFeeVault,
                    afTreasuryObj: cnf.aftermath.treasury,
                    afInsuranceFundObj: cnf.aftermath.insuranceFund,
                    afReferralVaultObj: cnf.aftermath.referralVault,
                });
            }

            const resp = await signAndExecuteTx({ tx, dryRun: true });
            console.debug("tx status:", resp.effects?.status.status);
            console.debug("tx digest:", resp.digest);
        });

    program.parse();
}
