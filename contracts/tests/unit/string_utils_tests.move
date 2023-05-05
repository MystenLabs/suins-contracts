#[test_only]
module suins::string_utils_tests {
    use suins::string_utils;
    use std::string::utf8;

    // TODO: is_valid_ascii
    // TODO: validate_label

    #[test]
    fun test_validate_label_works_with_alphabet() {
        string_utils::validate_label(utf8(b"abc"), 3, 63);
    }

    #[test]
    fun test_validate_label_works_with_alphabet_2() {
        string_utils::validate_label(utf8(b"abcdefghijklmnopqrstuvwxyz-0123456789"), 3, 63);
    }

    #[test]
    fun test_validate_label_can_start_with_a_number() {
        string_utils::validate_label(utf8(b"0123"), 3, 63);
    }

    #[test, expected_failure(abort_code = string_utils::EInvalidLabel)]
    fun test_validate_label_aborts_if_starts_with_hyphen() {
        string_utils::validate_label(utf8(b"-abcd"), 3, 63);
    }

    #[test, expected_failure(abort_code = string_utils::EInvalidLabel)]
    fun test_validate_label_aborts_if_ends_with_hyphen() {
        string_utils::validate_label(utf8(b"abcd-"), 3, 63);
    }

    #[test, expected_failure(abort_code = string_utils::EInvalidLabel)]
    fun test_validate_label_aborts_if_starts_and_ends_with_hyphen() {
        string_utils::validate_label(utf8(b"-abcd-"), 3, 63);
    }

    #[test, expected_failure(abort_code = string_utils::EInvalidLabel)]
    fun test_validate_label_aborts_with_upper_cased_character() {
        string_utils::validate_label(utf8(b"Abcd"), 3, 63);
    }

    #[test, expected_failure(abort_code = string_utils::EInvalidLabel)]
    fun test_validate_label_aborts() {
        let emoji = vector[
            240, 159, 167, 147, // 1f9d3
            240, 159, 145, 180 // 1f474
        ];
        string_utils::validate_label(utf8(emoji), 3, 63);
    }

    #[test, expected_failure(abort_code = string_utils::EInvalidLabel)]
    fun test_validate_label_aborts_if_label_too_short() {
        string_utils::validate_label(utf8(b"ab"), 3, 63);
    }

    #[test, expected_failure(abort_code = string_utils::EInvalidLabel)]
    fun test_validate_label_aborts_with_alphabet_and_emoji_and_non_emoji_unicode() {
        let emoji = vector[
            98, // 'b'
            99, // 'c'
            240, 159, 171, 177, // 1faf1_1f3fd_200d_1faf2_1f3fb skin-tone
            240, 159, 143, 189,
            226, 128, 141,
            240, 159, 171, 178,
            240, 159, 143, 187,
            227, 129, 185, // 30d9 non emoji
        ];
        string_utils::validate_label(utf8(emoji), 3, 63);
    }

    #[test, expected_failure(abort_code = string_utils::EInvalidLabel)]
    fun test_validate_label_aborts_with_alphabet_and_non_emoji_unicode() {
        let emoji = vector[
            98, // 'b'
            99, // 'c'
            227, 129, 185, // 30d9 non emoji
        ];
        string_utils::validate_label(utf8(emoji), 3, 63);
    }
}
