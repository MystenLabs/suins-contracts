import { toHex } from "@mysten/sui/utils";
import { z } from "zod/v4";

export const CetusSwapSchema = z.object({
    type: z.string(),
    fields: z.object({
        a2b: z.boolean(),
        decimals_a: z.number(),
        decimals_b: z.number(),
        feed_a: z
            .array(z.number())
            .transform((arr) => `0x${toHex(Uint8Array.from(arr))}`),
        feed_b: z
            .array(z.number())
            .transform((arr) => `0x${toHex(Uint8Array.from(arr))}`),
        max_age_secs: z.string(),
        pool_id: z.string(),
        slippage: z.string(),
        type_a: z.object({
            type: z.string(),
            fields: z.object({ name: z.string() }),
        }),
        type_b: z.object({
            type: z.string(),
            fields: z.object({ name: z.string() }),
        }),
    }),
});

export const CetusSwapEventSchema = z.object({
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
