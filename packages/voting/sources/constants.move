// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module suins_voting::constants;

/// The minimum voting period in milliseconds. (1 day)
public(package) macro fun min_voting_period_ms(): u64 {
    day_ms!() * 1
}

/// The maximum voting period in milliseconds. (14 days)
public(package) macro fun max_voting_period_ms(): u64 {
    day_ms!() * 14
}

/// 1 day in milliseconds
public(package) macro fun day_ms(): u64 {
    1000 * 60 * 60 * 24
}

/// 30 days in milliseconds
public(package) macro fun month_ms(): u64 {
    day_ms!() * 30
}
