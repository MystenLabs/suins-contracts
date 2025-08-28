module suins_voting::staking_admin;

// === structs ===

public struct StakingAdminCap has key, store {
    id: UID,
}

/// one-time witness
public struct STAKING_ADMIN has drop {}

// === initialization ===

fun init(_otw: STAKING_ADMIN, ctx: &mut TxContext) {
    let cap = StakingAdminCap { id: object::new(ctx) };
    transfer::transfer(cap, ctx.sender());
}

// === test functions ===

#[test_only]
public fun init_for_testing(ctx: &mut TxContext) {
    let otw = STAKING_ADMIN {};
    init(otw, ctx);
}
