module suins::helper {

    use std::bcs;
    use std::vector;
    use suins::configuration::getInvalidDiscountError;

    friend suins::reverse_registrar;
    friend suins::resolver;

    public(friend) fun address_to_string(addr: address): vector<u8> {
        let bytes = bcs::to_bytes(&addr);
        let len = vector::length(&bytes);
        let index = 0;
        let result: vector<u8> = vector[];

        while(index < len) {
            let byte = *vector::borrow(&bytes, index);

            let first: u8 = (byte >> 4) & 0xF;
            // a in HEX == 10 in DECIMAL
            // 'a' in CHAR  == 97 in DECIMAL
            // 8 in HEX == 8 in DECIMAL
            // '8' in CHAR  == 56 in DECIMAL
            if (first > 9) first = first + 87
            else first = first + 48;

            let second: u8 = byte & 0xF;
            if (second > 9) second = second + 87
            else second = second + 48;

            vector::push_back(&mut result, first);
            vector::push_back(&mut result, second);

            index = index + 1;
        };

        result
    }

    // discount is in (0..100], represents percentage
    public(friend) fun calculate_discount(original_fee: u64, discount: u8): u64 {
        if (discount == 100) return 0;
        assert!(discount > 0 && discount < 100, getInvalidDiscountError());

        let remaining_percent = 100 - discount;
        // we split the original_fee into 2 parts and calculate them seperately:
        //  - part 1 = original_fee - part 2
        //  - part 2 = last_two_decimal_digits
        let first_remaining_fee = 0;
        let last_two_decimal_digits;
        if (original_fee > 100) {
            first_remaining_fee = (original_fee / 100) * (remaining_percent as u64);
            last_two_decimal_digits = original_fee % 100;
        } else {
            last_two_decimal_digits = original_fee;
        };

        // we multiply `last_two_decimal_digits` by 100 to keep the last 2 digits
        // e.g. real_fee = last_two_decimal_digits * 100
        // now `last_two_decimal_digits` can be understood to be 1% of the `real_fee`
        let second_remaining_fee = last_two_decimal_digits * (remaining_percent as u64);
        let first_two_integral_digits = second_remaining_fee % 100;
        second_remaining_fee = second_remaining_fee / 100;
        // round up if first 2 integral digits greater than 50
        if (first_two_integral_digits >= 50) second_remaining_fee = second_remaining_fee + 1;
        first_remaining_fee + second_remaining_fee
    }

    #[test_only]
    friend suins::helper_tests;
    #[test_only]
    friend suins::resolver_tests;
}
