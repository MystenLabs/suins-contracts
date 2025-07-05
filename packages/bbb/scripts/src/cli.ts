import { coinWithBalance, Transaction } from "@mysten/sui/transactions";
import { Command, Option } from "commander";
import { afSwaps, burnTypes, cetusSwaps, cnf } from "./config.js";
import { AftermathConfigSchema } from "./schema/aftermath_config.js";
import { AftermathSwapEventSchema } from "./schema/aftermath_swap.js";
import { BalanceDfSchema } from "./schema/balance_df.js";
import { BurnEventSchema } from "./schema/burn.js";
import { BurnConfigSchema } from "./schema/burn_config.js";
import { BBBVaultSchema } from "./schema/vault.js";
import * as sdk from "./sdk.js";
import {
    getPriceInfoObject,
    getSigner,
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
const _cetusConfigObj = cnf.bbb.cetusConfigObj;

// === CLI ===

program.name("bbb").description("Buy Back & Burn CLI tool").version("1.0.0");

program
    .command("config-new")
    .description("Create, configure, and share all config objects (one-off)")
    .action(async () => {
        const tx = new Transaction();
        // burns
        const newBurnConfigObj = sdk.bbb_burn_config.new({ tx, packageId, adminCapObj });
        for (const coinType of Object.values(burnTypes)) {
            const burnObj = sdk.bbb_burn.new({ tx, packageId, adminCapObj, coinType });
            sdk.bbb_burn_config.add({
                tx,
                packageId,
                burnConfigObj: newBurnConfigObj,
                adminCapObj,
                burnObj,
            });
        }
        sdk.bbb_burn_config.share({ tx, packageId, obj: newBurnConfigObj });
        // aftermath swaps
        const newAftermathConfigObj = sdk.bbb_aftermath_config.new({
            tx,
            packageId,
            adminCapObj,
        });
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
                aftermathConfigObj: newAftermathConfigObj,
                adminCapObj,
                afSwapObj: swapObj,
            });
        }
        sdk.bbb_aftermath_config.share({ tx, packageId, obj: newAftermathConfigObj });
        // cetus swaps
        const newCetusConfigObj = sdk.bbb_cetus_config.new({
            tx,
            packageId,
            adminCapObj,
        });
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
                cetusConfigObj: newCetusConfigObj,
                adminCapObj,
                cetusSwapObj: swapObj,
            });
        }
        sdk.bbb_cetus_config.share({ tx, packageId, obj: newCetusConfigObj });

        const resp = await signAndExecuteTx({ tx, dryRun });
        const createdObjs = resp.objectChanges?.filter(
            (change) => change.type === "created",
        );
        logJson({
            tx_status: resp.effects?.status.status,
            tx_digest: resp.digest,
            createdObjs: createdObjs?.map((obj) => ({
                objectType: obj.objectType,
                objectId: obj.objectId,
                owner: obj.owner,
            })),
        });
    });

program
    .command("get-config")
    .description("Fetch the config objects")
    .action(async () => {
        const [burnConfigResp, aftermathConfigResp] = await Promise.all([
            client.getObject({
                id: burnConfigObj,
                options: { showContent: true },
            }),
            client.getObject({
                id: aftermathConfigObj,
                options: { showContent: true },
            }),
        ]);

        const burnConfig = BurnConfigSchema.parse(burnConfigResp.data);
        const aftermathConfig = AftermathConfigSchema.parse(aftermathConfigResp.data);

        logJson({
            burnConfig,
            aftermathConfig,
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
    .command("remove-burn")
    .description("Remove a burn coin type from the BBBConfig object")
    .addOption(
        new Option("-c, --coin-ticker <coin-ticker>", "coin ticker")
            .choices(Object.keys(burnTypes))
            .makeOptionMandatory(),
    )
    .action(async ({ coinTicker }: { coinTicker: keyof typeof burnTypes }) => {
        const tx = new Transaction();
        sdk.bbb_burn_config.remove({
            tx,
            packageId,
            burnConfigObj,
            adminCapObj,
            coinType: burnTypes[coinTicker],
        });
        const resp = await signAndExecuteTx({ tx, dryRun });
        logTxResp(resp);
    });

program
    .command("remove-swap")
    .description("Remove an Aftermath swap config from the BBBConfig object")
    .addOption(
        new Option("-c, --coin-ticker <coin-ticker>", "coin ticker")
            .choices(Object.keys(afSwaps))
            .makeOptionMandatory(),
    )
    .action(async ({ coinTicker }: { coinTicker: keyof typeof afSwaps }) => {
        const tx = new Transaction();
        sdk.bbb_aftermath_config.remove({
            tx,
            packageId,
            aftermathConfigObj,
            adminCapObj,
            coinInType: afSwaps[coinTicker].coinIn.type,
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
                priceInfo: await getPriceInfoObject(tx, coin.pyth_feed),
            })),
        );
        for (const afSwap of Object.values(afSwaps)) {
            const pythInfoObjIn = pythPriceInfoIds.find(
                (info) => info.coinType === afSwap.coinIn.type,
            )?.priceInfo;
            if (!pythInfoObjIn) {
                throw new Error(`PriceInfoObject not found for ${afSwap.coinIn.type}`);
            }
            const pythInfoObjOut = pythPriceInfoIds.find(
                (info) => info.coinType === afSwap.coinOut.type,
            )?.priceInfo;
            if (!pythInfoObjOut) {
                throw new Error(`PriceInfoObject not found for ${afSwap.coinOut.type}`);
            }

            const afSwapObj = sdk.bbb_aftermath_config.get({
                tx,
                packageId,
                aftermathConfigObj,
                coinType: afSwap.coinIn.type,
            });

            sdk.bbb_aftermath_swap.swap({
                tx,
                packageId,
                // ours
                coinInType: afSwap.coinIn.type,
                coinOutType: afSwap.coinOut.type,
                afSwapObj,
                bbbVaultObj,
                // pyth
                pythInfoObjIn,
                pythInfoObjOut,
                // aftermath
                afPoolType: afSwap.pool.lpType,
                afPoolObj: afSwap.pool.id,
                afPoolRegistryObj: cnf.aftermath.poolRegistry,
                afProtocolFeeVaultObj: cnf.aftermath.protocolFeeVault,
                afTreasuryObj: cnf.aftermath.treasury,
                afInsuranceFundObj: cnf.aftermath.insuranceFund,
                afReferralVaultObj: cnf.aftermath.referralVault,
            });
        }

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

        const burnEvents = resp.events
            ?.filter((e) => e.type.endsWith("::bbb_burn::BurnEvent"))
            .map((e) => BurnEventSchema.parse(e).parsedJson);
        const swapEvents = resp.events
            ?.filter((e) => e.type.endsWith("::bbb_aftermath_swap::AftermathSwapEvent"))
            .map((e) => AftermathSwapEventSchema.parse(e).parsedJson);
        logJson({
            time: new Date().toISOString(),
            tx_status: resp.effects?.status.status,
            tx_digest: resp.digest,
            swaps: swapEvents,
            burns: burnEvents,
        });
    });

program
    .command("cetus-demo")
    .description("Cetus swap demo")
    .action(async () => {
        const tx = new Transaction();
        const demoPkgId =
            "0x5b065e17dcd53c5eb2d1b6e902da2f65bb4be367c8afadeee4ebc649abb84a4d";
        const a2b: boolean = true;
        const ZERO_POINT_ONE_USDC = 1_000_000n / 10n;
        const ZERO_POINT_ONE_SUI = 1_000_000_000n / 10n;
        const coinIn = coinWithBalance({
            balance: a2b ? ZERO_POINT_ONE_USDC : ZERO_POINT_ONE_SUI,
            type: a2b ? cnf.coins.USDC.type : cnf.coins.SUI.type,
        });
        const coin = tx.moveCall({
            target: `${demoPkgId}::cetus_swap::swap_${a2b ? "a2b" : "b2a"}`,
            typeArguments: [cnf.coins.USDC.type, cnf.coins.SUI.type],
            arguments: [
                tx.object(cnf.cetus.globalConfigObjId),
                tx.object(cnf.cetus.pools.usdc_sui.id),
                coinIn,
                tx.object.clock(),
            ],
        });
        tx.transferObjects([coin], getSigner().toSuiAddress());
        const resp = await signAndExecuteTx({ tx, dryRun });
        logTxResp(resp);
    });

program.parse();
