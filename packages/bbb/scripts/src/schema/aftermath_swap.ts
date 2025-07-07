import { toHex } from "@mysten/sui/utils";
import { z } from "zod/v4";

export const AftermathSwapSchema = z.object({
    type: z.string(),
    fields: z.object({
        decimals_in: z.number(),
        decimals_out: z.number(),
        feed_in: z.array(z.number()).transform((arr) => `${toHex(Uint8Array.from(arr))}`),
        feed_out: z
            .array(z.number())
            .transform((arr) => `${toHex(Uint8Array.from(arr))}`),
        max_age_secs: z.string(),
        pool_id: z.string(),
        slippage: z.string(),
        type_in: z.object({
            type: z.string(),
            fields: z.object({ name: z.string() }),
        }),
        type_out: z.object({
            type: z.string(),
            fields: z.object({ name: z.string() }),
        }),
    }),
});

export const AftermathSwapEventSchema = z.object({
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
