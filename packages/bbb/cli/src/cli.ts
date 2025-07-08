import type { SuiTransactionBlockResponse } from "@mysten/sui/client";
import { coinWithBalance, Transaction } from "@mysten/sui/transactions";
import { Command, Option } from "commander";
import { cnf } from "./config.js";
import { AftermathRegistrySchema } from "./schema/aftermath_registry.js";
import { AftermathSwapEventSchema } from "./schema/aftermath_swap.js";
import { BalanceDynamicFieldSchema } from "./schema/balance_df.js";
import { BurnEventSchema } from "./schema/burn.js";
import { BurnRegistrySchema } from "./schema/burn_registry.js";
import { CetusRegistrySchema } from "./schema/cetus_registry.js";
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
const packageId = cnf.ids.bbb.package;
const adminCapObj = cnf.ids.bbb.adminCapObj;
const bbbVaultObj = cnf.ids.bbb.vaultObj;
const burnRegistryObj = cnf.ids.bbb.burnRegistryObj;
const aftermathRegistryObj = cnf.ids.bbb.aftermathRegistryObj;
const cetusRegistryObj = cnf.ids.bbb.cetusRegistryObj;

// === CLI ===

program.name("bbb").description("Buy Back & Burn CLI tool").version("1.0.0");

program
    .command("sync-config")
    .description("Update onchain config according to config.ts")
    .action(async () => {
        const tx = new Transaction();
        // burns
        sdk.bbb_burn_registry.remove_all({ tx, packageId, adminCapObj, burnRegistryObj });
        for (const coinType of Object.values(cnf.burnTypes)) {
            const burnObj = sdk.bbb_burn.new({ tx, packageId, adminCapObj, coinType });
            sdk.bbb_burn_registry.add({
                tx,
                packageId,
                burnRegistryObj,
                adminCapObj,
                burnObj,
            });
        }
        // aftermath swaps
        sdk.bbb_aftermath_registry.remove_all({
            tx,
            packageId,
            adminCapObj,
            aftermathRegistryObj,
        });
        for (const swap of Object.values(cnf.afSwaps)) {
            const swapObj = sdk.bbb_aftermath_swap.new({
                tx,
                packageId,
                adminCapObj,
                coinIn: swap.coinIn,
                coinOut: swap.coinOut,
                pool: swap.pool,
                slippage: cnf.defaultSlippage,
                maxAgeSecs: cnf.defaultMaxAgeSecs,
            });
            sdk.bbb_aftermath_registry.add({
                tx,
                packageId,
                aftermathRegistryObj,
                adminCapObj,
                afSwapObj: swapObj,
            });
        }
        // cetus swaps
        sdk.bbb_cetus_registry.remove_all({
            tx,
            packageId,
            adminCapObj,
            cetusRegistryObj,
        });
        for (const swap of Object.values(cnf.cetusSwaps)) {
            const swapObj = sdk.bbb_cetus_swap.new({
                tx,
                packageId,
                coinAType: swap.coinA.type,
                coinBType: swap.coinB.type,
                a2b: swap.a2b,
                decimalsA: swap.coinA.decimals,
                decimalsB: swap.coinB.decimals,
                feedA: swap.coinA.pythFeed,
                feedB: swap.coinB.pythFeed,
                pool: swap.pool,
                slippage: cnf.defaultSlippage,
                maxAgeSecs: cnf.defaultMaxAgeSecs,
                adminCapObj,
            });
            sdk.bbb_cetus_registry.add({
                tx,
                packageId,
                cetusRegistryObj,
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
        const [burnResp, afResp, cetusResp] = await Promise.all([
            client.getObject({
                id: burnRegistryObj,
                options: { showContent: true },
            }),
            client.getObject({
                id: aftermathRegistryObj,
                options: { showContent: true },
            }),
            client.getObject({
                id: cetusRegistryObj,
                options: { showContent: true },
            }),
        ]);

        const burnRegistry = BurnRegistrySchema.parse(burnResp.data);
        const aftermathRegistry = AftermathRegistrySchema.parse(afResp.data);
        const cetusRegistry = CetusRegistrySchema.parse(cetusResp.data);

        logJson({
            burnRegistry: burnRegistry.content.fields,
            aftermathRegistry: aftermathRegistry.content.fields,
            cetusRegistry: cetusRegistry.content.fields,
        });
    });

program
    .command("get-balances")
    .description("Fetch the coin balances in the BBBVault")
    .action(async () => {
        const balances = await getBalances();
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
        // check if any of the minimum balances are met
        const balances = await getBalances();
        const hasMinimumBalance = Object.entries(cnf.minimumBalances).some(
            ([ticker, minBalance]) => {
                const balance = balances.find((bal) => bal.ticker === ticker)?.balance;
                return balance && BigInt(balance) >= minBalance;
            },
        );
        if (!hasMinimumBalance) {
            logJson({
                time: new Date().toISOString(),
                info: "Minimum balances not met",
                balances,
            });
            process.exit(0);
        }

        // get all Pyth price info objects
        const tx = new Transaction();
        const pythPriceInfoIds = await Promise.all(
            Object.values(cnf.coins).map(async (coin) => ({
                coinType: coin.type,
                priceInfo: await getPriceInfoObject(tx, coin.pythFeed),
            })),
        ).catch((err) => {
            logJson({
                time: new Date().toISOString(),
                error: "Failed to fetch price info objects",
                detail: err instanceof Error ? err.message : String(err),
            });
            process.exit(1);
        });

        // helpers

        const findPriceInfoOrExit = (coinType: string): string => {
            const pythInfoObj = pythPriceInfoIds.find(
                (info) => info.coinType === coinType,
            )?.priceInfo;
            if (!pythInfoObj) {
                // should never happen unless config.ts is misconfigured
                logJson({
                    time: new Date().toISOString(),
                    error: `PriceInfoObject not found for ${coinType}`,
                });
                process.exit(1);
            }
            return pythInfoObj;
        };

        const swapAftermath = (tx: Transaction): void => {
            for (const swap of Object.values(cnf.afSwaps)) {
                const pythInfoObjIn = findPriceInfoOrExit(swap.coinIn.type);
                const pythInfoObjOut = findPriceInfoOrExit(swap.coinOut.type);

                const afSwapObj = sdk.bbb_aftermath_registry.get({
                    tx,
                    packageId,
                    aftermathRegistryObj,
                    coinInType: swap.coinIn.type,
                    coinOutType: swap.coinOut.type,
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
                    afPoolRegistryObj: cnf.ids.aftermath.poolRegistry,
                    afProtocolFeeVaultObj: cnf.ids.aftermath.protocolFeeVault,
                    afTreasuryObj: cnf.ids.aftermath.treasury,
                    afInsuranceFundObj: cnf.ids.aftermath.insuranceFund,
                    afReferralVaultObj: cnf.ids.aftermath.referralVault,
                });
            }
        };

        const swapCetus = (tx: Transaction): void => {
            for (const swap of Object.values(cnf.cetusSwaps)) {
                const pythInfoObjA = findPriceInfoOrExit(swap.coinA.type);
                const pythInfoObjB = findPriceInfoOrExit(swap.coinB.type);

                const cetusSwapObj = sdk.bbb_cetus_registry.get({
                    tx,
                    packageId,
                    cetusRegistryObj,
                    coinInType: swap.a2b ? swap.coinA.type : swap.coinB.type,
                    coinOutType: swap.a2b ? swap.coinB.type : swap.coinA.type,
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
                    cetusRegistryObj: cnf.ids.cetus.globalConfigObjId,
                    cetusPoolObj: swap.pool.id,
                });
            }
        };

        const burn = (tx: Transaction) => {
            for (const coinType of Object.values(cnf.burnTypes)) {
                const burnObj = sdk.bbb_burn_registry.get({
                    tx,
                    packageId,
                    burnRegistryObj,
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
        };

        const devInspectSwapAndBurn = async (swapFn: (tx: Transaction) => void) => {
            try {
                const tx = new Transaction();
                swapFn(tx);
                burn(tx);
                const dryRunResp = await signAndExecuteTx({ tx, dryRun: true });
                return { resp: dryRunResp, error: null };
            } catch (err) {
                return {
                    resp: null,
                    error: err instanceof Error ? err.message : String(err),
                };
            }
        };

        // find most profitable swap route by checking how much NS is burned

        const swapFns = [swapAftermath, swapCetus];

        const dryRuns = await Promise.all(
            swapFns.map(async (swapFn) => ({
                swapFn,
                dryRun: await devInspectSwapAndBurn(swapFn),
            })),
        );

        const successfulRuns = dryRuns
            .filter((run) => !run.dryRun.error)
            .map((run) => ({
                swapFn: run.swapFn,
                burnedNS: extractBurnedNS(run.dryRun.resp!),
            }));

        const mostProfitable =
            successfulRuns.length === 0
                ? null
                : successfulRuns.reduce((best, current) =>
                      current.burnedNS > best.burnedNS ? current : best,
                  );

        if (!mostProfitable) {
            logJson({
                time: new Date().toISOString(),
                error: "All swap routes failed",
                routeErrors: dryRuns.map((run) => ({
                    swapFn: run.swapFn.name,
                    error: run.dryRun.error,
                })),
            });
            process.exit(1);
        }

        // swap and burn

        mostProfitable.swapFn(tx);
        burn(tx);

        // execute tx

        try {
            const resp = await signAndExecuteTx({ tx, dryRun });
            logJson({
                time: new Date().toISOString(),
                tx_status: resp.effects?.status.status,
                tx_digest: resp.digest,
                afSwaps: extractAfSwapEvents(resp),
                cetusSwaps: extractCetusSwapEvents(resp),
                burns: extractBurnEvents(resp),
            });
        } catch (err) {
            logJson({
                time: new Date().toISOString(),
                error: "Failed to execute tx",
                detail: err instanceof Error ? err.message : String(err),
            });
        }
    });

program.parse();

// === helpers ===

function extractAfSwapEvents(resp: SuiTransactionBlockResponse) {
    return (resp.events ?? [])
        .filter((e) => e.type.endsWith("::bbb_aftermath_swap::AftermathSwapEvent"))
        .map((e) => AftermathSwapEventSchema.parse(e).parsedJson);
}

function extractCetusSwapEvents(resp: SuiTransactionBlockResponse) {
    return (resp.events ?? [])
        .filter((e) => e.type.endsWith("::bbb_cetus_swap::CetusSwapEvent"))
        .map((e) => CetusSwapEventSchema.parse(e).parsedJson);
}

function extractBurnEvents(resp: SuiTransactionBlockResponse) {
    return (resp.events ?? [])
        .filter((e) => e.type.endsWith("::bbb_burn::BurnEvent"))
        .map((e) => BurnEventSchema.parse(e).parsedJson);
}

function extractBurnedNS(resp: SuiTransactionBlockResponse): bigint {
    return extractBurnEvents(resp).reduce((acc, e) => acc + BigInt(e.amount), 0n);
}

async function getBalances() {
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
        BalanceDynamicFieldSchema.parse(resp.data),
    );
    return balanceDfObjs.map((bal) => ({
        ticker: bal.content.fields.name.fields.name.split("::")[2] ?? "UNKNOWN",
        balance: bal.content.fields.value,
    }));
}
