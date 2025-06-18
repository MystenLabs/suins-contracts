import { Command } from "commander";

import { cnf, af_swaps, newSuiClient } from "./config.js";
import { remove0x, signAndExecuteTx } from "./utils.js";
import { Transaction } from "@mysten/sui/transactions";

if (require.main === module) {
    const program = new Command();
    const client = newSuiClient();

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
            for (const swap of af_swaps) {
                tx.moveCall({
                    target: `${cnf.bbb.package}::bbb_aftermath_swap::new`,
                    typeArguments: [swap.coin_in.type, swap.coin_out.type, swap.pool.lp_type],
                    arguments: [
                        tx.object(cnf.bbb.adminCapObj),
                        tx.pure.u8(swap.coin_in.decimals),
                        tx.pure.u8(swap.coin_out.decimals),
                        tx.pure.string(remove0x(swap.coin_in.feed)),
                        tx.pure.string(remove0x(swap.coin_out.feed)),
                        tx.object(swap.pool.id),
                        tx.pure.u64(cnf.aftermath.default_slippage),
                        tx.pure.u64(cnf.pyth.default_max_age_secs),
                    ],
                });
            }
            const resp = await signAndExecuteTx({ tx, dryRun: true });
            // console.log(JSON.stringify(resp, null, 2));
            console.debug("tx status:", resp.effects?.status.status);
            console.debug("tx digest:", resp.digest);
        });

    program.parse();
}
