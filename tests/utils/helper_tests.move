#[test_only]
module suins::helper_tests {

    use suins::helper;
    use std::string;

    #[test]
    fun test_address_to_string() {
        let str = helper::address_to_string(@0xaa27befb8f8b35ad71c30cdcd55fab7c9310f87e);
        assert!(string::utf8(str) == string::utf8(b"aa27befb8f8b35ad71c30cdcd55fab7c9310f87e"), 0);
        let str = helper::address_to_string(@0xc9310f87e);
        assert!(string::utf8(str) == string::utf8(b"0000000000000000000000000000000c9310f87e"), 0);
        let str = helper::address_to_string(@0xABCDEF);
        assert!(string::utf8(str) == string::utf8(b"0000000000000000000000000000000000abcdef"), 0);
    }

    #[test]
    #[expected_failure(abort_code = 401)]
    fun test_calculate_discount_abort_with_zero_discount() {
        helper::calculate_discount(100, 0);
    }

    #[test]
    #[expected_failure(abort_code = 401)]
    fun test_calculate_discount_abort_if_discount_greater_than_100() {
        helper::calculate_discount(100, 101);
    }

    #[test]
    fun test_calculate_discount() {
        assert!(helper::calculate_discount(100, 100) == 0, 0);
        assert!(helper::calculate_discount(100, 94) == 6, 0);
        assert!(helper::calculate_discount(100, 30) == 70, 0);
        assert!(helper::calculate_discount(100, 24) == 76, 0);

        assert!(helper::calculate_discount(10, 94) == 1, 0);
        assert!(helper::calculate_discount(10, 30) == 7, 0);
        assert!(helper::calculate_discount(10, 24) == 8, 0);

        assert!(helper::calculate_discount(91, 94) == 5, 0);
        assert!(helper::calculate_discount(91, 30) == 64, 0);
        assert!(helper::calculate_discount(91, 24) == 69, 0);

        assert!(helper::calculate_discount(9, 94) == 1, 0);
        assert!(helper::calculate_discount(9, 30) == 6, 0);
        assert!(helper::calculate_discount(9, 24) == 7, 0);

        assert!(helper::calculate_discount(123456789, 94) == 7407407, 0);
        assert!(helper::calculate_discount(123456789, 30) == 86419752, 0);
        assert!(helper::calculate_discount(123456789, 24) == 93827160, 0);

        let max_u64: u128 = 18446744073709551615;
        assert!(helper::calculate_discount((max_u64 as u64), 94) == 1106804644422573097, 0);
        assert!(helper::calculate_discount((max_u64 as u64), 30) == 12912720851596686131, 0);
        assert!(helper::calculate_discount((max_u64 as u64), 24) == 14019525496019259227, 0);
    }
}
