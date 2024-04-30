// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
import type { TransactionBlock } from '@mysten/sui.js/transactions';
import { isValidSuiNSName, SUI_CLOCK_OBJECT_ID } from '@mysten/sui.js/utils';

import { ALLOWED_METADATA } from './constants.js';
import { isNestedSubName, isSubName, validateYears } from './helpers.js';
import type { SuinsClient } from './suins-client.js';
import type { ObjectArgument } from './types.js';

export class SuinsTransaction {
	#suinsClient: SuinsClient;
	transactionBlock: TransactionBlock;

	constructor(client: SuinsClient, transactionBlock: TransactionBlock) {
		this.#suinsClient = client;
		this.transactionBlock = transactionBlock;
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

		this.transactionBlock.moveCall({
			target: `${this.#suinsClient.constants.renewalPackageId}::renew::renew`,
			arguments: [
				this.transactionBlock.object(this.#suinsClient.constants.suinsObjectId),
				this.transactionBlock.object(nftId),
				this.transactionBlock.pure.u8(years),
				this.transactionBlock.splitCoins(this.transactionBlock.gas, [
					this.transactionBlock.pure.u64(price),
				]),
				this.transactionBlock.object(SUI_CLOCK_OBJECT_ID),
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

		const nft = this.transactionBlock.moveCall({
			target: `${this.#suinsClient.constants.registrationPackageId}::register::register`,
			arguments: [
				this.transactionBlock.object(this.#suinsClient.constants.suinsObjectId),
				this.transactionBlock.pure.string(name),
				this.transactionBlock.pure.u8(years),
				this.transactionBlock.splitCoins(this.transactionBlock.gas, [
					this.transactionBlock.pure.u64(price),
				]),
				this.transactionBlock.object(SUI_CLOCK_OBJECT_ID),
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
			throw new Error('Subdomains package ID not found');
		if (isParentSubdomain && !this.#suinsClient.constants.tempSubNamesProxyPackageId)
			throw new Error('Subdomains proxy package ID not found');

		const subNft = this.transactionBlock.moveCall({
			target: isParentSubdomain
				? `${this.#suinsClient.constants.tempSubNamesProxyPackageId}::subdomain_proxy::new`
				: `${this.#suinsClient.constants.subNamesPackageId}::subdomains::new`,
			arguments: [
				this.transactionBlock.object(this.#suinsClient.constants.suinsObjectId),
				this.transactionBlock.object(parentNft),
				this.transactionBlock.object(SUI_CLOCK_OBJECT_ID),
				this.transactionBlock.pure.string(name),
				this.transactionBlock.pure.u64(expirationTimestampMs),
				this.transactionBlock.pure.bool(!!allowChildCreation),
				this.transactionBlock.pure.bool(!!allowTimeExtension),
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
			throw new Error('Subdomains package ID not found');
		if (isParentSubdomain && !this.#suinsClient.constants.tempSubNamesProxyPackageId)
			throw new Error('Subdomains proxy package ID not found');

		this.transactionBlock.moveCall({
			target: isParentSubdomain
				? `${this.#suinsClient.constants.tempSubNamesProxyPackageId}::subdomain_proxy::new_leaf`
				: `${this.#suinsClient.constants.subNamesPackageId}::subdomains::new_leaf`,
			arguments: [
				this.transactionBlock.object(this.#suinsClient.constants.suinsObjectId),
				this.transactionBlock.object(parentNft),
				this.transactionBlock.object(SUI_CLOCK_OBJECT_ID),
				this.transactionBlock.pure.string(name),
				this.transactionBlock.pure.address(targetAddress),
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
			throw new Error('Subdomains package ID not found');
		if (isParentSubdomain && !this.#suinsClient.constants.tempSubNamesProxyPackageId)
			throw new Error('Subdomains proxy package ID not found');

		this.transactionBlock.moveCall({
			target: isParentSubdomain
				? `${this.#suinsClient.constants.tempSubNamesProxyPackageId}::subdomain_proxy::remove_leaf`
				: `${this.#suinsClient.constants.subNamesPackageId}::subdomains::remove_leaf`,
			arguments: [
				this.transactionBlock.object(this.#suinsClient.constants.suinsObjectId),
				this.transactionBlock.object(parentNft),
				this.transactionBlock.object(SUI_CLOCK_OBJECT_ID),
				this.transactionBlock.pure.string(name),
			],
		});
	}

	setTargetAddress({
		nft,
		address,
		isSubdomain,
	}: {
		nft: ObjectArgument;
		address?: string;
		isSubdomain?: boolean;
	}) {
		if (!this.#suinsClient.constants.suinsObjectId) throw new Error('SuiNS Object ID not found');
		if (!this.#suinsClient.constants.utilsPackageId) throw new Error('Utils package ID not found');

		if (isSubdomain && !this.#suinsClient.constants.tempSubNamesProxyPackageId)
			throw new Error('Subdomains proxy package ID not found');

		this.transactionBlock.moveCall({
			target: isSubdomain
				? `${this.#suinsClient.constants.tempSubNamesProxyPackageId}::subdomain_proxy::set_target_address`
				: `${this.#suinsClient.constants.utilsPackageId}::direct_setup::set_target_address`,
			arguments: [
				this.transactionBlock.object(this.#suinsClient.constants.suinsObjectId),
				this.transactionBlock.object(nft),
				this.transactionBlock.pure(address ? [address] : []),
				this.transactionBlock.object(SUI_CLOCK_OBJECT_ID),
			],
		});
	}

	/** Marks a name as default */
	setDefault(name: string) {
		if (!isValidSuiNSName(name)) throw new Error('Invalid SuiNS name');
		if (!this.#suinsClient.constants.suinsObjectId) throw new Error('SuiNS Object ID not found');
		if (!this.#suinsClient.constants.utilsPackageId) throw new Error('Utils package ID not found');

		this.transactionBlock.moveCall({
			target: `${this.#suinsClient.constants.utilsPackageId}::direct_setup::set_reverse_lookup`,
			arguments: [
				this.transactionBlock.object(this.#suinsClient.constants.suinsObjectId),
				this.transactionBlock.pure.string(name),
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
			throw new Error('Subdomains package ID not found');
		if (isParentSubdomain && !this.#suinsClient.constants.tempSubNamesProxyPackageId)
			throw new Error('Subdomains proxy package ID not found');

		this.transactionBlock.moveCall({
			target: isParentSubdomain
				? `${this.#suinsClient.constants.tempSubNamesProxyPackageId}::subdomain_proxy::edit_setup`
				: `${this.#suinsClient.constants.subNamesPackageId}::subdomains::edit_setup`,
			arguments: [
				this.transactionBlock.object(this.#suinsClient.constants.suinsObjectId),
				this.transactionBlock.object(parentNft),
				this.transactionBlock.object(SUI_CLOCK_OBJECT_ID),
				this.transactionBlock.pure.string(name),
				this.transactionBlock.pure.bool(!!allowChildCreation),
				this.transactionBlock.pure.bool(!!allowTimeExtension),
			],
		});
	}

	extendExpiration({
		parentNft,
		expirationTimestampMs,
		isSubdomain,
	}: {
		parentNft: ObjectArgument;
		expirationTimestampMs: number;
		isSubdomain?: boolean;
	}) {
		if (!this.#suinsClient.constants.suinsObjectId) throw new Error('SuiNS Object ID not found');
		if (isSubdomain && !this.#suinsClient.constants.tempSubNamesProxyPackageId)
			throw new Error('Subdomains proxy package ID not found');
		if (!isSubdomain && !this.#suinsClient.constants.subNamesPackageId)
			throw new Error('Subdomains package ID not found');

		this.transactionBlock.moveCall({
			target: `${this.#suinsClient.constants.subNamesPackageId}::subdomains::extend_expiration`,
			arguments: [
				this.transactionBlock.object(this.#suinsClient.constants.suinsObjectId),
				this.transactionBlock.object(parentNft),
				this.transactionBlock.pure.u64(expirationTimestampMs),
			],
		});
	}

	setUserData({ nft, value, key }: { nft: ObjectArgument; value: string; key: string }) {
		if (!this.#suinsClient.constants.suinsObjectId) throw new Error('SuiNS Object ID not found');
		if (!this.#suinsClient.constants.utilsPackageId) throw new Error('Utils package ID not found');

		if ('key' in ALLOWED_METADATA) throw new Error('Invalid key');

		this.transactionBlock.moveCall({
			target: `${this.#suinsClient.constants.utilsPackageId}::direct_setup::set_user_data`,
			arguments: [
				this.transactionBlock.object(this.#suinsClient.constants.suinsObjectId),
				this.transactionBlock.object(nft),
				this.transactionBlock.pure.string(key),
				this.transactionBlock.pure.string(value),
				this.transactionBlock.object(SUI_CLOCK_OBJECT_ID),
			],
		});
	}

	/**
	 * Burns an expired NFT to collect storage rebates.
	 */
	burnExpired({ nft, isSubdomain }: { nft: ObjectArgument; isSubdomain?: boolean }) {
		if (!this.#suinsClient.constants.suinsObjectId) throw new Error('SuiNS Object ID not found');
		if (!this.#suinsClient.constants.utilsPackageId) throw new Error('Utils package ID not found');

		this.transactionBlock.moveCall({
			target: `${this.#suinsClient.constants.utilsPackageId}::direct_setup::${
				isSubdomain ? 'burn_expired_subname' : 'burn_expired'
			}`,
			arguments: [
				this.transactionBlock.object(this.#suinsClient.constants.suinsObjectId),
				this.transactionBlock.object(nft),
				this.transactionBlock.object(SUI_CLOCK_OBJECT_ID),
			],
		});
	}
}
