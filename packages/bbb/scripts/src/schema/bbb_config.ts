import { toHex } from "@mysten/sui/utils";
import { z } from "zod/v4";

export const BBBConfigSchema = z.object({
    objectId: z.string(),
    version: z.string(),
    digest: z.string(),
    content: z.object({
        dataType: z.string(),
        type: z.string(),
        hasPublicTransfer: z.boolean(),
        fields: z.object({
            af_swaps: z.array(
                z.object({
                    type: z.string(),
                    fields: z.object({
                        decimals_in: z.number(),
                        decimals_out: z.number(),
                        feed_in: z
                            .array(z.number())
                            .transform((arr) => `0x${toHex(Uint8Array.from(arr))}`),
                        feed_out: z
                            .array(z.number())
                            .transform((arr) => `0x${toHex(Uint8Array.from(arr))}`),
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
                }),
            ),
            burns: z.array(
                z.object({
                    type: z.string(),
                    fields: z.object({
                        coin_type: z.object({
                            type: z.string(),
                            fields: z.object({ name: z.string() }),
                        }),
                    }),
                }),
            ),
            id: z.object({ id: z.string() }),
        }),
    }),
});
