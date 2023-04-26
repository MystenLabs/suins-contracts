#[test_only]
module suins::validator_tests {

    use sui::test_scenario;
    use std::string::utf8;
    use suins::validator;

    #[test]
    fun test_validate_label_works_with_alphabet() {
        let scenario = test_scenario::begin(@0x2);
        test_scenario::next_tx(&mut scenario, @0x2);
        {
            let label = vector[
                98, // 'b'
                99, // 'c'
                100, // 'd'
            ];
            validator::validate_label(utf8(label), 3, 63);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = validator::EInvalidLabel)]
    fun test_validate_label_with_emojis_aborts() {
        let scenario = test_scenario::begin(@0x2);
        test_scenario::next_tx(&mut scenario, @0x2);
        {
            let emoji = vector[
                240, 159, 167, 147, // 1f9d3
                240, 159, 145, 180 // 1f474
            ];
            validator::validate_label(utf8(emoji), 3, 63);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = validator::EInvalidLabel)]
    fun test_validate_label_with_emoji_aborts_if_label_too_short() {
        let scenario = test_scenario::begin(@0x2);
        test_scenario::next_tx(&mut scenario, @0x2);
        {
            let emoji = vector[
                98, // 'b'
                99, // 'c'
            ];
            validator::validate_label(utf8(emoji), 3, 63);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = validator::EInvalidLabel)]
    fun test_validate_label_with_emoji_aborts_with_alphabet_and_emoji_and_non_emoji_unicode() {
        let scenario = test_scenario::begin(@0x2);
        test_scenario::next_tx(&mut scenario, @0x2);
        {
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
            validator::validate_label(utf8(emoji), 3, 63);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = validator::EInvalidLabel)]
    fun test_validate_label_with_emoji_aborts_with_alphabet_and_non_emoji_unicode() {
        let scenario = test_scenario::begin(@0x2);
        test_scenario::next_tx(&mut scenario, @0x2);
        {
            let emoji = vector[
                98, // 'b'
                99, // 'c'
                227, 129, 185, // 30d9 non emoji
            ];
            validator::validate_label(utf8(emoji), 3, 63);
        };
        test_scenario::end(scenario);
    }
}
