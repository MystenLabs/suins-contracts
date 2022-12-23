module suins::emoticon {

    use std::string::{Self, String, utf8};
    use std::vector;
    use sui::tx_context::TxContext;
    use sui::object::UID;
    use sui::transfer;
    use sui::object;
    use suins::emoji;
    
    const EInvalidUTF8: u64 = 701;

    struct EmojiConfiguration has key {
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
        skin_tones: vector<vector<u8>>,
    }

    struct UTF8Emoji has drop {
        // first byte position
        from: u64,
        // start of the first byte not included
        to: u64,
        no_characters: u64,
    }

    struct UTF8Character has drop {
        char: String,
        no_bytes: u64,
    }

    fun init(ctx: &mut TxContext) {
        let two_character_emojis = emoji::two_character_emojis();
        let three_character_emojis = emoji::three_character_emojis();
        let four_character_emojis = emoji::four_character_emojis();
        let five_character_emojis = emoji::five_character_emojis();
        let six_character_emojis = emoji::six_character_emojis();
        let seven_character_emojis = emoji::seven_character_emojis();
        let eight_character_emojis = emoji::eight_character_emojis();
        let skin_tones = vector[
            vector[240, 159, 143, 187], // light skin tone U+1F3FB
            vector[240, 159, 143, 188], // medium-light skin tone U+1F3FC
            vector[240, 159, 143, 189], // medium skin tone U+1F3FD
            vector[240, 159, 143, 190], // medium-dark skin tone U+1F3FE
            vector[240, 159, 143, 191], // dark skin tone U+1F3FF
        ];
        transfer::share_object(EmojiConfiguration {
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
            skin_tones,
        });
    }

    public fun validate_emoji(emoji_config: &EmojiConfiguration, str: vector<u8>): vector<UTF8Emoji> {
        let emojis = to_emoji_sequences(emoji_config, str);
        let str = utf8(str);
        let len = vector::length(&emojis);
        let index = 0;

        while (index < len) {
            let emoji_metadata = vector::borrow(&emojis, index);
            let emoji = string::sub_string(&str, emoji_metadata.from, emoji_metadata.to);
            if (emoji_metadata.no_characters == 2) assert!(vector::contains(&emoji_config.two_character_emojis, string::bytes(&emoji)), 0)
            else if (emoji_metadata.no_characters == 3) assert!(vector::contains(&emoji_config.three_character_emojis, string::bytes(&emoji)), 0)
            else if (emoji_metadata.no_characters == 4) assert!(vector::contains(&emoji_config.four_character_emojis, string::bytes(&emoji)), 0)
            else if (emoji_metadata.no_characters == 5) assert!(vector::contains(&emoji_config.five_character_emojis, string::bytes(&emoji)), 0)
            else if (emoji_metadata.no_characters == 6) assert!(vector::contains(&emoji_config.six_character_emojis, string::bytes(&emoji)), 0)
            else if (emoji_metadata.no_characters == 7) assert!(vector::contains(&emoji_config.seven_character_emojis, string::bytes(&emoji)), 0);

            index = index + 1;
        };

        emojis
    }

    // Byte 1    Type
    // 0xxxxxxx  1 byte
    // 110xxxxx  2 bytes
    // 1110xxxx  3 bytes
    // 11110xxx  4 bytes
    fun get_no_bytes_of_utf8(first_byte: u8): u64 {
        if (first_byte <= 127) return 1;
        if (192 <= first_byte && first_byte <= 223) return 2;
        if (224 <= first_byte && first_byte <= 239) return 3;
        if (240 <= first_byte && first_byte <= 247) return 4;
        abort(EInvalidUTF8)
    }

    fun to_utf8_characters(bytes: &vector<u8>): vector<UTF8Character> {
        let str = utf8(*bytes);
        let result = vector<UTF8Character>[];
        let index = 0;
        let no_bytes = vector::length(bytes);

        while (index < no_bytes) {
            let first_byte = *vector::borrow(bytes, index);
            let no_bytes = get_no_bytes_of_utf8(first_byte);
            let c = string::sub_string(&str, index, index + no_bytes);
            vector::push_back(&mut result, UTF8Character { char: c, no_bytes });

            index = index + no_bytes;
        };

        result
    }

    fun to_emoji_sequences(emoji_config: &EmojiConfiguration, bytes: vector<u8>): vector<UTF8Emoji> {
        let characters = to_utf8_characters(&bytes);
        let len = vector::length(&characters);
        // consider only preceding character in the same emoji sequence
        let is_preceding_character_scalar = false;
        let result = vector<UTF8Emoji>[];
        let index = 0;
        let from = 0;
        let to = 0;
        let no_characters = 0;

        while (index < len) {
            let character = vector::borrow(&characters, index);
            to = to + character.no_bytes;
            no_characters = no_characters + 1;

            // is alphabet character
            if (character.no_bytes == 1) {
                if (is_preceding_character_scalar) {
                    vector::push_back(&mut result, UTF8Emoji {
                        from,
                        to: to - 1,
                        no_characters: no_characters - 1
                    });
                    from = to - 1;
                };
                let bytes = string::bytes(&character.char);
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
                is_preceding_character_scalar = false;
                index = index + 1;
                continue
            };

            if (is_emoji_sequence_with_two_characters(&character.char)) {
                let next_character = vector::borrow(&characters, index + 1);
                to = to + next_character.no_bytes;
                vector::push_back(&mut result, UTF8Emoji { from, to, no_characters: 2 });
                no_characters = 0;
                from = to;
                is_preceding_character_scalar = false;
                index = index + 2;
                continue
            };

            if (*string::bytes(&character.char) == emoji_config.variant) {
                // variant character is either at the last position, or followed by the joiner character
                if (index < len - 1) {
                    let next_character = vector::borrow(&characters, index + 1);
                    if (*string::bytes(&next_character.char) != emoji_config.joiner) {
                        vector::push_back(&mut result, UTF8Emoji { from, to, no_characters });
                        no_characters = 0;
                        from = to;
                    };
                    is_preceding_character_scalar = false;
                } else {
                    // this variant character is at the end of the input string,
                    // so this emoji sequence has to end here
                    vector::push_back(&mut result, UTF8Emoji { from, to, no_characters });
                };
                index = index + 1;
                continue
            };

            if (*string::bytes(&character.char) != emoji_config.joiner) {
                if (is_preceding_character_scalar) {
                    // 2 scalar characters cannot stand next to each other in a emoji sequence,
                    // so the previous scalar character is the end of its emoji sequence
                    vector::push_back(&mut result, UTF8Emoji {
                        from,
                        to: to - vector::length(string::bytes(&character.char)),
                        no_characters: no_characters - 1
                    });
                    no_characters = 1;
                    is_preceding_character_scalar = false;
                    from = to - vector::length(string::bytes(&character.char));
                } else is_preceding_character_scalar = true;
                if (index == len - 1) {
                    vector::push_back(&mut result, UTF8Emoji {
                        from,
                        to,
                        no_characters
                    });
                };
            } else is_preceding_character_scalar = false;

            index = index + 1;
        };

        result
    }

    fun is_emoji_sequence_with_two_characters(str: &String): bool {
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
        let skin_tones = vector[
            vector[240, 159, 143, 187], // light skin tone U+1F3FB
            vector[240, 159, 143, 188], // medium-light skin tone U+1F3FC
            vector[240, 159, 143, 189], // medium skin tone U+1F3FD
            vector[240, 159, 143, 190], // medium-dark skin tone U+1F3FE
            vector[240, 159, 143, 191], // dark skin tone U+1F3FF
        ];
        transfer::share_object(EmojiConfiguration {
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
            skin_tones,
        });
    }
}
