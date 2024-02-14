import { TransactionBlock } from "@mysten/sui.js";
import { mainPackage } from "./config/constants";
import { SuinsTransaction } from "./sdk/suins-transactions";
import { executeTx, prepareSigner, prepareSignerFromPrivateKey } from "./airdrop/helper";


(async () => {

    const suinsTransaction = new SuinsTransaction(mainPackage.testnet, new TransactionBlock());

    suinsTransaction.renew(
        '0x5135953cf5b95cf8149465adf1fb2b1f23ad6c0c57057021bade6ff654749ce0', 
        1, 
        suinsTransaction.getSecondLevelDomainCategory('dn1.sui')
    );

    await executeTx(prepareSignerFromPrivateKey('testnet'), suinsTransaction.transactionBlock);
})();
