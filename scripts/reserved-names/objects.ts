import { mainPackage } from "../config/constants";
import fs from "fs";

const config = mainPackage.mainnet;

const getAllOwnedDomains = async () => {

    let hasNextPage = true;
    let cursor = undefined;

    let names = [];

    while(hasNextPage){
        const res = await config.client.getOwnedObjects({
            owner: config.adminAddress,
            filter: {
                MatchAll: [
                    {
                        StructType: `0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0::suins_registration::SuinsRegistration`
                    },
                ],
            },
            options: {
                showContent: true,
                showType: true,
            },
            cursor
        });
        names.push(...res.data);
        hasNextPage = res.hasNextPage;

        cursor = res.nextCursor;

        console.log("Total names after batch: " + names.length);
    }

    // Save to file.
   fs.writeFileSync('./owned-objects.json', JSON.stringify(names));
}

getAllOwnedDomains();
