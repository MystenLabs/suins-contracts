// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

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
            76,22,86,253,18,34,106,113,248,175,58,88,7,191,242,70,50,38,150,221,239,43,7,155,95,107,223,224,196,220,142,62,116,188,153,182,162,82,55,223,159,152,42,147,212,205,73,30,74,165,193,185,24,165,70,21,190,24,84,138,43,65,243,22
        ],
        vector[
            17,14,201,154,177,6,140,97,255,251,14,120,221,124,232,133,90,174,211,7,101,42,167,204,101,123,206,206,165,62,41,144,100,55,4,114,127,178,208,79,124,206,240,47,245,234,236,24,60,72,55,50,189,240,111,137,69,244,40,225,206,114,21,51
        ],
        vector[
            239,187,105,3,81,191,245,121,123,98,46,112,107,28,21,128,146,206,147,76,60,243,69,70,247,12,186,121,227,112,237,209,45,168,32,226,114,148,44,151,138,137,211,253,29,245,80,223,171,136,82,0,55,197,148,187,210,36,172,136,129,229,66,119
        ],
        vector[
      78,151,45,191,133,242,178,189,64,203,66,73,190,250,154,225,29,73,255,175,99,56,83,30,96,171,38,147,46,89,83,221,66,92,145,167,90,220,105,5,249,111,33,32,55,219,164,148,10,115,137,85,201,84,247,157,69,91,124,250,96,248,33,14  ],
    ];

    // mapping between discord_id -> address
    // index 0: discord_id_1 : 0x5
    // index2:  discord_id_2 : 0x6
    const ADDRESS_MAPPING_SIGNATURES: vector<vector<u8>> = vector[
        vector[
            178,191,128,212,227,47,242,225,25,196,0,153,128,122,133,2,247,137,187,141,229,153,116,250,126,212,136,8,142,24,104,3,100,17,241,63,195,228,75,220,53,92,70,156,51,61,134,176,204,234,56,82,0,21,13,68,135,222,177,254,144,153,230,175   ],
        vector [
            164,150,220,183,98,107,123,12,27,30,168,206,146,226,88,154,139,195,177,86,126,67,172,85,235,236,85,61,11,230,233,100,106,199,154,3,229,49,105,79,88,140,112,158,120,157,249,37,242,165,186,89,78,11,239,198,128,94,160,200,106,40,26,220
        ]
    ];


    public fun get_nth_attach_roles_signature(i: u64): vector<u8> {
         *vector::borrow(&SIGNED_MESSAGES, i)
    }

    public fun get_nth_address_mapping_signature(i: u64): vector<u8> {
        *vector::borrow(&ADDRESS_MAPPING_SIGNATURES, i)
    }

}
