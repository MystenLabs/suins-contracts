import { mainPackage } from "../config/constants";
import { Price, PriceFeed, SuiPriceServiceConnection, SuiPythClient } from "@pythnetwork/pyth-sui-js";
import dotenv from "dotenv";
import { executeTx, prepareSigner } from "../airdrop/helper";
import { TransactionBlock } from "@mysten/sui.js/transactions";
import { SuiClient } from "@mysten/sui.js/client";
import { SUI_CLOCK_OBJECT_ID } from "@mysten/sui.js/utils";
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
    // these are new deployments for testing
    const registration = "0xa0aef08af40d63cc6f471bbd5fd3e137d7522b48f8864743423fa992f37d6d73";
    const suiNS = "0xa4788f3cdf9f5204571f2f10892ff6000a85be981789aeada438fc45a187066c";

    const setup = mainPackage["testnet"];
    // @ts-ignore-next-line
    const client = new SuiPythClient(setup.client, pythStateId, wormholeStateId);

    const txb = new TransactionBlock();
    // @ts-ignore-next-line
    let priceInfoObjectIds = await client.updatePriceFeeds(txb, priceUpdateData, priceIds); // update price feed in txb

    // get quantity of SUI required for registration
    // this can also be done off chain using pyth
    // https://docs.pyth.network/price-feeds/use-real-time-data/sui#off-chain-prices
    let quantity = txb.moveCall({
        target: `${registration}::register::get_sui_required`,
        arguments: [
            txb.object(priceInfoObjectIds[0]),
            txb.pure(20000000000), // $20
        ]
    });

    const coin = txb.splitCoins(txb.gas, [quantity]);
    const nft = txb.moveCall({
        target: `${registration}::register::register`,
        arguments: [
            txb.object(suiNS),
            txb.pure("testdomain3.sui"),
            txb.pure(1),
            coin,
            txb.object(priceInfoObjectIds[0]),
            txb.object(SUI_CLOCK_OBJECT_ID),
        ],
    });
    txb.transferObjects([nft], txb.pure.address('YOUR_ADDRESS')) // send to tx sender

    return executeTx(prepareSigner(), txb, setup.client);
};

setup();