module suins::converter {

    use std::vector;
    use std::string::{Self, String};
    use sui::tx_context::TxContext;
    use sui::object::ID;
    use sui::object;

    friend suins::auction;
    friend suins::reverse_registrar;
    friend suins::resolver;
    friend suins::controller;
    friend suins::configuration;
    friend suins::remove_later;
    friend suins::registrar;

    const REGISTRATION_FEE_PER_YEAR: u64 = 1000000;
    const EInvalidNumber: u64 = 601;

    public(friend) fun string_to_number(str: String): u64 {
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

    public(friend) fun new_id(ctx: &mut TxContext): ID {
        let new_uid = object::new(ctx);
        let new_id = object::uid_to_inner(&new_uid);
        object::delete(new_uid);
        new_id
    }

    #[test_only]
    friend suins::converter_tests;
    #[test_only]
    friend suins::resolver_tests;
}
