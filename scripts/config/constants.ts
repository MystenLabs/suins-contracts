// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
import { normalizeSuiAddress } from '@mysten/sui/utils';

export type Network = 'mainnet' | 'testnet';

export type Config = Record<'mainnet' | 'testnet', PackageInfo>;

export type DiscordConfig = {
	packageId: string;
	discordCap: string;
	discordObjectId: string;
	discordTableId: string;
};

export type PackageInfo = {
	packageId: string;
	registrationPackageId: string;
	upgradeCap?: string;
	publisherId: string;
	adminAddress: string;
	adminCap: string;
	suins: string;
	displayObject?: string;
	directSetupPackageId: string;
	discountsPackage: {
		packageId: string;
		discountHouseId: string;
	};
	renewalsPackageId: string;
	subNamesPackageId: string;
	tempSubdomainsProxyPackageId: string;
	discord: DiscordConfig | undefined;
	coupons: {
		packageId: string;
	};
	treasuryAddress?: string;
	coins: {
		[key: string]: {
			type: string;
			metadataID: string;
			feed: string;
		};
	};
};

export const mainPackage: Config = {
	mainnet: {
		packageId: '0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0',
		registrationPackageId: '0x9d451fa0139fef8f7c1f0bd5d7e45b7fa9dbb84c2e63c2819c7abd0a7f7d749d',
		upgradeCap: '0x9cda28244a0d0de294d2b271e772a9c33eb47d316c59913d7369b545b4af098c',
		publisherId: '0x7339f23f06df3601167d67a31752781d307136fd18304c48c928778e752caae1',
		adminAddress: normalizeSuiAddress(
			'0xa81a2328b7bbf70ab196d6aca400b5b0721dec7615bf272d95e0b0df04517e72',
		),
		adminCap: '0x3f8d702d90c572b60ac692fb5074f7a7ac350b80d9c59eab4f6b7692786cae0a',
		suins: '0x6e0ddefc0ad98889c04bab9639e512c21766c5e6366f89e696956d9be6952871',
		displayObject: '0x866fbd8e51b6637c25f0e811ece9a85eb417f3987ecdfefb80f15d1192d72b4c',
		discountsPackage: {
			packageId: '0x6a6ea140e095ddd82f7c745905054b3203129dd04a09d0375416c31161932d2d',
			discountHouseId: '0x7fdd883c0b7427f18cdb498c4c87a4a79d6bec4783cb3f21aa3816bbc64ce8ef',
		},
		directSetupPackageId: '0xdac22652eb400beb1f5e2126459cae8eedc116b73b8ad60b71e3e8d7fdb317e2',
		renewalsPackageId: '0xd5e5f74126e7934e35991643b0111c3361827fc0564c83fa810668837c6f0b0f',
		subNamesPackageId: 'TODO: Fill this in...',
		tempSubdomainsProxyPackageId: 'TODO: Fill this in...',
		discord: {
			discordCap: '0xd369c89ef88534b5ba9a78f16fec6adb3b5bc5d2ae72c990fd8aaccae1f2c56b',
			discordObjectId: '0x20eb3a33886f6cfb62600881207dd9acf0de125a40006bb7661898eb8426fae9',
			packageId: '0x408d22066775f20e0c13617c1f157a110d9a5b0873b878692b78aba92b1a46e1',
			discordTableId: '0x118167416475935cd8f98e104faa99302b72a85c8b9ae4ebb7d22fbd269ed8db',
		},
		coupons: {
			packageId: '0x6d14ca3049be747ec87166e6dce5d0d9a30f3b3c281c55d6e518958a236f8b97',
		},
		treasuryAddress: '0x638791b625c4482bc1b917847cdf8aa76fe226c0f3e0a9b1aa595625989e98a1',
		coins: {
			SUI: {
				type: '0x0000000000000000000000000000000000000000000000000000000000000002::sui::SUI',
				metadataID: '0x9258181f5ceac8dbffb7030890243caed69a9599d2886d957a9cb7656af3bdb3',
				feed: '0x23d7315113f5b1d3ba7a83604c44b94d79f4fd69af77f804fc7f920a6dc65744',
			},
			NS: {
				type: '0x5145494a5f5100e645e4b0aa950fa6b68f614e8c59e17bc5ded3495123a79178::ns::NS',
				metadataID: '0x279adec041f8ec5c2d419abf2c32713ae7930a9a3a1ff244c88e5ceced40db6e',
				feed: '0xbb5ff26e47a3a6cc7ec2fce1db996c2a145300edc5acaabe43bf9ff7c5dd5d32',
			},
			USDC: {
				type: '0xdba34672e30cb065b1f93e3ab55318768fd6fef66c15942c9f7cb846e2f900e7::usdc::USDC',
				metadataID: '0x69b7a7c3c200439c1b5f3b19d7d495d5966d5f08de66c69276152f8db3992ec6',
				feed: '',
			},
		},
	},
	testnet: {
		packageId: '0x22fa05f21b1ad71442491220bb9338f7b7095fe35000ef88d5400d28523bdd93',
		registrationPackageId: '0x4255184a0143c0ce4394a3f16a6f5aa5d64507269e54e51ea396d569fe8f1ba5',
		publisherId: '0x62d9690d7e6234bfd57170a89c9c8ec54604ea31cefaa3869e8be4912ee1a4ab',
		adminAddress: '0xfe09cf0b3d77678b99250572624bf74fe3b12af915c5db95f0ed5d755612eb68',
		adminCap: normalizeSuiAddress(
			'0x5def5bd9dc94b7d418d081a91c533ec619fb4350e6c4e4602aea96fd49331b15',
		),
		suins: '0x300369e8909b9a6464da265b9a5a9ab6fe2158a040e84e808628cde7a07ee5a3',
		directSetupPackageId: '0xb82c701b383df8e5e55e2c8f201ee5a9fe43fc252dad291d52cc7da32f44161f',
		discountsPackage: {
			packageId: 'TODO: Fill this in...',
			discountHouseId: 'TODO: Fill this in...',
		},
		renewalsPackageId: '0x54800ebb4606fd0c03b4554976264373b3374eeb3fd63e7ff69f31cac786ba8c',
		subNamesPackageId: '0x3c272bc45f9157b7818ece4f7411bdfa8af46303b071aca4e18c03119c9ff636',
		tempSubdomainsProxyPackageId:
			'0x3489ab5dcd346afee8b681267bcab2583a5eba9855680ec9931355e50e21c148',
		discord: {
			discordCap: '0x539810749d2f6f59f54606a6aaef0123f1568a8564b74e1eedff7ad768e0d0db',
			discordObjectId: '0x2e10e61b53e17e89aef8f8137e8ed3207043410ac3b628294a1f09ef059fac09',
			packageId: '0x8f01eb1378d53e62239f8cf4ca495c703eb346f35902cf5d7b7727cd6c0b39fc',
			discordTableId: '0x594e2b06246d5c4112309a8549eb2cc21169a884c05a87ef35e42cda1f4d54a4',
		},
		coupons: {
			packageId: '0x689a2d65a9666921e73ad4d59d13fee0d4be5df1ab5c0eeda8e0f7ebecb6f1b7',
		},
		/// Testnet coins will be different here for testing purposes, we can publish our own
		coins: {
			SUI: {
				type: '0x0000000000000000000000000000000000000000000000000000000000000002::sui::SUI',
				metadataID: '0x587c29de216efd4219573e08a1f6964d4fa7cb714518c2c8a0f29abfa264327d',
				feed: '0x50c67b3fd225db8912a424dd4baed60ffdde625ed2feaaf283724f9608fea266',
			},
			/// this is a test token published as 0xb48aac3f53bab328e1eb4c5b3c34f55e760f2fb3f2305ee1a474878d80f650f0::TESTNS::TESTNS
			NS: {
				type: '0xb48aac3f53bab328e1eb4c5b3c34f55e760f2fb3f2305ee1a474878d80f650f0::TESTNS::TESTNS',
				metadataID: '0xaa8b452c0b45dbda946aeb65ee050da5a32b5a4f18abff8b4020bfd041cc17d3',
				feed: '0x65aca56071505735c09091deb8733fdeba265bd9723dd4fb326b5ffd6843b3a3',
			},
			/// this is a test token published as 0xb48aac3f53bab328e1eb4c5b3c34f55e760f2fb3f2305ee1a474878d80f650f0::TESTUSDC::TESTUSDC
			USDC: {
				type: '0xb48aac3f53bab328e1eb4c5b3c34f55e760f2fb3f2305ee1a474878d80f650f0::TESTUSDC::TESTUSDC',
				metadataID: '0xd7ec3e9792cf4b3282238d64b96197a18f3e972f311800c485900b02e85ef62c',
				feed: '',
			},
		},
	},
};

export const MIST_PER_USDC = 1000000;
export const MAX_AGE = 1000 * 60 * 60; // 1 Hour as max age for last price, can be updated
