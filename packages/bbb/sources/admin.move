module suins_bbb::bbb_admin;

// === structs ===

public struct BBBAdminCap has key, store {
    id: UID,
}

/// one-time witness
public struct BBB_ADMIN has drop {}

// === initialization ===

fun init(
    _otw: BBB_ADMIN,
    ctx: &mut TxContext,
) {
    let cap = BBBAdminCap { id: object::new(ctx) };
    transfer::transfer(cap, ctx.sender());
}

// === test functions ===

#[test_only]
public fun init_for_testing(
    ctx: &mut TxContext,
) {
    let otw = BBB_ADMIN {};
    init(otw, ctx);
}
