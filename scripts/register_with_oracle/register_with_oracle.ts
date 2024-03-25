import { mainPackage } from "../config/constants";
import { SuiPriceServiceConnection, SuiPythClient } from "@pythnetwork/pyth-sui-js";
import dotenv from "dotenv";
import { executeTx, prepareSigner } from "../airdrop/helper";
import { TransactionBlock } from "@mysten/sui.js/src/transactions";
import { SuiClient } from "@mysten/sui.js/src/client";
dotenv.config();

const setup = async () => {
    const connection = new SuiPriceServiceConnection(
        "https://hermes-beta.pyth.network"
    );
    // You can find the ids of prices at https://pyth.network/developers/price-feed-ids
    const priceIds = ["0x50c67b3fd225db8912a424dd4baed60ffdde625ed2feaaf283724f9608fea266"]; // SUI/USD

    // In order to use Pyth prices in your protocol you need to submit the price update data to Pyth contract in your target
    // chain. `getPriceUpdateData` creates the update data which can be submitted to your contract.
    const priceUpdateData = await connection.getPriceFeedsUpdateData(priceIds);

    // https://docs.pyth.network/price-feeds/contract-addresses/sui
    const wormholeStateId = "0xebba4cc4d614f7a7cdbe883acc76d1cc767922bc96778e7b68be0d15fce27c02";
    const pythStateId = "0x2d82612a354f0b7e52809fc2845642911c7190404620cec8688f68808f8800d8";

    let suiClient = new SuiClient({
        url: "https://suins-rpc.testnet.sui.io:443"
    });
    const client = new SuiPythClient(suiClient, pythStateId, wormholeStateId);
    const txb = new TransactionBlock();
    let priceInfoObjectIds = await client.updatePriceFeeds(txb, priceUpdateData, priceIds);

    const setup = mainPackage["testnet"];
    const [sui_coin] = txb.splitCoins(txb.gas, [txb.pure(20)]);
    const nft = txb.moveCall({
        target: `${setup.registrationPackageId}::register::register`,
        arguments: [
            txb.object(setup.suins), // suins: &mut SuiNS
            txb.object("test_domain"), // domain_name: String
            txb.pure(1), // no_years: u8
            sui_coin, // payment: Coin<SUI>
            txb.object(priceInfoObjectIds[0]), // price_info_object: &PriceInfoObject
            // clock: &Clock
            // ctx: &mut TxContext
        ],
    });
    txb.transferObjects([nft], txb.pure.address('insert_address')) // send to tx sender

    return executeTx(prepareSigner(setup.client), txb);
};

setup();