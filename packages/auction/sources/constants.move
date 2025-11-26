module suins_auction::constants;

// Constants

const VERSION: u64 = 1;
const BID_EXTEND_TIME: u64 = 5 * 60; // 5 minutes
const MAX_PERCENTAGE: u64 = 100_000; // 100%
const DEFAULT_FEE_PERCENTAGE: u64 = 2_500; // 2.5%

// === Public functions ===

/// Returns the current version of the auction contract
public fun version(): u64 { VERSION }

/// Returns the bid extend time in seconds
public fun bid_extend_time(): u64 { BID_EXTEND_TIME }

/// Returns the maximum percentage value
public fun max_percentage(): u64 { MAX_PERCENTAGE }

/// Returns the default service fee percentage
public fun default_fee_percentage(): u64 { DEFAULT_FEE_PERCENTAGE }
