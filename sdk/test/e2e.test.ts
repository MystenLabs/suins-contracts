// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
import { Transaction } from '@mysten/sui/transactions';
import { normalizeSuiAddress } from '@mysten/sui/utils';
import { retry } from 'ts-retry-promise';
import { beforeAll, describe, expect, it } from 'vitest';

import { ALLOWED_METADATA, SuinsClient, SuinsTransaction } from '../src';
import { execute, publishAndSetupSuinsContracts } from './setup';
import { setupSuiClient, TestToolbox } from './toolbox';

/**
 * This e2e suite needs to run sequential (state needs to be preserved on-chain across)
 * these tests, and the order they are written is important for the tests to pass.
 */
describe('Testing SuiNS SDK e2e', () => {
	let toolbox: TestToolbox;
	let suinsClient: SuinsClient;
	const name = 'test.sui';

	beforeAll(async () => {
		toolbox = await setupSuiClient();

		// publish and setup these contracts and get back the constants (packageIds / objectIds).
		const constants = await retry(() => publishAndSetupSuinsContracts(toolbox), {
			backoff: 'EXPONENTIAL',
			// overall timeout in 2 minutes
			timeout: 1000 * 60 * 2,
			logger: (msg) => console.warn('Retrying publishing the contracts: ' + msg),
		});

		suinsClient = new SuinsClient({
			client: toolbox.client,
			packageIds: constants,
		});
	});

	it('Should return null as a non-existing name', async () => {
		const result = await suinsClient.getNameRecord('5215153153534543653.sui');
		expect(result).toBeNull();
	});

	it('Should register a new name, renew it, set the target address, set it as default', async () => {
		const transaction = new Transaction();
		const suinsTxb = new SuinsTransaction(suinsClient, transaction);

		const priceList = await suinsClient.getPriceList();
		const renewalPriceList = await suinsClient.getRenewalPriceList();

		const years = 1;

		// register test.sui for a year.
		const nft = suinsTxb.register({
			name,
			years,
			price: suinsClient.calculatePrice({ name, years, priceList }),
		});

		// renew for another 2 years.
		suinsTxb.renew({
			nftId: nft,
			years: 2,
			price: suinsClient.calculatePrice({
				name,
				years: 2,
				priceList: renewalPriceList,
			}),
		});

		// Sets the target address of the NFT.
		suinsTxb.setTargetAddress({
			nft,
			address: toolbox.address(),
			isSubname: false,
		});

		suinsTxb.setDefault(name);

		// Sets the avatar of the NFT.
		suinsTxb.setUserData({
			nft,
			key: ALLOWED_METADATA.avatar,
			value: '0x0',
		});

		suinsTxb.setUserData({
			nft,
			key: ALLOWED_METADATA.contentHash,
			value: '0x1',
		});

		transaction.transferObjects([nft], transaction.pure.address(toolbox.address()));

		const res = await execute(toolbox, transaction);

		expect(res.effects?.status.status).toBe('success');

		// Fetch and check the name record.
		const nameRecord = await suinsClient.getNameRecord(name);

		expect(nameRecord?.name).toBe(name);
		expect(nameRecord?.targetAddress).toBe(toolbox.address());
		expect(nameRecord?.contentHash).toBe('0x1');
		expect(nameRecord?.avatar).toBe('0x0');
	});

	it('Should create some node subnames and call functionality with these', async () => {
		const transaction = new Transaction();
		const suinsTxb = new SuinsTransaction(suinsClient, transaction);

		const subName = 'node.test.sui';

		const parentNameRecord = await suinsClient.getNameRecord(name);
		if (!parentNameRecord) throw new Error('Parent not found');

		const subNameNft = suinsTxb.createSubName({
			parentNft: parentNameRecord.nftId,
			name: subName,
			expirationTimestampMs: parentNameRecord.expirationTimestampMs,
			allowChildCreation: true,
			allowTimeExtension: true,
		});

		suinsTxb.setUserData({
			nft: subNameNft,
			key: ALLOWED_METADATA.contentHash,
			value: '0x1',
			isSubname: true,
		});

		// Check set the target address for a subname.
		suinsTxb.setTargetAddress({
			nft: subNameNft,
			address: toolbox.address(),
			isSubname: true,
		});
		// Check setting the subname as default.
		suinsTxb.setDefault(subName);

		transaction.transferObjects([subNameNft], transaction.pure.address(toolbox.address()));

		const res = await execute(toolbox, transaction);
		expect(res.effects?.status.status).toBe('success');

		// Fetch and check the subname record.
		const nameRecord = await suinsClient.getNameRecord(subName);

		expect(nameRecord?.name).toBe(subName);
		expect(nameRecord?.targetAddress).toBe(toolbox.address());
		expect(nameRecord?.expirationTimestampMs).toEqual(parentNameRecord.expirationTimestampMs);
		expect(nameRecord?.contentHash).toBe('0x1');
	});

	it('Should create leaf subnames, and remove them too', async () => {
		const transaction = new Transaction();
		const suinsTxb = new SuinsTransaction(suinsClient, transaction);
		const leaf = 'leaf.test.sui';
		const anotherSubname = 'another.test.sui';

		const parentNameRecord = await suinsClient.getNameRecord(name);
		if (!parentNameRecord) throw new Error('Parent not found');

		suinsTxb.createLeafSubName({
			parentNft: parentNameRecord.nftId,
			name: leaf,
			targetAddress: '0x2',
		});

		suinsTxb.createLeafSubName({
			parentNft: parentNameRecord.nftId,
			name: anotherSubname,
			targetAddress: '0x3',
		});
		const res = await execute(toolbox, transaction);
		expect(res.effects?.status.status).toBe('success');

		// Fetch and check the subname record.
		const nameRecord = await suinsClient.getNameRecord(leaf);
		expect(nameRecord?.name).toBe(leaf);
		expect(nameRecord?.targetAddress).toBe(normalizeSuiAddress('0x2'));
	});

	it('Should be able to remove the leaf names created', async () => {
		const transaction = new Transaction();
		const suinsTxb = new SuinsTransaction(suinsClient, transaction);

		const parentNameRecord = await suinsClient.getNameRecord(name);
		if (!parentNameRecord) throw new Error('Parent not found');

		suinsTxb.removeLeafSubName({
			parentNft: parentNameRecord.nftId,
			name: 'leaf.test.sui',
		});

		const res = await execute(toolbox, transaction);
		expect(res.effects?.status.status).toBe('success');
	});

	it('Should be able to unset the target address', async () => {
		const transaction = new Transaction();
		const suinsTxb = new SuinsTransaction(suinsClient, transaction);

		let parentNameRecord = await suinsClient.getNameRecord(name);
		if (!parentNameRecord) throw new Error('Parent not found');

		suinsTxb.setTargetAddress({
			nft: parentNameRecord.nftId,
			isSubname: false,
		});

		const res = await execute(toolbox, transaction);
		expect(res.effects?.status.status).toBe('success');

		parentNameRecord = await suinsClient.getNameRecord(name);
		if (!parentNameRecord) throw new Error('Parent not found');

		expect(parentNameRecord.targetAddress).toBeNull();
	});
});
