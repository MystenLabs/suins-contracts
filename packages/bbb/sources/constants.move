module suins_bbb::bbb_constants;

/// Swap slippage is represented as `1 - slippage` in 18-decimal fixed point.
/// E.g., 2% slippage = 980_000_000_000_000_000 (represents 0.98).
public macro fun slippage_scale(): u256 {
    1_000_000_000_000_000_000
}
