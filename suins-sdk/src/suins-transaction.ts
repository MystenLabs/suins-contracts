import { TransactionBlock, TransactionObjectArgument } from '@mysten/sui.js/transactions';
import {SUI_CLOCK_OBJECT_ID} from '@mysten/sui.js/utils'
import { SuinsClient } from './suins-client';
import { ObjectArgument } from './types';

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
	renew({
		nftId,
		price,
		years,
	}: {
		nftId: ObjectArgument;
		price: number;
		years: number;
	}) {
		if (!this.#suinsClient.constants.renewalPackageId) throw new Error('Renewal package id not found');
		if (!this.#suinsClient.constants.suinsObjectId) throw new Error('Suins Object ID not found');
		this.#validateYears(years);

		this.transactionBlock.moveCall({
			target: `${this.#suinsClient.constants.renewalPackageId}::renew::renew`,
			arguments: [
				this.transactionBlock.object(this.#suinsClient.constants.suinsObjectId),
				this.transactionBlock.object(nftId),
				this.transactionBlock.pure.u8(years),
				this.transactionBlock.splitCoins(this.transactionBlock.gas, [
					this.transactionBlock.pure.u64(price * years),
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
	register({
		name,
		price,
		years,
	}: {
		name: string;
		price: number;
		years: number;
	
	}) {
		if (!this.#suinsClient.constants.registrationPackageId) throw new Error('Registration package id not found');
		if (!this.#suinsClient.constants.suinsObjectId) throw new Error('Suins Object ID not found');
		this.#isValidSuinsName(name);
		this.#validateYears(years);

		const nft = this.transactionBlock.moveCall({
			target: `${this.#suinsClient.constants.registrationPackageId}::register::register`,
			arguments: [
				this.transactionBlock.object(this.#suinsClient.constants.suinsObjectId),
				this.transactionBlock.pure.string(name),
				this.transactionBlock.pure.u8(years),
				this.transactionBlock.splitCoins(this.transactionBlock.gas, [
					this.transactionBlock.pure.u64(price * years),
				]),
				this.transactionBlock.object(SUI_CLOCK_OBJECT_ID),
			],
		});

		return nft;
	}

	createSubdomain({
		parentNft,
		name,
		expirationTimestampMs,
		parentIsSubdomain,
		allowChildCreation,
		allowTimeExtension,
	}: {
		parentNft: ObjectArgument;
		name: string;
		expirationTimestampMs: number;
		parentIsSubdomain: boolean;
		allowChildCreation: boolean;
		allowTimeExtension: boolean;
	}) {
		if (!this.#suinsClient.constants.suinsObjectId) throw new Error('Suins Object ID not found');
		if (!this.#suinsClient.constants.subdomainsPackageId) throw new Error('Subdomains package ID not found');
		if (parentIsSubdomain && !this.#suinsClient.constants.tempSubdomainsProxyPackageId) throw new Error('Subdomains proxy package ID not found');

		const subNft = this.transactionBlock.moveCall({
			target: `${this.#suinsClient.constants.subdomainsPackageId}::subdomains::new`,
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
	createLeafSubdomain({
		parentNft,
		name,
		targetAddress,
		isParentSubdomain
	}: {
		parentNft: ObjectArgument;
		name: string;
		targetAddress: string;
		isParentSubdomain: boolean;
	}) { 
		if (!this.#suinsClient.constants.suinsObjectId) throw new Error('Suins Object ID not found');
		if (!this.#suinsClient.constants.subdomainsPackageId) throw new Error('Subdomains package ID not found');
		if (isParentSubdomain && !this.#suinsClient.constants.tempSubdomainsProxyPackageId) throw new Error('Subdomains proxy package ID not found');

		this.transactionBlock.moveCall({
			target: isParentSubdomain ? `${this.#suinsClient.constants.tempSubdomainsProxyPackageId}::subdomain_proxy::new_leaf` 
									: `${this.#suinsClient.constants.subdomainsPackageId}::subdomains::new_leaf`,
			arguments: [
			  this.transactionBlock.object(this.#suinsClient.constants.suinsObjectId),
			  this.transactionBlock.object(parentNft),
			  this.transactionBlock.object(SUI_CLOCK_OBJECT_ID),
			  this.transactionBlock.pure(name),
			  this.transactionBlock.pure.address(targetAddress),
			],
		});
	}

	/**
	 * Removes a leaf subdomain.
	 */
	removeLeafSubdomain({
		parentNft,
		name,
		isParentSubdomain,
	}: {
		parentNft: ObjectArgument;
		name: string;
		isParentSubdomain: boolean;
	}) {
		if (!this.#suinsClient.constants.suinsObjectId) throw new Error('Suins Object ID not found');
		if (!this.#suinsClient.constants.subdomainsPackageId) throw new Error('Subdomains package ID not found');
		if (isParentSubdomain && !this.#suinsClient.constants.tempSubdomainsProxyPackageId) throw new Error('Subdomains proxy package ID not found');

		this.transactionBlock.moveCall({
			target: isParentSubdomain ? `${this.#suinsClient.constants.tempSubdomainsProxyPackageId}::subdomain_proxy::remove_leaf` 
									: `${this.#suinsClient.constants.subdomainsPackageId}::subdomains::remove_leaf`,
			arguments: [
			  this.transactionBlock.object(this.#suinsClient.constants.suinsObjectId),
			  this.transactionBlock.object(parentNft),
			  this.transactionBlock.object(SUI_CLOCK_OBJECT_ID),
			  this.transactionBlock.pure(name),
			],
		});
	 }


	setTargetAddress({
		nft,
		address,
		isSubdomain,
	}: {
		nft: ObjectArgument;
		address: string;
		isSubdomain?: boolean;
	}) {
		if (!this.#suinsClient.constants.suinsObjectId) throw new Error('Suins Object ID not found');
		if (!this.#suinsClient.constants.utilsPackageId) throw new Error('Utils package ID not found');

		if (isSubdomain && !this.#suinsClient.constants.tempSubdomainsProxyPackageId) throw new Error('Subdomains proxy package ID not found');

		this.transactionBlock.moveCall({
			target: isSubdomain ? 
								`${this.#suinsClient.constants.tempSubdomainsProxyPackageId}::subdomain_proxy::set_target_address` 
								: `${this.#suinsClient.constants.utilsPackageId}::direct_setup::set_target_address`,
			arguments: [
				this.transactionBlock.object(this.#suinsClient.constants.suinsObjectId),
				this.transactionBlock.object(nft),
				this.transactionBlock.pure.address(address),
			],
		});
	 }

	/** Marks a name as default */
	setDefault({ name }: { name: string }) {
		this.#isValidSuinsName(name);
		if (!this.#suinsClient.constants.suinsObjectId) throw new Error('Suins Object ID not found');
		if (!this.#suinsClient.constants.utilsPackageId) throw new Error('Utils package ID not found');

		this.transactionBlock.moveCall({
			target: `${this.#suinsClient.constants.utilsPackageId}::direct_setup::set_reverse_lookup`,
			arguments: [
				this.transactionBlock.object(this.#suinsClient.constants.suinsObjectId),
				this.transactionBlock.pure.string(name),
			],
		});
	}

	// TODO: Extend this class with more validation methods
	#isValidSuinsName(name: string) {
		if (!name.endsWith('.sui')) throw new Error('Invalid SuiNS name');
	}
	#validateYears(years: number) {
		if (!(years > 0 && years < 6)) throw new Error('Years must be between 1 and 5');
	}
}
