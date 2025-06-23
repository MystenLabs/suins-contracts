import { coinWithBalance, Transaction } from "@mysten/sui/transactions";
import { Command, Option } from "commander";
import { afSwaps, cnf } from "./config.js";
import { BBBConfigSchema } from "./schema/bbb_config.js";
import * as sdk from "./sdk.js";
import {
    getPriceInfoObject,
    newSuiClient,
    shortenAddress,
    signAndExecuteTx,
} from "./utils.js";

// === constants ===

const program = new Command();
const client = newSuiClient();
const packageId = cnf.bbb.packageId;
const adminCapObj = cnf.bbb.adminCapObj;
const bbbVaultObj = cnf.bbb.vaultObj;
const bbbConfigObj = cnf.bbb.configObj;

// === CLI ===

program.name("bbb").description("Buy Back & Burn CLI tool").version("1.0.0");
program
    .command("get-config")
    .description("Fetch the BBBConfig object")
    .action(cmdGetConfig);
program
    .command("init")
    .description("Initialize the BBBConfig object (one-off)")
    .action(cmdInit);
program
    .command("deposit")
    .description("Deposit coins into the BBBVault")
    .addOption(
        new Option("-c, --coin-ticker <coin-ticker>", "coin ticker")
            .choices(Object.keys(cnf.coins))
            .makeOptionMandatory(),
    )
    .requiredOption("-a, --amount <amount>", 'human-readable amount (0.1 SUI = "0.1")')
    .action(cmdDeposit);
program
    .command("swap-and-burn")
    .description("Swap and burn coins")
    .action(cmdSwapAndBurn);

program.parse();

// === commands ===

async function cmdGetConfig() {
    const resp = await client.getObject({
        id: bbbConfigObj,
        options: { showContent: true },
    });
    const obj = BBBConfigSchema.parse(resp);
    console.log(JSON.stringify(obj, null, 2));
}

async function cmdInit() {
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
    const resp = await signAndExecuteTx({ tx, dryRun: true });
    console.debug("tx status:", resp.effects?.status.status);
    console.debug("tx digest:", resp.digest);
}

async function cmdDeposit({
    coinTicker,
    amount,
}: {
    coinTicker: keyof typeof cnf.coins;
    amount: string;
}) {
    const coinInfo = cnf.coins[coinTicker];

    const amountNum = parseFloat(amount);
    if (isNaN(amountNum) || amountNum <= 0) {
        throw new Error(`Invalid amount: ${amount}. Must be a positive number.`);
    }

    console.log(`depositing ${amount} ${coinTicker} into BBBVault...`);

    const tx = new Transaction();
    const coinObj = coinWithBalance({
        balance: BigInt(Math.floor(amountNum * 10**coinInfo.decimals)),
        type: coinInfo.type,
    });

    sdk.bbb_vault.deposit({
        tx,
        packageId,
        coinType: coinInfo.type,
        bbbVaultObj,
        coinObj,
    });
    const resp = await signAndExecuteTx({ tx, dryRun: true });
    console.debug("tx status:", resp.effects?.status.status);
    console.debug("tx digest:", resp.digest);
}

async function cmdSwapAndBurn() {
    const tx = new Transaction();

    console.debug("fetching price info objects...");
    const pythPriceInfoIds = await Promise.all(
        Object.values(cnf.coins).map(async (coin) => ({
            coinType: coin.type,
            priceInfo: await getPriceInfoObject(tx, coin.feed),
        })),
    );

    for (const afSwap of afSwaps) {
        console.log(
            `swapping  ${shortenAddress(afSwap.coin_in.type).padEnd(24)} for` +
                `  ${shortenAddress(afSwap.coin_out.type).padEnd(24)}`,
        );
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

    const resp = await signAndExecuteTx({ tx, dryRun: true });
    console.debug("tx status:", resp.effects?.status.status);
    console.debug("tx digest:", resp.digest);
}
