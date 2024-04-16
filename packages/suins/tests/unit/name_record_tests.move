// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
/// Testing strategy:
///
/// - check that default values are set correctly and that updates are correct
/// - IMPORTANT: test the `has_expired` function and make sure that grace period
///   and the expiration timestamp are working correctly;
///
module suins::name_record_tests {
    use std::{string::utf8, option::{none, some}};
    use sui::{test_utils::assert_eq, vec_map, clock};

    use suins::{name_record as record, constants};

    #[test]
    /// Make sure that the fields are empty by default. That they are updated
    /// correctly and the values match.
    fun create_and_update() {
        let mut ctx = tx_context::dummy();
        let nft_id = fresh_id(&mut ctx);
        let mut record = record::new(nft_id, 0);

        // check default values
        assert_eq(record.nft_id(), nft_id);
        assert_eq(*record.data(), vec_map::empty());
        assert_eq(record.target_address(), none());
        assert_eq(record.expiration_timestamp_ms(), 0);

        let mut data = vec_map::empty();
        data.insert(utf8(b"user_name"), utf8(b"Brandon"));
        data.insert(utf8(b"age"), utf8(b"forever young"));

        // update values
        record.set_data(*&data);
        record.set_target_address(some(@suins));
        record.set_expiration_timestamp_ms(123456789); // 123456789 ms = 3.9 years

        // check updated values
        assert_eq(record.nft_id(), nft_id);
        assert_eq(*record.data(), data);
        assert_eq(record.target_address(), some(@suins));
        assert_eq(record.expiration_timestamp_ms(), 123456789);
    }

    #[test]
    fun has_expired() {
        let mut ctx = tx_context::dummy();
        let nft_id = fresh_id(&mut ctx);
        let record = record::new(nft_id, 1000); // expires in 1 second
        let mut clock = clock::create_for_testing(&mut ctx);

        // clock is 0, record expires in 1 second with a 30 days (grace period)
        assert_eq(record.has_expired(&clock), false);
        assert_eq(record.has_expired_past_grace_period(&clock), false);

        // increment time by 30 days to check if the grace period is working;
        // in just 1 second from that the record will expire
        clock.increment_for_testing(constants::grace_period_ms());
        assert_eq(record.has_expired(&clock), true);
        assert_eq(record.has_expired_past_grace_period(&clock), false);

        // increment time by 1 second to check if record has expired
        clock.increment_for_testing(constants::grace_period_ms() + 1000);
        assert_eq(record.has_expired(&clock), true);
        assert_eq(record.has_expired_past_grace_period(&clock), true);

        clock.destroy_for_testing();
    }

    fun fresh_id(ctx: &mut TxContext): ID {
        object::id_from_address(
            tx_context::fresh_object_address(ctx)
        )
    }
}
