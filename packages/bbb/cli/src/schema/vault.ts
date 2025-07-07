import { z } from "zod/v4";

export const BBBVaultSchema = z.object({
    objectId: z.string(),
    version: z.string(),
    digest: z.string(),
    content: z.object({
        dataType: z.string(),
        type: z.string(),
        hasPublicTransfer: z.boolean(),
        fields: z.object({
            balances: z.object({
                type: z.string(),
                fields: z.object({
                    id: z.object({ id: z.string() }),
                    size: z.string(),
                }),
            }),
            id: z.object({ id: z.string() }),
        }),
    }),
});
