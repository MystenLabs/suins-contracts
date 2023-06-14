// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
/// Testing strategy:
///
/// - create config and make sure the values can be retrieved and updated
/// - price calculation should be correct for each length and duration
/// - config must save the user from making a dummy mistake and provide
///   the basic validation for parameters (public_key, years, other settings)
///
module suins::config_tests {
    use suins::config::{Self, Config};
    use sui::ecdsa_k1;

    // consts for fees (starting prices)
    const THREE: u64 = 9_000_000_000; // 9 SUI
    const FOUR: u64 = 5_000_000_000; // 5 SUI
    const FIVE_PLUS: u64 = 2_000_000_000; // 2 SUI

    #[test]
    fun create_and_update_config() {
        let config = default();

        // check that the values are set correctly in the `new` function
        assert!(config::public_key(&config) == &b"000000000000000000000000000000000", 0);
        assert!(config::three_char_price(&config) == THREE, 0);
        assert!(config::four_char_price(&config) == FOUR, 0);
        assert!(config::five_plus_char_price(&config) == FIVE_PLUS, 0);

        // update each of the values and make sure they are updated
        config::set_public_key(&mut config, b"000000000000000000000000000000001");
        config::set_three_char_price(&mut config, 4_000_000_000);
        config::set_four_char_price(&mut config, 3_000_000_000);
        config::set_five_plus_char_price(&mut config, 1_000_000_000);

        // check that the updated values match the new ones
        assert!(config::public_key(&config) == &b"000000000000000000000000000000001", 0);
        assert!(config::three_char_price(&config) == 4_000_000_000, 0);
        assert!(config::four_char_price(&config) == 3_000_000_000, 0);
        assert!(config::five_plus_char_price(&config) == 1_000_000_000, 0);
    }

    #[test]
    fun calculate_price() {
        let config = default();

        // test each of the length ranges and 1 year duration
        assert!(THREE == config::calculate_price(&config, 3, 1), 0);
        assert!(FOUR == config::calculate_price(&config, 4, 1), 0);
        assert!(FIVE_PLUS == config::calculate_price(&config, 5, 1), 0);
        assert!(FIVE_PLUS == config::calculate_price(&config, 6, 1), 0);

        // test each of the length ranges and 2 year duration
        assert!(THREE * 2 == config::calculate_price(&config, 3, 2), 0);
        assert!(FOUR * 2 == config::calculate_price(&config, 4, 2), 0);
        assert!(FIVE_PLUS * 2 == config::calculate_price(&config, 5, 2), 0);
        assert!(FIVE_PLUS * 2 == config::calculate_price(&config, 6, 2), 0);
    }

    #[test]
    #[expected_failure(abort_code = suins::config::ENoYears)]
    fun calculate_price_years_fail() {
        config::calculate_price(&default(), 3, 0);
    }

    #[test]
    #[expected_failure(abort_code = suins::config::ELabelTooShort)]
    fun calculate_price_length_min_fail() {
        config::calculate_price(&default(), 2, 1);
    }

    #[test]
    #[expected_failure(abort_code = suins::config::ELabelTooLong)]
    fun calculate_price_length_max_fail() {
        config::calculate_price(&default(), 255, 1);
    }

    #[test]
    #[expected_failure(abort_code = suins::config::EInvalidPublicKey)]
    fun new_invalid_public_key_fail() {
        config::new(
            vector[],
            0, 0, 0
        );
    }

    #[test]
    #[expected_failure(abort_code = suins::config::EInvalidPublicKey)]
    fun set_public_key_invalid_fail() {
        let config = default();
        config::set_public_key(&mut config, vector[]);
    }

    #[test]
    fun set_public_key_has_33_bytes() {
        let pubkey = x"034646ae5047316b4230d0086c8acec687f00b1cd9d1dc634f6cb358ac0a9a8fff";
        let signature =
            x"f2ecd870cfa290019c28f57c767e38a96b1544786126a84bdc250888e70ebee541abc8cf84c32a8d05331c42c403b6cb64e7aee9efe13eff7c7c2da60d294281";
        assert!(ecdsa_k1::secp256k1_verify(&signature, &pubkey, &b"helloworld", 1), 0);
    }

    // create a default configuration for tests
    fun default(): Config {
        config::new(
            b"000000000000000000000000000000000",
            THREE, // 3 symbol length (9 SUI)
            FOUR, // 4 symbol length (5 SUI)
            FIVE_PLUS, // 5 symbol length (2 SUI)
        )
    }
}
