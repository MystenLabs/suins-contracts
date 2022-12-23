module suins::emoji {

    use std::vector;

    friend suins::emoticon;

    public(friend) fun two_character_emojis(): vector<vector<u8>> {
        let emojis: vector<vector<u8>> = vector[];

        vector::push_back(&mut emojis,
            vector[240, 159, 135, 166, 240, 159, 135, 168] // 1f1e6_1f1e8
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 166, 240, 159, 135, 174] // 1f1e6_1f1ee
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 166, 240, 159, 135, 177] // 1f1e6_1f1f1
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 166, 240, 159, 135, 178] // 1f1e6_1f1f2
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 166, 240, 159, 135, 180] // 1f1e6_1f1f4
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 166, 240, 159, 135, 182] // 1f1e6_1f1f6
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 166, 240, 159, 135, 183] // 1f1e6_1f1f7
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 166, 240, 159, 135, 184] // 1f1e6_1f1f8
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 166, 240, 159, 135, 185] // 1f1e6_1f1f9
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 166, 240, 159, 135, 186] // 1f1e6_1f1fa
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 166, 240, 159, 135, 188] // 1f1e6_1f1fc
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 166, 240, 159, 135, 189] // 1f1e6_1f1fd
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 166, 240, 159, 135, 191] // 1f1e6_1f1ff
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 167, 240, 159, 135, 166] // 1f1e7_1f1e6
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 167, 240, 159, 135, 167] // 1f1e7_1f1e7
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 167, 240, 159, 135, 169] // 1f1e7_1f1e9
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 167, 240, 159, 135, 170] // 1f1e7_1f1ea
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 167, 240, 159, 135, 171] // 1f1e7_1f1eb
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 166, 240, 159, 135, 169] // 1f1e6_1f1e9
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 167, 240, 159, 135, 172] // 1f1e7_1f1ec
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 167, 240, 159, 135, 173] // 1f1e7_1f1ed
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 167, 240, 159, 135, 174] // 1f1e7_1f1ee
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 167, 240, 159, 135, 175] // 1f1e7_1f1ef
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 167, 240, 159, 135, 178] // 1f1e7_1f1f2
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 167, 240, 159, 135, 177] // 1f1e7_1f1f1
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 167, 240, 159, 135, 179] // 1f1e7_1f1f3
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 167, 240, 159, 135, 180] // 1f1e7_1f1f4
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 167, 240, 159, 135, 182] // 1f1e7_1f1f6
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 167, 240, 159, 135, 183] // 1f1e7_1f1f7
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 167, 240, 159, 135, 184] // 1f1e7_1f1f8
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 167, 240, 159, 135, 185] // 1f1e7_1f1f9
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 166, 240, 159, 135, 171] // 1f1e6_1f1eb
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 167, 240, 159, 135, 188] // 1f1e7_1f1fc
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 167, 240, 159, 135, 190] // 1f1e7_1f1fe
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 167, 240, 159, 135, 191] // 1f1e7_1f1ff
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 168, 240, 159, 135, 168] // 1f1e8_1f1e8
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 168, 240, 159, 135, 169] // 1f1e8_1f1e9
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 168, 240, 159, 135, 166] // 1f1e8_1f1e6
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 168, 240, 159, 135, 171] // 1f1e8_1f1eb
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 168, 240, 159, 135, 172] // 1f1e8_1f1ec
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 168, 240, 159, 135, 173] // 1f1e8_1f1ed
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 168, 240, 159, 135, 174] // 1f1e8_1f1ee
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 168, 240, 159, 135, 176] // 1f1e8_1f1f0
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 168, 240, 159, 135, 177] // 1f1e8_1f1f1
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 168, 240, 159, 135, 178] // 1f1e8_1f1f2
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 168, 240, 159, 135, 179] // 1f1e8_1f1f3
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 168, 240, 159, 135, 180] // 1f1e8_1f1f4
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 168, 240, 159, 135, 181] // 1f1e8_1f1f5
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 166, 240, 159, 135, 170] // 1f1e6_1f1ea
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 168, 240, 159, 135, 186] // 1f1e8_1f1fa
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 168, 240, 159, 135, 187] // 1f1e8_1f1fb
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 168, 240, 159, 135, 189] // 1f1e8_1f1fd
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 168, 240, 159, 135, 188] // 1f1e8_1f1fc
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 168, 240, 159, 135, 190] // 1f1e8_1f1fe
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 168, 240, 159, 135, 191] // 1f1e8_1f1ff
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 169, 240, 159, 135, 170] // 1f1e9_1f1ea
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 169, 240, 159, 135, 172] // 1f1e9_1f1ec
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 169, 240, 159, 135, 175] // 1f1e9_1f1ef
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 169, 240, 159, 135, 176] // 1f1e9_1f1f0
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 169, 240, 159, 135, 178] // 1f1e9_1f1f2
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 169, 240, 159, 135, 180] // 1f1e9_1f1f4
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 169, 240, 159, 135, 191] // 1f1e9_1f1ff
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 170, 240, 159, 135, 166] // 1f1ea_1f1e6
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 170, 240, 159, 135, 168] // 1f1ea_1f1e8
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 170, 240, 159, 135, 170] // 1f1ea_1f1ea
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 167, 240, 159, 135, 187] // 1f1e7_1f1fb
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 170, 240, 159, 135, 173] // 1f1ea_1f1ed
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 170, 240, 159, 135, 183] // 1f1ea_1f1f7
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 170, 240, 159, 135, 184] // 1f1ea_1f1f8
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 170, 240, 159, 135, 185] // 1f1ea_1f1f9
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 170, 240, 159, 135, 186] // 1f1ea_1f1fa
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 170, 240, 159, 135, 172] // 1f1ea_1f1ec
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 171, 240, 159, 135, 175] // 1f1eb_1f1ef
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 171, 240, 159, 135, 176] // 1f1eb_1f1f0
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 171, 240, 159, 135, 178] // 1f1eb_1f1f2
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 171, 240, 159, 135, 180] // 1f1eb_1f1f4
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 172, 240, 159, 135, 166] // 1f1ec_1f1e6
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 172, 240, 159, 135, 167] // 1f1ec_1f1e7
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 171, 240, 159, 135, 183] // 1f1eb_1f1f7
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 172, 240, 159, 135, 169] // 1f1ec_1f1e9
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 172, 240, 159, 135, 170] // 1f1ec_1f1ea
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 172, 240, 159, 135, 171] // 1f1ec_1f1eb
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 172, 240, 159, 135, 172] // 1f1ec_1f1ec
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 172, 240, 159, 135, 173] // 1f1ec_1f1ed
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 172, 240, 159, 135, 174] // 1f1ec_1f1ee
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 172, 240, 159, 135, 177] // 1f1ec_1f1f1
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 172, 240, 159, 135, 178] // 1f1ec_1f1f2
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 172, 240, 159, 135, 179] // 1f1ec_1f1f3
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 172, 240, 159, 135, 181] // 1f1ec_1f1f5
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 172, 240, 159, 135, 182] // 1f1ec_1f1f6
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 171, 240, 159, 135, 174] // 1f1eb_1f1ee
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 172, 240, 159, 135, 184] // 1f1ec_1f1f8
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 172, 240, 159, 135, 186] // 1f1ec_1f1fa
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 172, 240, 159, 135, 185] // 1f1ec_1f1f9
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 172, 240, 159, 135, 188] // 1f1ec_1f1fc
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 172, 240, 159, 135, 190] // 1f1ec_1f1fe
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 166, 240, 159, 135, 172] // 1f1e6_1f1ec
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 173, 240, 159, 135, 178] // 1f1ed_1f1f2
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 173, 240, 159, 135, 179] // 1f1ed_1f1f3
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 173, 240, 159, 135, 183] // 1f1ed_1f1f7
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 168, 240, 159, 135, 183] // 1f1e8_1f1f7
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 173, 240, 159, 135, 186] // 1f1ed_1f1fa
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 174, 240, 159, 135, 168] // 1f1ee_1f1e8
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 174, 240, 159, 135, 169] // 1f1ee_1f1e9
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 174, 240, 159, 135, 170] // 1f1ee_1f1ea
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 174, 240, 159, 135, 177] // 1f1ee_1f1f1
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 174, 240, 159, 135, 178] // 1f1ee_1f1f2
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 174, 240, 159, 135, 179] // 1f1ee_1f1f3
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 174, 240, 159, 135, 180] // 1f1ee_1f1f4
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 174, 240, 159, 135, 182] // 1f1ee_1f1f6
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 174, 240, 159, 135, 183] // 1f1ee_1f1f7
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 174, 240, 159, 135, 185] // 1f1ee_1f1f9
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 174, 240, 159, 135, 184] // 1f1ee_1f1f8
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 175, 240, 159, 135, 170] // 1f1ef_1f1ea
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 175, 240, 159, 135, 178] // 1f1ef_1f1f2
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 175, 240, 159, 135, 180] // 1f1ef_1f1f4
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 175, 240, 159, 135, 181] // 1f1ef_1f1f5
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 176, 240, 159, 135, 170] // 1f1f0_1f1ea
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 176, 240, 159, 135, 172] // 1f1f0_1f1ec
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 176, 240, 159, 135, 173] // 1f1f0_1f1ed
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 176, 240, 159, 135, 174] // 1f1f0_1f1ee
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 176, 240, 159, 135, 178] // 1f1f0_1f1f2
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 176, 240, 159, 135, 179] // 1f1f0_1f1f3
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 176, 240, 159, 135, 181] // 1f1f0_1f1f5
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 176, 240, 159, 135, 183] // 1f1f0_1f1f7
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 176, 240, 159, 135, 188] // 1f1f0_1f1fc
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 176, 240, 159, 135, 190] // 1f1f0_1f1fe
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 173, 240, 159, 135, 176] // 1f1ed_1f1f0
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 173, 240, 159, 135, 185] // 1f1ed_1f1f9
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 176, 240, 159, 135, 191] // 1f1f0_1f1ff
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 172, 240, 159, 135, 183] // 1f1ec_1f1f7
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 177, 240, 159, 135, 166] // 1f1f1_1f1e6
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 177, 240, 159, 135, 176] // 1f1f1_1f1f0
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 177, 240, 159, 135, 183] // 1f1f1_1f1f7
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 177, 240, 159, 135, 184] // 1f1f1_1f1f8
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 177, 240, 159, 135, 185] // 1f1f1_1f1f9
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 177, 240, 159, 135, 186] // 1f1f1_1f1fa
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 177, 240, 159, 135, 187] // 1f1f1_1f1fb
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 177, 240, 159, 135, 190] // 1f1f1_1f1fe
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 177, 240, 159, 135, 174] // 1f1f1_1f1ee
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 178, 240, 159, 135, 168] // 1f1f2_1f1e8
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 178, 240, 159, 135, 169] // 1f1f2_1f1e9
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 178, 240, 159, 135, 170] // 1f1f2_1f1ea
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 178, 240, 159, 135, 171] // 1f1f2_1f1eb
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 178, 240, 159, 135, 172] // 1f1f2_1f1ec
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 178, 240, 159, 135, 173] // 1f1f2_1f1ed
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 178, 240, 159, 135, 176] // 1f1f2_1f1f0
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 178, 240, 159, 135, 177] // 1f1f2_1f1f1
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 178, 240, 159, 135, 178] // 1f1f2_1f1f2
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 178, 240, 159, 135, 179] // 1f1f2_1f1f3
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 178, 240, 159, 135, 180] // 1f1f2_1f1f4
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 177, 240, 159, 135, 168] // 1f1f1_1f1e8
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 178, 240, 159, 135, 182] // 1f1f2_1f1f6
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 178, 240, 159, 135, 183] // 1f1f2_1f1f7
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 178, 240, 159, 135, 184] // 1f1f2_1f1f8
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 178, 240, 159, 135, 185] // 1f1f2_1f1f9
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 178, 240, 159, 135, 186] // 1f1f2_1f1fa
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 178, 240, 159, 135, 187] // 1f1f2_1f1fb
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 178, 240, 159, 135, 188] // 1f1f2_1f1fc
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 178, 240, 159, 135, 189] // 1f1f2_1f1fd
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 178, 240, 159, 135, 181] // 1f1f2_1f1f5
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 178, 240, 159, 135, 191] // 1f1f2_1f1ff
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 179, 240, 159, 135, 166] // 1f1f3_1f1e6
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 179, 240, 159, 135, 168] // 1f1f3_1f1e8
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 179, 240, 159, 135, 170] // 1f1f3_1f1ea
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 179, 240, 159, 135, 171] // 1f1f3_1f1eb
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 179, 240, 159, 135, 172] // 1f1f3_1f1ec
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 179, 240, 159, 135, 174] // 1f1f3_1f1ee
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 179, 240, 159, 135, 177] // 1f1f3_1f1f1
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 179, 240, 159, 135, 180] // 1f1f3_1f1f4
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 178, 240, 159, 135, 190] // 1f1f2_1f1fe
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 179, 240, 159, 135, 183] // 1f1f3_1f1f7
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 179, 240, 159, 135, 186] // 1f1f3_1f1fa
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 179, 240, 159, 135, 191] // 1f1f3_1f1ff
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 180, 240, 159, 135, 178] // 1f1f4_1f1f2
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 181, 240, 159, 135, 166] // 1f1f5_1f1e6
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 181, 240, 159, 135, 170] // 1f1f5_1f1ea
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 181, 240, 159, 135, 171] // 1f1f5_1f1eb
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 181, 240, 159, 135, 172] // 1f1f5_1f1ec
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 181, 240, 159, 135, 173] // 1f1f5_1f1ed
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 181, 240, 159, 135, 176] // 1f1f5_1f1f0
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 181, 240, 159, 135, 177] // 1f1f5_1f1f1
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 181, 240, 159, 135, 178] // 1f1f5_1f1f2
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 181, 240, 159, 135, 179] // 1f1f5_1f1f3
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 181, 240, 159, 135, 183] // 1f1f5_1f1f7
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 181, 240, 159, 135, 184] // 1f1f5_1f1f8
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 181, 240, 159, 135, 185] // 1f1f5_1f1f9
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 181, 240, 159, 135, 188] // 1f1f5_1f1fc
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 181, 240, 159, 135, 190] // 1f1f5_1f1fe
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 179, 240, 159, 135, 181] // 1f1f3_1f1f5
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 183, 240, 159, 135, 170] // 1f1f7_1f1ea
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 183, 240, 159, 135, 180] // 1f1f7_1f1f4
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 182, 240, 159, 135, 166] // 1f1f6_1f1e6
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 183, 240, 159, 135, 186] // 1f1f7_1f1fa
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 183, 240, 159, 135, 188] // 1f1f7_1f1fc
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 184, 240, 159, 135, 166] // 1f1f8_1f1e6
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 184, 240, 159, 135, 167] // 1f1f8_1f1e7
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 184, 240, 159, 135, 168] // 1f1f8_1f1e8
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 184, 240, 159, 135, 169] // 1f1f8_1f1e9
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 184, 240, 159, 135, 170] // 1f1f8_1f1ea
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 184, 240, 159, 135, 172] // 1f1f8_1f1ec
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 184, 240, 159, 135, 173] // 1f1f8_1f1ed
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 184, 240, 159, 135, 174] // 1f1f8_1f1ee
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 184, 240, 159, 135, 175] // 1f1f8_1f1ef
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 184, 240, 159, 135, 176] // 1f1f8_1f1f0
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 184, 240, 159, 135, 177] // 1f1f8_1f1f1
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 184, 240, 159, 135, 178] // 1f1f8_1f1f2
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 184, 240, 159, 135, 179] // 1f1f8_1f1f3
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 184, 240, 159, 135, 180] // 1f1f8_1f1f4
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 184, 240, 159, 135, 183] // 1f1f8_1f1f7
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 184, 240, 159, 135, 184] // 1f1f8_1f1f8
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 184, 240, 159, 135, 185] // 1f1f8_1f1f9
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 184, 240, 159, 135, 187] // 1f1f8_1f1fb
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 184, 240, 159, 135, 189] // 1f1f8_1f1fd
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 184, 240, 159, 135, 190] // 1f1f8_1f1fe
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 184, 240, 159, 135, 191] // 1f1f8_1f1ff
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 185, 240, 159, 135, 166] // 1f1f9_1f1e6
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 185, 240, 159, 135, 168] // 1f1f9_1f1e8
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 185, 240, 159, 135, 169] // 1f1f9_1f1e9
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 185, 240, 159, 135, 171] // 1f1f9_1f1eb
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 185, 240, 159, 135, 172] // 1f1f9_1f1ec
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 185, 240, 159, 135, 173] // 1f1f9_1f1ed
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 185, 240, 159, 135, 175] // 1f1f9_1f1ef
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 185, 240, 159, 135, 176] // 1f1f9_1f1f0
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 185, 240, 159, 135, 177] // 1f1f9_1f1f1
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 185, 240, 159, 135, 178] // 1f1f9_1f1f2
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 185, 240, 159, 135, 179] // 1f1f9_1f1f3
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 185, 240, 159, 135, 180] // 1f1f9_1f1f4
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 185, 240, 159, 135, 183] // 1f1f9_1f1f7
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 185, 240, 159, 135, 185] // 1f1f9_1f1f9
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 185, 240, 159, 135, 187] // 1f1f9_1f1fb
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 185, 240, 159, 135, 188] // 1f1f9_1f1fc
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 185, 240, 159, 135, 191] // 1f1f9_1f1ff
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 186, 240, 159, 135, 166] // 1f1fa_1f1e6
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 186, 240, 159, 135, 172] // 1f1fa_1f1ec
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 186, 240, 159, 135, 179] // 1f1fa_1f1f3
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 186, 240, 159, 135, 178] // 1f1fa_1f1f2
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 186, 240, 159, 135, 184] // 1f1fa_1f1f8
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 186, 240, 159, 135, 191] // 1f1fa_1f1ff
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 186, 240, 159, 135, 190] // 1f1fa_1f1fe
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 187, 240, 159, 135, 166] // 1f1fb_1f1e6
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 187, 240, 159, 135, 168] // 1f1fb_1f1e8
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 187, 240, 159, 135, 170] // 1f1fb_1f1ea
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 187, 240, 159, 135, 172] // 1f1fb_1f1ec
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 187, 240, 159, 135, 174] // 1f1fb_1f1ee
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 187, 240, 159, 135, 179] // 1f1fb_1f1f3
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 187, 240, 159, 135, 186] // 1f1fb_1f1fa
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 188, 240, 159, 135, 171] // 1f1fc_1f1eb
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 188, 240, 159, 135, 184] // 1f1fc_1f1f8
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 190, 240, 159, 135, 170] // 1f1fe_1f1ea
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 190, 240, 159, 135, 185] // 1f1fe_1f1f9
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 191, 240, 159, 135, 166] // 1f1ff_1f1e6
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 189, 240, 159, 135, 176] // 1f1fd_1f1f0
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 191, 240, 159, 135, 178] // 1f1ff_1f1f2
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 183, 240, 159, 135, 184] // 1f1f7_1f1f8
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 177, 240, 159, 135, 167] // 1f1f1_1f1e7
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 178, 240, 159, 135, 166] // 1f1f2_1f1e6
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 135, 191, 240, 159, 135, 188] // 1f1ff_1f1fc
        );

        emojis
    }

    public(friend) fun three_character_emojis(): vector<vector<u8>> {
        let emojis: vector<vector<u8>> = vector[];

        vector::push_back(&mut emojis,
            vector[240, 159, 152, 174, 226, 128, 141, 240, 159, 146, 168] // 1f62e_200d_1f4a8
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 168, 226, 128, 141, 240, 159, 166, 177] // 1f468_200d_1f9b1
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 167, 145, 226, 128, 141, 240, 159, 166, 176] // 1f9d1_200d_1f9b0
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 169, 226, 128, 141, 240, 159, 166, 176] // 1f469_200d_1f9b0
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 169, 226, 128, 141, 240, 159, 166, 177] // 1f469_200d_1f9b1
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 167, 145, 226, 128, 141, 240, 159, 166, 177] // 1f9d1_200d_1f9b1
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 169, 226, 128, 141, 240, 159, 166, 179] // 1f469_200d_1f9b3
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 167, 145, 226, 128, 141, 240, 159, 166, 179] // 1f9d1_200d_1f9b3
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 169, 226, 128, 141, 240, 159, 166, 178] // 1f469_200d_1f9b2
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 167, 145, 226, 128, 141, 240, 159, 166, 178] // 1f9d1_200d_1f9b2
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 167, 145, 226, 128, 141, 240, 159, 142, 147] // 1f9d1_200d_1f393
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 168, 226, 128, 141, 240, 159, 142, 147] // 1f468_200d_1f393
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 169, 226, 128, 141, 240, 159, 142, 147] // 1f469_200d_1f393
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 168, 226, 128, 141, 240, 159, 166, 176] // 1f468_200d_1f9b0
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 167, 145, 226, 128, 141, 240, 159, 143, 171] // 1f9d1_200d_1f3eb
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 168, 226, 128, 141, 240, 159, 143, 171] // 1f468_200d_1f3eb
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 169, 226, 128, 141, 240, 159, 143, 171] // 1f469_200d_1f3eb
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 167, 145, 226, 128, 141, 240, 159, 140, 190] // 1f9d1_200d_1f33e
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 168, 226, 128, 141, 240, 159, 140, 190] // 1f468_200d_1f33e
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 169, 226, 128, 141, 240, 159, 140, 190] // 1f469_200d_1f33e
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 167, 145, 226, 128, 141, 240, 159, 141, 179] // 1f9d1_200d_1f373
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 168, 226, 128, 141, 240, 159, 141, 179] // 1f468_200d_1f373
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 169, 226, 128, 141, 240, 159, 141, 179] // 1f469_200d_1f373
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 167, 145, 226, 128, 141, 240, 159, 148, 167] // 1f9d1_200d_1f527
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 168, 226, 128, 141, 240, 159, 148, 167] // 1f468_200d_1f527
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 169, 226, 128, 141, 240, 159, 148, 167] // 1f469_200d_1f527
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 167, 145, 226, 128, 141, 240, 159, 143, 173] // 1f9d1_200d_1f3ed
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 168, 226, 128, 141, 240, 159, 143, 173] // 1f468_200d_1f3ed
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 169, 226, 128, 141, 240, 159, 143, 173] // 1f469_200d_1f3ed
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 167, 145, 226, 128, 141, 240, 159, 146, 188] // 1f9d1_200d_1f4bc
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 168, 226, 128, 141, 240, 159, 146, 188] // 1f468_200d_1f4bc
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 169, 226, 128, 141, 240, 159, 146, 188] // 1f469_200d_1f4bc
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 167, 145, 226, 128, 141, 240, 159, 148, 172] // 1f9d1_200d_1f52c
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 168, 226, 128, 141, 240, 159, 148, 172] // 1f468_200d_1f52c
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 169, 226, 128, 141, 240, 159, 148, 172] // 1f469_200d_1f52c
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 167, 145, 226, 128, 141, 240, 159, 146, 187] // 1f9d1_200d_1f4bb
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 168, 226, 128, 141, 240, 159, 166, 179] // 1f468_200d_1f9b3
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 169, 226, 128, 141, 240, 159, 146, 187] // 1f469_200d_1f4bb
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 167, 145, 226, 128, 141, 240, 159, 142, 164] // 1f9d1_200d_1f3a4
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 168, 226, 128, 141, 240, 159, 142, 164] // 1f468_200d_1f3a4
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 169, 226, 128, 141, 240, 159, 142, 164] // 1f469_200d_1f3a4
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 167, 145, 226, 128, 141, 240, 159, 142, 168] // 1f9d1_200d_1f3a8
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 168, 226, 128, 141, 240, 159, 142, 168] // 1f468_200d_1f3a8
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 169, 226, 128, 141, 240, 159, 142, 168] // 1f469_200d_1f3a8
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 167, 145, 226, 128, 141, 240, 159, 154, 128] // 1f9d1_200d_1f680
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 168, 226, 128, 141, 240, 159, 154, 128] // 1f468_200d_1f680
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 169, 226, 128, 141, 240, 159, 154, 128] // 1f469_200d_1f680
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 167, 145, 226, 128, 141, 240, 159, 154, 146] // 1f9d1_200d_1f692
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 168, 226, 128, 141, 240, 159, 154, 146] // 1f468_200d_1f692
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 169, 226, 128, 141, 240, 159, 154, 146] // 1f469_200d_1f692
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 169, 226, 128, 141, 240, 159, 141, 188] // 1f469_200d_1f37c
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 168, 226, 128, 141, 240, 159, 141, 188] // 1f468_200d_1f37c
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 167, 145, 226, 128, 141, 240, 159, 141, 188] // 1f9d1_200d_1f37c
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 167, 145, 226, 128, 141, 240, 159, 142, 132] // 1f9d1_200d_1f384
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 167, 145, 226, 128, 141, 240, 159, 166, 175] // 1f9d1_200d_1f9af
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 168, 226, 128, 141, 240, 159, 166, 175] // 1f468_200d_1f9af
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 169, 226, 128, 141, 240, 159, 166, 175] // 1f469_200d_1f9af
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 167, 145, 226, 128, 141, 240, 159, 166, 188] // 1f9d1_200d_1f9bc
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 168, 226, 128, 141, 240, 159, 166, 188] // 1f468_200d_1f9bc
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 169, 226, 128, 141, 240, 159, 166, 188] // 1f469_200d_1f9bc
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 167, 145, 226, 128, 141, 240, 159, 166, 189] // 1f9d1_200d_1f9bd
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 168, 226, 128, 141, 240, 159, 166, 189] // 1f468_200d_1f9bd
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 169, 226, 128, 141, 240, 159, 166, 189] // 1f469_200d_1f9bd
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 168, 226, 128, 141, 240, 159, 145, 166] // 1f468_200d_1f466
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 168, 226, 128, 141, 240, 159, 145, 167] // 1f468_200d_1f467
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 169, 226, 128, 141, 240, 159, 145, 166] // 1f469_200d_1f466
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 169, 226, 128, 141, 240, 159, 145, 167] // 1f469_200d_1f467
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 144, 149, 226, 128, 141, 240, 159, 166, 186] // 1f415_200d_1f9ba
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 144, 136, 226, 128, 141, 226, 172, 155] // 1f408_200d_2b1b
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 144, 166, 226, 128, 141, 226, 172, 155] // 1f426_200d_2b1b
        );
        vector::push_back(&mut emojis,
            vector[35, 239, 184, 143, 226, 131, 163] // 0023_fe0f_20e3
        );
        vector::push_back(&mut emojis,
            vector[42, 239, 184, 143, 226, 131, 163] // 002a_fe0f_20e3
        );
        vector::push_back(&mut emojis,
            vector[48, 239, 184, 143, 226, 131, 163] // 0030_fe0f_20e3
        );
        vector::push_back(&mut emojis,
            vector[49, 239, 184, 143, 226, 131, 163] // 0031_fe0f_20e3
        );
        vector::push_back(&mut emojis,
            vector[50, 239, 184, 143, 226, 131, 163] // 0032_fe0f_20e3
        );
        vector::push_back(&mut emojis,
            vector[51, 239, 184, 143, 226, 131, 163] // 0033_fe0f_20e3
        );
        vector::push_back(&mut emojis,
            vector[52, 239, 184, 143, 226, 131, 163] // 0034_fe0f_20e3
        );
        vector::push_back(&mut emojis,
            vector[53, 239, 184, 143, 226, 131, 163] // 0035_fe0f_20e3
        );
        vector::push_back(&mut emojis,
            vector[54, 239, 184, 143, 226, 131, 163] // 0036_fe0f_20e3
        );
        vector::push_back(&mut emojis,
            vector[55, 239, 184, 143, 226, 131, 163] // 0037_fe0f_20e3
        );
        vector::push_back(&mut emojis,
            vector[56, 239, 184, 143, 226, 131, 163] // 0038_fe0f_20e3
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 152, 181, 226, 128, 141, 240, 159, 146, 171] // 1f635_200d_1f4ab
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 168, 226, 128, 141, 240, 159, 166, 178] // 1f468_200d_1f9b2
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 168, 226, 128, 141, 240, 159, 146, 187] // 1f468_200d_1f4bb
        );
        vector::push_back(&mut emojis,
            vector[57, 239, 184, 143, 226, 131, 163] // 0039_fe0f_20e3
        );

        emojis
    }

    public(friend) fun four_character_emojis(): vector<vector<u8>> {
        let emojis: vector<vector<u8>> = vector[];

        vector::push_back(&mut emojis,
            vector[240, 159, 152, 182, 226, 128, 141, 240, 159, 140, 171, 239, 184, 143] // 1f636_200d_1f32b_fe0f
        );
        vector::push_back(&mut emojis,
            vector[226, 157, 164, 239, 184, 143, 226, 128, 141, 240, 159, 148, 165] // 2764_fe0f_200d_1f525
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 167, 148, 226, 128, 141, 226, 153, 128, 239, 184, 143] // 1f9d4_200d_2640_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 177, 226, 128, 141, 226, 153, 130, 239, 184, 143] // 1f471_200d_2642_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 153, 141, 226, 128, 141, 226, 153, 130, 239, 184, 143] // 1f64d_200d_2642_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 153, 141, 226, 128, 141, 226, 153, 128, 239, 184, 143] // 1f64d_200d_2640_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 153, 142, 226, 128, 141, 226, 153, 130, 239, 184, 143] // 1f64e_200d_2642_fe0f
        );
        vector::push_back(&mut emojis,
            vector[226, 157, 164, 239, 184, 143, 226, 128, 141, 240, 159, 169, 185] // 2764_fe0f_200d_1fa79
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 153, 133, 226, 128, 141, 226, 153, 130, 239, 184, 143] // 1f645_200d_2642_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 153, 133, 226, 128, 141, 226, 153, 128, 239, 184, 143] // 1f645_200d_2640_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 153, 134, 226, 128, 141, 226, 153, 130, 239, 184, 143] // 1f646_200d_2642_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 153, 134, 226, 128, 141, 226, 153, 128, 239, 184, 143] // 1f646_200d_2640_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 146, 129, 226, 128, 141, 226, 153, 130, 239, 184, 143] // 1f481_200d_2642_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 146, 129, 226, 128, 141, 226, 153, 128, 239, 184, 143] // 1f481_200d_2640_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 153, 139, 226, 128, 141, 226, 153, 130, 239, 184, 143] // 1f64b_200d_2642_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 153, 139, 226, 128, 141, 226, 153, 128, 239, 184, 143] // 1f64b_200d_2640_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 167, 143, 226, 128, 141, 226, 153, 130, 239, 184, 143] // 1f9cf_200d_2642_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 167, 143, 226, 128, 141, 226, 153, 128, 239, 184, 143] // 1f9cf_200d_2640_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 153, 135, 226, 128, 141, 226, 153, 130, 239, 184, 143] // 1f647_200d_2642_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 153, 135, 226, 128, 141, 226, 153, 128, 239, 184, 143] // 1f647_200d_2640_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 164, 166, 226, 128, 141, 226, 153, 130, 239, 184, 143] // 1f926_200d_2642_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 164, 166, 226, 128, 141, 226, 153, 128, 239, 184, 143] // 1f926_200d_2640_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 164, 183, 226, 128, 141, 226, 153, 130, 239, 184, 143] // 1f937_200d_2642_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 164, 183, 226, 128, 141, 226, 153, 128, 239, 184, 143] // 1f937_200d_2640_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 167, 145, 226, 128, 141, 226, 154, 149, 239, 184, 143] // 1f9d1_200d_2695_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 169, 226, 128, 141, 226, 154, 149, 239, 184, 143] // 1f469_200d_2695_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 168, 226, 128, 141, 226, 154, 149, 239, 184, 143] // 1f468_200d_2695_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 167, 145, 226, 128, 141, 226, 154, 150, 239, 184, 143] // 1f9d1_200d_2696_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 169, 226, 128, 141, 226, 154, 150, 239, 184, 143] // 1f469_200d_2696_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 168, 226, 128, 141, 226, 154, 150, 239, 184, 143] // 1f468_200d_2696_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 167, 145, 226, 128, 141, 226, 156, 136, 239, 184, 143] // 1f9d1_200d_2708_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 168, 226, 128, 141, 226, 156, 136, 239, 184, 143] // 1f468_200d_2708_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 169, 226, 128, 141, 226, 156, 136, 239, 184, 143] // 1f469_200d_2708_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 174, 226, 128, 141, 226, 153, 130, 239, 184, 143] // 1f46e_200d_2642_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 177, 226, 128, 141, 226, 153, 128, 239, 184, 143] // 1f471_200d_2640_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 174, 226, 128, 141, 226, 153, 128, 239, 184, 143] // 1f46e_200d_2640_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 146, 130, 226, 128, 141, 226, 153, 130, 239, 184, 143] // 1f482_200d_2642_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 146, 130, 226, 128, 141, 226, 153, 128, 239, 184, 143] // 1f482_200d_2640_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 183, 226, 128, 141, 226, 153, 130, 239, 184, 143] // 1f477_200d_2642_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 183, 226, 128, 141, 226, 153, 128, 239, 184, 143] // 1f477_200d_2640_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 179, 226, 128, 141, 226, 153, 130, 239, 184, 143] // 1f473_200d_2642_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 179, 226, 128, 141, 226, 153, 128, 239, 184, 143] // 1f473_200d_2640_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 164, 181, 226, 128, 141, 226, 153, 130, 239, 184, 143] // 1f935_200d_2642_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 167, 148, 226, 128, 141, 226, 153, 130, 239, 184, 143] // 1f9d4_200d_2642_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 176, 226, 128, 141, 226, 153, 128, 239, 184, 143] // 1f470_200d_2640_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 166, 184, 226, 128, 141, 226, 153, 130, 239, 184, 143] // 1f9b8_200d_2642_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 166, 184, 226, 128, 141, 226, 153, 128, 239, 184, 143] // 1f9b8_200d_2640_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 166, 185, 226, 128, 141, 226, 153, 128, 239, 184, 143] // 1f9b9_200d_2640_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 166, 185, 226, 128, 141, 226, 153, 130, 239, 184, 143] // 1f9b9_200d_2642_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 167, 153, 226, 128, 141, 226, 153, 130, 239, 184, 143] // 1f9d9_200d_2642_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 167, 153, 226, 128, 141, 226, 153, 128, 239, 184, 143] // 1f9d9_200d_2640_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 167, 154, 226, 128, 141, 226, 153, 130, 239, 184, 143] // 1f9da_200d_2642_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 167, 154, 226, 128, 141, 226, 153, 128, 239, 184, 143] // 1f9da_200d_2640_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 167, 155, 226, 128, 141, 226, 153, 130, 239, 184, 143] // 1f9db_200d_2642_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 164, 181, 226, 128, 141, 226, 153, 128, 239, 184, 143] // 1f935_200d_2640_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 167, 156, 226, 128, 141, 226, 153, 130, 239, 184, 143] // 1f9dc_200d_2642_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 167, 156, 226, 128, 141, 226, 153, 128, 239, 184, 143] // 1f9dc_200d_2640_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 167, 157, 226, 128, 141, 226, 153, 130, 239, 184, 143] // 1f9dd_200d_2642_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 153, 142, 226, 128, 141, 226, 153, 128, 239, 184, 143] // 1f64e_200d_2640_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 167, 158, 226, 128, 141, 226, 153, 128, 239, 184, 143] // 1f9de_200d_2640_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 167, 158, 226, 128, 141, 226, 153, 130, 239, 184, 143] // 1f9de_200d_2642_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 167, 159, 226, 128, 141, 226, 153, 130, 239, 184, 143] // 1f9df_200d_2642_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 167, 159, 226, 128, 141, 226, 153, 128, 239, 184, 143] // 1f9df_200d_2640_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 146, 134, 226, 128, 141, 226, 153, 130, 239, 184, 143] // 1f486_200d_2642_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 146, 134, 226, 128, 141, 226, 153, 128, 239, 184, 143] // 1f486_200d_2640_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 146, 135, 226, 128, 141, 226, 153, 130, 239, 184, 143] // 1f487_200d_2642_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 154, 182, 226, 128, 141, 226, 153, 130, 239, 184, 143] // 1f6b6_200d_2642_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 146, 135, 226, 128, 141, 226, 153, 128, 239, 184, 143] // 1f487_200d_2640_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 154, 182, 226, 128, 141, 226, 153, 128, 239, 184, 143] // 1f6b6_200d_2640_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 167, 141, 226, 128, 141, 226, 153, 130, 239, 184, 143] // 1f9cd_200d_2642_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 167, 141, 226, 128, 141, 226, 153, 128, 239, 184, 143] // 1f9cd_200d_2640_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 167, 142, 226, 128, 141, 226, 153, 130, 239, 184, 143] // 1f9ce_200d_2642_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 167, 142, 226, 128, 141, 226, 153, 128, 239, 184, 143] // 1f9ce_200d_2640_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 143, 131, 226, 128, 141, 226, 153, 130, 239, 184, 143] // 1f3c3_200d_2642_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 167, 155, 226, 128, 141, 226, 153, 128, 239, 184, 143] // 1f9db_200d_2640_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 175, 226, 128, 141, 226, 153, 130, 239, 184, 143] // 1f46f_200d_2642_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 175, 226, 128, 141, 226, 153, 128, 239, 184, 143] // 1f46f_200d_2640_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 167, 150, 226, 128, 141, 226, 153, 130, 239, 184, 143] // 1f9d6_200d_2642_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 167, 150, 226, 128, 141, 226, 153, 128, 239, 184, 143] // 1f9d6_200d_2640_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 167, 151, 226, 128, 141, 226, 153, 130, 239, 184, 143] // 1f9d7_200d_2642_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 167, 151, 226, 128, 141, 226, 153, 128, 239, 184, 143] // 1f9d7_200d_2640_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 143, 132, 226, 128, 141, 226, 153, 130, 239, 184, 143] // 1f3c4_200d_2642_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 143, 132, 226, 128, 141, 226, 153, 128, 239, 184, 143] // 1f3c4_200d_2640_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 167, 157, 226, 128, 141, 226, 153, 128, 239, 184, 143] // 1f9dd_200d_2640_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 154, 163, 226, 128, 141, 226, 153, 128, 239, 184, 143] // 1f6a3_200d_2640_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 143, 138, 226, 128, 141, 226, 153, 130, 239, 184, 143] // 1f3ca_200d_2642_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 143, 138, 226, 128, 141, 226, 153, 128, 239, 184, 143] // 1f3ca_200d_2640_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 154, 180, 226, 128, 141, 226, 153, 130, 239, 184, 143] // 1f6b4_200d_2642_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 154, 180, 226, 128, 141, 226, 153, 128, 239, 184, 143] // 1f6b4_200d_2640_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 154, 181, 226, 128, 141, 226, 153, 130, 239, 184, 143] // 1f6b5_200d_2642_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 164, 184, 226, 128, 141, 226, 153, 130, 239, 184, 143] // 1f938_200d_2642_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 164, 184, 226, 128, 141, 226, 153, 128, 239, 184, 143] // 1f938_200d_2640_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 164, 188, 226, 128, 141, 226, 153, 130, 239, 184, 143] // 1f93c_200d_2642_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 154, 181, 226, 128, 141, 226, 153, 128, 239, 184, 143] // 1f6b5_200d_2640_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 164, 188, 226, 128, 141, 226, 153, 128, 239, 184, 143] // 1f93c_200d_2640_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 164, 189, 226, 128, 141, 226, 153, 130, 239, 184, 143] // 1f93d_200d_2642_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 164, 189, 226, 128, 141, 226, 153, 128, 239, 184, 143] // 1f93d_200d_2640_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 164, 190, 226, 128, 141, 226, 153, 130, 239, 184, 143] // 1f93e_200d_2642_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 164, 190, 226, 128, 141, 226, 153, 128, 239, 184, 143] // 1f93e_200d_2640_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 164, 185, 226, 128, 141, 226, 153, 130, 239, 184, 143] // 1f939_200d_2642_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 154, 163, 226, 128, 141, 226, 153, 130, 239, 184, 143] // 1f6a3_200d_2642_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 167, 152, 226, 128, 141, 226, 153, 130, 239, 184, 143] // 1f9d8_200d_2642_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 167, 152, 226, 128, 141, 226, 153, 128, 239, 184, 143] // 1f9d8_200d_2640_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 144, 187, 226, 128, 141, 226, 157, 132, 239, 184, 143] // 1f43b_200d_2744_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 143, 179, 239, 184, 143, 226, 128, 141, 240, 159, 140, 136] // 1f3f3_fe0f_200d_1f308
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 164, 185, 226, 128, 141, 226, 153, 128, 239, 184, 143] // 1f939_200d_2640_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 143, 131, 226, 128, 141, 226, 153, 128, 239, 184, 143] // 1f3c3_200d_2640_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 176, 226, 128, 141, 226, 153, 130, 239, 184, 143] // 1f470_200d_2642_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 143, 180, 226, 128, 141, 226, 152, 160, 239, 184, 143] // 1f3f4_200d_2620_fe0f
        );

        emojis
    }

    public(friend) fun five_character_emojis(): vector<vector<u8>> {
        let emojis: vector<vector<u8>> = vector[];

        vector::push_back(&mut emojis,
            vector[240, 159, 145, 129, 239, 184, 143, 226, 128, 141, 240, 159, 151, 168, 239, 184, 143] // 1f441_fe0f_200d_1f5e8_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 149, 181, 239, 184, 143, 226, 128, 141, 226, 153, 130, 239, 184, 143] // 1f575_fe0f_200d_2642_fe0f
        );
        vector::push_back(&mut emojis,
            vector[226, 155, 185, 239, 184, 143, 226, 128, 141, 226, 153, 130, 239, 184, 143] // 26f9_fe0f_200d_2642_fe0f
        );
        vector::push_back(&mut emojis,
            vector[226, 155, 185, 239, 184, 143, 226, 128, 141, 226, 153, 128, 239, 184, 143] // 26f9_fe0f_200d_2640_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 143, 139, 239, 184, 143, 226, 128, 141, 226, 153, 130, 239, 184, 143] // 1f3cb_fe0f_200d_2642_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 143, 139, 239, 184, 143, 226, 128, 141, 226, 153, 128, 239, 184, 143] // 1f3cb_fe0f_200d_2640_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 167, 145, 226, 128, 141, 240, 159, 164, 157, 226, 128, 141, 240, 159, 167, 145] // 1f9d1_200d_1f91d_200d_1f9d1
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 168, 226, 128, 141, 240, 159, 145, 169, 226, 128, 141, 240, 159, 145, 167] // 1f468_200d_1f469_200d_1f467
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 168, 226, 128, 141, 240, 159, 145, 169, 226, 128, 141, 240, 159, 145, 166] // 1f468_200d_1f469_200d_1f466
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 168, 226, 128, 141, 240, 159, 145, 168, 226, 128, 141, 240, 159, 145, 166] // 1f468_200d_1f468_200d_1f466
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 168, 226, 128, 141, 240, 159, 145, 168, 226, 128, 141, 240, 159, 145, 167] // 1f468_200d_1f468_200d_1f467
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 169, 226, 128, 141, 240, 159, 145, 169, 226, 128, 141, 240, 159, 145, 166] // 1f469_200d_1f469_200d_1f466
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 169, 226, 128, 141, 240, 159, 145, 169, 226, 128, 141, 240, 159, 145, 167] // 1f469_200d_1f469_200d_1f467
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 168, 226, 128, 141, 240, 159, 145, 166, 226, 128, 141, 240, 159, 145, 166] // 1f468_200d_1f466_200d_1f466
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 143, 140, 239, 184, 143, 226, 128, 141, 226, 153, 130, 239, 184, 143] // 1f3cc_fe0f_200d_2642_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 149, 181, 239, 184, 143, 226, 128, 141, 226, 153, 128, 239, 184, 143] // 1f575_fe0f_200d_2640_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 143, 140, 239, 184, 143, 226, 128, 141, 226, 153, 128, 239, 184, 143] // 1f3cc_fe0f_200d_2640_fe0f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 168, 226, 128, 141, 240, 159, 145, 167, 226, 128, 141, 240, 159, 145, 166] // 1f468_200d_1f467_200d_1f466
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 169, 226, 128, 141, 240, 159, 145, 166, 226, 128, 141, 240, 159, 145, 166] // 1f469_200d_1f466_200d_1f466
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 169, 226, 128, 141, 240, 159, 145, 167, 226, 128, 141, 240, 159, 145, 166] // 1f469_200d_1f467_200d_1f466
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 168, 226, 128, 141, 240, 159, 145, 167, 226, 128, 141, 240, 159, 145, 167] // 1f468_200d_1f467_200d_1f467
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 169, 226, 128, 141, 240, 159, 145, 167, 226, 128, 141, 240, 159, 145, 167] // 1f469_200d_1f467_200d_1f467
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 143, 179, 239, 184, 143, 226, 128, 141, 226, 154, 167, 239, 184, 143] // 1f3f3_fe0f_200d_26a7_fe0f
        );

        emojis
    }

    public(friend) fun six_character_emojis(): vector<vector<u8>> {
        let emojis: vector<vector<u8>> = vector[];

        vector::push_back(&mut emojis,
            vector[240, 159, 145, 169, 226, 128, 141, 226, 157, 164, 239, 184, 143, 226, 128, 141, 240, 159, 145, 168] // 1f469_200d_2764_fe0f_200d_1f468
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 168, 226, 128, 141, 226, 157, 164, 239, 184, 143, 226, 128, 141, 240, 159, 145, 168] // 1f468_200d_2764_fe0f_200d_1f468
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 169, 226, 128, 141, 226, 157, 164, 239, 184, 143, 226, 128, 141, 240, 159, 145, 169] // 1f469_200d_2764_fe0f_200d_1f469
        );

        emojis
    }

    public(friend) fun seven_character_emojis(): vector<vector<u8>> {
        let emojis: vector<vector<u8>> = vector[];

        vector::push_back(&mut emojis,
            vector[240, 159, 145, 168, 226, 128, 141, 240, 159, 145, 169, 226, 128, 141, 240, 159, 145, 167, 226, 128, 141, 240, 159, 145, 166] // 1f468_200d_1f469_200d_1f467_200d_1f466
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 169, 226, 128, 141, 240, 159, 145, 169, 226, 128, 141, 240, 159, 145, 167, 226, 128, 141, 240, 159, 145, 166] // 1f469_200d_1f469_200d_1f467_200d_1f466
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 169, 226, 128, 141, 240, 159, 145, 169, 226, 128, 141, 240, 159, 145, 166, 226, 128, 141, 240, 159, 145, 166] // 1f469_200d_1f469_200d_1f466_200d_1f466
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 168, 226, 128, 141, 240, 159, 145, 168, 226, 128, 141, 240, 159, 145, 167, 226, 128, 141, 240, 159, 145, 167] // 1f468_200d_1f468_200d_1f467_200d_1f467
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 168, 226, 128, 141, 240, 159, 145, 169, 226, 128, 141, 240, 159, 145, 166, 226, 128, 141, 240, 159, 145, 166] // 1f468_200d_1f469_200d_1f466_200d_1f466
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 169, 226, 128, 141, 240, 159, 145, 169, 226, 128, 141, 240, 159, 145, 167, 226, 128, 141, 240, 159, 145, 167] // 1f469_200d_1f469_200d_1f467_200d_1f467
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 143, 180, 243, 160, 129, 167, 243, 160, 129, 162, 243, 160, 129, 165, 243, 160, 129, 174, 243, 160, 129, 167, 243, 160, 129, 191] // 1f3f4_e0067_e0062_e0065_e006e_e0067_e007f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 168, 226, 128, 141, 240, 159, 145, 168, 226, 128, 141, 240, 159, 145, 167, 226, 128, 141, 240, 159, 145, 166] // 1f468_200d_1f468_200d_1f467_200d_1f466
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 143, 180, 243, 160, 129, 167, 243, 160, 129, 162, 243, 160, 129, 179, 243, 160, 129, 163, 243, 160, 129, 180, 243, 160, 129, 191] // 1f3f4_e0067_e0062_e0073_e0063_e0074_e007f
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 168, 226, 128, 141, 240, 159, 145, 168, 226, 128, 141, 240, 159, 145, 166, 226, 128, 141, 240, 159, 145, 166] // 1f468_200d_1f468_200d_1f466_200d_1f466
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 168, 226, 128, 141, 240, 159, 145, 169, 226, 128, 141, 240, 159, 145, 167, 226, 128, 141, 240, 159, 145, 167] // 1f468_200d_1f469_200d_1f467_200d_1f467
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 143, 180, 243, 160, 129, 167, 243, 160, 129, 162, 243, 160, 129, 183, 243, 160, 129, 172, 243, 160, 129, 179, 243, 160, 129, 191] // 1f3f4_e0067_e0062_e0077_e006c_e0073_e007f
        );

        emojis
    }

    public(friend) fun eight_character_emojis(): vector<vector<u8>> {
        let emojis: vector<vector<u8>> = vector[];

        vector::push_back(&mut emojis,
            vector[240, 159, 145, 169, 226, 128, 141, 226, 157, 164, 239, 184, 143, 226, 128, 141, 240, 159, 146, 139, 226, 128, 141, 240, 159, 145, 168] // 1f469_200d_2764_fe0f_200d_1f48b_200d_1f468
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 168, 226, 128, 141, 226, 157, 164, 239, 184, 143, 226, 128, 141, 240, 159, 146, 139, 226, 128, 141, 240, 159, 145, 168] // 1f468_200d_2764_fe0f_200d_1f48b_200d_1f468
        );
        vector::push_back(&mut emojis,
            vector[240, 159, 145, 169, 226, 128, 141, 226, 157, 164, 239, 184, 143, 226, 128, 141, 240, 159, 146, 139, 226, 128, 141, 240, 159, 145, 169] // 1f469_200d_2764_fe0f_200d_1f48b_200d_1f469
        );

        emojis
    }
}
