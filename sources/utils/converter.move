module suins::converter {

    use std::bcs;
    use std::vector;
    use std::string;

    friend suins::reverse_registrar;
    friend suins::resolver;
    friend suins::controller;
    friend suins::configuration;
    friend suins::remove_later;

    const REGISTRATION_FEE_PER_YEAR: u64 = 1000000;
    const EInvalidNumber: u64 = 601;

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

    public(friend) fun string_to_number(str: string::String): u64 {
        let bytes = string::bytes(&str);
        // count from 1 because Move doesn't have negative number atm
        let index = vector::length(bytes);
        let result: u64 = 0;
        let base = 1;

        while (index > 0) {
            let byte = *vector::borrow(bytes, index - 1);
            assert!(byte >= 0x30 && byte <= 0x39, EInvalidNumber); // 0-9
            result = result + ((byte as u64) - 0x30) * base;
            // avoid overflow if input is MAX_U64
            if (index != 1) base = base * 10;
            index = index - 1;
        };
        result
    }

    #[test_only]
    friend suins::converter_tests;
    #[test_only]
    friend suins::resolver_tests;
}
