// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
import { Transaction } from '@mysten/sui/transactions';

export const getImageUrl = (isSubdomain: boolean, network: 'mainnet' | 'testnet') => {
	const name = `{${isSubdomain ? 'nft.' : ''}domain_name}`;
	const expiration = `{${isSubdomain ? 'nft.' : ''}expiration_timestamp_ms}`;

	return `https://api-${network}.suins.io/nfts/${name}/${expiration}`;
};

/** Creates the display. Should be called for both subnames and names. */
export const createDisplay = ({
	txb,
	publisher,
	isSubdomain,
	suinsPackageIdV1,
	subdomainsPackageId,
	network = 'mainnet',
}: {
	txb: Transaction;
	publisher: string;
	isSubdomain: boolean;
	suinsPackageIdV1: string;
	subdomainsPackageId: string;
	network: 'mainnet' | 'testnet';
}) => {
	const subnameRegistration = `${subdomainsPackageId}::subdomain_registration::SubDomainRegistration`;
	const suinsRegistration = `${suinsPackageIdV1}::suins_registration::SuinsRegistration`;

	const display = txb.moveCall({
		target: `0x2::display::new`,
		arguments: [txb.object(publisher)],
		typeArguments: [isSubdomain ? subnameRegistration : suinsRegistration],
	});

	txb.moveCall({
		target: `0x2::display::add_multiple`,
		arguments: [
			display,
			txb.pure.vector('string', ['name', 'link', 'image_url', 'description', 'project_url']),
			txb.pure.vector('string', [
				`{${isSubdomain ? 'nft.' : ''}domain_name}`,
				`https://{${isSubdomain ? 'nft.' : ''}domain_name}.id`,
				getImageUrl(isSubdomain, network),
				'SuiNS - Sculpt Your Identity',
				'https://suins.io',
			]),
		],
		typeArguments: [isSubdomain ? subnameRegistration : suinsRegistration],
	});

	txb.moveCall({
		target: `0x2::display::update_version`,
		arguments: [display],
		typeArguments: [isSubdomain ? subnameRegistration : suinsRegistration],
	});

	const sender = txb.moveCall({
		target: '0x2::tx_context::sender',
	});

	txb.transferObjects([display], sender);
};
