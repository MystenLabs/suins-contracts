import type { SuiTransactionBlockResponse } from "@mysten/sui/client";
import { coinWithBalance, Transaction } from "@mysten/sui/transactions";
import { Command, Option } from "commander";
import { afSwaps, burnTypes, cetusSwaps, cnf } from "./config.js";
import { AftermathConfigSchema } from "./schema/aftermath_config.js";
import { AftermathSwapEventSchema } from "./schema/aftermath_swap.js";
import { BalanceDfSchema } from "./schema/balance_df.js";
import { BurnEventSchema } from "./schema/burn.js";
import { BurnConfigSchema } from "./schema/burn_config.js";
import { CetusConfigSchema } from "./schema/cetus_config.js";
import { CetusSwapEventSchema } from "./schema/cetus_swap.js";
import { BBBVaultSchema } from "./schema/vault.js";
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
const packageId = cnf.bbb.package;
const adminCapObj = cnf.bbb.adminCapObj;
const bbbVaultObj = cnf.bbb.vaultObj;
const burnConfigObj = cnf.bbb.burnConfigObj;
const aftermathConfigObj = cnf.bbb.aftermathConfigObj;
const cetusConfigObj = cnf.bbb.cetusConfigObj;

// === CLI ===

program.name("bbb").description("Buy Back & Burn CLI tool").version("1.0.0");

program
    .command("init") // TODO: allow this to be run multiple times with remove_all
    .description("Initialize the config objects (one-off)")
    .action(async () => {
        const tx = new Transaction();
        // burns
        for (const coinType of Object.values(burnTypes)) {
            const burnObj = sdk.bbb_burn.new({ tx, packageId, adminCapObj, coinType });
            sdk.bbb_burn_config.add({
                tx,
                packageId,
                burnConfigObj,
                adminCapObj,
                burnObj,
            });
        }
        // aftermath swaps
        for (const swap of Object.values(afSwaps)) {
            const swapObj = sdk.bbb_aftermath_swap.new({
                tx,
                packageId,
                adminCapObj,
                coinIn: swap.coinIn,
                coinOut: swap.coinOut,
                pool: swap.pool,
                slippage: swap.slippage,
                maxAgeSecs: swap.maxAgeSecs,
            });
            sdk.bbb_aftermath_config.add({
                tx,
                packageId,
                aftermathConfigObj,
                adminCapObj,
                afSwapObj: swapObj,
            });
        }
        // cetus swaps
        for (const swap of Object.values(cetusSwaps)) {
            const swapObj = sdk.bbb_cetus_swap.new({
                tx,
                packageId,
                coinAType: swap.coinA.type,
                coinBType: swap.coinB.type,
                a2b: swap.a2b,
                decimalsA: swap.coinA.decimals,
                decimalsB: swap.coinB.decimals,
                feedA: swap.coinA.pyth_feed,
                feedB: swap.coinB.pyth_feed,
                pool: swap.pool,
                slippage: swap.slippage,
                maxAgeSecs: swap.maxAgeSecs,
                adminCapObj,
            });
            sdk.bbb_cetus_config.add({
                tx,
                packageId,
                cetusConfigObj,
                adminCapObj,
                cetusSwapObj: swapObj,
            });
        }

        const resp = await signAndExecuteTx({ tx, dryRun });
        const createdObjs = resp.objectChanges?.filter(
            (change) => change.type === "created",
        );
        logJson({
            tx_status: resp.effects?.status.status,
            tx_digest: resp.digest,
            createdObjs: createdObjs?.map((obj) => ({
                type: obj.objectType,
                id: obj.objectId,
            })),
        });
    });

program
    .command("get-config")
    .description("Fetch the config objects")
    .action(async () => {
        const [burnConfigResp, aftermathConfigResp, cetusConfigResp] = await Promise.all([
            client.getObject({
                id: burnConfigObj,
                options: { showContent: true },
            }),
            client.getObject({
                id: aftermathConfigObj,
                options: { showContent: true },
            }),
            client.getObject({
                id: cetusConfigObj,
                options: { showContent: true },
            }),
        ]);

        const burnConfig = BurnConfigSchema.parse(burnConfigResp.data);
        const aftermathConfig = AftermathConfigSchema.parse(aftermathConfigResp.data);
        const cetusConfig = CetusConfigSchema.parse(cetusConfigResp.data);

        logJson({
            burnConfig: burnConfig.content.fields,
            aftermathConfig: aftermathConfig.content.fields,
            cetusConfig: cetusConfig.content.fields,
        });
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
    .command("swap-and-burn")
    .description("Swap and burn coins")
    .action(async () => {
        const tx = new Transaction();

        const pythPriceInfoIds = await Promise.all(
            Object.values(cnf.coins).map(async (coin) => ({
                coinType: coin.type,
                priceInfo: await getPriceInfoObject(tx, coin.pyth_feed),
            })),
        ).catch((err) => {
            logJson({
                error: "Failed to fetch price info objects",
                message: err.message,
            });
            process.exit(1);
        });

        const swapAf = (tx: Transaction) => {
            for (const swap of Object.values(afSwaps)) {
                const pythInfoObjIn = pythPriceInfoIds.find(
                    (info) => info.coinType === swap.coinIn.type,
                )?.priceInfo;
                if (!pythInfoObjIn) {
                    throw new Error(`PriceInfoObject not found for ${swap.coinIn.type}`);
                }

                const pythInfoObjOut = pythPriceInfoIds.find(
                    (info) => info.coinType === swap.coinOut.type,
                )?.priceInfo;
                if (!pythInfoObjOut) {
                    throw new Error(`PriceInfoObject not found for ${swap.coinOut.type}`);
                }

                const afSwapObj = sdk.bbb_aftermath_config.get({
                    tx,
                    packageId,
                    aftermathConfigObj,
                    coinType: swap.coinIn.type,
                });

                sdk.bbb_aftermath_swap.swap({
                    tx,
                    packageId,
                    // ours
                    coinInType: swap.coinIn.type,
                    coinOutType: swap.coinOut.type,
                    afSwapObj,
                    bbbVaultObj,
                    // pyth
                    pythInfoObjIn,
                    pythInfoObjOut,
                    // aftermath
                    afPoolType: swap.pool.lpType,
                    afPoolObj: swap.pool.id,
                    afPoolRegistryObj: cnf.aftermath.poolRegistry,
                    afProtocolFeeVaultObj: cnf.aftermath.protocolFeeVault,
                    afTreasuryObj: cnf.aftermath.treasury,
                    afInsuranceFundObj: cnf.aftermath.insuranceFund,
                    afReferralVaultObj: cnf.aftermath.referralVault,
                });
            }
        };

        const swapCetus = (tx: Transaction) => {
            for (const swap of Object.values(cetusSwaps)) {
                const pythInfoObjA = pythPriceInfoIds.find(
                    (info) => info.coinType === swap.coinA.type,
                )?.priceInfo;
                if (!pythInfoObjA) {
                    throw new Error(`PriceInfoObject not found for ${swap.coinA.type}`);
                }

                const pythInfoObjB = pythPriceInfoIds.find(
                    (info) => info.coinType === swap.coinB.type,
                )?.priceInfo;
                if (!pythInfoObjB) {
                    throw new Error(`PriceInfoObject not found for ${swap.coinB.type}`);
                }

                const cetusSwapObj = sdk.bbb_cetus_config.get({
                    tx,
                    packageId,
                    cetusConfigObj,
                    coinInType: swap.a2b ? swap.coinA.type : swap.coinB.type,
                });

                sdk.bbb_cetus_swap.swap({
                    tx,
                    packageId,
                    // ours
                    coinAType: swap.coinA.type,
                    coinBType: swap.coinB.type,
                    cetusSwapObj,
                    bbbVaultObj,
                    // pyth
                    pythInfoObjA,
                    pythInfoObjB,
                    // cetus
                    cetusConfigObj: cnf.cetus.globalConfigObjId,
                    cetusPoolObj: swap.pool.id,
                });
            }
        };

        // find most profitable route
        const afDryRunTx = new Transaction();
        swapAf(afDryRunTx);
        const afDryRunResp = await signAndExecuteTx({ tx: afDryRunTx, dryRun: true });

        const cetusDryRunTx = new Transaction();
        swapCetus(cetusDryRunTx);
        const cetusDryRunResp = await signAndExecuteTx({
            tx: cetusDryRunTx,
            dryRun: true,
        });

        logJson({
            afSwaps: extractAfSwapEvents(afDryRunResp),
            afGas: calculateGasUsed(afDryRunResp),
            cetusSwaps: extractCetusSwapEvents(cetusDryRunResp),
            cetusGas: calculateGasUsed(cetusDryRunResp),
        });

        return;

        // actual swaps

        swapAf(tx);
        swapCetus(tx);

        // burn

        for (const coinType of Object.values(burnTypes)) {
            const burnObj = sdk.bbb_burn_config.get({
                tx,
                packageId,
                burnConfigObj,
                coinType,
            });
            sdk.bbb_burn.burn({
                tx,
                packageId,
                coinType,
                burnObj,
                bbbVaultObj,
            });
        }

        const resp = await signAndExecuteTx({ tx, dryRun });

        // log

        logJson({
            time: new Date().toISOString(),
            tx_status: resp.effects?.status.status,
            tx_digest: resp.digest,
            afSwaps: extractAfSwapEvents(resp),
            cetusSwaps: extractCetusSwapEvents(resp),
            burns: extractBurnEvents(resp),
        });
    });

program.parse();

// === helpers ===

function extractAfSwapEvents(resp: SuiTransactionBlockResponse) {
    return resp.events
        ?.filter((e) => e.type.endsWith("::bbb_aftermath_swap::AftermathSwapEvent"))
        .map((e) => AftermathSwapEventSchema.parse(e).parsedJson);
}

function extractCetusSwapEvents(resp: SuiTransactionBlockResponse) {
    return resp.events
        ?.filter((e) => e.type.endsWith("::bbb_cetus_swap::CetusSwapEvent"))
        .map((e) => CetusSwapEventSchema.parse(e).parsedJson);
}

function extractBurnEvents(resp: SuiTransactionBlockResponse) {
    return resp.events
        ?.filter((e) => e.type.endsWith("::bbb_burn::BurnEvent"))
        .map((e) => BurnEventSchema.parse(e).parsedJson);
}

function calculateGasUsed(resp: SuiTransactionBlockResponse) {
    return (
        Number(resp.effects?.gasUsed.computationCost) +
        Number(resp.effects?.gasUsed.storageCost) -
        Number(resp.effects?.gasUsed.storageRebate)
    );
}
