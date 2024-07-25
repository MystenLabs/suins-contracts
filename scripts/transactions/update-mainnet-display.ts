// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
import { TransactionBlock } from '@mysten/sui.js/transactions';

import { mainPackage } from '../config/constants';
import { getImageUrl } from '../init/display_tp';
import { prepareMultisigTx, signAndExecute } from '../utils/utils';

const run = async () => {
	const txb = new TransactionBlock();
	const pkg = mainPackage.mainnet;

	const subnameRegistrationType = `0x00c2f85e07181b90c140b15c5ce27d863f93c4d9159d2a4e7bdaeb40e286d6f5::subdomain_registration::SubDomainRegistration`;
	const suinsRegistrationType = `${pkg.packageId}::suins_registration::SuinsRegistration`;


	// update Display
	const nameDisplay = txb.object(
		`0x866fbd8e51b6637c25f0e811ece9a85eb417f3987ecdfefb80f15d1192d72b4c`,
	);
	const subNameDisplay = txb.object(
		`0xaf0cdabb6592026c58dae385d84791f21ce8e35a75f343f7e11acaf224f6a680`,
	);

	txb.moveCall({
		target: `0x2::display::edit`,
		arguments: [
			nameDisplay,
			txb.pure.string('image_url'),
			txb.pure.string(getImageUrl(false, 'mainnet')),
		],
		typeArguments: [suinsRegistrationType],
	});

	txb.moveCall({
		target: `0x2::display::edit`,
		arguments: [
			subNameDisplay,
			txb.pure.string('image_url'),
			txb.pure.string(getImageUrl(true, 'mainnet')),
		],
		typeArguments: [subnameRegistrationType],
	});

	txb.moveCall({
		target: `0x2::display::update_version`,
		arguments: [nameDisplay],
		typeArguments: [suinsRegistrationType],
	});

	txb.moveCall({
		target: `0x2::display::update_version`,
		arguments: [subNameDisplay],
		typeArguments: [subnameRegistrationType],
	});

    // transfer nikhil.sui to address!
    txb.transferObjects(
        [
            txb.object('0x2560cf8d37120ab69c29969fd69f0d9ce2eaf68f874b6a2cd5e2c9b3ae3487c7')
        ],
        txb.pure.address('0x2fd42dfdbd2eb7055a7bc7d4ce000ae53cc22f0c2f2006862bebc8df1f676027')
    );

	await prepareMultisigTx(txb, 'mainnet', mainPackage.mainnet.adminAddress);
};

run();
