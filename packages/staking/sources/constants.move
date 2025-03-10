module staking::constants;

/// 1 day in milliseconds
public macro fun day_ms(): u64 {
    1000 * 60 * 60 * 24
}

/// 30 days in milliseconds
public macro fun month_ms(): u64 {
    30 * day_ms!()
}

public macro fun cooldown_period_ms(): u64 {
    3 * day_ms!()
}

public macro fun max_lock_months(): u64 {
    12
}
