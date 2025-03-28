// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module suins_discord::test_payloads;

use std::string::{String, utf8};

// This Private & Public Key are used only for the tests.
// DO NOT USE FOR ANY OTHER USE-CASE.
// The signatures were generated manually using them.
const PUBLIC_KEY: vector<u8> = vector[
    4, 177, 184, 19, 176, 151, 134, 25, 40, 7, 168, 22, 178, 146, 103, 231, 118, 184, 226, 112, 30,
    112, 60, 79, 82, 48, 21, 178, 230, 245, 196, 0, 33, 215, 72, 73, 76, 69, 45, 51, 238, 183, 5,
    116, 103, 167, 55, 47, 141, 122, 164, 235, 152, 113, 12, 66, 220, 0, 89, 40, 222, 144, 54, 204,
    180,
];

// const PRIVATE_KEY: vector<u8> = vector[
//     41,57,20,16,48,176,168,150,45,108,210,160,72,179,198,136,55,154,99,223,169,111,177,151,119,241,163,34,227,94,174,212
// ];

// some sample roles & percentages
const ROLES: vector<u8> = vector[0, 1, 2, 3, 4];
const PERCENTAGES: vector<u8> = vector[20, 30, 100, 50, 60];

const ADDRESSES: vector<address> = vector[@0x5, @0x6, @0x7];
const DISCORD_IDS: vector<vector<u8>> = vector[b"discord_id_1", b"discord_id_2"];

public fun get_public_key(): vector<u8> {
    PUBLIC_KEY
}

public fun get_nth_user(i: u64): address {
    ADDRESSES[i]
}

public fun get_nth_role(i: u64): u8 {
    ROLES[i]
}

public fun get_nth_role_percentage(i: u64): u8 {
    PERCENTAGES[i]
}

public fun get_nth_discord_id(i: u64): String {
    utf8(DISCORD_IDS[i])
}

// A list of singed messages.

// index 0: discord_id_1 + [0,1] roles -> discord_id_1 has maximum of 50% discount.
// index 1: discord_id_1 + [1,3] roles (check overlap abort)
// index 2: discord_id_2 + [2,3] roles -> discord_id_2 has maximum of 150% discount.
// index 3: discord_id_2 + [5] roles (check non-existing role addition)
// prettier-ignore
const SIGNED_MESSAGES: vector<vector<u8>> = vector[
    vector[105,42,23,89,169,88,11,179,47,36,192,254,188,47,205,43,5,90,189,216,117,222,85,208,79,123,27,171,178,110,210,142,27,129,237,16,104,239,13,206,187,126,182,105,229,110,242,43,61,54,47,120,174,109,238,112,3,8,53,248,7,65,161,16],
    vector[248,231,188,11,131,135,248,201,97,171,85,72,55,165,16,68,92,57,84,25,8,231,162,243,118,206,152,133,149,226,104,184,41,90,23,72,125,111,104,152,228,203,249,100,56,128,178,251,96,48,109,242,211,231,221,187,2,220,156,191,92,216,80,218],
    vector[196,231,220,181,211,72,131,106,104,57,169,215,200,90,59,133,174,90,31,246,244,208,155,167,96,207,12,45,136,251,218,19,20,190,111,206,120,229,183,107,199,124,76,93,104,9,75,230,150,250,98,127,126,48,155,184,135,56,47,17,105,213,82,133],
    vector[141,172,35,213,222,139,7,252,39,254,225,93,172,118,29,178,146,153,7,74,9,229,17,196,203,118,95,84,44,59,214,158,71,103,95,137,177,133,109,65,241,62,189,160,31,134,32,176,43,161,67,172,189,167,250,140,139,154,163,132,30,219,172,57],
];

// mapping between discord_id -> address
// index 0: discord_id_1 : 0x5
// index2:  discord_id_2 : 0x6
// prettier-ignore
const ADDRESS_MAPPING_SIGNATURES: vector<vector<u8>> = vector[
    vector[222,90,232,68,190,121,104,148,106,213,78,28,141,55,222,243,174,154,53,58,151,69,5,1,73,8,132,152,80,96,24,244,125,215,21,11,156,197,57,150,233,59,81,36,33,59,212,79,134,160,114,9,19,30,145,38,211,61,29,8,221,108,29,144],
    vector[170,142,191,35,165,75,154,136,163,51,150,87,228,232,189,66,214,110,135,104,20,120,205,137,104,57,203,43,5,189,67,218,94,253,147,138,234,230,166,190,246,163,16,202,10,28,198,64,1,165,133,75,183,179,88,186,181,7,164,238,97,22,74,190]
];

public fun get_nth_attach_roles_signature(i: u64): vector<u8> {
    SIGNED_MESSAGES[i]
}

public fun get_nth_address_mapping_signature(i: u64): vector<u8> {
    ADDRESS_MAPPING_SIGNATURES[i]
}
