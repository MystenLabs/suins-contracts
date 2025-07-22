import { z } from "zod/v4";

export const BurnSchema = z.object({
    type: z.string(),
    fields: z.object({
        coin_type: z.object({
            type: z.string(),
            fields: z.object({ name: z.string() }),
        }),
    }),
});

export const BurnEventSchema = z.object({
    id: z.object({ txDigest: z.string(), eventSeq: z.string() }),
    packageId: z.string(),
    transactionModule: z.string(),
    sender: z.string(),
    type: z.string(),
    parsedJson: z.object({ amount: z.string(), coin_type: z.string() }),
    bcsEncoding: z.string(),
    bcs: z.string(),
});
