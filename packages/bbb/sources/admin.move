module suins_bbb::bbb_admin;

// === structs ===

public struct BBBAdminCap has key, store {
    id: UID,
}

public fun id(self: &BBBAdminCap): ID { self.id.to_inner() }

fun new(ctx: &mut TxContext): BBBAdminCap {
    BBBAdminCap { id: object::new(ctx) }
}

// === initialization ===

public struct BBB_ADMIN has drop {}

fun init(
    _otw: BBB_ADMIN,
    ctx: &mut TxContext,
) {
    transfer::transfer(new(ctx), ctx.sender());
}
