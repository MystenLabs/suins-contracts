// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
import type { Constants } from './types.js';

/**
 * Allowed keys for metadata.
 */
export const ALLOWED_METADATA = {
	contentHash: 'content_hash',
	avatar: 'avatar',
};

export const getConfigType = (suinsPackageV1: string, innerType: string) =>
	`${suinsPackageV1}::suins::ConfigKey<${innerType}>`;

export const getDomainType = (suinsPackageV1: string) => `${suinsPackageV1}::domain::Domain`;

export const getPricelistConfigType = (suinsPackageId: string) =>
	`${suinsPackageId}::pricing_config::PricingConfig`;

export const getRenewalPricelistConfigType = (suinsPackageId: string) =>
	`${suinsPackageId}::pricing_config::RenewalConfig`;

export const MAINNET_CONFIG: Constants = {
	suinsPackageId: {
		latest: '0xb7004c7914308557f7afbaf0dca8dd258e18e306cb7a45b28019f3d0a693f162',
		v1: '0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0',
	},
	suinsObjectId: '0x6e0ddefc0ad98889c04bab9639e512c21766c5e6366f89e696956d9be6952871',
	utilsPackageId: '0xf7854c81cf500d60a4437f4599f7ff3b89abd13f645ae08f62345c7a25317bee',
	subNamesPackageId: '0xe177697e191327901637f8d2c5ffbbde8b1aaac27ec1024c4b62d1ebd1cd7430',
	tempSubNamesProxyPackageId: '0xdacfd7c1176a68137b38a875d76a2f65d277596d2c632881931d926b16de2698',
	registryTableId: '0xe64cd9db9f829c6cc405d9790bd71567ae07259855f4fba6f02c84f52298c106',
};

export const TESTNET_CONFIG: Constants = {
	suinsPackageId: {
		latest: '0xb4ab809c3cb1c9c802222da482198b04886595a2b1beec89399753bc88a81a5b',
		v1: '0xb4ab809c3cb1c9c802222da482198b04886595a2b1beec89399753bc88a81a5b',
	},
	suinsObjectId: '0xe55868f5adc5f84f946867635d3aba6bd02bedee2c54b5e76a1d88d530443d51',
	utilsPackageId: '',
	subNamesPackageId: '',
	tempSubNamesProxyPackageId: '',
	registryTableId: '',
};
