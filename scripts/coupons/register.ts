import { MIST_PER_SUI, SUI_CLOCK_OBJECT_ID, TransactionBlock } from "@mysten/sui.js"
import { PackageInfo, mainPackage } from "../config/constants";
import { executeTx, inspectTransaction, prepareSigner } from "../airdrop/helper";


const prices: Record<string, number> = {
    '3': 300000,
    '4': 200000,
    '5': 100000
}

///  Name without .sui
export const registerWithDiscount = async (nameWithoutTld: string, coupon_code: string, config: PackageInfo) => {
    const txb = new TransactionBlock();

    const price = txb.moveCall({
        target: `${config.coupons.packageId}::coupons::calculate_sale_price`,
        arguments: [
            txb.sharedObjectRef(config.coupons.couponHouse),
            txb.pure(nameWithoutTld.length < 5 ? prices[nameWithoutTld.length] : prices['5'], 'u64'),
            txb.pure(coupon_code, 'string')
        ]
    });

    const coin = txb.splitCoins(txb.gas, [price]);

    const registration = txb.moveCall({
        target: `${config.coupons.packageId}::coupons::register_with_coupon`,
        arguments: [
            txb.sharedObjectRef(config.coupons.couponHouse),
            txb.object(config.suins),
            txb.pure(coupon_code, 'string'),
            txb.pure(`${nameWithoutTld}.sui`, 'string'),
            txb.pure(1, 'u8'),
            coin,
            txb.object(SUI_CLOCK_OBJECT_ID)
        ]
    });

    const signer = prepareSigner(config.provider);
    const activeAddr = await signer.getAddress();

    txb.transferObjects([registration], txb.pure(activeAddr, 'address'));

    // await inspectTransaction(txb, config.provider, 'testnet');

    await executeTx(prepareSigner(config.provider), txb);
    
}


registerWithDiscount('oxo', '3_DIGIT_75_OFF', mainPackage.testnet);
