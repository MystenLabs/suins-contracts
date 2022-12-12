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
}
