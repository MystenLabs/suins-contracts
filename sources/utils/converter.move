module suins::converter {

    use std::bcs;
    use std::vector;

    friend suins::reverse_registrar;
    friend suins::name_resolver;

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

    #[test_only]
    friend suins::converter_tests;
    #[test_only]
    friend suins::name_resolver_tests;
}