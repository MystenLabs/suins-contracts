// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module suins_voting::leaderboard_tests;

use suins_voting::leaderboard;

#[test]
fun test_multi_insertions() {
    let mut leaderboard = leaderboard::new(3);

    leaderboard.add_if_eligible(@0x0, 10);
    leaderboard.add_if_eligible(@0x1, 20);
    leaderboard.add_if_eligible(@0x2, 30);
    leaderboard.add_if_eligible(@0x3, 40);
    // this should override the first entry
    leaderboard.add_if_eligible(@0x3, 65);
    leaderboard.add_if_eligible(@0x4, 25);
    leaderboard.add_if_eligible(@0x5, 15);
    leaderboard.add_if_eligible(@0x6, 20);

    assert!(leaderboard.entries().length() == 3);
    assert!(leaderboard.entries()[0].value() == 65);
    assert!(leaderboard.entries()[1].value() == 30);
    assert!(leaderboard.entries()[2].value() == 25);
}

#[test, expected_failure(abort_code = ::suins_voting::leaderboard::EInvalidMaxSize)]
fun create_zero_sized_leaderboard() {
    let _leaderboard = leaderboard::new(0);
}

#[test, expected_failure(abort_code = ::suins_voting::leaderboard::EInvalidMaxSize)]
fun create_too_large_leaderboard() {
    let _leaderboard = leaderboard::new(1000);
}
