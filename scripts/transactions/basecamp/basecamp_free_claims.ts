import { TransactionBlock } from "@mysten/sui.js/transactions";
import { Network, mainPackage } from "../../config/constants";
import { setupFreeClaimsForType } from "../../config/discounts";
import { executeTx, prepareMultisigTx, prepareSigner } from "../../airdrop/helper";

const BASECAMP_NFT_TYPE = '0xadccd2df6d388cf75bbe8913a2eb66bb64a079ca3f2c1fab71dfa86671f1daae::commemorative_nfts::Commemorative';

export const setup = async (network: Network) => {
    const setup = mainPackage[network];
    const txb = new TransactionBlock();

    // a free claim for names of 5+ characters for each nami bag NFT
    setupFreeClaimsForType(txb, setup, BASECAMP_NFT_TYPE, { from: 5, to: 63 });

    return prepareMultisigTx(txb, 'mainnet');
}

setup('mainnet')
