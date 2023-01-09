#[test_only]
module suins::converter_tests {

    use suins::converter;
    use std::string::utf8;

    #[test]
    fun test_address_to_string() {
        let str = converter::address_to_string(@0xaa27befb8f8b35ad71c30cdcd55fab7c9310f87e);
        assert!(utf8(str) == utf8(b"aa27befb8f8b35ad71c30cdcd55fab7c9310f87e"), 0);
        let str = converter::address_to_string(@0xc9310f87e);
        assert!(utf8(str) == utf8(b"0000000000000000000000000000000c9310f87e"), 0);
        let str = converter::address_to_string(@0xABCDEF);
        assert!(utf8(str) == utf8(b"0000000000000000000000000000000000abcdef"), 0);
    }

    #[test]
    fun test_string_to_number() {
        assert!(converter::string_to_number(utf8(b"1234")) == 1234, 0);
        assert!(converter::string_to_number(utf8(b"0")) == 0, 0);
        assert!(converter::string_to_number(utf8(b"18446744073709551615")) == 18446744073709551615, 0);
    }

    #[test, expected_failure(abort_code = converter::EInvalidNumber)]
    fun test_string_to_number_abort_if_NAN() {
        converter::string_to_number(utf8(b"a"));
    }
}
