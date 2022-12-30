module suins::emoji {

    use std::string::{Self, String, utf8};
    use std::vector;
    use suins::emoji_resource;

    friend suins::configuration;

    const EInvalidEmojiSequence: u64 = 702;
    const EInvalidLabel: u64 = 704;

    struct EmojiConfiguration has store, drop {
        joiner: vector<u8>,
        variant: vector<u8>,
        combining_enclosing: vector<u8>,
        // U+20E3, used to check special cases of 3-character sequences
        latin_small_g: vector<u8>,
        // U+E0067, used to check special cases of 7-character sequences
        one_character_emojis: vector<vector<u8>>,
        two_character_emojis: vector<vector<u8>>,
        three_character_emojis: vector<vector<u8>>,
        four_character_emojis: vector<vector<u8>>,
        five_character_emojis: vector<vector<u8>>,
        six_character_emojis: vector<vector<u8>>,
        seven_character_emojis: vector<vector<u8>>,
        eight_character_emojis: vector<vector<u8>>,
        two_character_skin_tone_emojis: vector<vector<u8>>,
        four_character_skin_tone_emojis: vector<vector<u8>>,
        five_character_skin_tone_emojis: vector<vector<u8>>,
        seven_character_skin_tone_emojis: vector<vector<u8>>,
        eight_character_skin_tone_emojis: vector<vector<u8>>,
        ten_character_skin_tone_emojis: vector<vector<u8>>,
        skin_tones: vector<vector<u8>>,
    }

    struct UTF8Emoji has drop {
        // first byte position
        from: u64,
        // start of the first byte not included
        to: u64,
        no_characters: u64,
        is_skin_tone: bool,
        is_single_byte: bool,
    }

    struct UTF8Character has drop {
        char: String,
        no_bytes: u64,
    }

    public(friend) fun init_emoji_config(): EmojiConfiguration {
        let one_character_emojis = emoji_resource::one_character_emojis();
        let two_character_emojis = emoji_resource::two_character_emojis();
        let three_character_emojis = emoji_resource::three_character_emojis();
        let four_character_emojis = emoji_resource::four_character_emojis();
        let five_character_emojis = emoji_resource::five_character_emojis();
        let six_character_emojis = emoji_resource::six_character_emojis();
        let seven_character_emojis = emoji_resource::seven_character_emojis();
        let eight_character_emojis = emoji_resource::eight_character_emojis();
        let two_character_skin_tone_emojis = emoji_resource::two_character_skin_tone_emojis();
        let four_character_skin_tone_emojis = emoji_resource::four_character_skin_tone_emojis();
        let five_character_skin_tone_emojis = emoji_resource::five_character_skin_tone_emojis();
        let seven_character_skin_tone_emojis = emoji_resource::seven_character_skin_tone_emojis();
        let eight_character_skin_tone_emojis = emoji_resource::eight_character_skin_tone_emojis();
        let ten_character_skin_tone_emojis = emoji_resource::ten_character_skin_tone_emojis();
        let skin_tones = vector[
            vector[240, 159, 143, 187], // light skin tone U+1F3FB
            vector[240, 159, 143, 188], // medium-light skin tone U+1F3FC
            vector[240, 159, 143, 189], // medium skin tone U+1F3FD
            vector[240, 159, 143, 190], // medium-dark skin tone U+1F3FE
            vector[240, 159, 143, 191], // dark skin tone U+1F3FF
        ];
        EmojiConfiguration {
            joiner: vector[226, 128, 141], // U+200D
            variant: vector[239, 184, 143], // U+FE0F
            combining_enclosing: vector[226, 131, 163], // U+20E3
            latin_small_g: vector[243, 160, 129, 167], // U+E0067
            one_character_emojis,
            two_character_emojis,
            three_character_emojis,
            four_character_emojis,
            five_character_emojis,
            six_character_emojis,
            seven_character_emojis,
            eight_character_emojis,
            two_character_skin_tone_emojis,
            four_character_skin_tone_emojis,
            five_character_skin_tone_emojis,
            seven_character_skin_tone_emojis,
            eight_character_skin_tone_emojis,
            ten_character_skin_tone_emojis,
            skin_tones,
        }
    }

    // Valid label have between 3 to 63 characters and contain only: lowercase (a-z), numbers (0-9), hyphen (-).
    // A name may not start or end with a hyphen
    public fun validate_label_with_emoji(emoji_config: &EmojiConfiguration, str: vector<u8>) {
        let emojis = to_emoji_sequences(emoji_config, str);
        let str = utf8(str);
        let len = vector::length(&emojis);
        let index = 0;
        assert!(2 < len && len < 64, EInvalidLabel);

        while (index < len) {
            let emoji_metadata = vector::borrow(&emojis, index);
            let emoji = string::sub_string(&str, emoji_metadata.from, emoji_metadata.to);
            if (emoji_metadata.is_single_byte) {
                let bytes = string::bytes(&emoji);
                let byte = *vector::borrow(bytes, 0);
                assert!(
                    (0x61 <= byte && byte <= 0x7A)                           // a-z
                        || (0x30 <= byte && byte <= 0x39)                    // 0-9
                        || (byte == 0x2D && index != 0 && index != len - 1), // -
                    EInvalidLabel
                );
                index = index + 1;
                continue
            };

            if (emoji_metadata.is_skin_tone) {
                if (emoji_metadata.no_characters == 2)
                    assert!(
                        vector::contains(&emoji_config.two_character_skin_tone_emojis, string::bytes(&emoji)),
                        EInvalidEmojiSequence
                    )
                else if (emoji_metadata.no_characters == 4)
                    assert!(
                        vector::contains(&emoji_config.four_character_skin_tone_emojis, string::bytes(&emoji)),
                        EInvalidEmojiSequence
                    )
                else if (emoji_metadata.no_characters == 5)
                    assert!(
                        vector::contains(&emoji_config.five_character_skin_tone_emojis, string::bytes(&emoji)),
                        EInvalidEmojiSequence
                    )
                else if (emoji_metadata.no_characters == 7)
                    assert!(
                        vector::contains(&emoji_config.seven_character_skin_tone_emojis, string::bytes(&emoji)),
                        EInvalidEmojiSequence
                    )
                else if (emoji_metadata.no_characters == 8)
                    assert!(
                        vector::contains(&emoji_config.eight_character_skin_tone_emojis, string::bytes(&emoji)),
                        EInvalidEmojiSequence
                    )
                else if (emoji_metadata.no_characters == 10)
                    assert!(
                        vector::contains(&emoji_config.ten_character_skin_tone_emojis, string::bytes(&emoji)),
                        EInvalidEmojiSequence
                    )
                else abort EInvalidEmojiSequence;
            } else {
                if (emoji_metadata.no_characters == 1)
                    assert!(
                        vector::contains(&emoji_config.one_character_emojis, string::bytes(&emoji)),
                        EInvalidEmojiSequence
                    )
                else if (emoji_metadata.no_characters == 2)
                    assert!(
                        vector::contains(&emoji_config.two_character_emojis, string::bytes(&emoji)),
                        EInvalidEmojiSequence
                    )
                else if (emoji_metadata.no_characters == 3)
                    assert!(
                        vector::contains(&emoji_config.three_character_emojis, string::bytes(&emoji)),
                        EInvalidEmojiSequence
                    )
                else if (emoji_metadata.no_characters == 4)
                    assert!(
                        vector::contains(&emoji_config.four_character_emojis, string::bytes(&emoji)),
                        EInvalidEmojiSequence
                    )
                else if (emoji_metadata.no_characters == 5)
                    assert!(
                        vector::contains(&emoji_config.five_character_emojis, string::bytes(&emoji)),
                        EInvalidEmojiSequence
                    )
                else if (emoji_metadata.no_characters == 6)
                    assert!(
                        vector::contains(&emoji_config.six_character_emojis, string::bytes(&emoji)),
                        EInvalidEmojiSequence
                    )
                else if (emoji_metadata.no_characters == 7)
                    assert!(
                        vector::contains(&emoji_config.seven_character_emojis, string::bytes(&emoji)),
                        EInvalidEmojiSequence
                    )
                else if (emoji_metadata.no_characters == 8)
                    assert!(
                        vector::contains(&emoji_config.eight_character_emojis, string::bytes(&emoji)),
                        EInvalidEmojiSequence
                    )
                else abort EInvalidEmojiSequence
            };
            index = index + 1;
        };
    }

    fun to_emoji_sequences(emoji_config: &EmojiConfiguration, bytes: vector<u8>): vector<UTF8Emoji> {
        let characters = to_utf8_characters(&bytes);
        let len = vector::length(&characters);
        // consider only preceding character in the same emoji sequence
        let is_preceding_character_scalar = false;
        let is_skin_tone = false;
        let result = vector<UTF8Emoji>[];
        let index = 0;
        let from_index = 0;
        let to_index = 0;
        let no_characters = 0;
        let remaining_characters = len;

        while (index < len) {
            let current_character = vector::borrow(&characters, index);
            to_index = to_index + current_character.no_bytes;
            no_characters = no_characters + 1;

            // is alphabet character
            if (current_character.no_bytes == 1) {
                handle_single_byte_character(
                    emoji_config, &mut result, &characters,
                    &mut from_index, &mut to_index, &mut index,
                    &mut remaining_characters, &mut is_skin_tone, &mut no_characters,
                    &mut is_preceding_character_scalar, len,
                );
                continue
            };

            if (*string::bytes(&current_character.char) == emoji_config.latin_small_g) {
                handle_latin_small_g_character(
                    &mut result, &mut characters, &mut from_index,
                    &mut to_index, index, &mut remaining_characters,
                    is_skin_tone, &mut no_characters, &mut is_preceding_character_scalar,
                );
                index = index + 6;
                continue
            };

            if (vector::contains(&emoji_config.skin_tones, string::bytes(&current_character.char))) {
                assert!(is_preceding_character_scalar, EInvalidEmojiSequence);
                is_skin_tone = true;
                if (index == len - 1) {
                    vector::push_back(&mut result, UTF8Emoji { from: from_index, to: to_index, no_characters, is_skin_tone, is_single_byte: false });
                    remaining_characters = remaining_characters - no_characters;
                };
                index = index + 1;
                continue
            };

            if (is_emoji_sequence_of_two_characters(&current_character.char)) {
                handle_emoji_sequence_of_two_characters(
                    &mut result, &characters, &mut from_index,
                    &mut to_index, index, &mut remaining_characters,
                    &mut is_skin_tone, &mut no_characters, &mut is_preceding_character_scalar,
                );
                index = index + 2;
                continue
            };

            if (*string::bytes(&current_character.char) == emoji_config.variant) {
                handle_variant_character(
                    emoji_config, &mut result, &characters,
                    &mut from_index, to_index, index,
                    &mut remaining_characters, &mut is_skin_tone,
                    &mut no_characters, &mut is_preceding_character_scalar, len
                );
                index = index + 1;
                continue
            };

            if (*string::bytes(&current_character.char) != emoji_config.joiner) {
                handle_scalar_character(
                    &mut result, current_character, &mut from_index,
                    to_index, index, &mut remaining_characters, &mut is_skin_tone,
                    &mut no_characters, is_preceding_character_scalar, len
                );
                is_preceding_character_scalar = true;
            } else is_preceding_character_scalar = false;

            index = index + 1;
        };
        assert!(remaining_characters == 0, EInvalidLabel);
        result
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
        abort(EInvalidLabel)
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

    fun handle_emoji_sequence_of_two_characters(
        result: &mut vector<UTF8Emoji>,
        characters: &vector<UTF8Character>,
        from_index: &mut u64,
        to_index: &mut u64,
        index: u64,
        remaining_characters: &mut u64,
        is_skin_tone: &mut bool,
        no_characters: &mut u64,
        is_preceding_character_scalar: &mut bool,
    ) {
        let next_character = vector::borrow(characters, index + 1);
        *to_index = *to_index + next_character.no_bytes;
        vector::push_back(result, UTF8Emoji {
            from: *from_index,
            to: *to_index,
            no_characters: 2,
            is_skin_tone: *is_skin_tone,
            is_single_byte: false
        });
        *no_characters = 0;
        *is_skin_tone = false;
        *from_index = *to_index;
        *remaining_characters = *remaining_characters - 2;
        *is_preceding_character_scalar = false;
    }

    fun handle_scalar_character(
        result: &mut vector<UTF8Emoji>,
        current_character: &UTF8Character,
        from_index: &mut u64,
        to_index: u64,
        index: u64,
        remaining_characters: &mut u64,
        is_skin_tone: &mut bool,
        no_characters: &mut u64,
        is_preceding_character_scalar: bool,
        len: u64
    ) {
        if (is_preceding_character_scalar) {
            // 2 scalar characters cannot stand next to each other in a emoji sequence,
            // so the previous scalar character is the end of its emoji sequence
            let bytes = string::bytes(&current_character.char);
            vector::push_back(result, UTF8Emoji {
                from: *from_index,
                to: to_index - vector::length(bytes),
                no_characters: *no_characters - 1,
                is_skin_tone: *is_skin_tone,
                is_single_byte: false
            });
            *remaining_characters = *remaining_characters - *no_characters + 1;
            *no_characters = 1;
            *is_skin_tone = false;
            *from_index = to_index - vector::length(bytes);
        };
        if (index == len - 1) {
            vector::push_back(result, UTF8Emoji {
                from: *from_index,
                to: to_index,
                no_characters: *no_characters,
                is_skin_tone: *is_skin_tone,
                is_single_byte: false
            });
            *remaining_characters = *remaining_characters - *no_characters;
        };
    }

    fun handle_single_byte_character(
        emoji_config: &EmojiConfiguration,
        result: &mut vector<UTF8Emoji>,
        characters: &vector<UTF8Character>,
        from_index: &mut u64,
        to_index: &mut u64,
        index: &mut u64,
        remaining_characters: &mut u64,
        is_skin_tone: &mut bool,
        no_characters: &mut u64,
        is_preceding_character_scalar: &mut bool,
        len: u64,
    ) {
        if (*no_characters > 1) {
            vector::push_back(result, UTF8Emoji {
                from: *from_index,
                to: *to_index - 1,
                no_characters: *no_characters - 1,
                is_skin_tone: *is_skin_tone,
                is_single_byte: false,
            });
            *from_index = *to_index - 1;
            *remaining_characters = *remaining_characters + 1 - *no_characters;
        };
        // check for special cases that end with u+20e3, i.e. 0023_fe0f_20e3
        if (*index < len - 2) {
            let next_next_character = vector::borrow(characters, *index + 2);
            let bytes = string::bytes(&next_next_character.char);
            if (*bytes == emoji_config.combining_enclosing) {
                assert!(!*is_skin_tone, EInvalidLabel);
                let next_character = vector::borrow(characters, *index + 2);
                *to_index = *to_index + next_character.no_bytes;
                *to_index = *to_index + next_next_character.no_bytes;
                vector::push_back(
                    result,
                    UTF8Emoji {
                        from: *from_index,
                        to: *to_index,
                        no_characters: 3,
                        is_skin_tone: *is_skin_tone,
                        is_single_byte: false
                    }
                );
                *remaining_characters = *remaining_characters - 3;
                *no_characters = 0;
                *from_index = *to_index;
                *index = *index + 3;
                *is_preceding_character_scalar = false;
                return
            };
        };
        vector::push_back(
            result,
            UTF8Emoji {
                from: *to_index - 1,
                to: *to_index,
                no_characters: 1,
                is_skin_tone: *is_skin_tone,
                is_single_byte: true
            }
        );
        *remaining_characters = *remaining_characters - 1;
        *from_index = *to_index;
        *is_skin_tone = false;
        *no_characters = 0;
        *is_preceding_character_scalar = false;
        *index = *index + 1;
    }

    fun handle_latin_small_g_character(
        result: &mut vector<UTF8Emoji>,
        characters: &vector<UTF8Character>,
        from_index: &mut u64,
        to_index: &mut u64,
        index: u64,
        remaining_characters: &mut u64,
        is_skin_tone: bool,
        no_characters: &mut u64,
        is_preceding_character_scalar: &mut bool,
    ) {
        // special cases, i.e. 1f3f4_e0067_e0062_e0065_e006e_e0067_e007f
        // if matches with E0067 => the next 5 characters are in the same emoji sequence
        assert!(!is_skin_tone, EInvalidLabel);
        assert!(*no_characters == 2, EInvalidLabel);
        let i = 1;
        while (i <= 5) {
            let character = vector::borrow(characters, index + i);
            *to_index = *to_index + character.no_bytes;
            i = i + 1;
        };
        vector::push_back(result, UTF8Emoji {
            from: *from_index,
            to: *to_index,
            no_characters: 7,
            is_skin_tone,
            is_single_byte: false,
        });
        *remaining_characters = *remaining_characters - 7;
        *from_index = *to_index;
        *no_characters = 0;
        *is_preceding_character_scalar = false;
    }

    fun handle_variant_character(
        emoji_config: &EmojiConfiguration,
        result: &mut vector<UTF8Emoji>,
        characters: &vector<UTF8Character>,
        from_index: &mut u64,
        to_index: u64,
        index: u64,
        remaining_characters: &mut u64,
        is_skin_tone: &mut bool,
        no_characters: &mut u64,
        is_preceding_character_scalar: &mut bool,
        len: u64
    ) {
        // variant character is either at the last position, or followed by the joiner character
        if (index < len - 1) {
            let next_character = vector::borrow(characters, index + 1);
            if (*string::bytes(&next_character.char) != emoji_config.joiner) {
                vector::push_back(
                    result,
                    UTF8Emoji {
                        from: *from_index,
                        to: to_index,
                        no_characters: *no_characters,
                        is_skin_tone: *is_skin_tone,
                        is_single_byte: false
                    }
                );
                *remaining_characters = *remaining_characters - *no_characters;
                *no_characters = 0;
                *from_index = to_index;
                *is_skin_tone = false;
            };
            *is_preceding_character_scalar = false;
        } else {
            // this variant character is at the end of the input string,
            // so this emoji sequence has to end here
            vector::push_back(
                result,
                UTF8Emoji {
                    from: *from_index,
                    to: to_index,
                    no_characters: *no_characters,
                    is_skin_tone: *is_skin_tone,
                    is_single_byte: false
                }
            );
            *remaining_characters = *remaining_characters - *no_characters;
        };
    }

    fun is_emoji_sequence_of_two_characters(str: &String): bool {
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
    friend suins::emoji_tests;
}
