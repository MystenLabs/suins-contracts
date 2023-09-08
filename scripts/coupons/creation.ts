import { MIST_PER_SUI, TransactionBlock } from "@mysten/sui.js"
import { FixedPriceCoupon, PercentageOffCoupon } from "./coupon"
import { PackageInfo, mainPackage } from "../config/constants";
import { executeTx, inspectTransaction, prepareSigner } from "../airdrop/helper";

const exampleCouponsCreation = async (config: PackageInfo) => {

    const txb = new TransactionBlock();

    new FixedPriceCoupon(100n * MIST_PER_SUI)
        .setName("100_SUI_DISC")
        .setAvailableClaims(5)
        .setUser(config.adminAddress)
        .setLengthRule([5,63])
        .toTransaction(txb, config);

    // // 50% OFF for 3 or 4 letter names with at least 2 years of purchase.
    new PercentageOffCoupon(50)
        .setName("DISCOUNT50")
        .setAvailableClaims(100)
        .setYears([2,5])
        .setLengthRule([3,4])
        .toTransaction(txb, config);

    // 75% OFF for 3 digit names, expires September 15h,
    new PercentageOffCoupon(75)
        .setExpiration(String(1694781382 * 1000)) // September 15th
        .setName("3_DIGIT_75_OFF")
        .setLengthRule(3) // Only works with 3 letter names
        .toTransaction(txb, config);


    // // 10 SUI off for 5 + digits
    new FixedPriceCoupon(10n * MIST_PER_SUI)
        .setExpiration(String(1694781382 * 1000)) // September 15th
        .setName("10_OFF")
        .setLengthRule([5, 63]) // Only works with 5+ letter names
        .toTransaction(txb, config);


    // await inspectTransaction(txb, config.provider, 'testnet');
    const signer = prepareSigner(config.provider);
    // console.log(signer)
    
    await executeTx(signer, txb);
}

exampleCouponsCreation(mainPackage.testnet);
