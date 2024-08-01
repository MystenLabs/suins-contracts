// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
import { TransactionBlock } from '@mysten/sui.js/transactions';
import { MIST_PER_SUI } from '@mysten/sui.js/utils';

import { mainPackage } from '../config/constants';
import { setupDiscountForType } from '../config/discounts';
import { prepareMultisigTx } from '../utils/utils';

export const run = async () => {
	const txb = new TransactionBlock();

	const suiLinkType = (innerType: string) => {
		return `0xf857fa9df5811e6df2a0240a1029d365db24b5026896776ddd1c3c70803bccd3::suilink::SuiLink<${innerType}>`;
	};

	const suilinkSolanaType = suiLinkType(
		'0xf857fa9df5811e6df2a0240a1029d365db24b5026896776ddd1c3c70803bccd3::solana::Solana',
	);

	const ethType = suiLinkType(
		'0xf857fa9df5811e6df2a0240a1029d365db24b5026896776ddd1c3c70803bccd3::ethereum::Ethereum',
	);

	setupDiscountForType(txb, mainPackage.mainnet, suilinkSolanaType, {
		threeCharacterPrice: 400n * MIST_PER_SUI,
		fourCharacterPrice: 60n * MIST_PER_SUI,
		fivePlusCharacterPrice: 10n * MIST_PER_SUI,
	});

	setupDiscountForType(txb, mainPackage.mainnet, ethType, {
		threeCharacterPrice: 400n * MIST_PER_SUI,
		fourCharacterPrice: 60n * MIST_PER_SUI,
		fivePlusCharacterPrice: 10n * MIST_PER_SUI,
	});

	await prepareMultisigTx(txb, 'mainnet', mainPackage.mainnet.adminAddress);
};

run();
