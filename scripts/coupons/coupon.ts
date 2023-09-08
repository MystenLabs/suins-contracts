import { TransactionBlock, isValidSuiAddress } from "@mysten/sui.js";
import { PackageInfo } from "../config/constants";

export class CouponType {
    name?: string;
    type?: number;
    value: string | number | bigint;
    rules: CouponRules;
    
    constructor(value: string | number | bigint, type?: number) {
        this.value = value;
        this.type = type;
        this.rules = {};
    }

    /**
     * Accepts a range for characters.
     * Use plain number for fixed length. (e.g. `setLengthRule(3)`)
     * Use range for specific lengths. Max length = 63, min length = 3
     */
    setLengthRule(range: number[] | number){

        if(typeof range === 'number') range = [range, range];
        if(range.length !== 2 || range[1] < range[0]  || range[0] < 3 || range[1] > 63) 
            throw new Error("Range has to be 2 numbers, from smaller to number, between [3,63]");
        this.rules.length = range;
        return this;
    }
    
    setAvailableClaims(claims: number) {
        this.rules.availableClaims = claims;
        return this;
    }

    setUser(user: string){
        if(!isValidSuiAddress(user)) throw new Error("Invalid address for user.");
        this.rules.user = user;
        return this;
    }

    setExpiration(timestamp_ms: string) {
        this.rules.expiration = timestamp_ms;
        return this;
    }

    /**
     * Accepts a range for years, between [1,5]
     */
    setYears(range: number[]) {
        if(range.length !== 2 || range[1] < range[0]  || range[0] < 1 || range[1] > 5) 
         throw new Error("Range has to be 2 numbers, from smaller to number, between [1,5]");
        this.rules.years = range;
        return this;
    }

    setName(name: string) {
        this.name = name;
        return this;
    }

    /**
     * Converts the coupon to a transaction.
     */
    toTransaction(txb: TransactionBlock, config: PackageInfo): TransactionBlock {

        if(this.type === undefined) throw new Error("You have to define a type");
        if(!this.name) throw new Error("Please define a name for the coupon");

        let couponHouseObject = txb.sharedObjectRef(config.coupons.couponHouse);
        let adminCap = txb.object(config.adminCap);

        let lengthRule = optionalRangeConstructor(txb, config, this.rules.length);
        let yearsRule = optionalRangeConstructor(txb, config, this.rules.years);

        let rules = txb.moveCall({
            target: `${config.coupons.packageId}::rules::new_coupon_rules`,
            arguments: [
                lengthRule, 
                this.rules.availableClaims ? filledOption(txb, this.rules.availableClaims, 'u64') : emptyOption(txb, 'u64'),
                this.rules.user ? filledOption(txb, this.rules.user, 'address') : emptyOption(txb, 'address'),
                this.rules.expiration ? filledOption(txb, this.rules.expiration, 'u64') : emptyOption(txb, 'u64'),
                yearsRule
            ]
        });

        txb.moveCall({
            target: `${config.coupons.packageId}::coupons::admin_add_coupon`,
            arguments:[
                adminCap,
                couponHouseObject,
                txb.pure(this.name),
                txb.pure(this.type),
                txb.pure(this.value),
                rules
            ]
        });

        return txb;

    }
}

export class FixedPriceCoupon extends CouponType {
    constructor(value: string | number | bigint) {
        super(value, 1);
    }
}
export class PercentageOffCoupon extends CouponType {
    constructor(value: string | number | bigint) {
        if(Number(value) <=0 || Number(value) >= 100) throw new Error("Percentage discount can be in (0, 100] range, 0 exclusive.")
        super(value, 0);
    }
}

export type CouponRules = {
    length?: number[];
    availableClaims?: number;
    user?: string;
    expiration?: string;
    years?: number[]
}

const emptyOption = (txb: TransactionBlock, type: string) => {
    return txb.pure({
        None: true
    }, `Option<${type}>`)
};

const filledOption = (txb: TransactionBlock, value: any, type: string) => {
    return txb.pure({
        Some: value
    }, `Option<${type}>`)
};

const optionalRangeConstructor = (txb: TransactionBlock, config: PackageInfo, range?: number[]) => {

    if(!range) return txb.moveCall({
            target: "0x1::option::none", 
            typeArguments: [ `${config.coupons.packageId}::range::Range` ],
            arguments: []
        });;

    let rangeArg = txb.moveCall({
        target: `${config.coupons.packageId}::range::new`,
        arguments: [
            txb.pure(range[0], 'u8'),
            txb.pure(range[1], 'u8'),
        ]
    });

    return txb.moveCall({
            target: "0x1::option::some", 
            typeArguments: [ `${config.coupons.packageId}::range::Range` ],
            arguments: [ rangeArg ]
        });
}
