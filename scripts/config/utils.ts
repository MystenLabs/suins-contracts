// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import dotenv from "dotenv";
dotenv.config();
import fs from "fs";


/* Read and Replace an ENV Variable, for ease of use of the contracts. */
export const readEnvAndReplaceKey = (key: string, value: string) => {

    let keyExisted = false;
    const env = fs.readFileSync('.env').toString().split('\n').filter(x => !!x).map(x => x.split('='));

    for (let item of env) {
        if (item[0] === key) {
            item[1] = value;
            keyExisted = true;
        }
    }

    if (!keyExisted) {
        env.push([key, value])
    }

    const new_env = env.map(x => x.join('=')).join('\n')

    fs.writeFileSync('.env', new_env)
}
