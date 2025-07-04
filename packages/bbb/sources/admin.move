module suins_bbb::bbb_admin;

public struct BBBAdminCap has key, store {
    id: UID,
}

public struct BBB_ADMIN has drop {}

fun init(_otw: BBB_ADMIN, ctx: &mut TxContext) {
    transfer::transfer(
        BBBAdminCap { id: object::new(ctx) },
        ctx.sender(),
    );
}
