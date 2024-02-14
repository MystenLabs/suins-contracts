import { TransactionBlock } from "@mysten/sui.js";
import { mainPackage } from "./config/constants";
import { SuinsTransaction } from "./sdk/suins-transactions";
import { executeTx, prepareSigner, prepareSignerFromPrivateKey } from "./airdrop/helper";


(async () => {
    const suinsTransaction = new SuinsTransaction(mainPackage.testnet, new TransactionBlock());
    suinsTransaction.renew('0xf387f7eb465da77163186dbb5fa2f69d56b842df4bd25a15a1c2acd2a33645f9', 5, 1);

    await executeTx(prepareSignerFromPrivateKey('testnet'), suinsTransaction.transactionBlock);
})();
