module suins_bbb::bbb_admin;

// === structs ===

public struct BBBAdminCap has key, store {
    id: UID,
}

// === initialization ===

public struct BBB_ADMIN has drop {}

fun init(
    _otw: BBB_ADMIN,
    ctx: &mut TxContext,
) {
    let cap = BBBAdminCap { id: object::new(ctx) };
    transfer::transfer(cap, ctx.sender());
}
