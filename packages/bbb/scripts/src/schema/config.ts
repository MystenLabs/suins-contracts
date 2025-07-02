import { z } from "zod/v4";
import { AftermathSwapSchema } from "./aftermath_swap.js";
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

export const AftermathConfigSchema = z.object({
    objectId: z.string(),
    version: z.string(),
    digest: z.string(),
    content: z.object({
        dataType: z.string(),
        type: z.string(),
        hasPublicTransfer: z.boolean(),
        fields: z.object({
            af_swaps: z.array(AftermathSwapSchema),
            id: z.object({ id: z.string() }),
        }),
    }),
});
