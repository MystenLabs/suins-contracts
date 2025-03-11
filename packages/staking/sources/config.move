module staking::config;

/// how long it takes to unstake a batch
public macro fun cooldown_ms(): u64 {
    3 * day_ms!()
}

/// max number of months a batch can be staked for
public macro fun max_lock_months(): u64 {
    12
}

/// monthly power multiplier for staked/locked batches
public macro fun monthly_boost_pct(): u64 {
    110 // 110% / 1.1x
}

/// max multiplier when locking a batch for `max_lock_months`
public macro fun max_boost_pct(): u64 {
    300 // 300% / 3.0x
}

/// minimum NS balance allowed in a batch
public macro fun min_balance(): u64 {
    1000 // 0.001 NS
}

/// 1 day in milliseconds
public macro fun day_ms(): u64 {
    1000 * 60 * 60 * 24
}

/// 30 days in milliseconds
public macro fun month_ms(): u64 {
    30 * day_ms!()
}
