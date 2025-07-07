// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/**
 * Extracts the VAA bytes embedded in an accumulator message.
 *
 * @param accumulatorMessage The accumulator price update message as a Uint8Array.
 * @returns VAA bytes as a Uint8Array.
 */
export function extractVaaBytesFromAccumulatorMessage(accumulatorMessage: Uint8Array): Uint8Array {
	const dataView = new DataView(
		accumulatorMessage.buffer,
		accumulatorMessage.byteOffset,
		accumulatorMessage.byteLength,
	);

	const trailingPayloadSize = dataView.getUint8(6);
	const vaaSizeOffset = 7 + trailingPayloadSize + 1; // Header (7 bytes), trailing payload size, proof type
	const vaaSize = dataView.getUint16(vaaSizeOffset, false); // Read 2 bytes for VAA size (big-endian)
	const vaaOffset = vaaSizeOffset + 2; // VAA size is 2 bytes

	return accumulatorMessage.subarray(vaaOffset, vaaOffset + vaaSize);
}
