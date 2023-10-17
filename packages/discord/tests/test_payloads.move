// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module discord::test_payloads{
    use std::vector;
    use std::string::{String, utf8};

    // This Private & Public Key are used only for the tests.
    // DO NOT USE FOR ANY OTHER USE-CASE.
    // The signatures were generated manually using them.
    const PUBLIC_KEY: vector<u8> = vector[
        4,177,184,19,176,151,134,25,40,7,168,22,178,146,103,231,118,184,226,112,30,112,60,79,82,48,21,178,230,245,196,0,33,215,72,73,76,69,45,51,238,183,5,116,103,167,55,47,141,122,164,235,152,113,12,66,220,0,89,40,222,144,54,204,180
    ];

    const PRIVATE_KEY: vector<u8> = vector[
        41,57,20,16,48,176,168,150,45,108,210,160,72,179,198,136,55,154,99,223,169,111,177,151,119,241,163,34,227,94,174,212
    ];

    // some sample roles & percentages
    const ROLES: vector<u8> = vector[0,1,2,3,4];
    const PERCENTAGES: vector<u8> = vector[20,30,100,50,60];

    const ADDRESSES: vector<address> = vector[@0x5, @0x6, @0x7];
    const DISCORD_IDS: vector<vector<u8>> = vector[b"discord_id_1", b"discord_id_2"];

    public fun get_public_key(): vector<u8>{
        PUBLIC_KEY
    }

    public fun get_nth_user(i: u64): address {
        *vector::borrow(&ADDRESSES, i)
    }

    public fun get_nth_role(i: u64): u8 {
         *vector::borrow(&ROLES, i)
    }

    public fun get_nth_role_percentage(i: u64): u8 {
         *vector::borrow(&PERCENTAGES, i)
    }

    public fun get_nth_discord_id(i: u64): String {
        let id = vector::borrow(&DISCORD_IDS, i);
        utf8(*id)
    }

    // A list of singed messages.

    // index 0: discord_id_1 + [0,1] roles -> discord_id_1 has maximum of 50% discount.
    // index 1: discord_id_1 + [1,3] roles (check overlap abort)
    // index 2: discord_id_2 + [2,3] roles -> discord_id_2 has maximum of 150% discount.
    // index 3: discord_id_2 + [5] roles (check non-existing role addition)
    const SIGNED_MESSAGES: vector<vector<u8>> = vector[
        vector[
            243, 239,  87, 201,  77, 233, 247, 188, 176, 224, 120,
            96,  61, 127, 192, 166, 133, 214, 201, 229, 179,  81,
            249, 183,  52, 230,   5, 203, 194,  50, 198, 146,  37,
            249,  78, 116,  38, 208, 236,  47, 111,  93,  84,  26,
            49,  26, 214,  84,  61, 198, 197, 202, 111, 123,  86,
            161, 117, 129, 248, 143, 104,  45, 146,  73
            ],
        vector[
            119, 219, 230,   8,  13, 193, 235,  97,  98, 244, 121,
            41, 200, 107,  98, 121, 100,  26,  25, 250, 116, 246,
            25, 165, 169, 130, 146, 120, 255, 200, 170,   4,  43,
            175,  74, 192, 183,  64,  39, 187,  67,  99, 160,  87,
            214,   0,  43,  67, 251, 228, 204, 196,  52, 202, 109,
            233,  41, 103, 200, 210, 221, 166,  98, 105
            ],
        vector[
                    127,  51,  10,  50, 206, 150,  93, 239, 183, 105, 157,
            242, 210, 168,   0, 194, 142, 121,  30,  28, 102,  73,
            151, 224,  85, 147,  26, 201, 160, 153, 197, 215, 103,
            188, 128,  61, 225,  56, 243, 171,  61,  74, 115,  14,
            77,  91,  64, 146,   1,  77,  82, 217,  39, 117, 133,
            101, 111,  90, 247,  33, 126, 248,  31, 107
        ],
        vector[
                251, 193,  44, 186,  44, 122,  78, 114, 111, 183, 183,
            104, 240,  11,  92, 229, 193, 104, 110,  90,  43, 254,
            91,  73, 243, 153, 228, 171,  17, 152,  26, 217, 104,
            14, 195, 183,  96,  38,  69, 100, 246, 162, 147, 244,
            223, 207, 255, 132, 253,  38,  96,  73, 154, 175,  42,
            165, 157, 237,  87,  27,  20, 245, 186, 149
        ]
];

    // mapping between discord_id -> address
    // index 0: discord_id_1 : 0x5
    // index2:  discord_id_2 : 0x6
    const ADDRESS_MAPPING_SIGNATURES: vector<vector<u8>> = vector[
        vector[
            10,  73,  65, 184,  87,   9, 136,  21,  21, 183, 255,
            254, 191, 108,  53, 167,  22, 172,  34,  27, 115,  16,
            202, 137, 137, 238, 255, 141, 103, 238, 224,  72, 101,
            62, 142, 102, 108, 142, 111, 187,  75,  31,  37,  55,
            217,  20,  81, 128, 235,  52, 156, 117, 158,  98,  66,
            71, 133,  46, 209,  92, 116,  73,  85, 147
        ],
        vector [
            16, 111, 191, 124,  10, 102, 184, 188, 189,  22, 180,
            65, 236,  34,  36,  80,   3, 126, 145,  22, 199, 250,
            35,  35, 100, 125, 116,  86, 171, 152, 158,  35, 100,
            12,  72,  78, 162, 238,   3,  82, 229,  96,  71, 137,
            36, 165, 186,  95, 213, 230, 206, 167, 113, 222, 112,
            175, 202, 128, 100, 254, 114,  86, 122,  58
        ]
    ];


    public fun get_nth_attach_roles_signature(i: u64): vector<u8> {
         *vector::borrow(&SIGNED_MESSAGES, i)
    }

    public fun get_nth_address_mapping_signature(i: u64): vector<u8> {
        *vector::borrow(&ADDRESS_MAPPING_SIGNATURES, i)
    }

}
