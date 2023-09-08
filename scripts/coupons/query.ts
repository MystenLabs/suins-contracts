import { PackageInfo, mainPackage } from "../config/constants";

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

    let couponObject: CouponInfo = {
        name,
        amount: parsedData.amount, 
        type: parsedData.type === 0 ? CouponTypes.PERCENTAGE : CouponTypes.FIXED,
        rules: {
            availableClaims: parsedData.rules.fields.available_claims ? Number(parsedData.rules.fields.available_claims) : undefined,
            expiration: parsedData.rules.fields.expiration ?? undefined,
            user: parsedData.rules.fields.user ?? undefined,
            length: parsedData.rules.fields.length?.fields.vec,
            years: parsedData.rules.fields.years?.fields.vec
        }
    }

    if(couponObject.rules.expiration){
        couponObject.rules.expirationDate = new Date(Number(couponObject.rules.expiration))
    }
    return couponObject;
}

getCouponByCodeName('10_OFF', mainPackage.testnet);
getCouponByCodeName('100_SUI_DISC', mainPackage.testnet);
getCouponByCodeName('DISCOUNT50', mainPackage.testnet);
getCouponByCodeName('3_DIGIT_75_OFF', mainPackage.testnet);
