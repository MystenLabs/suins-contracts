import { coinWithBalance, Transaction } from "@mysten/sui/transactions";
import { Command, Option } from "commander";
import { afSwaps, cnf } from "./config.js";
import { BalanceDfSchema } from "./schema/balance_df.js";
import { BBBConfigSchema } from "./schema/bbb_config.js";
import { BBBVaultSchema } from "./schema/bbb_vault.js";
import { BurnedEventSchema } from "./schema/burned_event.js";
import { SwappedEventSchema } from "./schema/swapped_event.js";
import * as sdk from "./sdk.js";
import {
    getPriceInfoObject,
    logJson,
    logTxResp,
    newSuiClient,
    signAndExecuteTx,
} from "./utils.js";

// === constants ===

const dryRun = true;

const program = new Command();
const client = newSuiClient();
const packageId = cnf.bbb.packageId;
const adminCapObj = cnf.bbb.adminCapObj;
const bbbVaultObj = cnf.bbb.vaultObj;
const bbbConfigObj = cnf.bbb.configObj;

// === CLI ===

program.name("bbb").description("Buy Back & Burn CLI tool").version("1.0.0");

program
    .command("init")
    .description("Initialize the BBBConfig object (one-off)")
    .action(async () => {
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
        for (const swap of afSwaps) {
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
        const resp = await signAndExecuteTx({ tx, dryRun });
        logTxResp(resp);
    });

program
    .command("get-config")
    .description("Fetch the BBBConfig object")
    .action(async () => {
        const objResp = await client.getObject({
            id: bbbConfigObj,
            options: { showContent: true },
        });
        const obj = BBBConfigSchema.parse(objResp.data);
        logJson(obj);
    });

program
    .command("get-balances")
    .description("Fetch the coin balances in the BBBVault")
    .action(async () => {
        const objResp = await client.getObject({
            id: bbbVaultObj,
            options: { showContent: true },
        });
        const vaultObj = BBBVaultSchema.parse(objResp.data);
        const dfPage = await client.getDynamicFields({
            parentId: vaultObj.content.fields.balances.fields.id.id,
        });
        const balanceDfResps = await client.multiGetObjects({
            ids: dfPage.data.map((df) => df.objectId),
            options: { showContent: true },
        });
        const balanceDfObjs = balanceDfResps.map((resp) =>
            BalanceDfSchema.parse(resp.data),
        );
        const balances = balanceDfObjs.map((bal) => {
            return {
                ticker: bal.content.fields.name.fields.name.split("::")[2],
                balance: bal.content.fields.value,
            };
        });
        logJson(balances);
    });

program
    .command("deposit")
    .description("Deposit coins into the BBBVault")
    .addOption(
        new Option("-c, --coin-ticker <coin-ticker>", "coin ticker")
            .choices(Object.keys(cnf.coins))
            .makeOptionMandatory(),
    )
    .requiredOption("-a, --amount <amount>", 'human-readable amount (0.1 SUI = "0.1")')
    .action(
        async ({
            coinTicker,
            amount,
        }: {
            coinTicker: keyof typeof cnf.coins;
            amount: string;
        }) => {
            const coinInfo = cnf.coins[coinTicker];
            const amountNum = parseFloat(amount);
            if (Number.isNaN(amountNum) || amountNum <= 0) {
                throw new Error(`Invalid amount: ${amount}. Must be a positive number.`);
            }

            const tx = new Transaction();
            const coinObj = coinWithBalance({
                balance: BigInt(Math.floor(amountNum * 10 ** coinInfo.decimals)),
                type: coinInfo.type,
            });
            sdk.bbb_vault.deposit({
                tx,
                packageId,
                coinType: coinInfo.type,
                bbbVaultObj,
                coinObj,
            });

            const resp = await signAndExecuteTx({ tx, dryRun });
            logTxResp(resp);
        },
    );

program
    .command("remove-burn")
    .description("Remove a burn coin type from the BBBConfig object")
    .addOption(
        new Option("-c, --coin-ticker <coin-ticker>", "coin ticker")
            .choices(Object.keys(cnf.coins))
            .makeOptionMandatory(),
    )
    .action(async ({ coinTicker }: { coinTicker: keyof typeof cnf.coins }) => {
        const tx = new Transaction();
        sdk.bbb_config.remove_burn_type({
            tx,
            packageId,
            bbbConfigObj,
            adminCapObj,
            coinType: cnf.coins[coinTicker].type,
        });
        const resp = await signAndExecuteTx({ tx, dryRun });
        logTxResp(resp);
    });

program
    .command("remove-swap")
    .description("Remove an Aftermath swap config from the BBBConfig object")
    .addOption(
        new Option("-c, --coin-ticker <coin-ticker>", "coin ticker")
            .choices(Object.keys(cnf.coins))
            .makeOptionMandatory(),
    )
    .action(async ({ coinTicker }: { coinTicker: keyof typeof cnf.coins }) => {
        const tx = new Transaction();
        sdk.bbb_config.remove_aftermath_swap({
            tx,
            packageId,
            bbbConfigObj,
            adminCapObj,
            coinInType: cnf.coins[coinTicker].type,
        });
        const resp = await signAndExecuteTx({ tx, dryRun });
        logTxResp(resp);
    });

program
    .command("swap-and-burn")
    .description("Swap and burn coins")
    .action(async () => {
        const tx = new Transaction();

        // swap

        const pythPriceInfoIds = await Promise.all(
            Object.values(cnf.coins).map(async (coin) => ({
                coinType: coin.type,
                priceInfo: await getPriceInfoObject(tx, coin.feed),
            })),
        );
        for (const afSwap of afSwaps) {
            const pythInfoObjIn = pythPriceInfoIds.find(
                (info) => info.coinType === afSwap.coin_in.type,
            )?.priceInfo;
            if (!pythInfoObjIn) {
                throw new Error(`PriceInfoObject not found for ${afSwap.coin_in.type}`);
            }
            const pythInfoObjOut = pythPriceInfoIds.find(
                (info) => info.coinType === afSwap.coin_out.type,
            )?.priceInfo;
            if (!pythInfoObjOut) {
                throw new Error(`PriceInfoObject not found for ${afSwap.coin_out.type}`);
            }
            const afSwapObj = sdk.bbb_config.get_aftermath_swap({
                tx,
                packageId,
                bbbConfigObj,
                coinType: afSwap.coin_in.type,
            });

            sdk.bbb_aftermath_swap.swap({
                tx,
                packageId,
                // ours
                coinInType: afSwap.coin_in.type,
                coinOutType: afSwap.coin_out.type,
                afSwapObj,
                bbbVaultObj,
                // pyth
                pythInfoObjIn,
                pythInfoObjOut,
                // aftermath
                afPoolType: afSwap.pool.lp_type,
                afPoolObj: afSwap.pool.id,
                afPoolRegistryObj: cnf.aftermath.poolRegistry,
                afProtocolFeeVaultObj: cnf.aftermath.protocolFeeVault,
                afTreasuryObj: cnf.aftermath.treasury,
                afInsuranceFundObj: cnf.aftermath.insuranceFund,
                afReferralVaultObj: cnf.aftermath.referralVault,
            });
        }

        // burn

        const burnObj = sdk.bbb_config.get_burn({
            tx,
            packageId,
            bbbConfigObj,
            coinType: cnf.coins.NS.type,
        });
        sdk.bbb_burn.burn({
            tx,
            packageId,
            coinType: cnf.coins.NS.type,
            burnObj,
            bbbVaultObj,
        });

        // logging

        const resp = await signAndExecuteTx({ tx, dryRun });
        const burnEvents = resp.events
            ?.filter((e) => e.type.endsWith("::bbb_burn::Burned"))
            .map((e) => BurnedEventSchema.parse(e).parsedJson);
        const swapEvents = resp.events
            ?.filter((e) => e.type.endsWith("::bbb_aftermath_swap::Swapped"))
            .map((e) => SwappedEventSchema.parse(e).parsedJson);
        logJson({
            time: new Date().toISOString(),
            tx_status: resp.effects?.status.status,
            tx_digest: resp.digest,
            swaps: swapEvents,
            burns: burnEvents,
        });
    });

program.parse();
