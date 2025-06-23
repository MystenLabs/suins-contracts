import { z } from "zod";

export const BurnedEventSchema = z.object({
    id: z.object({ txDigest: z.string(), eventSeq: z.string() }),
    packageId: z.string(),
    transactionModule: z.string(),
    sender: z.string(),
    type: z.string(),
    parsedJson: z.object({ amount: z.string(), coin_type: z.string() }),
    bcsEncoding: z.string(),
    bcs: z.string(),
});
