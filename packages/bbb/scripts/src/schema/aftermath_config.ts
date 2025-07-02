import { z } from "zod/v4";
import { AftermathSwapSchema } from "./aftermath_swap.js";

export const AftermathConfigSchema = z.object({
    objectId: z.string(),
    version: z.string(),
    digest: z.string(),
    content: z.object({
        dataType: z.string(),
        type: z.string(),
        hasPublicTransfer: z.boolean(),
        fields: z.object({
            id: z.object({ id: z.string() }),
            af_swaps: z.array(AftermathSwapSchema),
        }),
    }),
});
