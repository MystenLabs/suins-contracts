// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { bcs } from '@mysten/sui/bcs';
import type { SuiClient } from '@mysten/sui/client';
import type { Transaction } from '@mysten/sui/transactions';
import { coinWithBalance } from '@mysten/sui/transactions';
import { fromBase64, fromHex, parseStructTag } from '@mysten/sui/utils';

import type { HexString } from './PriceServiceConnection.js';
import { PriceServiceConnection } from './PriceServiceConnection.js';
import { extractVaaBytesFromAccumulatorMessage } from './pyth-helpers.js';

const MAX_ARGUMENT_SIZE = 16 * 1024;
export type ObjectId = string;
export class SuiPriceServiceConnection extends PriceServiceConnection {
	/**
	 * Fetch price feed update data.
	 *
	 * @param priceIds Array of hex-encoded price IDs.
	 * @returns Array of buffers containing the price update data.
	 */
	async getPriceFeedsUpdateData(priceIds: HexString[]): Promise<Uint8Array[]> {
		const latestVaas = await this.getLatestVaas(priceIds);
		return latestVaas.map((vaa) => fromBase64(vaa));
	}
}
export class SuiPythClient {
	#pythPackageId?: Promise<ObjectId>;
	#wormholePackageId?: Promise<ObjectId>;
	#priceFeedObjectIdCache: Map<HexString, Promise<ObjectId>> = new Map();
	#priceTableInfo?: Promise<{ id: ObjectId; fieldType: ObjectId }>;
	#baseUpdateFee?: Promise<number>;
	provider: SuiClient;
	pythStateId: ObjectId;
	wormholeStateId: ObjectId;

	constructor(provider: SuiClient, pythStateId: ObjectId, wormholeStateId: ObjectId) {
		this.provider = provider;
		this.pythStateId = pythStateId;
		this.wormholeStateId = wormholeStateId;
	}
	/**
	 * Verifies the VAAs using the Wormhole contract.
	 *
	 * @param vaas Array of VAA buffers to verify.
	 * @param tx Transaction block to add commands to.
	 * @returns Array of verified VAAs.
	 */
	async verifyVaas(vaas: Uint8Array[], tx: Transaction) {
		const wormholePackageId = await this.getWormholePackageId();
		const verifiedVaas = [];
		for (const vaa of vaas) {
			const [verifiedVaa] = tx.moveCall({
				target: `${wormholePackageId}::vaa::parse_and_verify`,
				arguments: [tx.object(this.wormholeStateId), tx.pure.vector('u8', vaa), tx.object.clock()],
			});
			verifiedVaas.push(verifiedVaa);
		}
		return verifiedVaas;
	}
	/**
	 * Adds the necessary commands for updating the Pyth price feeds to the transaction block.
	 *
	 * @param tx Transaction block to add commands to.
	 * @param updates Array of price feed updates received from the price service.
	 * @param feedIds Array of feed IDs to update (in hex format).
	 */
	async updatePriceFeeds(
		tx: Transaction,
		updates: Uint8Array[],
		feedIds: HexString[],
	): Promise<ObjectId[]> {
		const packageId = await this.getPythPackageId();
		let priceUpdatesHotPotato;
		if (updates.length > 1) {
			throw new Error(
				'SDK does not support sending multiple accumulator messages in a single transaction',
			);
		}
		const vaa = extractVaaBytesFromAccumulatorMessage(updates[0]);
		const verifiedVaas = await this.verifyVaas([vaa], tx);
		[priceUpdatesHotPotato] = tx.moveCall({
			target: `${packageId}::pyth::create_authenticated_price_infos_using_accumulator`,
			arguments: [
				tx.object(this.pythStateId),
				tx.pure(
					bcs
						.vector(bcs.U8)
						.serialize(Array.from(updates[0]), {
							maxSize: MAX_ARGUMENT_SIZE,
						})
						.toBytes(),
				),
				verifiedVaas[0],
				tx.object.clock(),
			],
		});
		const priceInfoObjects: ObjectId[] = [];
		const baseUpdateFee = await this.getBaseUpdateFee();
		for (const feedId of feedIds) {
			const priceInfoObjectId = await this.getPriceFeedObjectId(feedId);
			if (!priceInfoObjectId) {
				throw new Error(`Price feed ${feedId} not found, please create it first`);
			}
			priceInfoObjects.push(priceInfoObjectId);
			[priceUpdatesHotPotato] = tx.moveCall({
				target: `${packageId}::pyth::update_single_price_feed`,
				arguments: [
					tx.object(this.pythStateId),
					priceUpdatesHotPotato,
					tx.object(priceInfoObjectId),
					coinWithBalance({ balance: baseUpdateFee }),
					tx.object.clock(),
				],
			});
		}
		tx.moveCall({
			target: `${packageId}::hot_potato_vector::destroy`,
			arguments: [priceUpdatesHotPotato],
			typeArguments: [`${packageId}::price_info::PriceInfo`],
		});
		return priceInfoObjects;
	}
	/**
	 * Get the price feed object ID for a given feed ID, caching the promise.
	 * @param feedId
	 */
	getPriceFeedObjectId(feedId: HexString): Promise<ObjectId | undefined> {
		if (!this.#priceFeedObjectIdCache.has(feedId)) {
			this.#priceFeedObjectIdCache.set(
				feedId,
				this.#fetchPriceFeedObjectId(feedId).catch((err) => {
					// Remove failed promises from the cache to allow retries
					this.#priceFeedObjectIdCache.delete(feedId);
					throw err;
				}),
			);
		}

		return this.#priceFeedObjectIdCache.get(feedId)!;
	}

	/**
	 * Fetches the price feed object ID for a given feed ID (no caching).
	 * Throws an error if the object is not found.
	 */
	async #fetchPriceFeedObjectId(feedId: HexString): Promise<ObjectId> {
		const { id: tableId, fieldType } = await this.getPriceTableInfo();
		const result = await this.provider.getDynamicFieldObject({
			parentId: tableId,
			name: {
				type: `${fieldType}::price_identifier::PriceIdentifier`,
				value: {
					bytes: Array.from(fromHex(feedId)),
				},
			},
		});

		if (!result.data || !result.data.content) {
			throw new Error(`Price feed object ID for feed ID ${feedId} not found.`);
		}
		if (result.data.content.dataType !== 'moveObject') {
			throw new Error('Price feed type mismatch');
		}

		// @ts-ignore
		return result.data.content.fields.value;
	}

	/**
	 * Fetches the price table object ID for the current state ID, caching the promise.
	 * @returns Price table object ID and field type
	 */
	getPriceTableInfo(): Promise<{ id: ObjectId; fieldType: ObjectId }> {
		if (!this.#priceTableInfo) {
			const promise = this.#fetchPriceTableInfo().catch((err) => {
				// Clear the cached promise on error
				this.#priceTableInfo = undefined;
				throw err;
			});

			this.#priceTableInfo = promise;
		}

		return this.#priceTableInfo;
	}

	/**
	 * Fetches the price table object ID and field type (no caching).
	 * @returns Price table object ID and field type
	 */
	async #fetchPriceTableInfo(): Promise<{ id: ObjectId; fieldType: ObjectId }> {
		const result = await this.provider.getDynamicFieldObject({
			parentId: this.pythStateId,
			name: {
				type: 'vector<u8>',
				value: 'price_info',
			},
		});

		if (!result.data || !result.data.type) {
			throw new Error('Price Table not found, contract may not be initialized');
		}

		const priceIdentifier = parseStructTag(result.data.type).typeParams[0];
		if (
			typeof priceIdentifier === 'object' &&
			priceIdentifier !== null &&
			priceIdentifier.name === 'PriceIdentifier' &&
			'address' in priceIdentifier
		) {
			return { id: result.data.objectId, fieldType: priceIdentifier.address };
		} else {
			throw new Error('fieldType not found');
		}
	}
	/**
	 * Fetches the package ID for the Wormhole contract, with caching.
	 */
	getWormholePackageId(): Promise<ObjectId> {
		if (!this.#wormholePackageId) {
			this.#wormholePackageId = this.#fetchWormholePackageId();
		}
		return this.#wormholePackageId;
	}

	/**
	 * Fetches the package ID for the Wormhole contract (no caching).
	 */
	async #fetchWormholePackageId(): Promise<ObjectId> {
		return await this.#getPackageId(this.wormholeStateId);
	}

	/**
	 * Fetches the package ID for the Pyth contract, with caching.
	 */
	getPythPackageId(): Promise<ObjectId> {
		if (!this.#pythPackageId) {
			this.#pythPackageId = this.#fetchPythPackageId();
		}
		return this.#pythPackageId;
	}

	/**
	 * Fetches the package ID for the Pyth contract (no caching).
	 */
	async #fetchPythPackageId(): Promise<ObjectId> {
		return await this.#getPackageId(this.pythStateId);
	}

	/**
	 * Fetches the package ID for a given object.
	 *
	 * @param objectId Object ID to fetch the package ID for.
	 */
	async #getPackageId(objectId: ObjectId): Promise<ObjectId> {
		const result = await this.provider.getObject({
			id: objectId,
			options: { showContent: true },
		});

		if (
			result.data?.content?.dataType === 'moveObject' &&
			'upgrade_cap' in result.data.content.fields
		) {
			const fields = result.data.content.fields as {
				upgrade_cap: {
					fields: {
						package: ObjectId;
					};
				};
			};
			return fields.upgrade_cap.fields.package;
		}

		throw new Error(`Cannot fetch package ID for object ${objectId}`);
	}
	/**
	 * Gets the base update fee from the Pyth state object.
	 */
	async #fetchBaseUpdateFee(): Promise<number> {
		const result = await this.provider.getObject({
			id: this.pythStateId,
			options: { showContent: true },
		});

		if (!result.data || result.data.content?.dataType !== 'moveObject') {
			throw new Error('Unable to fetch Pyth state object');
		}

		const fields = result.data.content.fields as { base_update_fee: number };
		return fields.base_update_fee;
	}

	/**
	 * Returns the cached base update fee, fetching it if necessary.
	 */
	getBaseUpdateFee(): Promise<number> {
		if (!this.#baseUpdateFee) {
			this.#baseUpdateFee = this.#fetchBaseUpdateFee();
		}
		return this.#baseUpdateFee;
	}
}
