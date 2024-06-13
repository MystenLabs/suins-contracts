// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
import { bcs } from '@mysten/sui.js/bcs';
import { SuiClient } from '@mysten/sui.js/client';
import { Ed25519Keypair } from '@mysten/sui.js/keypairs/ed25519';
import { TransactionBlock } from '@mysten/sui.js/transactions';
import { SUI_CLOCK_OBJECT_ID } from '@mysten/sui.js/utils';
import axios from 'axios';
import dotenv from 'dotenv';

dotenv.config();

const MAX_ARGUMENT_SIZE = 16 * 1024;
// these are new deployments for testing
const oracleRegistration = '0xdcbc4694dbed0574aceac0845f615ea7279e8547d5c99c0bd1f382db9d571844';
const suiNS = '0x8c40c84e0e6485c44c07984df338dbfee868fb6c399a61e99aa609bf9e700da4';
const client = new SuiClient({ url: 'https://suins-rpc.testnet.sui.io' });
// https://docs.pyth.network/price-feeds/contract-addresses/sui
const wormholeStateId = '0xebba4cc4d614f7a7cdbe883acc76d1cc767922bc96778e7b68be0d15fce27c02';
const pythStateId = '0x2d82612a354f0b7e52809fc2845642911c7190404620cec8688f68808f8800d8';

const setup = async () => {
	const txb = new TransactionBlock();
	const priceInfoObjectId = await setupOracleTxb(txb);

	// get quantity of SUI required for registration
	// this can also be done off chain using pyth
	// https://docs.pyth.network/price-feeds/use-real-time-data/sui#off-chain-prices
	let quantity = txb.moveCall({
		target: `${oracleRegistration}::register::calculate_registration_price`,
		arguments: [txb.object(suiNS), txb.pure('def.sui'), txb.pure(1), txb.object(priceInfoObjectId)],
	});

	const coin = txb.splitCoins(txb.gas, [quantity]);
	const nft = txb.moveCall({
		target: `${oracleRegistration}::register::register`,
		arguments: [
			txb.object(suiNS),
			txb.pure('def.sui'),
			txb.pure(1),
			coin,
			txb.object(priceInfoObjectId),
			txb.object(SUI_CLOCK_OBJECT_ID),
		],
	});
	txb.transferObjects(
		[nft],
		txb.pure.address('0x683f02dfb1b1a5336dfa36f6d527d1dd1144de7e13b35a8b4bbd7b78ec68b464'),
	);

	let keypair = Ed25519Keypair.deriveKeypair(process.env.ADMIN_PHRASE!);
	client.signAndExecuteTransactionBlock({
		transactionBlock: txb,
		signer: keypair,
		options: {
			showObjectChanges: true,
			showEffects: true,
		},
	});
};

const setupOracleTxb = async (txb: TransactionBlock) => {
	// You can find the ids of prices at https://pyth.network/developers/price-feed-ids
	const priceId = '0x50c67b3fd225db8912a424dd4baed60ffdde625ed2feaaf283724f9608fea266'; // SUI/USD
	// In order to use Pyth prices in your protocol you need to submit the price update data to Pyth contract in your target
	// chain. `getPriceUpdateData` creates the update data which can be submitted to your contract.
	const priceUpdateData = await getPriceUpdateData([priceId]);
	const priceUpdate = priceUpdateData[0];

	const pythPackageId = await getPackageId(pythStateId);
	const wormholePackageId = await getPackageId(wormholeStateId);

	let priceUpdatesHotPotato;
	const vaa = extractVaaBytesFromAccumulatorMessage(priceUpdate);
	const verifiedVaas = verifyVaas([vaa], txb, wormholePackageId);
	[priceUpdatesHotPotato] = txb.moveCall({
		target: `${pythPackageId}::pyth::create_authenticated_price_infos_using_accumulator`,
		arguments: [
			txb.object(pythStateId),
			txb.pure(
				bcs
					.ser('vector<u8>', Array.from(priceUpdate), {
						maxSize: MAX_ARGUMENT_SIZE,
					})
					.toBytes(),
			),
			verifiedVaas[0],
			txb.object(SUI_CLOCK_OBJECT_ID),
		],
	});

	const baseUpdateFee = await getBaseUpdateFee();
	const coin = txb.splitCoins(txb.gas, [baseUpdateFee]);
	const priceInfoObjectId = await getPriceFeedObjectId(priceId);
	if (!priceInfoObjectId) {
		throw new Error(`Price feed ${priceId} not found, please create it first`);
	}
	[priceUpdatesHotPotato] = txb.moveCall({
		target: `${pythPackageId}::pyth::update_single_price_feed`,
		arguments: [
			txb.object(pythStateId),
			priceUpdatesHotPotato,
			txb.object(priceInfoObjectId),
			coin,
			txb.object(SUI_CLOCK_OBJECT_ID),
		],
	});
	txb.moveCall({
		target: `${pythPackageId}::hot_potato_vector::destroy`,
		arguments: [priceUpdatesHotPotato],
		typeArguments: [`${pythPackageId}::price_info::PriceInfo`],
	});

	return priceInfoObjectId;
};

// eslint-disable-next-line no-restricted-globals, @typescript-eslint/ban-types
const getPriceUpdateData = async (priceIds: string[]): Promise<Buffer[]> => {
	let httpClient = axios.create({
		baseURL: 'https://hermes-beta.pyth.network',
		timeout: 5000,
	});
	const response = await httpClient.get('/api/latest_vaas', {
		params: {
			ids: priceIds,
		},
	});
	let latestVaas = response.data;
	// eslint-disable-next-line no-restricted-globals
	return latestVaas.map((vaa: any) => Buffer.from(vaa, 'base64'));
};

const getPriceFeedObjectId = async (feedId: string): Promise<any | undefined> => {
	const normalizedFeedId = feedId.replace('0x', '');
	const { id: tableId, fieldType } = await getPriceTableInfo();
	const result = await client.getDynamicFieldObject({
		parentId: tableId,
		name: {
			type: `${fieldType}::price_identifier::PriceIdentifier`,
			value: {
				// eslint-disable-next-line no-restricted-globals
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
	// eslint-disable-next-line @typescript-eslint/ban-ts-comment
	// @ts-ignore
	return result.data.content.fields.value;
};

const getPriceTableInfo = async (): Promise<{ id: any; fieldType: any }> => {
	const result = await client.getDynamicFieldObject({
		parentId: pythStateId,
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
	return { id: result.data.objectId, fieldType: type };
};

const getBaseUpdateFee = async (): Promise<number> => {
	const result = await client.getObject({
		id: pythStateId,
		options: { showContent: true },
	});
	if (!result.data || !result.data.content || result.data.content.dataType !== 'moveObject') {
		throw new Error('Unable to fetch pyth state object');
	}

	// eslint-disable-next-line @typescript-eslint/ban-ts-comment
	// @ts-ignore
	return result.data.content.fields.base_update_fee as number;
};

const verifyVaas = (
	// eslint-disable-next-line no-restricted-globals, @typescript-eslint/ban-types
	vaas: Buffer[],
	txb: TransactionBlock,
	wormholePackageId: string,
) => {
	const verifiedVaas = [];
	for (const vaa of vaas) {
		const [verifiedVaa] = txb.moveCall({
			target: `${wormholePackageId}::vaa::parse_and_verify`,
			arguments: [
				txb.object(wormholeStateId),
				txb.pure(
					bcs
						.ser('vector<u8>', Array.from(vaa), {
							maxSize: MAX_ARGUMENT_SIZE,
						})
						.toBytes(),
				),
				txb.object(SUI_CLOCK_OBJECT_ID),
			],
		});
		verifiedVaas.push(verifiedVaa);
	}
	return verifiedVaas;
};

// eslint-disable-next-line no-restricted-globals, @typescript-eslint/ban-types
const extractVaaBytesFromAccumulatorMessage = (accumulatorMessage: Buffer): Buffer => {
	// the first 6 bytes in the accumulator message encode the header, major, and minor bytes
	// we ignore them, since we are only interested in the VAA bytes
	// header bytes (header(4) + major(1) + minor(1) + trailing payload size(1))
	// trailing payload (variable number of bytes)
	// proof_type (1 byte)
	const trailingPayloadSize = accumulatorMessage.readUint8(6);
	const vaaSizeOffset = 7 + trailingPayloadSize + 1;
	const vaaSize = accumulatorMessage.readUint16BE(vaaSizeOffset);
	const vaaOffset = vaaSizeOffset + 2;
	return accumulatorMessage.subarray(vaaOffset, vaaOffset + vaaSize);
};

const getPackageId = async (objectId: any): Promise<any> => {
	const state = await client
		.getObject({
			id: objectId,
			options: {
				showContent: true,
			},
		})
		.then((result) => {
			if (result.data?.content?.dataType === 'moveObject') {
				return result.data.content.fields;
			}

			throw new Error(`Cannot fetch package id for object ${objectId}`);
		});

	if ('upgrade_cap' in state) {
		// eslint-disable-next-line @typescript-eslint/ban-ts-comment
		// @ts-ignore
		return state.upgrade_cap.fields.package;
	}

	throw new Error(`upgrade_cap not found`);
};

setup();
