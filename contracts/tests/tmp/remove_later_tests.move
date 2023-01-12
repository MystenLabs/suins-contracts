#[test_only]
module suins::remove_later_tests {

    use std::vector;
    use std::ascii;
    use suins::remove_later;

    #[test]
    fun test_deserialize_new_discount_code_batch() {
        let codes = remove_later::deserialize_new_discount_code_batch(b"DF1234,10,0x0000000000000000000000000000000c9310f87e");
        assert!(vector::length(&codes) == 1, 0);
        let discount_code = vector::borrow(&codes, 0);
        let (code, rate, owner) = remove_later::get_discount_fields(discount_code);
        assert!(code == ascii::string(b"DF1234"), 0);
        assert!(rate == 10, 0);
        assert!(owner == ascii::string(b"0000000000000000000000000000000c9310f87e"), 0);

        codes = remove_later::deserialize_new_discount_code_batch(b"abc23,25,0x0000000000000000000000000000000000abcdef;");
        assert!(vector::length(&codes) == 1, 0);
        discount_code = vector::borrow(&codes, 0);
        let (code, rate, owner) = remove_later::get_discount_fields(discount_code);
        assert!(code == ascii::string(b"abc23"), 0);
        assert!(rate == 25, 0);
        assert!(owner == ascii::string(b"0000000000000000000000000000000000abcdef"), 0);

        codes = remove_later::deserialize_new_discount_code_batch(b"abc23asds,100,0xABCDef;");
        assert!(vector::length(&codes) == 1, 0);
        discount_code = vector::borrow(&codes, 0);
        let (code, rate, owner) = remove_later::get_discount_fields(discount_code);
        assert!(code == ascii::string(b"abc23asds"), 0);
        assert!(rate == 100, 0);
        assert!(owner == ascii::string(b"0000000000000000000000000000000000abcdef"), 0);

        // code batch without semicolon at the end
        codes = remove_later::deserialize_new_discount_code_batch(b"abc23asds,100,0xABCDef;DF1234,10,0x0000000000000000000000000000000c9310f87e");
        assert!(vector::length(&codes) == 2, 0);
        discount_code = vector::borrow(&codes, 0);
        let (code, rate, owner) = remove_later::get_discount_fields(discount_code);
        assert!(code == ascii::string(b"abc23asds"), 0);
        assert!(rate == 100, 0);
        assert!(owner == ascii::string(b"0000000000000000000000000000000000abcdef"), 0);
        discount_code = vector::borrow(&codes, 1);
        let (code, rate, owner) = remove_later::get_discount_fields(discount_code);
        assert!(code == ascii::string(b"DF1234"), 0);
        assert!(rate == 10, 0);
        assert!(owner == ascii::string(b"0000000000000000000000000000000c9310f87e"), 0);

        // code batch with semicolon at the end
        codes = remove_later::deserialize_new_discount_code_batch(b"abc23asds,100,0xABCDef;DF1234,10,0x0000000000000000000000000000000c9310f87e;");
        assert!(vector::length(&codes) == 2, 0);
        discount_code = vector::borrow(&codes, 0);
        let (code, rate, owner) = remove_later::get_discount_fields(discount_code);
        assert!(code == ascii::string(b"abc23asds"), 0);
        assert!(rate == 100, 0);
        assert!(owner == ascii::string(b"0000000000000000000000000000000000abcdef"), 0);
        discount_code = vector::borrow(&codes, 1);
        let (code, rate, owner) = remove_later::get_discount_fields(discount_code);
        assert!(code == ascii::string(b"DF1234"), 0);
        assert!(rate == 10, 0);
        assert!(owner == ascii::string(b"0000000000000000000000000000000c9310f87e"), 0);
    }

    #[test, expected_failure(abort_code = remove_later::EInvalidDiscountCodeBatch)]
    fun test_deserialize_new_discount_code_batch_abort_if_rate_greater_than_100() {
        remove_later::deserialize_new_discount_code_batch(b"DF1234,102,0x00000000000c9310f87e");
    }

    #[test, expected_failure(abort_code = remove_later::EInvalidDiscountCodeBatch)]
    fun test_deserialize_new_discount_code_batch_abort_with_invalid_owner() {
        remove_later::deserialize_new_discount_code_batch(b"DF1234,10,0x00000000000c9Ge");
    }

    #[test, expected_failure(abort_code = remove_later::EInvalidDiscountCodeBatch)]
    fun test_deserialize_new_discount_code_batch_abort_if_owner_starts_with_0X() {
        remove_later::deserialize_new_discount_code_batch(b"abc23asds,100,0XABCDef;");
    }

    #[test, expected_failure(abort_code = remove_later::EInvalidDiscountCodeBatch)]
    fun test_deserialize_new_discount_code_batch_abort_if_owner_not_starts_with_0x() {
        let batch: vector<u8> = vector[68, 46, 31, 32, 33, 34, 44, 31, 30, 44, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 63, 39, 65];
        remove_later::deserialize_new_discount_code_batch(batch);
    }

    #[test, expected_failure(abort_code = remove_later::EInvalidDiscountCodeBatch)]
    fun test_deserialize_new_discount_code_batch_abort_if_code_has_unprintable_character() {
        let batch: vector<u8> = vector[0x7F, 0x1F, 31, 32, 33, 34, 44, 31, 30, 44, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 63, 39, 65];
        remove_later::deserialize_new_discount_code_batch(batch);
    }

    #[test]
    fun test_deserialize_remove_discount_code_batch() {
        let codes = remove_later::deserialize_remove_discount_code_batch(b"DF1234;");
        assert!(vector::length(&codes) == 1, 0);
        let code = vector::borrow(&codes, 0);
        assert!(*code == ascii::string(b"DF1234"), 0);

        codes = remove_later::deserialize_remove_discount_code_batch(b"abc23");
        assert!(vector::length(&codes) == 1, 0);
        code = vector::borrow(&codes, 0);
        assert!(*code == ascii::string(b"abc23"), 0);

        let batch: vector<u8> = vector[61, 62, 63, 32, 33];
        codes = remove_later::deserialize_remove_discount_code_batch(batch);
        assert!(vector::length(&codes) == 1, 0);
        code = vector::borrow(&codes, 0);
        assert!(*code == ascii::string(batch), 0);

        // code batch without semicolon at the end
        codes = remove_later::deserialize_remove_discount_code_batch(b"abc23asds;DF1234");
        assert!(vector::length(&codes) == 2, 0);
        code = vector::borrow(&codes, 0);
        assert!(*code == ascii::string(b"abc23asds"), 0);
        code = vector::borrow(&codes, 1);
        assert!(*code == ascii::string(b"DF1234"), 0);

        // code batch with semicolon at the end
        codes = remove_later::deserialize_remove_discount_code_batch(b"abc23asds;DF1234;");
        assert!(vector::length(&codes) == 2, 0);
        code = vector::borrow(&codes, 0);
        assert!(*code == ascii::string(b"abc23asds"), 0);
        code = vector::borrow(&codes, 1);
        assert!(*code == ascii::string(b"DF1234"), 0);
    }

    #[test, expected_failure(abort_code = remove_later::EInvalidDiscountCodeBatch)]
    fun test_deserialize_remove_discount_code_batch_abort_if_code_has_unprintable_character() {
        let batch: vector<u8> = vector[0x1E, 62, 63, 32, 33];
        remove_later::deserialize_remove_discount_code_batch(batch);
    }
}
