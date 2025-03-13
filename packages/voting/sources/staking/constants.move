module suins_voting::staking_constants;

/// 1 day in milliseconds
public macro fun day_ms(): u64 {
    1000 * 60 * 60 * 24
}

/// 30 days in milliseconds
public macro fun month_ms(): u64 {
    30 * day_ms!()
}
