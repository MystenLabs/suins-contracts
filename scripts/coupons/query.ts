import { PackageInfo, mainPackage } from "../config/constants";
import { CouponRules } from "./coupon";

export enum CouponTypes {
    PERCENTAGE,
    FIXED
}

export type CouponInfo = {
    name: string;
    type: CouponTypes;
    amount: string;
    rules: {
        availableClaims?: number;
        expiration?: string;
        expirationDate?: Date;
        length?: number[];
        user?: string;
        years?: number[]
    }
}

export const getCouponByCodeName = async (name: string, config: PackageInfo): Promise<CouponInfo | undefined> => {
    let coupon = await config.provider.getDynamicFieldObject({
        parentId: config.coupons.tableId,
        name: {
            type: '0x1::string::String',
            value: name
        }
    });

    if(!coupon.data) return undefined;
    // @ts-ignore-next-line
    let parsedData = coupon.data?.content?.fields?.value?.fields;

    const rules: CouponRules = {}

    let ruleset = parsedData.rules.fields;

    if(ruleset.available_claims) rules.availableClaims = Number(ruleset.available_claims);
    if(ruleset.expiration) rules.expiration = ruleset.expiration;
    if(ruleset.user) rules.user = ruleset.user;
    if(ruleset.length?.fields.vec) rules.length = ruleset.length.fields.vec;
    if(ruleset.years?.fields.vec) rules.years = ruleset.years.fields.vec;


    let couponObject: CouponInfo = {
        name,
        amount: parsedData.amount, 
        type: parsedData.type === 0 ? CouponTypes.PERCENTAGE : CouponTypes.FIXED,
        rules
    }

    if(couponObject.rules.expiration){
        couponObject.rules.expirationDate = new Date(Number(couponObject.rules.expiration))
    }
    console.log(couponObject);
    return couponObject;
}

getCouponByCodeName('10_OFF', mainPackage.testnet);
getCouponByCodeName('100_SUI_DISC', mainPackage.testnet);
getCouponByCodeName('DISCOUNT50', mainPackage.testnet);
getCouponByCodeName('3_DIGIT_75_OFF', mainPackage.testnet);
