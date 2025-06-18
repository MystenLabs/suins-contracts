import { Command } from "commander";

import { cnf, newSuiClient } from "./config.js";

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

    program.parse();
}
