module suins_voting::constants;

/// The minimum voting period in milliseconds. (1 day)
public macro fun min_voting_period_ms(): u64 {
    1000 * 60 * 60 * 24 * 1
}

/// The maximum voting period in milliseconds. (14 days)
public macro fun max_voting_period_ms(): u64 {
    1000 * 60 * 60 * 24 * 14
}
