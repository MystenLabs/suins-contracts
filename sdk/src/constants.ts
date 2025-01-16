// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import type { Config } from './types';

export const MAX_U64 = BigInt('18446744073709551615');

/**
 * Allowed keys for metadata.
 */
export const ALLOWED_METADATA = {
	contentHash: 'content_hash',
	avatar: 'avatar',
	walrusSiteId: 'walrus_site_id',
};

export const getConfigType = (suinsPackageV1: string, innerType: string) =>
	`${suinsPackageV1}::suins::ConfigKey<${innerType}>`;

export const getDomainType = (suinsPackageV1: string) => `${suinsPackageV1}::domain::Domain`;

export const getPricelistConfigType = (suinsPackageId: string) =>
	`${suinsPackageId}::pricing_config::PricingConfig`;

export const getRenewalPricelistConfigType = (suinsPackageId: string) =>
	`${suinsPackageId}::pricing_config::RenewalConfig`;

export const getCoinDiscountConfigType = (paymentPackageId: string) =>
	`${paymentPackageId}::payments::PaymentsConfig`;

export const mainPackage: Config = {
	mainnet: {
		packageId: '0x71af035413ed499710980ed8adb010bbf2cc5cacf4ab37c7710a4bb87eb58ba5',
		packageIdV1: '0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0',
		packageIdPricing: '0x71af035413ed499710980ed8adb010bbf2cc5cacf4ab37c7710a4bb87eb58ba5',
		suins: '0x6e0ddefc0ad98889c04bab9639e512c21766c5e6366f89e696956d9be6952871',
		discountsPackage: {
			packageId: '0x03f625d805339b1b0235ba8c503fa6ea62c88c02ddf14cd9d246d9e1febc0c76',
			discountHouseId: '0x4ce82dee11e6f4858509dcdba1a62985f12e5afb054df680a04f16790bfe1d04',
		},
		subNamesPackageId: '0xe177697e191327901637f8d2c5ffbbde8b1aaac27ec1024c4b62d1ebd1cd7430',
		tempSubdomainsProxyPackageId:
			'0xf335dfbcb2020fc996250c0d6fd4655c5e2036b0606cac7408aa163f51340886',
		coupons: {
			packageId: '0xb162340524e0697461c307b9dc530c17e837b0f2c6d7f787da40d29d29681e5e',
		},
		payments: {
			packageId: '0x863d5f9760f302495398c8e4c6e9784bc17c44b079c826a1813715ef08cbe41a',
		},
		pyth: {
			pythStateId: '0x1f9310238ee9298fb703c3419030b35b22bb1cc37113e3bb5007c99aec79e5b8',
			wormholeStateId: '0xaeab97f96cf9877fee2883315d459552b2b921edc16d7ceac6eab944dd88919c',
		},
		coins: {
			SUI: {
				type: '0x0000000000000000000000000000000000000000000000000000000000000002::sui::SUI',
				feed: '0x23d7315113f5b1d3ba7a83604c44b94d79f4fd69af77f804fc7f920a6dc65744',
			},
			NS: {
				type: '0x5145494a5f5100e645e4b0aa950fa6b68f614e8c59e17bc5ded3495123a79178::ns::NS',
				feed: '0xbb5ff26e47a3a6cc7ec2fce1db996c2a145300edc5acaabe43bf9ff7c5dd5d32',
			},
			USDC: {
				type: '0xdba34672e30cb065b1f93e3ab55318768fd6fef66c15942c9f7cb846e2f900e7::usdc::USDC',
				feed: '',
			},
		},
		registryTableId: '0xe64cd9db9f829c6cc405d9790bd71567ae07259855f4fba6f02c84f52298c106',
	},
	testnet: {
		packageId: '0x40eee27b014a872f5c3330dcd5329aa55c7fe0fcc6e70c6498852e2e3727172e',
		packageIdV1: '0x22fa05f21b1ad71442491220bb9338f7b7095fe35000ef88d5400d28523bdd93',
		packageIdPricing: '0x8a4df604a449ccb9ef2efb9747046b78f78ba60fc8d88df098d0dd47619df5a4',
		suins: '0x300369e8909b9a6464da265b9a5a9ab6fe2158a040e84e808628cde7a07ee5a3',
		discountsPackage: {
			packageId: '0x7976f9bfe81dcbdbb635efb0ecb02844cd79109d3a698d05c06ca9fd2f97d262',
			discountHouseId: '0x9f1ac0f49ddaec4fd2248ae1cc63ed91946f43a236b333439efb9126f31f8e9b',
		},
		subNamesPackageId: '0x3c272bc45f9157b7818ece4f7411bdfa8af46303b071aca4e18c03119c9ff636',
		tempSubdomainsProxyPackageId:
			'0x295a0749dae0e76126757c305f218f929df0656df66a6361f8b6c6480a943f12',
		coupons: {
			packageId: '0x63029aae8abbefae4f4ac6c5e3e0021159ea93a94ba648681fd64caf5b40677a',
		},
		payments: {
			packageId: '0x9e8b85270cf5e7ec0ae44c745abe000b6dd7d8b54ca2d367e044d8baccefc10c',
		},
		pyth: {
			pythStateId: '0x243759059f4c3111179da5878c12f68d612c21a8d54d85edc86164bb18be1c7c',
			wormholeStateId: '0x31358d198147da50db32eda2562951d53973a0c0ad5ed738e9b17d88b213d790',
		},
		/// Testnet coins will be different here for testing purposes, we can publish our own
		coins: {
			SUI: {
				type: '0x0000000000000000000000000000000000000000000000000000000000000002::sui::SUI',
				feed: '0x50c67b3fd225db8912a424dd4baed60ffdde625ed2feaaf283724f9608fea266',
			},
			/// this is a test token published as 0xb48aac3f53bab328e1eb4c5b3c34f55e760f2fb3f2305ee1a474878d80f650f0::TESTNS::TESTNS
			/// NS token is using the HFT feed since NS feed on testnet is not available
			NS: {
				type: '0xb48aac3f53bab328e1eb4c5b3c34f55e760f2fb3f2305ee1a474878d80f650f0::TESTNS::TESTNS',
				feed: '0x99137a18354efa7fb6840889d059fdb04c46a6ce21be97ab60d9ad93e91ac758',
			},
			/// this is a test token published as 0xb48aac3f53bab328e1eb4c5b3c34f55e760f2fb3f2305ee1a474878d80f650f0::TESTUSDC::TESTUSDC
			USDC: {
				type: '0xb48aac3f53bab328e1eb4c5b3c34f55e760f2fb3f2305ee1a474878d80f650f0::TESTUSDC::TESTUSDC',
				feed: '',
			},
		},
		registryTableId: '0xb120c0d55432630fce61f7854795a3463deb6e3b443cc4ae72e1282073ff56e4',
	},
};

export const MIST_PER_USDC = 1000000;
