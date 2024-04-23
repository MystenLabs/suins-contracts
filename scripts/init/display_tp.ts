// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
import { TransactionBlock } from '@mysten/sui.js/transactions';

/** Creates the display. Should be called for both subnames and names. */
export const createDisplay = ({
	txb,
	publisher,
	isSubdomain,
	suinsPackageIdV1,
}: {
	txb: TransactionBlock;
	publisher: string;
	isSubdomain: boolean;
	suinsPackageIdV1: string;
}) => {
	const display = txb.moveCall({
		target: `0x2::display::new`,
		arguments: [txb.object(publisher)],
		typeArguments: [
			isSubdomain
				? `${suinsPackageIdV1}::subdomain_registration::SubDomainRegistration`
				: `${suinsPackageIdV1}::suins_registration::SuinsRegistration`,
		],
	});

	txb.moveCall({
		target: `0x2::display::add_multiple`,
		arguments: [
			display,
			txb.pure(['name', 'link', 'image_url', 'description', 'project_url']),
			txb.pure([
				`{${isSubdomain ? 'nft.' : ''}domain_name}`,
				`https://{${isSubdomain ? 'nft.' : ''}domain_name}.id`,
				`https://storage.googleapis.com/suins-nft-images/{${isSubdomain ? 'nft.' : ''}image_url}.png`,
				'SuiNS - Sculpt Your Identity',
				'https://suins.io',
			]),
		],
		typeArguments: [
			isSubdomain
				? `${suinsPackageIdV1}::subdomain_registration::SubDomainRegistration`
				: `${suinsPackageIdV1}::suins_registration::SuinsRegistration`,
		],
	});

	txb.moveCall({
		target: `0x2::display::update_version`,
		arguments: [display],
		typeArguments: [
			isSubdomain
				? `${suinsPackageIdV1}::subdomain_registration::SubDomainRegistration`
				: `${suinsPackageIdV1}::suins_registration::SuinsRegistration`,
		],
	});

	const sender = txb.moveCall({
		target: '0x2::tx_context::sender',
	});

	txb.transferObjects([display], sender);
};
