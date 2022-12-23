module suins::emoticon {

    use std::string;
    use std::string::{String, utf8};
    use std::vector;
    use sui::tx_context::TxContext;
    use sui::object::UID;
    use sui::transfer;
    use sui::object;
    use suins::emoji;

    friend suins::base_registrar;
    friend suins::controller;

    const EInvalidUTF8: u64 = 701;

    struct Emoticon has key {
        id: UID,
        joiner: vector<u8>,
        variant: vector<u8>,
        two_character_emojis: vector<vector<u8>>,
        three_character_emojis: vector<vector<u8>>,
        four_character_emojis: vector<vector<u8>>,
        five_character_emojis: vector<vector<u8>>,
        six_character_emojis: vector<vector<u8>>,
        seven_character_emojis: vector<vector<u8>>,
        eight_character_emojis: vector<vector<u8>>,
    }

    struct UTF8Emoji has drop {
        from: u64,
        to: u64,
        no_characters: u64,
    }

    fun init(ctx: &mut TxContext) {
        let two_character_emojis = emoji::two_character_emojis();
        let three_character_emojis = emoji::three_character_emojis();
        let four_character_emojis = emoji::four_character_emojis();
        let five_character_emojis = emoji::five_character_emojis();
        let six_character_emojis = emoji::six_character_emojis();
        let seven_character_emojis = emoji::seven_character_emojis();
        let eight_character_emojis = emoji::eight_character_emojis();

        transfer::share_object(Emoticon {
            id: object::new(ctx),
            joiner: vector[226, 128, 141], // U+200D
            variant: vector[239, 184, 143], // U+FE0F
            two_character_emojis,
            three_character_emojis,
            four_character_emojis,
            five_character_emojis,
            six_character_emojis,
            seven_character_emojis,
            eight_character_emojis,
        });
    }

    public fun get_no_bytes_utf8(first_byte: u8): u64 {
        if (first_byte <= 127) return 1;
        if (192 <= first_byte && first_byte <= 223) return 2;
        if (224 <= first_byte && first_byte <= 239) return 3;
        if (240 <= first_byte && first_byte <= 247) return 4;
        abort(EInvalidUTF8)
    }

    struct UTF8Tmp has drop {
        c: String,
        no_bytes: u64,
    }

    public fun split_to_utf8_character(bytes: &vector<u8>): vector<UTF8Tmp> {
        let str = utf8(*bytes);
        let no_bytes = vector::length(bytes);
        let result = vector<UTF8Tmp>[];
        let index = 0;

        while (index < no_bytes) {
            let first_byte = *vector::borrow(bytes, index);
            let no_bytes = get_no_bytes_utf8(first_byte);
            let sub_str = string::sub_string(&str, index, index + no_bytes);
            vector::push_back(&mut result, UTF8Tmp {
                c: sub_str,
                no_bytes
            });

            index = index + no_bytes;
        };

        result
    }
    public fun validate_emoticon(emoticon: &Emoticon, node: vector<u8>): vector<UTF8Emoji> {
        let emoji_str = utf8(node);
        let emojis = split_to_emoji_list(emoticon, node);
        let len = vector::length(&emojis);
        let index = 0;

        while (index < len) {
            let emoji_metadata = vector::borrow(&emojis, index);
            let emoji = string::sub_string(&emoji_str, emoji_metadata.from, emoji_metadata.to);
            if (emoji_metadata.no_characters == 2) assert!(vector::contains(&emoticon.two_character_emojis, string::bytes(&emoji)), 0)
            else if (emoji_metadata.no_characters == 3) assert!(vector::contains(&emoticon.three_character_emojis, string::bytes(&emoji)), 0)
            else if (emoji_metadata.no_characters == 4) assert!(vector::contains(&emoticon.four_character_emojis, string::bytes(&emoji)), 0)
            else if (emoji_metadata.no_characters == 5) assert!(vector::contains(&emoticon.five_character_emojis, string::bytes(&emoji)), 0)
            else if (emoji_metadata.no_characters == 6) assert!(vector::contains(&emoticon.six_character_emojis, string::bytes(&emoji)), 0)
            else if (emoji_metadata.no_characters == 7) assert!(vector::contains(&emoticon.seven_character_emojis, string::bytes(&emoji)), 0);

            index = index + 1;
        };

        emojis
    }
    public fun split_to_emoji_list(emoticon: &Emoticon, node: vector<u8>): vector<UTF8Emoji> {
        let characters = split_to_utf8_character(&node);
        let len = vector::length(&characters);
        let last_character_scalar = false;
        let result = vector<UTF8Emoji>[];
        let index = 0;
        let from = 0;
        let to = 0;
        let no_characters = 0;

        while (index < len) {
            let tmp = vector::borrow(&characters, index);
            to = to + tmp.no_bytes;
            no_characters = no_characters + 1;

            // TODO: asdasd
            if (tmp.no_bytes == 1) {
                let bytes = string::bytes(&tmp.c);
                let byte = *vector::borrow(bytes, 0);
                assert!(
                    (0x61 <= byte && byte <= 0x7A)                           // a-z
                        || (0x30 <= byte && byte <= 0x39)                    // 0-9
                        || (byte == 0x2D && index != 0 && index != len - 1), // -
                    0
                );
                vector::push_back(&mut result, UTF8Emoji { from, to, no_characters: 1 });
                from = to;
                no_characters = 0;
                index = index + 1;
                continue
            };

            if (validate_glyph_with_two_characters(&tmp.c)) {
                let next_tmp = vector::borrow(&characters, index + 1);
                to = to + next_tmp.no_bytes;
                no_characters = no_characters + 1;
                vector::push_back(&mut result, UTF8Emoji { from, to, no_characters });
                no_characters = 0;
                index = index + 2;
                from = to;
                last_character_scalar = false;
                continue
            };

            if (emoticon.variant == *string::bytes(&tmp.c)) {
                if (index < len - 1) {
                    let next_tmp = vector::borrow(&characters, index + 1);
                    if (emoticon.joiner != *string::bytes(&next_tmp.c)) {
                        vector::push_back(&mut result, UTF8Emoji { from, to, no_characters });
                        no_characters = 0;
                        from = to;
                    }
                } else {
                    vector::push_back(&mut result, UTF8Emoji { from, to, no_characters });
                    no_characters = 0;
                };
                last_character_scalar = false;
                index = index + 1;
                continue
            };

            if (emoticon.joiner != *string::bytes(&tmp.c)) {
                if (last_character_scalar) {
                    vector::push_back(&mut result, UTF8Emoji {
                        from,
                        to: to - vector::length(string::bytes(&tmp.c)),
                        no_characters: no_characters - 1
                    });
                    no_characters = 1;
                    last_character_scalar = false;
                    from = to - vector::length(string::bytes(&tmp.c));
                } else last_character_scalar = true;
                if (index == len - 1) {
                    vector::push_back(&mut result, UTF8Emoji {
                        from,
                        to,
                        no_characters
                    });
                    no_characters = 0;
                    index = index + 1;
                    continue
                };
            } else last_character_scalar = false;
            index = index + 1;
        };

        result
    }

    fun validate_glyph_with_two_characters(str: &String): bool {
        let bytes = string::bytes(str);
        if (vector::length(bytes) != 4) return false;

        let first_byte = *vector::borrow(bytes, 0);
        if (first_byte != 240) return false;

        let second_byte = *vector::borrow(bytes, 1);
        if (second_byte != 159) return false;

        let third_byte = *vector::borrow(bytes, 2);
        if (third_byte != 135) return false;

        let fourth_byte = *vector::borrow(bytes, 3);
        if (166 <= fourth_byte && fourth_byte <= 191) return true;
        false
    }

    #[test_only]
    /// Wrapper of module initializer for testing
    public fun test_init(ctx: &mut TxContext) {
        let two_character_emojis = emoji::two_character_emojis();
        let three_character_emojis = emoji::three_character_emojis();
        let four_character_emojis = emoji::four_character_emojis();
        let five_character_emojis = emoji::five_character_emojis();
        let six_character_emojis = emoji::six_character_emojis();
        let seven_character_emojis = emoji::seven_character_emojis();
        let eight_character_emojis = emoji::eight_character_emojis();

        transfer::share_object(Emoticon {
            id: object::new(ctx),
            joiner: vector[226, 128, 141], // U+200D
            variant: vector[239, 184, 143], // U+FE0F
            two_character_emojis,
            three_character_emojis,
            four_character_emojis,
            five_character_emojis,
            six_character_emojis,
            seven_character_emojis,
            eight_character_emojis,
        });
    }
}
