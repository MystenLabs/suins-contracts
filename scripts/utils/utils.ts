// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
import { execFileSync, execSync } from 'child_process';
import fs, { readFileSync } from 'fs';
import { homedir } from 'os';
import path from 'path';
import { getFullnodeUrl, SuiClient } from '@mysten/sui/client';
import { decodeSuiPrivateKey } from '@mysten/sui/cryptography';
import { Ed25519Keypair } from '@mysten/sui/keypairs/ed25519';
import { Secp256k1Keypair } from '@mysten/sui/keypairs/secp256k1';
import { Secp256r1Keypair } from '@mysten/sui/keypairs/secp256r1';
import { Transaction, UpgradePolicy } from '@mysten/sui/transactions';
import { fromBase64, toBase64 } from '@mysten/sui/utils';

import { Network } from '../init/packages';

const SUI = process.env.SUI_BINARY ?? `sui`;

export const getActiveAddress = () => {
	return execSync(`${SUI} client active-address`, { encoding: 'utf8' }).trim();
};

export const publishPackage = (txb: Transaction, path: string, configPath?: string) => {
	const command = [
		'move',
		...(configPath ? ['--client.config', configPath] : []),
		'build',
		'--dump-bytecode-as-base64',
		'--path',
		path,
	];

	const { modules, dependencies } = JSON.parse(
		execFileSync(SUI, command, {
			encoding: 'utf-8',
		}),
	);

	const cap = txb.publish({
		modules,
		dependencies,
	});

	const sender = txb.moveCall({
		target: `0x2::tx_context::sender`,
	});

	// Transfer the upgrade capability to the sender so they can upgrade the package later if they want.
	txb.transferObjects([cap], sender);
};

export const upgradePackage = (
	txb: Transaction,
	path: string,
	packageId: string,
	upgradeCapId: string,
) => {
	const { modules, dependencies, digest } = JSON.parse(
		execFileSync(SUI, ['move', 'build', '--dump-bytecode-as-base64', '--path', path], {
			encoding: 'utf-8',
		}),
	);

	const cap = txb.object(upgradeCapId);

	const ticket = txb.moveCall({
		target: '0x2::package::authorize_upgrade',
		arguments: [cap, txb.pure.u8(UpgradePolicy.COMPATIBLE), txb.pure(digest)],
	});

	const receipt = txb.upgrade({
		modules,
		dependencies,
		package: packageId,
		ticket,
	});

	txb.moveCall({
		target: '0x2::package::commit_upgrade',
		arguments: [cap, receipt],
	});
};

/// Returns a signer based on the active address of system's sui.
export const getSigner = () => {
	if (process.env.PRIVATE_KEY) {
		console.log('Using supplied private key.');
		const { schema, secretKey } = decodeSuiPrivateKey(process.env.PRIVATE_KEY);

		if (schema === 'ED25519') return Ed25519Keypair.fromSecretKey(secretKey);
		if (schema === 'Secp256k1') return Secp256k1Keypair.fromSecretKey(secretKey);
		if (schema === 'Secp256r1') return Secp256r1Keypair.fromSecretKey(secretKey);

		throw new Error('Keypair not supported.');
	}

	const sender = getActiveAddress();

	const keystore = JSON.parse(
		readFileSync(path.join(homedir(), '.sui', 'sui_config', 'sui.keystore'), 'utf8'),
	);

	for (const priv of keystore) {
		const raw = fromBase64(priv);
		if (raw[0] !== 0) {
			continue;
		}

		const pair = Ed25519Keypair.fromSecretKey(raw.slice(1));
		if (pair.getPublicKey().toSuiAddress() === sender) {
			return pair;
		}
	}

	throw new Error(`keypair not found for sender: ${sender}`);
};

/// Get the client for the specified network.
export const getClient = (network: Network) => {
	const url = process.env.RPC_URL || getFullnodeUrl(network);
	return new SuiClient({ url });
};

/// A helper to sign & execute a transaction.
export const signAndExecute = async (txb: Transaction, network: Network) => {
	const client = getClient(network);
	const signer = getSigner();

	return client.signAndExecuteTransaction({
		transaction: txb,
		signer,
		options: {
			showEffects: true,
			showObjectChanges: true,
		},
	});
};

/// Builds a transaction (unsigned) and saves it on `setup/tx/tx-data.txt` (on production)
/// or `setup/src/tx-data.local.txt` on mainnet.
export const prepareMultisigTx = async (tx: Transaction, network: Network, address?: string) => {
	const adminAddress = address ?? getActiveAddress();
	const client = getClient(network);
	const gasObjectId = process.env.GAS_OBJECT;

	// enabling the gas Object check only on mainnet, to allow testnet multisig tests.
	if (!gasObjectId) throw new Error('No gas object supplied for a mainnet transaction');

	// Prevent any possible RGP changes across epoch change, which would invalidate the transaction.
	tx.setGasPrice(1_000);

	// set the sender to be the admin address from config.
	tx.setSenderIfNotSet(adminAddress as string);

	// setting up gas object for the multi-sig transaction
	if (gasObjectId) await setupGasPayment(tx, gasObjectId, client);

	// first do a dryRun, to make sure we are getting a success.
	const dryRun = await inspectTransaction(tx, client);

	if (!dryRun) throw new Error('This transaction failed.');

	tx.build({
		client,
	}).then((bytes) => {
		let serializedBase64 = toBase64(bytes);

		const output_location =
			process.env.NODE_ENV === 'development' ? './tx/tx-data-local.txt' : './tx/tx-data.txt';

		fs.writeFileSync(output_location, serializedBase64);
	});
};

/// Fetch the gas Object and setup the payment for the tx.
async function setupGasPayment(tx: Transaction, gasObjectId: string, client: SuiClient) {
	const gasObject = await client.getObject({
		id: gasObjectId,
	});

	if (!gasObject.data) throw new Error('Invalid Gas Object supplied.');

	// set the gas payment.
	tx.setGasPayment([
		{
			objectId: gasObject.data.objectId,
			version: gasObject.data.version,
			digest: gasObject.data.digest,
		},
	]);
}

/// A helper to dev inspect a transaction.
async function inspectTransaction(tx: Transaction, client: SuiClient) {
	const result = await client.dryRunTransactionBlock({
		transactionBlock: await tx.build({ client: client }),
	});
	// log the result.
	console.dir(result, { depth: null });

	return result.effects.status.status === 'success';
}

export const getAllObjectsByType = async (type: string, owner: string, client: SuiClient) => {
	let objects = [];
	let hasNextPage = true;
	let cursor = null;

	while (hasNextPage) {
		const data = await client.getOwnedObjects({
			owner,
			filter: {
				StructType: type,
			},
			options: {
				showContent: true,
				showType: true,
			},
			cursor,
		});

		hasNextPage = data.hasNextPage;
		cursor = data.nextCursor;
		objects.push(...data.data.map((x) => x.data!));
	}

	return objects;
};

export const getCoinMetadataId = async (type: string) => {
	const suiClient = new SuiClient({
		url: getFullnodeUrl('mainnet'),
	});
	const metadata = await suiClient.getCoinMetadata({ coinType: type });
	if (!metadata || !metadata.id) {
		throw new Error('Coin metadata or ID not found.');
	}
	return metadata.id;
};
