import { SUI_CLOCK_OBJECT_ID, TransactionBlock } from '@mysten/sui.js';

import { PackageInfo } from '../config/constants';

enum DomainLengthCategories {
	ThreeLetter = '3',
	FourLetter = '4',
	FivePlusLetter = '5+',
}

export class SuinsTransaction {
	#config: PackageInfo;
	transactionBlock: TransactionBlock;

	constructor(config: PackageInfo, transactionBlock: TransactionBlock) {
		this.#config = config;
		this.transactionBlock = transactionBlock;
	}

	// TODO: Add a dynamic method for fetching the price list.
	priceList: Record<DomainLengthCategories, string> = {
		[DomainLengthCategories.ThreeLetter]: '10000000000',
		[DomainLengthCategories.FourLetter]: '5000000000',
		[DomainLengthCategories.FivePlusLetter]: '1000000000',
	};

	/**
	 * Constructs the transaction to renew a name.
	 * Expects the nftId, the number of years to renew
	 * as well as the length category of the domain.
	 *
	 * This only applies for SLDs (Second Level Domains) (e.g. example.sui, test.sui).
	 * You can use `getSecondLevelDomainCategory` to get the category of a domain.
	 */
	renew(nftId: string, years: number, category: DomainLengthCategories) {
		this.#validateYears(years);

		this.transactionBlock.moveCall({
			target: `${this.#config.renewalsPackageId}::renew::renew`,
			arguments: [
				this.transactionBlock.object(this.#config.suins),
				this.transactionBlock.object(nftId),
				this.transactionBlock.pure(years),
				this.transactionBlock.splitCoins(this.transactionBlock.gas, [
					this.transactionBlock.pure(this.priceList[category]),
				]),
				this.transactionBlock.object(SUI_CLOCK_OBJECT_ID),
			],
		});
	}

	getSecondLevelDomainCategory(domain: string): DomainLengthCategories {
		// get labels.
		const labels = domain.split('.');
		const sld = labels[1];

		if (sld.length === 3) return DomainLengthCategories.ThreeLetter;
		if (sld.length === 4) return DomainLengthCategories.FourLetter;
		return DomainLengthCategories.FivePlusLetter;
	}

	#validateYears(years: number) {
		if (!(years > 0 && years < 6)) throw new Error('Years must be between 1 and 5');
	}
}
