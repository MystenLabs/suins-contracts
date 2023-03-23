/// These funtionalities are supposed to be supported by the Sui SDK in the future
/// we will remove it as soon as SDK's support is ready
module suins::remove_later {

    use std::vector;
    use std::string::{Self, utf8, String};
    use std::ascii;
    use suins::converter;

    friend suins::configuration;
    friend suins::registrar;

    const EInvalidDiscountCodeBatch: u64 = 501;

    struct DiscountCode has drop {
        code: ascii::String,
        rate: u8,
        owner: ascii::String,
    }

    /// `msg` format: <ipfs_url>,<node>,<expiry>,<data>
    public(friend) fun deserialize_image_msg(msg: vector<u8>): (String, String, u64, String) {
        // `msg` now: ipfs_url,owner,expiry,data
        let msg = utf8(msg);
        let comma = utf8(b",");

        let index_of_next_comma = string::index_of(&msg, &comma);
        let ipfs = string::sub_string(&msg, 0, index_of_next_comma);
        // `msg` now: node,expiry,data
        msg = string::sub_string(&msg, index_of_next_comma + 1, string::length(&msg));
        index_of_next_comma = string::index_of(&msg, &comma);
        let node = string::sub_string(&msg, 0, index_of_next_comma);

        // `msg` now: expiry,data
        msg = string::sub_string(&msg, index_of_next_comma + 1, string::length(&msg));
        index_of_next_comma = string::index_of(&msg, &comma);
        let expiry = string::sub_string(&msg, 0, index_of_next_comma);

        // `msg` now: data
        msg = string::sub_string(&msg, index_of_next_comma + 1, string::length(&msg));
        // TODO: should we check that these data are non blank?
        (ipfs, node, converter::string_to_number(expiry), msg)
    }

    /// This funtion doesn't validate domains
    /// `domains` format: domain1;domain2;
    public(friend) fun deserialize_reserve_domains(domains: vector<u8>): vector<String> {
        let last_character = vector::borrow(&domains, vector::length(&domains) - 1);
        // add a semicolon to the end of `discount_code_batch` to make every code have the same layout
        if (*last_character != 59) {
            vector::push_back(&mut domains, 59);
        };
        let reserve_domains: vector<String> = vector[];
        let semi_colon = utf8(b";");
        let domains = utf8(domains);

        let index_of_next_semi_colon = string::index_of(&domains, &semi_colon);
        let len = string::length(&domains);
        while (index_of_next_semi_colon != len) {
            let domain = string::sub_string(&domains, 0, index_of_next_semi_colon);
            vector::push_back(&mut reserve_domains, domain);

            domains = string::sub_string(&domains, index_of_next_semi_colon + 1, len);
            len = len - index_of_next_semi_colon - 1;
            index_of_next_semi_colon = string::index_of(&domains, &semi_colon);
        };

        reserve_domains
    }

    /// `discount_code_batch` format: code1,rate1,owner1;code2,rate2,owner2;
    /// owner must have '0x'
    public(friend) fun deserialize_new_discount_code_batch(discount_code_batch: vector<u8>): vector<DiscountCode> {
        let last_character = vector::borrow(&discount_code_batch, vector::length(&discount_code_batch) - 1);
        // add a semicolon to the end of `discount_code_batch` to make every code have the same layout
        if (*last_character != 59) {
            vector::push_back(&mut discount_code_batch, 59);
        };
        let discount_codes: vector<DiscountCode> = vector[];
        let semi_colon = utf8(b";");
        // convert to UTF8 string because ASCII string doesn't have `sub_string`
        // the deserialized codes are in ASCII
        let discount_code_batch = utf8(discount_code_batch);

        let index_of_next_semi_colon = string::index_of(&discount_code_batch, &semi_colon);
        let len = string::length(&discount_code_batch);
        while (index_of_next_semi_colon != len) {
            let discount_code_str = string::sub_string(&discount_code_batch, 0, index_of_next_semi_colon);
            let discount = deserialize_discount_code(discount_code_str);
            vector::push_back(&mut discount_codes, discount);

            discount_code_batch = string::sub_string(&discount_code_batch, index_of_next_semi_colon + 1, len);
            len = len - index_of_next_semi_colon - 1;
            index_of_next_semi_colon = string::index_of(&discount_code_batch, &semi_colon);
        };

        discount_codes
    }

    // discount_code_batch has format: code1;code2;
    public(friend) fun deserialize_remove_discount_code_batch(discount_code_batch: vector<u8>): vector<ascii::String> {
        let last_character = vector::borrow(&discount_code_batch, vector::length(&discount_code_batch) - 1);
        // add a semicolon to the end of `discount_code_batch` to make every code have the same layout
        if (*last_character != 59) {
            vector::push_back(&mut discount_code_batch, 59);
        };
        let codes: vector<ascii::String> = vector[];
        let semi_colon = utf8(b";");
        // convert to UTF8 string because ASCII string doesn't have `sub_string` and `index`
        // the deserialized codes are in ASCII
        let discount_code_batch = utf8(discount_code_batch);

        let index_of_next_semi_colon = string::index_of(&discount_code_batch, &semi_colon);
        let len = string::length(&discount_code_batch);
        while (index_of_next_semi_colon != len) {
            let code_str = string::sub_string(&discount_code_batch, 0, index_of_next_semi_colon);
            let code_bytes = string::bytes(&code_str);
            let code_str = ascii::string(*code_bytes);
            assert!(ascii::all_characters_printable(&code_str), EInvalidDiscountCodeBatch);
            vector::push_back(&mut codes, code_str);

            discount_code_batch = string::sub_string(&discount_code_batch, index_of_next_semi_colon + 1, len);
            len = len - index_of_next_semi_colon - 1;
            index_of_next_semi_colon = string::index_of(&discount_code_batch, &semi_colon);
        };

        codes
    }

    public(friend) fun get_discount_fields(discount_code: &DiscountCode): (ascii::String, u8, ascii::String) {
        (discount_code.code, discount_code.rate, discount_code.owner)
    }

    /// `str` format: code1,rate1,owner1
    fun deserialize_discount_code(str: String): DiscountCode {
        // `str` now: code,rate,owner
        let comma = utf8(b",");

        let index_of_next_comma = string::index_of(&str, &comma);
        let code = string::sub_string(&str, 0, index_of_next_comma);
        let code_bytes = string::bytes(&code);
        let code = ascii::string(*code_bytes);
        assert!(ascii::all_characters_printable(&code), EInvalidDiscountCodeBatch);

        // all processed parts are removed because `string::index_of` only returns first index
        // also remove colon character
        // `str` now: rate:owner
        str = string::sub_string(&str, index_of_next_comma + 1, string::length(&str));
        index_of_next_comma = string::index_of(&str, &comma);
        // rate cannot has more than 3 characters
        // index_of_next_colon == 0: rate is not included
        assert!((0 < index_of_next_comma || index_of_next_comma < 3), EInvalidDiscountCodeBatch);
        let rate_str = string::sub_string(&str, 0, index_of_next_comma);
        let rate: u8;
        // 3 characters means it has to be 100
        if (index_of_next_comma == 3) {
            assert!(rate_str == utf8(b"100"), EInvalidDiscountCodeBatch);
            rate = 100
        } else rate = (converter::string_to_number(rate_str) as u8);

        // `str` now: owner
        str = string::sub_string(&str, index_of_next_comma + 1, string::length(&str));
        // TODO: check start with 0x
        let hex_prefix = string::sub_string(&str, 0, 2);
        assert!(hex_prefix == utf8(b"0x"), EInvalidDiscountCodeBatch);
        let owner = string::sub_string(&str, 2, string::length(&str));
        let owner_bytes = *string::bytes(&owner);
        let index = 0;
        let len = vector::length(&owner_bytes);
        while(index < len) {
            let byte = vector::borrow_mut(&mut owner_bytes, index);
            // hack for the `assert` statement below
            let byte_tmp = *byte;
            assert!(
                (0x61 <= byte_tmp && byte_tmp <= 0x66)                           // a-f
                    || (0x41 <= byte_tmp && byte_tmp <= 0x46)                    // A-F
                    || (0x30 <= byte_tmp && byte_tmp <= 0x39),                   // 0-9
                EInvalidDiscountCodeBatch
            );
            if (0x41 <= byte_tmp && byte_tmp <= 0x46) {
                *byte = *byte + 32;
            };
            index = index + 1;
        };
        let owner: vector<u8> = vector[];
        // padding leading '0'
        while (len < 40) {
            vector::push_back(&mut owner, 0x30);
            len = len + 1;
        };
        vector::append(&mut owner, owner_bytes);
        DiscountCode { code, rate, owner: ascii::string(owner) }
    }


    #[test_only]
    friend suins::remove_later_tests;
}
