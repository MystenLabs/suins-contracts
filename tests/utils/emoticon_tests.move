#[test_only]
module suins::emoticon_tests {

    use suins::emoticon;
    use std::vector;
    use sui::test_scenario::Scenario;
    use sui::test_scenario;
    use suins::emoticon::EmojiConfiguration;

    fun test_init(): Scenario {
        let scenario = test_scenario::begin(@0x2);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            emoticon::test_init(ctx);

        };
        scenario
    }

    // #[test]
    // fun test_ky_emoticon() {
    //     assert!(emoticon::get_no_bytes_of_utf8(120) == 1, 0);
    //     assert!(emoticon::get_no_bytes_of_utf8(194) == 2, 0);
    //     assert!(emoticon::get_no_bytes_of_utf8(226) == 3, 0);
    //     assert!(emoticon::get_no_bytes_of_utf8(240) == 4, 0);
    // }

    // #[test]
    // fun test_ky_to_list_utf8_characters() {
    //     let expected_res = vector[];
    //     vector::push_back(&mut expected_res, utf8(vector[194, 163]));
    //     vector::push_back(&mut expected_res, utf8(vector[226, 130, 172]));
    //     vector::push_back(&mut expected_res, utf8(vector[240, 144, 141, 136]));
    //     assert!(
    //         expected_res == (emoticon::split_to_utf8_character(&vector[194, 163, 226, 130, 172, 240, 144, 141, 136])),
    //         0
    //     );
    // }

    #[test]
    fun test_ky_validate_emoticon() {
        let scenario = test_init();
        test_scenario::next_tx(&mut scenario, @0x2);
        {
            let emoticon = test_scenario::take_shared<EmojiConfiguration>(&mut scenario);
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
                100, // 'd'
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
            ];
            let found = emoticon::validate_emoji(&emoticon, emoji);
            std::debug::print(&found);
            assert!(vector::length(&found) == 27, 0);
            test_scenario::return_shared(emoticon);
        };
        test_scenario::end(scenario);
    }
}

// assert!(emoticon::get_no_bytes_utf8(&vector[194, 163]) == 2, 0);
// assert!(emoticon::get_no_bytes_utf8(&vector[226, 130, 172]) == 3, 0);
// assert!(emoticon::get_no_bytes_utf8(&vector[240, 144, 141, 136]) == 4, 0);
