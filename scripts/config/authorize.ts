import { TransactionBlock } from '@mysten/sui.js';

import { mainPackage, Network } from '../config/constants';

/**
 * Default code for authorizing an app on SuiNS
 * `app` should be in the type of `packageId::app::AppName`
 * e..g `0x701b8ca1c40f11288a1ed2de0a9a2713e972524fbab748a7e6c137225361653f::renew::Renew`
 */
export const authorizeApp = async (network: Network, txb: TransactionBlock, app: string) => {
	const suinsPackageConfig = mainPackage[network];

	txb.moveCall({
		target: `${suinsPackageConfig.packageId}::suins::authorize_app`,
		arguments: [txb.object(suinsPackageConfig.adminCap), txb.object(suinsPackageConfig.suins)],
		typeArguments: [app],
	});
};

/** Default code for de-authorizing an app on SuiNS */
export const deauthorizeApp = async (
	network: Network,
	txb: TransactionBlock,
	app: string,
): Promise<TransactionBlock | void> => {
	const suinsPackageConfig = mainPackage[network];

	txb.moveCall({
		target: `${suinsPackageConfig.packageId}::suins::deauthorize_app`,
		arguments: [txb.object(suinsPackageConfig.adminCap), txb.object(suinsPackageConfig.suins)],
		typeArguments: [app],
	});

	return txb;
};
