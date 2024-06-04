// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
import { bcs } from '@mysten/sui/bcs';
import type { Transaction } from '@mysten/sui/transactions';
import { isValidSuiNSName, normalizeSuiNSName, SUI_CLOCK_OBJECT_ID } from '@mysten/sui/utils';

import { ALLOWED_METADATA } from './constants.js';
import { isNestedSubName, isSubName, validateYears } from './helpers.js';
import type { SuinsClient } from './suins-client.js';
import type { ObjectArgument } from './types.js';

export class SuinsTransaction {
	#suinsClient: SuinsClient;
	transaction: Transaction;

	constructor(client: SuinsClient, transaction: Transaction) {
		this.#suinsClient = client;
		this.transaction = transaction;
	}

	/**
	 * Constructs the transaction to renew a name.
	 * Expects the nftId (or a transactionArgument), the number of years to renew
	 * as well as the length category of the domain.
	 *
	 * This only applies for SLDs (Second Level Domains) (e.g. example.sui, test.sui).
	 * You can use `getSecondLevelDomainCategory` to get the category of a domain.
	 */
	renew({ nftId, price, years }: { nftId: ObjectArgument; price: number; years: number }) {
		if (!this.#suinsClient.constants.renewalPackageId)
			throw new Error('Renewal package id not found');
		if (!this.#suinsClient.constants.suinsObjectId) throw new Error('SuiNS Object ID not found');
		validateYears(years);

		this.transaction.moveCall({
			target: `${this.#suinsClient.constants.renewalPackageId}::renew::renew`,
			arguments: [
				this.transaction.object(this.#suinsClient.constants.suinsObjectId),
				this.transaction.object(nftId),
				this.transaction.pure.u8(years),
				this.transaction.splitCoins(this.transaction.gas, [this.transaction.pure.u64(price)]),
				this.transaction.object(SUI_CLOCK_OBJECT_ID),
			],
		});
	}

	/**
	 * Registers a new SLD name.
	 *
	 * You can get the price by calling `getPrice` on the SuinsClient.
	 */
	register({ name, price, years }: { name: string; price: number; years: number }) {
		if (!this.#suinsClient.constants.registrationPackageId)
			throw new Error('Registration package id not found');
		if (!this.#suinsClient.constants.suinsObjectId) throw new Error('SuiNS Object ID not found');
		if (!isValidSuiNSName(name)) throw new Error('Invalid SuiNS name');
		validateYears(years);

		const nft = this.transaction.moveCall({
			target: `${this.#suinsClient.constants.registrationPackageId}::register::register`,
			arguments: [
				this.transaction.object(this.#suinsClient.constants.suinsObjectId),
				this.transaction.pure.string(normalizeSuiNSName(name, 'dot')),
				this.transaction.pure.u8(years),
				this.transaction.splitCoins(this.transaction.gas, [this.transaction.pure.u64(price)]),
				this.transaction.object(SUI_CLOCK_OBJECT_ID),
			],
		});

		return nft;
	}

	createSubName({
		parentNft,
		name,
		expirationTimestampMs,
		allowChildCreation,
		allowTimeExtension,
	}: {
		parentNft: ObjectArgument;
		name: string;
		expirationTimestampMs: number;
		allowChildCreation: boolean;
		allowTimeExtension: boolean;
	}) {
		if (!isValidSuiNSName(name)) throw new Error('Invalid SuiNS name');
		const isParentSubdomain = isNestedSubName(name);
		if (!this.#suinsClient.constants.suinsObjectId) throw new Error('SuiNS Object ID not found');
		if (!this.#suinsClient.constants.subNamesPackageId)
			throw new Error('Subnames package ID not found');
		if (isParentSubdomain && !this.#suinsClient.constants.tempSubNamesProxyPackageId)
			throw new Error('Subnames proxy package ID not found');

		const subNft = this.transaction.moveCall({
			target: isParentSubdomain
				? `${this.#suinsClient.constants.tempSubNamesProxyPackageId}::subdomain_proxy::new`
				: `${this.#suinsClient.constants.subNamesPackageId}::subdomains::new`,
			arguments: [
				this.transaction.object(this.#suinsClient.constants.suinsObjectId),
				this.transaction.object(parentNft),
				this.transaction.object(SUI_CLOCK_OBJECT_ID),
				this.transaction.pure.string(normalizeSuiNSName(name, 'dot')),
				this.transaction.pure.u64(expirationTimestampMs),
				this.transaction.pure.bool(!!allowChildCreation),
				this.transaction.pure.bool(!!allowTimeExtension),
			],
		});

		return subNft;
	}

	/**
	 * Builds the PTB to create a leaf subdomain.
	 * Parent can be a `SuinsRegistration` or a `SubDomainRegistration` object.
	 * Can be passed in as an ID or a TransactionArgument.
	 */
	createLeafSubName({
		parentNft,
		name,
		targetAddress,
	}: {
		parentNft: ObjectArgument;
		name: string;
		targetAddress: string;
	}) {
		if (!isValidSuiNSName(name)) throw new Error('Invalid SuiNS name');
		const isParentSubdomain = isNestedSubName(name);
		if (!this.#suinsClient.constants.suinsObjectId) throw new Error('SuiNS Object ID not found');
		if (!this.#suinsClient.constants.subNamesPackageId)
			throw new Error('Subnames package ID not found');
		if (isParentSubdomain && !this.#suinsClient.constants.tempSubNamesProxyPackageId)
			throw new Error('Subnames proxy package ID not found');

		this.transaction.moveCall({
			target: isParentSubdomain
				? `${this.#suinsClient.constants.tempSubNamesProxyPackageId}::subdomain_proxy::new_leaf`
				: `${this.#suinsClient.constants.subNamesPackageId}::subdomains::new_leaf`,
			arguments: [
				this.transaction.object(this.#suinsClient.constants.suinsObjectId),
				this.transaction.object(parentNft),
				this.transaction.object(SUI_CLOCK_OBJECT_ID),
				this.transaction.pure.string(normalizeSuiNSName(name, 'dot')),
				this.transaction.pure.address(targetAddress),
			],
		});
	}

	/**
	 * Removes a leaf subname.
	 */
	removeLeafSubName({ parentNft, name }: { parentNft: ObjectArgument; name: string }) {
		if (!isValidSuiNSName(name)) throw new Error('Invalid SuiNS name');
		const isParentSubdomain = isNestedSubName(name);
		if (!isSubName(name)) throw new Error('This can only be invoked for subnames');
		if (!this.#suinsClient.constants.suinsObjectId) throw new Error('SuiNS Object ID not found');
		if (!this.#suinsClient.constants.subNamesPackageId)
			throw new Error('Subnames package ID not found');
		if (isParentSubdomain && !this.#suinsClient.constants.tempSubNamesProxyPackageId)
			throw new Error('Subnames proxy package ID not found');

		this.transaction.moveCall({
			target: isParentSubdomain
				? `${this.#suinsClient.constants.tempSubNamesProxyPackageId}::subdomain_proxy::remove_leaf`
				: `${this.#suinsClient.constants.subNamesPackageId}::subdomains::remove_leaf`,
			arguments: [
				this.transaction.object(this.#suinsClient.constants.suinsObjectId),
				this.transaction.object(parentNft),
				this.transaction.object(SUI_CLOCK_OBJECT_ID),
				this.transaction.pure.string(normalizeSuiNSName(name, 'dot')),
			],
		});
	}

	setTargetAddress({
		nft,
		address,
		isSubname,
	}: {
		nft: ObjectArgument;
		address?: string;
		isSubname?: boolean;
	}) {
		if (!this.#suinsClient.constants.suinsObjectId) throw new Error('SuiNS Object ID not found');
		if (!this.#suinsClient.constants.utilsPackageId) throw new Error('Utils package ID not found');

		if (isSubname && !this.#suinsClient.constants.tempSubNamesProxyPackageId)
			throw new Error('Subnames proxy package ID not found');

		this.transaction.moveCall({
			target: isSubname
				? `${this.#suinsClient.constants.tempSubNamesProxyPackageId}::subdomain_proxy::set_target_address`
				: `${this.#suinsClient.constants.utilsPackageId}::direct_setup::set_target_address`,
			arguments: [
				this.transaction.object(this.#suinsClient.constants.suinsObjectId),
				this.transaction.object(nft),
				this.transaction.pure(bcs.option(bcs.Address).serialize(address).toBytes()),
				this.transaction.object(SUI_CLOCK_OBJECT_ID),
			],
		});
	}

	/** Marks a name as default */
	setDefault(name: string) {
		if (!isValidSuiNSName(name)) throw new Error('Invalid SuiNS name');
		if (!this.#suinsClient.constants.suinsObjectId) throw new Error('SuiNS Object ID not found');
		if (!this.#suinsClient.constants.utilsPackageId) throw new Error('Utils package ID not found');

		this.transaction.moveCall({
			target: `${this.#suinsClient.constants.utilsPackageId}::direct_setup::set_reverse_lookup`,
			arguments: [
				this.transaction.object(this.#suinsClient.constants.suinsObjectId),
				this.transaction.pure.string(normalizeSuiNSName(name, 'dot')),
			],
		});
	}

	editSetup({
		parentNft,
		name,
		allowChildCreation,
		allowTimeExtension,
	}: {
		parentNft: ObjectArgument;
		name: string;
		allowChildCreation: boolean;
		allowTimeExtension: boolean;
	}) {
		if (!isValidSuiNSName(name)) throw new Error('Invalid SuiNS name');
		const isParentSubdomain = isNestedSubName(name);
		if (!this.#suinsClient.constants.suinsObjectId) throw new Error('SuiNS Object ID not found');
		if (!isParentSubdomain && !this.#suinsClient.constants.subNamesPackageId)
			throw new Error('Subnames package ID not found');
		if (isParentSubdomain && !this.#suinsClient.constants.tempSubNamesProxyPackageId)
			throw new Error('Subnames proxy package ID not found');

		this.transaction.moveCall({
			target: isParentSubdomain
				? `${this.#suinsClient.constants.tempSubNamesProxyPackageId}::subdomain_proxy::edit_setup`
				: `${this.#suinsClient.constants.subNamesPackageId}::subdomains::edit_setup`,
			arguments: [
				this.transaction.object(this.#suinsClient.constants.suinsObjectId),
				this.transaction.object(parentNft),
				this.transaction.object(SUI_CLOCK_OBJECT_ID),
				this.transaction.pure.string(normalizeSuiNSName(name, 'dot')),
				this.transaction.pure.bool(!!allowChildCreation),
				this.transaction.pure.bool(!!allowTimeExtension),
			],
		});
	}

	extendExpiration({
		nft,
		expirationTimestampMs,
	}: {
		nft: ObjectArgument;
		expirationTimestampMs: number;
	}) {
		if (!this.#suinsClient.constants.suinsObjectId) throw new Error('SuiNS Object ID not found');
		if (!this.#suinsClient.constants.subNamesPackageId)
			throw new Error('Subnames package ID not found');

		this.transaction.moveCall({
			target: `${this.#suinsClient.constants.subNamesPackageId}::subdomains::extend_expiration`,
			arguments: [
				this.transaction.object(this.#suinsClient.constants.suinsObjectId),
				this.transaction.object(nft),
				this.transaction.pure.u64(expirationTimestampMs),
			],
		});
	}

	setUserData({
		nft,
		value,
		key,
		isSubname,
	}: {
		nft: ObjectArgument;
		value: string;
		key: string;
		isSubname?: boolean;
	}) {
		if (!this.#suinsClient.constants.suinsObjectId) throw new Error('SuiNS Object ID not found');
		if (!isSubname && !this.#suinsClient.constants.utilsPackageId)
			throw new Error('Utils package ID not found');
		if (isSubname && !this.#suinsClient.constants.tempSubNamesProxyPackageId)
			throw new Error('Subnames proxy package ID not found');

		if (!Object.values(ALLOWED_METADATA).some((x) => x === key)) throw new Error('Invalid key');

		this.transaction.moveCall({
			target: isSubname
				? `${this.#suinsClient.constants.tempSubNamesProxyPackageId}::subdomain_proxy::set_user_data`
				: `${this.#suinsClient.constants.utilsPackageId}::direct_setup::set_user_data`,
			arguments: [
				this.transaction.object(this.#suinsClient.constants.suinsObjectId),
				this.transaction.object(nft),
				this.transaction.pure.string(key),
				this.transaction.pure.string(value),
				this.transaction.object(SUI_CLOCK_OBJECT_ID),
			],
		});
	}

	/**
	 * Burns an expired NFT to collect storage rebates.
	 */
	burnExpired({ nft, isSubname }: { nft: ObjectArgument; isSubname?: boolean }) {
		if (!this.#suinsClient.constants.suinsObjectId) throw new Error('SuiNS Object ID not found');
		if (!this.#suinsClient.constants.utilsPackageId) throw new Error('Utils package ID not found');

		this.transaction.moveCall({
			target: `${this.#suinsClient.constants.utilsPackageId}::direct_setup::${
				isSubname ? 'burn_expired_subname' : 'burn_expired'
			}`,
			arguments: [
				this.transaction.object(this.#suinsClient.constants.suinsObjectId),
				this.transaction.object(nft),
				this.transaction.object(SUI_CLOCK_OBJECT_ID),
			],
		});
	}
}
