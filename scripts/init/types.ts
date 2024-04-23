// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
export type PackageInfo = {
	SuiNS: SuiNS;
	Utils: Package;
	DenyList: Package;
	Registration: Package;
	Renewal: Package;
	DayOne: Package;
	Coupons: Coupons;
	Subdomains: Package;
	Discounts: Package & {
		discountHouse: string;
	};
	TempSubdomainProxy: Package;
};

export type Package = {
	packageId: string;
	upgradeCap: string;
	authorizationType?: string;
};
export type Coupons = Package & {
	couponHouse: string;
};

export type SuiNS = {
	packageId: string;
	upgradeCap: string;
	publisher: string;
	suins: string;
	adminCap: string;
};
