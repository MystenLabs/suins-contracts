// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
export type PackageInfo = {
	SuiNS: SuiNS;
	DenyList: Package;
	DayOne: Package;
	Coupons: Package;
	Subdomains: Package;
	Discounts: Package & {
		discountHouse: string;
	};
	TempSubdomainProxy: Package;
	BBB?: Package; // Optional - only on mainnet/testnet
	Payments?: Package; // Optional - only on mainnet/testnet (requires BBB and Pyth)
};

export type Package = {
	packageId: string;
	upgradeCap: string;
};

export type SuiNS = {
	packageId: string;
	upgradeCap: string;
	publisher: string;
	suins: string;
	adminCap: string;
};
