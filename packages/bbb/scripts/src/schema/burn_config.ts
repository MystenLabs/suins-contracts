import { z } from "zod/v4";
import { BurnSchema } from "./burn.js";

export const BurnConfigSchema = z.object({
    objectId: z.string(),
    version: z.string(),
    digest: z.string(),
    content: z.object({
        dataType: z.string(),
        type: z.string(),
        hasPublicTransfer: z.boolean(),
        fields: z.object({
            id: z.object({ id: z.string() }),
            burns: z.array(BurnSchema),
        }),
    }),
});
