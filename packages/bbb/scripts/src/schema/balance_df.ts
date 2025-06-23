import { z } from "zod";

export const BalanceDfSchema = z.object({
    objectId: z.string(),
    version: z.string(),
    digest: z.string(),
    content: z.object({
        dataType: z.string(),
        type: z.string(),
        hasPublicTransfer: z.boolean(),
        fields: z.object({
            id: z.object({ id: z.string() }),
            name: z.object({
                type: z.string(),
                fields: z.object({ name: z.string() }),
            }),
            value: z.string(),
        }),
    }),
});
