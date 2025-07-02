import { toHex } from "@mysten/sui/utils";
import { z } from "zod/v4";

export const BBBBurnConfigSchema = z.object({
    objectId: z.string(),
    version: z.string(),
    digest: z.string(),
    content: z.object({
        dataType: z.string(),
        type: z.string(),
        hasPublicTransfer: z.boolean(),
        fields: z.object({
            burns: z.array(
                z.object({
                    type: z.string(),
                    fields: z.object({
                        coin_type: z.object({
                            type: z.string(),
                            fields: z.object({ name: z.string() }),
                        }),
                    }),
                }),
            ),
            id: z.object({ id: z.string() }),
        }),
    }),
});
