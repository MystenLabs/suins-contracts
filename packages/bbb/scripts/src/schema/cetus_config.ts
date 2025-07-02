import { z } from "zod/v4";
import { CetusSwapSchema } from "./cetus_swap.js";

export const CetusConfigSchema = z.object({
    objectId: z.string(),
    version: z.string(),
    digest: z.string(),
    content: z.object({
        dataType: z.string(),
        type: z.string(),
        hasPublicTransfer: z.boolean(),
        fields: z.object({
            id: z.object({ id: z.string() }),
            swaps: z.array(CetusSwapSchema),
        }),
    }),
});
