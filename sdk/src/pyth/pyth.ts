// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
import { Buffer } from 'buffer';
import { bcs } from '@mysten/sui/bcs';
import { SuiClient } from '@mysten/sui/client';
import { Transaction } from '@mysten/sui/transactions';
import { SUI_CLOCK_OBJECT_ID } from '@mysten/sui/utils';

import { HexString, PriceServiceConnection } from './PriceServiceConnection';

const MAX_ARGUMENT_SIZE = 16 * 1024;
export type ObjectId = string;
export class SuiPriceServiceConnection extends PriceServiceConnection {
	/**
	 * Fetch price feed update data.
	 *
	 * @param priceIds Array of hex-encoded price IDs.
	 * @returns Array of buffers containing the price update data.
	 */
	async getPriceFeedsUpdateData(priceIds: HexString[]): Promise<Buffer[]> {
		const latestVaas = await this.getLatestVaas(priceIds);
		return latestVaas.map((vaa) => Buffer.from(vaa, 'base64'));
	}
}
export class SuiPythClient {
	private pythPackageId: ObjectId | undefined;
	private wormholePackageId: ObjectId | undefined;
	private priceFeedObjectIdCache: Map<HexString, ObjectId> = new Map();
	private priceTableInfo: { id: ObjectId; fieldType: ObjectId } | undefined;
	private baseUpdateFee: number | undefined;
	constructor(
		public provider: SuiClient,
		public pythStateId: ObjectId,
		public wormholeStateId: ObjectId,
	) {}
	/**
	 * Verifies the VAAs using the Wormhole contract.
	 *
	 * @param vaas Array of VAA buffers to verify.
	 * @param tx Transaction block to add commands to.
	 * @returns Array of verified VAAs.
	 */
	async verifyVaas(vaas: Buffer[], tx: Transaction) {
		const wormholePackageId = await this.getWormholePackageId();
		const verifiedVaas = [];
		for (const vaa of vaas) {
			const [verifiedVaa] = tx.moveCall({
				target: `${wormholePackageId}::vaa::parse_and_verify`,
				arguments: [
					tx.object(this.wormholeStateId),
					tx.pure(
						bcs
							.vector(bcs.U8)
							.serialize(Array.from(vaa), {
								maxSize: MAX_ARGUMENT_SIZE,
							})
							.toBytes(),
					),
					tx.object(SUI_CLOCK_OBJECT_ID),
				],
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
		updates: Buffer[],
		feedIds: HexString[],
	): Promise<ObjectId[]> {
		const packageId = await this.getPythPackageId();
		let priceUpdatesHotPotato;
		if (updates.length > 1) {
			throw new Error(
				'SDK does not support sending multiple accumulator messages in a single transaction',
			);
		}
		const vaa = this.extractVaaBytesFromAccumulatorMessage(updates[0]);
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
				tx.object(SUI_CLOCK_OBJECT_ID),
			],
		});
		const priceInfoObjects: ObjectId[] = [];
		const baseUpdateFee = await this.getBaseUpdateFee();
		const coins = tx.splitCoins(
			tx.gas,
			feedIds.map(() => tx.pure.u64(baseUpdateFee)),
		);
		let coinId = 0;
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
					coins[coinId],
					tx.object(SUI_CLOCK_OBJECT_ID),
				],
			});
			coinId++;
		}
		tx.moveCall({
			target: `${packageId}::hot_potato_vector::destroy`,
			arguments: [priceUpdatesHotPotato],
			typeArguments: [`${packageId}::price_info::PriceInfo`],
		});
		return priceInfoObjects;
	}
	/**
	 * Get the priceFeedObjectId for a given feedId if not already cached
	 * @param feedId
	 */
	async getPriceFeedObjectId(feedId: HexString): Promise<ObjectId | undefined> {
		const normalizedFeedId = feedId.replace('0x', '');
		if (!this.priceFeedObjectIdCache.has(normalizedFeedId)) {
			const { id: tableId, fieldType } = await this.getPriceTableInfo();
			const result = await this.provider.getDynamicFieldObject({
				parentId: tableId,
				name: {
					type: `${fieldType}::price_identifier::PriceIdentifier`,
					value: {
						bytes: Array.from(Buffer.from(normalizedFeedId, 'hex')),
					},
				},
			});
			if (!result.data || !result.data.content) {
				return undefined;
			}
			if (result.data.content.dataType !== 'moveObject') {
				throw new Error('Price feed type mismatch');
			}
			this.priceFeedObjectIdCache.set(
				normalizedFeedId,
				// eslint-disable-next-line @typescript-eslint/ban-ts-comment
				// @ts-ignore
				result.data.content.fields.value,
			);
		}
		return this.priceFeedObjectIdCache.get(normalizedFeedId);
	}
	/**
	 * Fetches the price table object id for the current state id if not cached
	 * @returns price table object id
	 */
	async getPriceTableInfo(): Promise<{ id: ObjectId; fieldType: ObjectId }> {
		if (this.priceTableInfo === undefined) {
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
			let type = result.data.type.replace('0x2::table::Table<', '');
			type = type.replace('::price_identifier::PriceIdentifier, 0x2::object::ID>', '');
			this.priceTableInfo = { id: result.data.objectId, fieldType: type };
		}
		return this.priceTableInfo;
	}
	/**
	 * Extracts the VAA bytes embedded in an accumulator message.
	 *
	 * @param accumulatorMessage The accumulator price update message.
	 * @returns VAA bytes as a Buffer.
	 */
	extractVaaBytesFromAccumulatorMessage(accumulatorMessage: Buffer): Buffer {
		const trailingPayloadSize = accumulatorMessage.readUint8(6);
		const vaaSizeOffset = 7 + trailingPayloadSize + 1; // Header (7 bytes), trailing payload size, proof type
		const vaaSize = accumulatorMessage.readUint16BE(vaaSizeOffset);
		const vaaOffset = vaaSizeOffset + 2; // 2 bytes for VAA size
		return accumulatorMessage.subarray(vaaOffset, vaaOffset + vaaSize);
	}
	/**
	 * Fetches the package ID for the Wormhole contract.
	 */
	async getWormholePackageId(): Promise<ObjectId> {
		if (!this.wormholePackageId) {
			this.wormholePackageId = await this.getPackageId(this.wormholeStateId);
		}
		return this.wormholePackageId;
	}
	/**
	 * Fetches the package ID for the Pyth contract.
	 */
	async getPythPackageId(): Promise<ObjectId> {
		if (!this.pythPackageId) {
			this.pythPackageId = await this.getPackageId(this.pythStateId);
		}
		return this.pythPackageId;
	}
	/**
	 * Fetches the package ID for a given object.
	 *
	 * @param objectId Object ID to fetch the package ID for.
	 */
	private async getPackageId(objectId: ObjectId): Promise<ObjectId> {
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
	async getBaseUpdateFee(): Promise<number> {
		if (this.baseUpdateFee === undefined) {
			const result = await this.provider.getObject({
				id: this.pythStateId,
				options: { showContent: true },
			});
			if (!result.data || result.data.content?.dataType !== 'moveObject') {
				throw new Error('Unable to fetch Pyth state object');
			}
			const fields = result.data.content.fields as {
				base_update_fee: number;
			};
			this.baseUpdateFee = fields.base_update_fee as number;
		}
		return this.baseUpdateFee;
	}
}
