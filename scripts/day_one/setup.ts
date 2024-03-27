import { TransactionArgument, TransactionBlock } from "@mysten/sui.js/transactions";
import { Network, mainPackage } from "../config/constants";
import { AirdropConfig, addressConfig, mainnetConfig } from "../config/day_one";
import { Network as KioskNetwork, ObjectArgument } from "@mysten/kiosk";
import { KioskClient } from '@mysten/kiosk';

export const dayOneType = (config: AirdropConfig) =>  `${config.packageId}::day_one::DayOne`;


export const createDayOneDisplay = async (tx: TransactionBlock, network: Network) => {
  const config = network === 'mainnet' ? mainnetConfig : addressConfig;
    const displayObject = {
        keys: ["name", "description", "link", "image_url"],
        values: [
            "SuiNS Day 1 NFT #{serial}",
            "The SuiNS Day 1 NFT represents community members who have been with SuiNS since day 1 of launch.",
            "https://suins.io/",
            "https://suins.io/day_one_active_{active}.webp"
        ],
    };

    const mainPackageConfig = mainPackage[network];
    
    let display = tx.moveCall({
        target: "0x2::display::new_with_fields",
        arguments: [
          tx.object(config.publisher),
          tx.pure(displayObject.keys),
          tx.pure(displayObject.values),
        ],
        typeArguments: [dayOneType(config)],
      });
    
      tx.moveCall({
        target: "0x2::display::update_version",
        arguments: [display],
        typeArguments: [dayOneType(config)],
      });
  
      tx.transferObjects([display], tx.pure(mainPackageConfig.adminAddress));
};

export const createDayOneTransferPolicy = async (
    tx: TransactionBlock,
    network: Network,
  ) => {
    const config = network === 'mainnet' ? mainnetConfig : addressConfig;
    const mainPackageConfig = mainPackage[network];

    const kioskClient = new KioskClient({
      client: mainPackageConfig.client,
      network: network === 'mainnet' ? KioskNetwork.MAINNET : KioskNetwork.TESTNET
    })

    const existingPolicy = await kioskClient.getTransferPolicies({ type: dayOneType(config) });
  
    if (existingPolicy.length > 0) {
      console.warn(`Type ${dayOneType} already had a tranfer policy so the transaction was skipped.`);
      return false;
    }
    // create transfer policy
    let transferPolicyCap = createTransferPolicy(tx, dayOneType(config), config.publisher) as TransactionArgument;
  
    // transfer cap to owner
    // @ts-ignore-next-line
    tx.transferObjects([transferPolicyCap], tx.pure(mainPackageConfig.adminAddress));
  
    return true;
  }

const createTransferPolicy = (
  tx: TransactionBlock,
  itemType: string,
  publisher: ObjectArgument,
): TransactionArgument => {
  let [transferPolicy, transferPolicyCap] = tx.moveCall({
		target: `0x2::transfer_policy::new`,
		typeArguments: [itemType],
		arguments: [tx.object(publisher)],
	});

	tx.moveCall({
		target: `0x2::transfer::public_share_object`,
		typeArguments: [`0x2::transfer_policy::TransferPolicy<${itemType}>`],
		arguments: [transferPolicy],
	});

	return transferPolicyCap;
}