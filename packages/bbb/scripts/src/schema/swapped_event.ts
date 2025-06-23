import { z } from "zod";

export const SwappedEventSchema = z.object({
    id: z.object({ txDigest: z.string(), eventSeq: z.string() }),
    packageId: z.string(),
    transactionModule: z.string(),
    sender: z.string(),
    type: z.string(),
    parsedJson: z.object({
        amount_in: z.string(),
        amount_out: z.string(),
        expected_out: z.string(),
        type_in: z.string(),
        type_out: z.string(),
    }),
    bcsEncoding: z.string(),
    bcs: z.string(),
});
