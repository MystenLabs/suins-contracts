#[test_only]
module suins::emoji_tests {

    use suins::emoji;
    use sui::test_scenario::Scenario;
    use sui::test_scenario;
    use suins::emoji::EmojiConfiguration;

    fun test_init(): Scenario {
        let scenario = test_scenario::begin(@0x2);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            emoji::test_init(ctx);
        };
        scenario
    }

    #[test]
    fun test_validate_emoji() {
        let scenario = test_init();
        test_scenario::next_tx(&mut scenario, @0x2);
        {
            let emoji_config = test_scenario::take_shared<EmojiConfiguration>(&mut scenario);
            let emoji = vector[
                98, // 'b'
                99, // 'c'
                240, 159, 135, 166, // 1f1e6_1f1e8
                240, 159, 135, 168,
                240, 159, 135, 171, // 1f1eb_1f1f2
                240, 159, 135, 178,
                240, 159, 135, 191, // 1f1ff_1f1fc
                240, 159, 135, 188,
                97, // 'a'
                240, 159, 152, 174, // 1f62e_200d_1f4a8
                226, 128, 141,
                240, 159, 146, 168,
                240, 159, 167, 145, // 1f9d1_200d_1f373
                226, 128, 141,
                240, 159, 141, 179,
                240, 159, 144, 166, // 1f426_200d_2b1b
                226, 128, 141,
                226, 172, 155,
                // 35, // 0023_fe0f_20e3
                // 239, 184, 143,
                // 226, 131, 163,
                240, 159, 167, 145, // 1f9d1_200d_1f9b2
                226, 128, 141,
                240, 159, 166, 178,
                240, 159, 152, 182, // 1f636_200d_1f32b_fe0f
                226, 128, 141,
                240, 159, 140, 171,
                239, 184, 143,
                240, 159, 143, 180, // 1f3f4_200d_2620_fe0f
                226, 128, 141,
                226, 152, 160,
                239, 184, 143,
                226, 157, 164, // 2764_fe0f_200d_1f525
                239, 184, 143,
                226, 128, 141,
                240, 159, 148, 165,
                240, 159, 143, 179, // 1f3f3_fe0f_200d_1f308
                239, 184, 143,
                226, 128, 141,
                240, 159, 140, 136,
                101, // 'e'
                240, 159, 145, 129, // 1f441_fe0f_200d_1f5e8_fe0f
                239, 184, 143,
                226, 128, 141,
                240, 159, 151, 168,
                239, 184, 143,
                240, 159, 143, 179, // 1f3f3_fe0f_200d_26a7_fe0f
                239, 184, 143,
                226, 128, 141,
                226, 154, 167,
                239, 184, 143,
                240, 159, 167, 145, // 1f9d1_200d_1f91d_200d_1f9d1
                226, 128, 141,
                240, 159, 164, 157,
                226, 128, 141,
                240, 159, 167, 145,
                240, 159, 145, 169, // 1f469_200d_1f467_200d_1f467
                226, 128, 141,
                240, 159, 145, 167,
                226, 128, 141,
                240, 159, 145, 167,
                102, // 'f'
                240, 159, 145, 169, // 1f469_200d_2764_fe0f_200d_1f468
                226, 128, 141,
                226, 157, 164,
                239, 184, 143,
                226, 128, 141,
                240, 159, 145, 168,
                240, 159, 145, 169, //1f469_200d_2764_fe0f_200d_1f469
                226, 128, 141,
                226, 157, 164,
                239, 184, 143,
                226, 128, 141,
                240, 159, 145, 169,
                103, // 'g'
                240, 159, 145, 168, // 1f468_200d_1f469_200d_1f467_200d_1f466
                226, 128, 141,
                240, 159, 145, 169,
                226, 128, 141,
                240, 159, 145, 167,
                226, 128, 141,
                240, 159, 145, 166,
                97, // a
                 240, 159, 145, 169, // 1f469_200d_1f469_200d_1f467_200d_1f467
                226, 128, 141,
                240, 159, 145, 169,
                226, 128, 141,
                240, 159, 145, 167,
                226, 128, 141,
                240, 159, 145, 167,
                104, // 'h'
                // 240, 159, 143, 180, // 1f3f4_e0067_e0062_e0065_e006e_e0067_e007f
                // 243, 160, 129, 167,
                // 243, 160, 129, 162,
                // 243, 160, 129, 165,
                // 243, 160, 129, 174,
                // 243, 160, 129, 167,
                // 243, 160, 129, 191
                // 65,
                240, 159, 145, 139, // 1f44b_1f3fb skin-tone
                240, 159, 143, 187,
                226, 156, 139, // 270b_1f3fc skin-tone
                240, 159, 143, 188,
                240, 159, 146, 145, // 1f491_1f3fe skin-tone
                240, 159, 143, 190,
                240, 159, 145, 168, // 1f468_1f3fe_200d_1f9b0 skin-tone
                240, 159, 143, 190,
                226, 128, 141,
                240, 159, 166, 176,
                240, 159, 167, 145, // 1f9d1_1f3ff_200d_1f9bd skin-tone
                240, 159, 143, 191,
                226, 128, 141,
                240, 159, 166, 189,
                240, 159, 171, 177, // 1faf1_1f3fd_200d_1faf2_1f3fb skin-tone
                240, 159, 143, 189,
                226, 128, 141,
                240, 159, 171, 178,
                240, 159, 143, 187,
                240, 159, 167, 148, // 1f9d4_1f3fb_200d_2642_fe0f skin-tone
                240, 159, 143, 187,
                226, 128, 141,
                226, 153, 130,
                239, 184, 143,
                226, 155, 185, // 26f9_1f3fd_200d_2640_fe0f skin-tone
                240, 159, 143, 189,
                226, 128, 141,
                226, 153, 128,
                239, 184, 143,
                240, 159, 145, 169, // 1f469_1f3fb_200d_1f91d_200d_1f469_1f3fc skin tone
                240, 159, 143, 187,
                226, 128, 141,
                240, 159, 164, 157,
                226, 128, 141,
                240, 159, 145, 169,
                240, 159, 143, 188,
                // 240, 159, 145, 169, // 1f469_1f3ff_200d_2764_fe0f_200d_1f468_1f3fc skin tone
                // 240, 159, 143, 191,
                // 226, 128, 141,
                // 226, 157, 164,
                // 239, 184, 143,
                // 226, 128, 141,
                // 240, 159, 145, 168,
                // 240, 159, 143, 188,
            ];
            emoji::validate_emoji(&emoji_config, emoji);
            test_scenario::return_shared(emoji_config);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_validate_emoji_works_with_alphabet() {
        let scenario = test_init();
        test_scenario::next_tx(&mut scenario, @0x2);
        {
            let emoji_config = test_scenario::take_shared<EmojiConfiguration>(&mut scenario);
            let emoji = vector[
                98, // 'b'
                99, // 'c'
            ];
            emoji::validate_emoji(&emoji_config, emoji);
            test_scenario::return_shared(emoji_config);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = emoji::EInvalidCharacter)]
    fun test_validate_emoji_aborts_with_alphabet_and_emoji_and_non_emoji_unicode() {
        let scenario = test_init();
        test_scenario::next_tx(&mut scenario, @0x2);
        {
            let emoji_config = test_scenario::take_shared<EmojiConfiguration>(&mut scenario);
            let emoji = vector[
                98, // 'b'
                99, // 'c'
                240, 159, 171, 177, // 1faf1_1f3fd_200d_1faf2_1f3fb skin-tone
                240, 159, 143, 189,
                226, 128, 141,
                240, 159, 171, 178,
                240, 159, 143, 187,
                112, 104, 97, 110, 107, 225, 187, 179,
            ];
            emoji::validate_emoji(&emoji_config, emoji);
            test_scenario::return_shared(emoji_config);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = emoji::EInvalidCharacter)]
    fun test_validate_emoji_aborts_with_alphabet_and_non_emoji_unicode() {
        let scenario = test_init();
        test_scenario::next_tx(&mut scenario, @0x2);
        {
            let emoji_config = test_scenario::take_shared<EmojiConfiguration>(&mut scenario);
            let emoji = vector[
                98, // 'b'
                99, // 'c'
                112, 104, 97, 110, 107, 225, 187, 179,
            ];
            emoji::validate_emoji(&emoji_config, emoji);
            test_scenario::return_shared(emoji_config);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = emoji::EInvalidCharacter)]
    fun test_validate_emoji_abort_with_non_emoji_unicode() {
        let scenario = test_init();
        test_scenario::next_tx(&mut scenario, @0x2);
        {
            let emoji_config = test_scenario::take_shared<EmojiConfiguration>(&mut scenario);
            let emoji = vector[
                112, 104, 97, 110, 107, 225, 187, 179
            ];
            emoji::validate_emoji(&emoji_config, emoji);
            test_scenario::return_shared(emoji_config);
        };
        test_scenario::end(scenario);
    }
}
