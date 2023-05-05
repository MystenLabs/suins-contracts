#[test_only]
module suins::converter_tests {
    use suins::string_utils;
    use std::string::utf8;

    #[test]
    fun test_string_to_number() {
        assert!(string_utils::string_to_number(utf8(b"1234")) == 1234, 0);
        assert!(string_utils::string_to_number(utf8(b"0")) == 0, 0);
        assert!(string_utils::string_to_number(utf8(b"18446744073709551615")) == 18446744073709551615, 0);
    }

    #[test, expected_failure(abort_code = string_utils::EInvalidNumber)]
    fun test_string_to_number_abort_if_NAN() {
        string_utils::string_to_number(utf8(b"a"));
    }
}
