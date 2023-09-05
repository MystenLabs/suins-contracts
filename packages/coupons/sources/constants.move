// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

// Some constants used in coupons 
module coupons::constants {

    // discount types
    const PERCENTAGE_DISCOUNT: u8 = 0;
    const FIXED_PRICE_DISCOUNT: u8 = 1;
    public fun percentage_discount_type(): u8 { PERCENTAGE_DISCOUNT  }
    public fun fixed_price_discount_type(): u8 { FIXED_PRICE_DISCOUNT }
    // A vector with all the discount rule types.
    public fun discount_rule_types(): vector<u8> { vector[PERCENTAGE_DISCOUNT, FIXED_PRICE_DISCOUNT] }

    /// === RULES FOR DOMAIN CHARACTER SIZES ===
    // Allow only the length of a specific size (e..g only 20 digits)
    const FIXED_LENGTH_RULE: u8 = 0;
    // Allow only the length >= size (e.g. >= 20 digits)
    const MIN_CHAR_RULE: u8 = 1;
    // Allow only the length <= size (e.g. <=4 digits)
    const MAX_CHAR_RULE: u8 = 2;

    public fun fixed_length_rule():u8{ FIXED_LENGTH_RULE }
    public fun min_char_rule():u8{ MIN_CHAR_RULE }
    public fun max_char_rule():u8{ MAX_CHAR_RULE }
    // A vector with all the length rules.
    public fun name_rules(): vector<u8> { vector[FIXED_LENGTH_RULE, MIN_CHAR_RULE, MAX_CHAR_RULE] }
}
